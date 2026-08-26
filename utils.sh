#!/usr/bin/env bash

MODULE_TEMPLATE_DIR="module"
CWD=$(pwd)
TEMP_DIR="temp"
BIN_DIR="bin"
BUILD_DIR="build"
# Prioritized source list: APKMirror -> Uptodown -> GitHub -> Direct override -> Archive
DL_SRCS=("apkmirror" "uptodown" "github" "direct" "archive")

if [ "${GITHUB_TOKEN-}" ]; then GH_HEADER="Authorization: token ${GITHUB_TOKEN}"; else GH_HEADER=; fi
NEXT_VER_CODE=${NEXT_VER_CODE:-$(date +'%Y%m%d')}
OS=$(uname -o)

DEF_PATCHES_SRC="github:MorpheApp/morphe-patches"
DEF_CLI_SRC="github:MorpheApp/morphe-desktop"

toml_prep() {
	if [ ! -f "$1" ]; then return 1; fi
	if [ "${1##*.}" == toml ]; then
		__TOML__=$($TOML --output json --file "$1" .)
	elif [ "${1##*.}" == json ]; then
		__TOML__=$(cat "$1")
	else abort "config extension not supported"; fi
}
toml_get_table_names() { jq -r -e 'to_entries[] | select(.value | type == "object") | .key' <<<"$__TOML__"; }
toml_get_table_main() { jq -r -e 'to_entries | map(select(.value | type != "object")) | from_entries' <<<"$__TOML__"; }
toml_get_table() { jq -r -e ".\"${1}\"" <<<"$__TOML__"; }
toml_get() {
	local op quote_placeholder=$'\001'
	op=$(jq -r ".\"${2}\" | if type == \"array\" then join(\" \") else . end | values" <<<"$1" 2>/dev/null)
	if [[ -n "$op" && "$op" != "null" ]]; then
		op=$(echo "$op" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
		op=${op//\\\'/$quote_placeholder}
		op=${op//"''"/$quote_placeholder}
		op=${op//"'"/'"'}
		op=${op//$quote_placeholder/$'\''}
		echo "$op"
	else return 1; fi
}

pr() { echo -e "\033[0;32m[+] ${1}\033[0m"; }
epr() {
	echo >&2 -e "\033[0;31m[-] ${1}\033[0m"
	if [ -n "${GITHUB_REPOSITORY:-}" ]; then echo >&2 -e "::error::utils.sh [-] ${1}\n"; fi
}
wpr() {
	echo >&2 -e "\033[0;33m[!] ${1}\033[0m"
	if [ -n "${GITHUB_REPOSITORY:-}" ]; then echo >&2 -e "::warning::utils.sh [!] ${1}\n"; fi
}

_clean_tmp() {
	rm -rf ./${TEMP_DIR}/*tmp.* ./${TEMP_DIR}/*tmp_* ./${TEMP_DIR}/*/*tmp.* ./${TEMP_DIR}/*-temporary-files ./*-temporary-files
}

abort() {
	epr "ABORT: ${1-}"
	_clean_tmp
	trap - SIGTERM SIGINT EXIT
	kill -9 -- -$$ 2>/dev/null
	exit 1
}

java() {
	if [ "${JAVA_HOME_21_X64-}" ]; then
		env -i JAVA_HOME="$JAVA_HOME_21_X64" "$JAVA_HOME_21_X64"/bin/java --enable-native-access=ALL-UNNAMED "$@"
	else
		env -i java --enable-native-access=ALL-UNNAMED "$@"
	fi
}

get_prebuilts() {
	local cli_src=${1:-$DEF_CLI_SRC} cli_ver=${2:-latest}
	local patches_src=${3:-$DEF_PATCHES_SRC} patches_ver=${4:-latest}

	read -r -a p_src_arr <<< "$(echo "$patches_src" | tr ',' ' ')"
	read -r -a p_ver_arr <<< "$(echo "$patches_ver" | tr ',' ' ')"

	local collected_patch_files=()

	for i in "${!p_src_arr[@]}"; do
		local raw_p_src="${p_src_arr[$i]}"
		local p_ver="${p_ver_arr[$i]:-${p_ver_arr[0]:-latest}}"

		local host="github"
		local clean_src="$raw_p_src"
		if [[ "$raw_p_src" =~ ^gitlab:(.+) ]]; then
			host="gitlab"
			clean_src="${BASH_REMATCH[1]}"
		elif [[ "$raw_p_src" =~ ^github:(.+) ]]; then
			host="github"
			clean_src="${BASH_REMATCH[1]}"
		fi

		local org="${clean_src%/*}"
		local dir="${TEMP_DIR}/${org,,}-rv"
		[[ -d "$dir" ]] || mkdir -p "$dir"

		pr "Getting prebuilts (${clean_src})" >&2

		local name_ver="*"
		if [[ "$p_ver" != "latest" ]]; then
			name_ver="$p_ver"
		fi

		local file=""
		file=$(find "$dir" -maxdepth 1 -name "*patches-${name_ver#v}.*" -type f 2>/dev/null)
		if [[ -n "$file" ]]; then
			if [ "$p_ver" = "latest" ]; then
				file=$(grep -v '/[^/]*dev[^/]*$' <<<"$file" | head -1)
			else
				file=$(grep "/[^/]*${p_ver#v}[^/]*\$" <<<"$file" | head -1)
			fi
		fi

		local grab_cl=true
		if [[ -z "$file" ]]; then
			local resp="" matches="" asset="" name="" tag_name=""
			if [ "$host" = "gitlab" ]; then
				local project_enc="${clean_src//\//%2F}"
				local gl_rel="https://gitlab.com/api/v4/projects/${project_enc}/releases"
				if [[ "$p_ver" == "dev" ]]; then
					resp=$(req "$gl_rel" -) || return 1
					p_ver=$(jq -e -r '.[].tag_name' <<<"$resp" | get_highest_ver) || return 1
				fi
				if [[ "$p_ver" == "latest" ]]; then
					resp=$(req "${gl_rel}/permalink/latest" -) || return 1
				else
					resp=$(req "${gl_rel}/${p_ver}" -) || return 1
				fi
				tag_name=$(jq -r '.tag_name // empty' <<<"$resp") || return 1
				matches=$(jq -e '.assets.links // [] | map(select(.name | (endswith("asc") or endswith("json")) | not))' <<<"$resp" 2>/dev/null || jq -e '.assets // []' <<<"$resp") || return 1
			else
				local gh_rel="https://api.github.com/repos/${clean_src}/releases"
				if [[ "$p_ver" == "dev" ]]; then
					resp=$(gh_req "$gh_rel" -) || return 1
					p_ver=$(jq -e -r '.[] | .tag_name' <<<"$resp" | get_highest_ver) || return 1
				fi
				if [[ "$p_ver" == "latest" ]]; then
					gh_rel+="/latest"
				else
					gh_rel+="/tags/${p_ver}"
				fi
				resp=$(gh_req "$gh_rel" -) || return 1
				tag_name=$(jq -r '.tag_name' <<<"$resp") || return 1
				matches=$(jq -e '.assets | map(select(.name | (endswith("asc") or endswith("json")) | not))' <<<"$resp") || return 1
			fi

			if [[ "$(jq 'length' <<<"$matches")" -gt 1 ]]; then
				local matches_new
				matches_new=$(jq -e -r 'map(select(.name | contains("-dev") | not))' <<<"$matches" 2>/dev/null)
				if [[ "$(jq 'length' <<<"$matches_new")" -eq 1 ]]; then
					matches=$matches_new
				fi
			fi

			if [[ "$(jq 'length' <<<"$matches")" -eq 0 ]]; then
				epr "No patch asset was found for ${raw_p_src}"
				return 1
			fi

			asset=$(jq -r ".[0]" <<<"$matches")
			name=$(jq -r '.name' <<<"$asset")
			file="${dir}/${name}"

			if [ "$host" = "gitlab" ]; then
				local url
				url=$(jq -r '.direct_asset_url // .url' <<<"$asset")
				pr "Getting '$file' from '$url'" >&2
				_req "$url" "$file" || return 1
			else
				local url
				url=$(jq -r '.url' <<<"$asset")
				gh_dl "$file" >&2 "$url" || return 1
			fi
		else
			grab_cl=false
			name=$(basename "$file")
			tag_name=$(cut -d'-' -f3- <<<"$name")
			tag_name=v${tag_name%.*}
		fi

		if [[ "$grab_cl" == true ]]; then
			local cl_str=""
			if [ "$host" = "gitlab" ]; then
				cl_str="> ⚙️ » Patches: \`${org}/${name}\` ([🔗 » Changelog](https://gitlab.com/${clean_src}/-/releases/${tag_name}))"
			else
				cl_str="> ⚙️ » Patches: \`${org}/${name}\` ([🔗 » Changelog](https://github.com/${clean_src}/releases/tag/${tag_name}))"
			fi
			if ! grep -qF "\`${org}/${name}\`" "${TEMP_DIR}/patches_changelog.md" 2>/dev/null; then
				echo -e "$cl_str\n" >>"${TEMP_DIR}/patches_changelog.md"
			fi
		fi

		if [[ "${REMOVE_RV_INTEGRATIONS_CHECKS:-}" == true ]]; then
			local extensions_ext
			extensions_ext=$(unzip -l "${file}" "extensions/shared.*" 2>/dev/null | grep -o "shared\..*") || true
			extensions_ext="${extensions_ext#*.}"
			if [[ -n "$extensions_ext" ]]; then
				if ! (
					mkdir -p "${file}-zip" || return 1
					unzip -qo "${file}" -d "${file}-zip" || return 1
					java -cp "${BIN_DIR}/paccer.jar:${BIN_DIR}/dexlib2.jar" com.jhc.Main "${file}-zip/extensions/shared.${extensions_ext}" "${file}-zip/extensions/shared-patched.${extensions_ext}" || return 1
					mv -f "${file}-zip/extensions/shared-patched.${extensions_ext}" "${file}-zip/extensions/shared.${extensions_ext}" || return 1
					rm "${file}" || return 1
					cd "${file}-zip" || abort
					zip -0rq "${CWD}/${file}" . || return 1
				) >&2; then
					echo >&2 "Patching revanced-integrations failed"
				fi
				rm -rf "${file}-zip" || :
			fi
		fi

		collected_patch_files+=("$file")
	done

	# Fetch CLI
	local cli_host="github"
	local clean_cli="$cli_src"
	if [[ "$cli_src" =~ ^gitlab:(.+) ]]; then
		cli_host="gitlab"
		clean_cli="${BASH_REMATCH[1]}"
	elif [[ "$cli_src" =~ ^github:(.+) ]]; then
		cli_host="github"
		clean_cli="${BASH_REMATCH[1]}"
	fi

	local cli_org="${clean_cli%/*}"
	local cli_dir="${TEMP_DIR}/${cli_org,,}-rv"
	[[ -d "$cli_dir" ]] || mkdir -p "$cli_dir"

	local cli_name_ver="*"
	if [[ "$cli_ver" != "latest" ]]; then
		cli_name_ver="$cli_ver"
	fi

	local cli_file=""
	cli_file=$(find "$cli_dir" -maxdepth 1 -name "*cli-${cli_name_ver#v}*.jar" -o -name "*desktop-${cli_name_ver#v}*.jar" -type f 2>/dev/null)
	if [[ -n "$cli_file" ]]; then
		if [ "$cli_ver" = "latest" ]; then
			cli_file=$(grep -v '/[^/]*dev[^/]*$' <<<"$cli_file" | head -1)
		else
			cli_file=$(grep "/[^/]*${cli_ver#v}[^/]*\$" <<<"$cli_file" | head -1)
		fi
	fi

	if [[ -z "$cli_file" ]]; then
		local resp="" matches="" asset="" name=""
		if [ "$cli_host" = "gitlab" ]; then
			local project_enc="${clean_cli//\//%2F}"
			local gl_rel="https://gitlab.com/api/v4/projects/${project_enc}/releases"
			if [[ "$cli_ver" == "dev" ]]; then
				resp=$(req "$gl_rel" -) || return 1
				cli_ver=$(jq -e -r '.[].tag_name' <<<"$resp" | get_highest_ver) || return 1
			fi
			if [[ "$cli_ver" == "latest" ]]; then
				resp=$(req "${gl_rel}/permalink/latest" -) || return 1
			else
				resp=$(req "${gl_rel}/${cli_ver}" -) || return 1
			fi
			matches=$(jq -e '.assets.links // [] | map(select(.name | (endswith("asc") or endswith("json")) | not))' <<<"$resp" 2>/dev/null || jq -e '.assets // []' <<<"$resp") || return 1
		else
			local gh_rel="https://api.github.com/repos/${clean_cli}/releases"
			if [[ "$cli_ver" == "dev" ]]; then
				resp=$(gh_req "$gh_rel" -) || return 1
				cli_ver=$(jq -e -r '.[] | .tag_name' <<<"$resp" | get_highest_ver) || return 1
			fi
			if [[ "$cli_ver" == "latest" ]]; then
				gh_rel+="/latest"
			else
				gh_rel+="/tags/${cli_ver}"
			fi
			resp=$(gh_req "$gh_rel" -) || return 1
			matches=$(jq -e '.assets | map(select(.name | (endswith("asc") or endswith("json")) | not))' <<<"$resp") || return 1
		fi

		if [[ "$(jq 'length' <<<"$matches")" -gt 1 ]]; then
			local matches_new
			matches_new=$(jq -e -r 'map(select(.name | contains("-dev") | not))' <<<"$matches" 2>/dev/null)
			if [[ "$(jq 'length' <<<"$matches_new")" -eq 1 ]]; then
				matches=$matches_new
			fi
		fi

		if [[ "$(jq 'length' <<<"$matches")" -eq 0 ]]; then
			epr "No CLI asset was found for ${cli_src}"
			return 1
		fi

		asset=$(jq -r ".[0]" <<<"$matches")
		name=$(jq -r '.name' <<<"$asset")
		cli_file="${cli_dir}/${name}"

		if [ "$cli_host" = "gitlab" ]; then
			local url
			url=$(jq -r '.direct_asset_url // .url' <<<"$asset")
			pr "Getting '$cli_file' from '$url'" >&2
			_req "$url" "$cli_file" || return 1
		else
			local url
			url=$(jq -r '.url' <<<"$asset")
			gh_dl "$cli_file" >&2 "$url" || return 1
		fi
	else
		name=$(basename "$cli_file")
	fi

	if ! grep -qF "CLI: \`${cli_org}/${name}\`" "${TEMP_DIR}/cli_changelog.md" 2>/dev/null; then
		echo -e "> ⚙️ » CLI: \`${cli_org}/${name}\`\n" >>"${TEMP_DIR}/cli_changelog.md"
	fi

	echo "${collected_patch_files[*]} ${cli_file}"
}

set_prebuilts() {
	APKSIGNER="${BIN_DIR}/apksigner.jar"
	local arch
	arch=$(uname -m)
	if [ "$arch" = aarch64 ]; then arch=arm64; elif [ "${arch:0:5}" = "armv7" ]; then arch=arm; fi
	HTMLQ="${BIN_DIR}/htmlq/htmlq-${arch}"
	AAPT2="${BIN_DIR}/aapt2/aapt2-${arch}"
	TOML="${BIN_DIR}/toml/tq-${arch}"
}

config_update() {
	if [ ! -f build.md ]; then abort "build.md not available"; fi
	declare -A sources
	: >"$TEMP_DIR"/skipped
	local upped=()
	local prcfg=false
	for table_name in $(toml_get_table_names); do
		if [ -z "$table_name" ]; then continue; fi
		t=$(toml_get_table "$table_name")
		enabled=$(toml_get "$t" enabled) || enabled=true
		if [ "$enabled" = "false" ]; then continue; fi

		PATCHES_SRC=$(toml_get "$t" patches-source) || PATCHES_SRC=$DEF_PATCHES_SRC
		PATCHES_VER=$(toml_get "$t" patches-version) || PATCHES_VER=$DEF_PATCHES_VER

		read -r -a p_src_arr <<< "$(echo "$PATCHES_SRC" | tr ',' ' ')"
		read -r -a p_ver_arr <<< "$(echo "$PATCHES_VER" | tr ',' ' ')"

		for i in "${!p_src_arr[@]}"; do
			local raw_src="${p_src_arr[$i]}"
			local p_ver="${p_ver_arr[$i]:-${p_ver_arr[0]:-latest}}"

			local host="github"
			local clean_src="$raw_src"
			if [[ "$raw_src" =~ ^gitlab:(.+) ]]; then
				host="gitlab"
				clean_src="${BASH_REMATCH[1]}"
			elif [[ "$raw_src" =~ ^github:(.+) ]]; then
				host="github"
				clean_src="${BASH_REMATCH[1]}"
			fi
			local org="${clean_src%/*}"

			if [[ -v sources["$raw_src/$p_ver"] ]]; then
				if [ "${sources["$raw_src/$p_ver"]}" = 1 ]; then upped+=("$table_name"); fi
			else
				sources["$raw_src/$p_ver"]=0
				local last_patches=""
				if [ "$host" = "gitlab" ]; then
					local project_enc="${clean_src//\//%2F}"
					local gl_rel="https://gitlab.com/api/v4/projects/${project_enc}/releases"
					if [ "$p_ver" = "dev" ]; then
						last_patches=$(req "$gl_rel" - | jq -e -r '.[0]') || continue
					elif [ "$p_ver" = "latest" ]; then
						last_patches=$(req "$gl_rel/permalink/latest" -) || continue
					else
						last_patches=$(req "$gl_rel/${p_ver}" -) || continue
					fi
					if ! last_patches=$(jq -e -r '.assets.links[]? | select(.name | (endswith("asc") or endswith("json")) | not) | .name' <<<"$last_patches"); then
						continue
					fi
				else
					local rv_rel="https://api.github.com/repos/${clean_src}/releases"
					if [ "$p_ver" = "dev" ]; then
						last_patches=$(gh_req "$rv_rel" - | jq -e -r '.[0]') || continue
					elif [ "$p_ver" = "latest" ]; then
						last_patches=$(gh_req "$rv_rel/latest" -) || continue
					else
						last_patches=$(gh_req "$rv_rel/tags/${p_ver}" -) || continue
					fi
					if ! last_patches=$(jq -e -r '.assets[] | select(.name | (endswith("asc") or endswith("json")) | not) | .name' <<<"$last_patches"); then
						continue
					fi
				fi

				if [ -n "$last_patches" ]; then
					if ! OP=$(grep "^Patches: ${org}/" build.md 2>/dev/null | grep -m1 "$last_patches"); then
						sources["$raw_src/$p_ver"]=1
						prcfg=true
						upped+=("$table_name")
					else
						echo "$OP" >>"$TEMP_DIR"/skipped
					fi
				fi
			fi
		done
	done

	if [ "$prcfg" = true ]; then
		local query=""
		for table in "${upped[@]}"; do
			if [ -n "$query" ]; then query+=" or "; fi
			query+=".key == \"$table\""
		done
		jq "to_entries | map(select(${query} or (.value | type != \"object\"))) | from_entries" <<<"$__TOML__"
	fi
}

_req() {
	local ip="$1" op="$2"
	shift 2
	local dlp="$op"
	if [ "$op" != - ]; then
		if [ -f "$op" ]; then return; fi
		dlp="$(dirname "$op")/tmp.$(basename "$op")"
		if [ -f "$dlp" ]; then
			while [ -f "$dlp" ]; do sleep 1; done
			return
		fi
	fi
	ip=$(echo "$ip" | xargs)

	if ! curl -L --connect-timeout 20 --retry 3 --retry-delay 4 -b "$TEMP_DIR/cookie.txt" -c "$TEMP_DIR/cookie.txt" --fail -s -S "$@" "$ip" -o "$dlp"; then
		epr "Request failed: $ip"
		if [ "$dlp" != - ]; then rm -f "$dlp"; fi
		return 1
	fi
	if [ "$dlp" != - ]; then
		mv -f "$dlp" "$op"
	fi
}

req() { _req "$1" "$2" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"; }
gh_req() { _req "$1" "$2" -H "$GH_HEADER"; }
gh_dl() {
	if [ ! -f "$1" ]; then
		pr "Getting '$1' from '$2'"
		_req "$2" "$1" -H "$GH_HEADER" -H "Accept: application/octet-stream"
	fi
}

log() { echo -e "$1  " >>"build.md"; }

get_highest_ver() {
	local vers m
	vers=$(tee)
	m=$(head -1 <<<"$vers")
	if ! semver_validate "$m"; then 
		echo "$m"
	else 
		sort -s -t- -k1,1Vr <<<"$vers" 2>/dev/null | { head -1; cat >/dev/null 2>&1; } || true
	fi
}

semver_validate() {
	local a="${1%-*}"
	local a="${a#v}"
	local ac="${a//[.0-9]/}"
	[[ ${#ac} -eq 0 ]]
}

export __TARGET_VERSION_CODE__=""
export __TARGET_VERSION__=""

get_patch_last_supported_ver() {
	local list_patches=$1 pkg_name=$2 inc_sel=${3:-} is_experimental=${4:-false} arch=${5:-arm64-v8a}
	local op
	__TARGET_VERSION_CODE__=""
	__TARGET_VERSION__=""

	local arch_key="ARM64_V8A"
	if [[ "$arch" == "arm-v7a" ]]; then arch_key="ARMEABI_V7A"
	elif [[ "$arch" == "x86" ]]; then arch_key="X86"
	elif [[ "$arch" == "x86_64" ]]; then arch_key="X86_64"; fi

	if [[ -n "$inc_sel" ]]; then
		if ! op=$(awk '{$1=$1}1' <<<"$list_patches"); then
			epr "list-patches: '$op'"
			return 1
		fi
		local ver vers="" NL=$'\n'
		while IFS= read -r line; do
			line="${line:1:${#line}-2}"
			ver=$(sed -n "/^Name: $line\$/,/^\$/p" <<<"$op" | sed -n "/^Compatible versions:\$/,/^\$/p" | tail -n +2)
			vers=${ver}${NL}
		done <<<"$(list_args "$inc_sel")"
		vers=$(awk '{$1=$1}1' <<<"$vers")
		if [[ -n "$vers" ]]; then
			local best_ver=$(get_highest_ver <<<"$vers")
			if [[ -n "$best_ver" ]]; then
				if [[ "$best_ver" =~ $arch_key=([0-9]+) ]]; then
					export __TARGET_VERSION_CODE__="${BASH_REMATCH[1]}"
				fi
				local clean_ver="${best_ver%%\[*}"
				export __TARGET_VERSION__=$(echo "${clean_ver}" | tr -d '[:space:]')
				return 0
			fi
		fi
	fi
	if ! op=$(patches_list_versions "${args[cli]}" "${args[ptjar]}" "$pkg_name" "$is_experimental"); then
		return 1
	fi
	op=$(sed -n '/Most common compatible versions:/,$p' <<<"$op" | sed '1d' | awk '{$1=$1}1')
	if [[ "$op" == "Any" ]]; then return; fi
	pcount=$(head -1 <<<"$op") pcount=${pcount#*(} pcount=${pcount% *}
	if [[ -z "$pcount" ]]; then
		if grep -Fq "$pkg_name" <<<"$list_patches"; then
			return
		else
			abort "No patches found for '$pkg_name' in patches '${args[ptjar]}'"
		fi
	fi
	local best_ver=$(grep -F "($pcount patch" <<<"$op" | sed 's/ (.* patch.*//' | get_highest_ver || true)
	if [[ -n "$best_ver" ]]; then
		if [[ "$best_ver" =~ $arch_key=([0-9]+) ]]; then
			export __TARGET_VERSION_CODE__="${BASH_REMATCH[1]}"
		fi
		local clean_ver="${best_ver%%\[*}"
		export __TARGET_VERSION__=$(echo "${clean_ver}" | tr -d '[:space:]')
		return 0
	fi
	return 1
}

patches_list_versions() {
	local cli_jar=$1 patches_jars=$2 pkg_name=$3 is_experimental=$4
	local combined_op="" op="" cmd cmd_base="java -jar '$cli_jar' list-versions"
	local cli_name
	cli_name=$(basename "$cli_jar")
	if [ "${cli_name::8}" = "revanced" ]; then
		cmd_base+=" -b"
	elif [ "$is_experimental" = "true" ]; then
		cmd_base+=" -x"
	fi

	for pj in $patches_jars; do
		cmd="${cmd_base} --patches='$pj' -f '$pkg_name'"
		if op=$(eval "$cmd" 2>&1); then
			combined_op+="$op"$'\n'
			continue
		fi
		cmd="${cmd_base} '$pj' -f '$pkg_name'"
		if op=$(eval "$cmd" 2>&1); then
			combined_op+="$op"$'\n'
		fi
	done

	if [[ -n "$combined_op" ]]; then
		echo "$combined_op"
		return 0
	fi
	epr "Could not list versions ($pkg_name) $cli_jar"
	return 1
}

patches_list() {
	local cli_jar=$1 patches_jars=$2 pkg_name=$3 is_experimental=$4
	local combined_op="" op=""
	for pj in $patches_jars; do
		if op=$(java -jar "$cli_jar" list-patches -p "$pj" --filter-package-name "$pkg_name" --versions --packages -b 2>&1); then
			combined_op+="$op"$'\n'
		else
			local cmd="java -jar '$cli_jar' list-patches --patches '$pj' -f '$pkg_name' --with-versions --with-packages"
			if [ "$is_experimental" = "true" ]; then cmd+=" -x"; fi
			if op=$(eval "$cmd" 2>&1); then
				combined_op+="$op"$'\n'
			fi
		fi
	done

	if [[ -z "$combined_op" ]]; then
		epr "Could not get patches list ($pkg_name) $cli_jar"
		return 1
	fi
	echo "$combined_op"
}

isoneof() {
	local i=$1 v
	shift
	for v; do [[ "$v" == "$i" ]] && return 0; done
	return 1
}

merge_splits() {
	local bundle=$1 output=$2
	pr "Merging splits"
	gh_dl "$TEMP_DIR/apkeditor.jar" "https://github.com/REAndroid/APKEditor/releases/download/V1.4.8/APKEditor-1.4.8.jar" >/dev/null || return 1
	if ! OP=$(java -jar "$TEMP_DIR/apkeditor.jar" merge -i "$bundle" -o "${output}-unsigned" -clean-meta -f 2>&1); then
		epr "APKEditor error: $OP"
		return 1
	fi
	if ! OP=$(java -jar "$APKSIGNER" sign --ks ks-p12.keystore --ks-pass pass:123456789 --key-pass pass:123456789 --ks-key-alias jhc \
		--out "${output}" "${output}-unsigned"); then
		epr "apksigner error: $OP"
		return 1
	fi
	rm "${output}.idsig" "${output}-unsigned" 2>/dev/null || :
	return 0
}

# ----------------- Pure Python Independent Engine -----------------
setup_python_backend() {
	mkdir -p "$TEMP_DIR"
	if [ ! -f "$TEMP_DIR/network_engine.py" ]; then
		export PIP_BREAK_SYSTEM_PACKAGES=1
		python3 -m pip install -q "curl_cffi>=0.7.0" beautifulsoup4 urllib3 requests 2>/dev/null || true
		cat << 'EOF' > "$TEMP_DIR/network_engine.py"
import sys, os, re, time, json, random
from urllib.parse import urljoin

def log(msg):
    sys.stderr.write(f"[Scraper] {msg}\n")
    sys.stderr.flush()

try:
    from curl_cffi import requests as cffi_requests
    from bs4 import BeautifulSoup
    import requests
except ImportError as e:
    log(f"Fatal Import Error: {e}. Missing dependencies.")
    if len(sys.argv) > 1 and sys.argv[1].endswith("_pkg"):
        print("PKG:UNKNOWN")
        sys.exit(0)
    sys.exit(1)

COOKIE_JAR = "/tmp/apkmirror_cookies.json"
BROWSER_CFG = "/tmp/apkmirror_browser.txt"
SOLVER_URL = os.getenv("CF_SOLVER_URL", "http://localhost:8000")

class Scraper:
    def __init__(self):
        self.session = None
        self.current_browser = "chrome120"
        
    def _create_session(self, browser):
        sess = cffi_requests.Session(impersonate=browser)
        sess.headers.update({
            "Accept-Language": "en-US,en;q=0.9",
            "Sec-Ch-Ua-Mobile": "?0",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Upgrade-Insecure-Requests": "1"
        })
        return sess

    def save_state(self):
        if self.session and self.current_browser:
            try:
                with open(BROWSER_CFG, "w") as f: f.write(self.current_browser)
                with open(COOKIE_JAR, "w") as f: json.dump(self.session.cookies.get_dict(), f)
            except Exception: pass

    def load_state(self):
        try:
            if os.path.exists(BROWSER_CFG) and os.path.exists(COOKIE_JAR):
                with open(BROWSER_CFG, "r") as f: self.current_browser = f.read().strip()
                self.session = self._create_session(self.current_browser)
                with open(COOKIE_JAR, "r") as f:
                    for k, v in json.load(f).items():
                        self.session.cookies.set(k, v)
                return True
        except Exception: pass
        return False

    def clear_state(self):
        try:
            if os.path.exists(BROWSER_CFG): os.remove(BROWSER_CFG)
            if os.path.exists(COOKIE_JAR): os.remove(COOKIE_JAR)
        except Exception: pass

    def _solve_via_docker_service(self, url):
        try:
            log(f"Attempting Cloudflare solve via local API for {url}...")
            resp = requests.get(f"{SOLVER_URL}/cookies", params={"url": url}, timeout=60)
            if resp.status_code != 200:
                return False
            data = resp.json()
            cookies = data.get("cookies", {})
            user_agent = data.get("user_agent")
            if not cookies or not user_agent:
                return False

            self.clear_state()
            self.current_browser = "chrome120"
            sess = self._create_session("chrome120")
            
            if isinstance(cookies, dict):
                for k, v in cookies.items():
                    sess.cookies.set(k, v)
            elif isinstance(cookies, list):
                for c in cookies:
                    if isinstance(c, dict) and "name" in c and "value" in c:
                        sess.cookies.set(c["name"], c["value"])

            sess.headers["User-Agent"] = user_agent
            self.session = sess
            self.save_state()
            log("Cloudflare bypass cookies synchronized successfully.")
            return True
        except Exception:
            return False

    def is_challenge(self, r):
        if not r: return True
        if r.status_code in (403, 503, 429): return True
        body = (r.text or "").lower()
        return "cf-browser-verification" in body or "just a moment" in body or "attention required" in body

    def get_soup(self, url, referer=None, force_solve=False):
        headers = {"Referer": referer} if referer else {}
        time.sleep(random.uniform(1.5, 3.0))
        
        if not force_solve and (self.load_state() or self.session):
            try:
                r = self.session.get(url, headers=headers, timeout=20, allow_redirects=True)
                if not self.is_challenge(r):
                    self.save_state()
                    return BeautifulSoup(r.text, 'html.parser'), r
            except Exception:
                pass

        if force_solve or self._solve_via_docker_service(url):
            if force_solve:
                self._solve_via_docker_service(url)
            try:
                r = self.session.get(url, headers=headers, timeout=20, allow_redirects=True)
                if not self.is_challenge(r):
                    self.save_state()
                    return BeautifulSoup(r.text, 'html.parser'), r
            except Exception:
                pass

        self.clear_state()
        browsers = ["chrome124", "chrome120", "edge99", "safari15_5", "chrome116", "chrome110"]
        random.shuffle(browsers)
        
        for browser in browsers:
            try:
                time.sleep(random.uniform(2.5, 4.5))
                new_session = self._create_session(browser)
                r = new_session.get(url, headers=headers, timeout=20, allow_redirects=True)
                
                if self.is_challenge(r):
                    continue
                    
                self.session = new_session
                self.current_browser = browser
                self.save_state()
                return BeautifulSoup(r.text, 'html.parser'), r
            except Exception:
                time.sleep(1)
                
        log("All browsers failed Cloudflare checks.")
        return None, None

    def download(self, url, dest_path, is_bundle, referer):
        headers = {"Referer": referer} if referer else {}
        real_dest = f"{dest_path}.apkm" if is_bundle else dest_path
        
        log(f"Downloading file: {url}")
        r_file = self.session.get(url, headers=headers, timeout=300)
        
        if r_file.status_code == 200 and r_file.content.startswith(b"PK"):
            with open(real_dest, "wb") as f: f.write(r_file.content)
            with open(f"{dest_path}.is_bundle", "w") as f: f.write("true" if is_bundle else "false")
            log("SUCCESS")
        else:
            log(f"Download failed. HTTP {r_file.status_code}. Valid Zip: {r_file.content.startswith(b'PK')}")
            sys.exit(1)

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    url = sys.argv[2] if len(sys.argv) > 2 else ""
    
    scraper = Scraper()
    
    # ------------------ GITHUB HANDLERS ------------------
    if mode.startswith("github_"):
        gh_token = os.environ.get("GITHUB_TOKEN", "")
        gh_headers = {"User-Agent": "Morphe-DeVanced-Builder"}
        if gh_token:
            gh_headers["Authorization"] = f"token {gh_token}"

        gh_match = re.search(r"github\.com/([^/]+)/([^/]+)/releases/tags?/([^/]+)", url)
        if not gh_match:
            log(f"Invalid GitHub release URL: {url}")
            sys.exit(1)

        owner, repo, tag = gh_match.groups()
        api_url = f"https://api.github.com/repos/{owner}/{repo}/releases/tags/{tag}"

        try:
            r = requests.get(api_url, headers=gh_headers, timeout=20)
            if r.status_code != 200:
                log(f"GitHub API error {r.status_code}: {r.text}")
                sys.exit(1)
            release_data = r.json()
        except Exception as e:
            log(f"Failed to fetch GitHub release: {e}")
            sys.exit(1)

        arch_suffix = re.compile(r"(?:-(all|arm64-v8a|armeabi-v7a|x86_64|x86))?(?:\.apk\.apkm|\.apk|\.apkm)$", re.I)

        if mode == "github_pkg":
            pkg_name = release_data.get("name") or release_data.get("tag_name") or "UNKNOWN"
            print(f"PKG:{pkg_name}")

        elif mode == "github_vers":
            pkg_name = release_data.get("name") or release_data.get("tag_name") or ""
            prefix = f"{pkg_name}-"
            seen = {}
            for asset in release_data.get("assets", []):
                name = asset.get("name", "")
                if name.startswith(prefix) and name.endswith((".apk", ".apkm")):
                    ver = arch_suffix.sub("", name[len(prefix):])
                    seen[ver] = None
            versions = list(seen.keys()) or [release_data.get("tag_name", "")]
            for v in versions:
                if v:
                    print(v)

        elif mode == "github_dl":
            version = sys.argv[3].strip() if len(sys.argv) > 3 else ""
            dest_path = sys.argv[4].strip() if len(sys.argv) > 4 else ""
            arch = sys.argv[5].strip() if len(sys.argv) > 5 else "all"
            dpi = sys.argv[6].strip() if len(sys.argv) > 6 else ""
            version_code = sys.argv[7].strip() if len(sys.argv) > 7 else ""

            if arch == "arm-v7a":
                arch = "armeabi-v7a"
            version_f = version.replace(" ", "").lstrip("v")

            apk_assets = [a for a in release_data.get("assets", []) if a.get("name", "").endswith((".apk", ".apkm"))]
            target_asset = None

            # 1st Pass: Match version string AND version code
            if version_code:
                for a in apk_assets:
                    name = a.get("name", "")
                    if version_f not in name or version_code not in name:
                        continue
                    m = arch_suffix.search(name)
                    file_arch = m.group(1).lower() if m and m.group(1) else "all"
                    if arch in ("all", "both") and file_arch != "all": continue
                    if arch not in ("all", "both") and file_arch not in (arch, "all"): continue
                    target_asset = a
                    break

            # 2nd Pass: Fallback matching version string only
            if not target_asset:
                for a in apk_assets:
                    name = a.get("name", "")
                    if version_f and version_f not in name:
                        continue
                    m = arch_suffix.search(name)
                    file_arch = m.group(1).lower() if m and m.group(1) else "all"
                    if arch in ("all", "both") and file_arch != "all": continue
                    if arch not in ("all", "both") and file_arch not in (arch, "all"): continue
                    target_asset = a
                    break

            if not target_asset and apk_assets:
                target_asset = apk_assets[0]

            if not target_asset:
                log(f"No matching GitHub asset found for arch '{arch}' and version '{version}'")
                sys.exit(1)

            dl_url = target_asset.get("browser_download_url")
            is_bundle = target_asset.get("name", "").endswith(".apkm")
            real_dest = f"{dest_path}.apkm" if is_bundle else dest_path

            log(f"Downloading GitHub asset: {target_asset.get('name')}")
            dl_headers = gh_headers.copy()
            dl_headers["Accept"] = "application/octet-stream"

            r_file = requests.get(dl_url, headers=dl_headers, timeout=300, allow_redirects=True)
            if r_file.status_code == 200 and r_file.content.startswith(b"PK"):
                with open(real_dest, "wb") as f:
                    f.write(r_file.content)
                with open(f"{dest_path}.is_bundle", "w") as f:
                    f.write("true" if is_bundle else "false")
                log("SUCCESS")
            else:
                log(f"Download failed. HTTP {r_file.status_code}")
                sys.exit(1)

    # ------------------ APKMIRROR HANDLERS ------------------
    elif mode == "apkmirror_pkg":
        resolved_pkg = None
        if "youtube-music" in url: resolved_pkg = "com.google.android.apps.youtube.music"
        elif "youtube" in url: resolved_pkg = "com.google.android.youtube"
        elif "photos" in url: resolved_pkg = "com.google.android.apps.photos"
        elif "reddit" in url: resolved_pkg = "com.reddit.frontpage"
        elif "twitter" in url or "x-corp" in url: resolved_pkg = "com.twitter.android"
        elif "messenger" in url: resolved_pkg = "com.facebook.orca"
        elif "facebook" in url: resolved_pkg = "com.facebook.katana"
        elif "threads" in url: resolved_pkg = "com.instagram.barcelona"
        elif "instagram" in url: resolved_pkg = "com.instagram.android"

        soup, r = scraper.get_soup(url)
        if r and r.text:
            m = re.search(r"play\.google\.com/store/apps/details\?id=([\w.]+)", r.text)
            if m: 
                print(f"PKG:{m.group(1)}")
                return
        print(f"PKG:{resolved_pkg}" if resolved_pkg else "PKG:UNKNOWN")

    elif mode == "apkmirror_vers":
        cat = url.rstrip("/").split("/")[-1]
        soup, _ = scraper.get_soup(f"https://www.apkmirror.com/uploads/?appcategory={cat}")
        if soup:
            for a in soup.select("#primary a.fontBlack[href*='-release/']"):
                txt = a.get_text(strip=True)
                if txt and "beta" not in txt.lower() and "alpha" not in txt.lower():
                    print(txt.split()[-1])

    elif mode == "apkmirror_dl":
        version = sys.argv[3].strip() if len(sys.argv) > 3 else ""
        dest_path = sys.argv[4].strip() if len(sys.argv) > 4 else ""
        arch = sys.argv[5].strip() if len(sys.argv) > 5 else "all"
        dpi = sys.argv[6].strip() if len(sys.argv) > 6 else ""
        version_code = sys.argv[7].strip() if len(sys.argv) > 7 else ""
        if arch == "arm-v7a": arch = "armeabi-v7a"
        
        cat = url.rstrip("/").split("/")[-1]
        
        release_url = None
        
        # Priority 1: Match directly via exact path URL pattern (Robust against hyphens)
        search_url = f"{url.rstrip('/')}/?s={version}"
        log(f"Searching APKMirror via exact path: {search_url}")
        soup_search, _ = scraper.get_soup(search_url)
        
        if soup_search:
            for a in soup_search.select("a.fontBlack[href*='-release/']"):
                if version in a.get_text() and f"/{cat}/" in a.get("href", ""):
                    release_url = urljoin("https://www.apkmirror.com", a["href"])
                    break
                    
        # Priority 2: Fallback to global search if path lookup fails
        if not release_url:
            log("APKMirror release URL not found via path search, trying global search...")
            search_term = version.split("-")[0].strip()
            global_search_url = f"https://www.apkmirror.com/?post_type=app_release&searchtype=apk&s={cat}+{search_term}"
            if version_code:
                global_search_url += f"+{version_code}"

            soup_search, _ = scraper.get_soup(global_search_url)
            if soup_search:
                clean_target = re.sub(r'[^a-zA-Z0-9]', '', version.lower())
                for a in soup_search.select("a.fontBlack[href*='-release/']"):
                    txt = a.get_text(strip=True)
                    href = a.get("href", "")
                    clean_slug = re.sub(r'[^a-zA-Z0-9]', '', href.lower())
                    clean_txt = re.sub(r'[^a-zA-Z0-9]', '', txt.lower())
                    if clean_target in clean_slug or clean_target in clean_txt:
                        release_url = urljoin("https://www.apkmirror.com", href)
                        break

        if not release_url:
            log("APKMirror release URL not found.")
            sys.exit(1)
            
        soup_rel, r_rel = scraper.get_soup(release_url, referer=search_url)
        if not soup_rel:
            sys.exit(1)
            
        rows = soup_rel.select("div.table-row.headerFont")
        if not rows:
            rows = [r for r in soup_rel.select("div.table-row") if len(r.select("div.table-cell")) >= 4]
        
        apparch = {"universal", "noarch", "arm64-v8a + armeabi-v7a", "arm64-v8a + armeabi"}
        if arch != "all": apparch.add(arch)
        
        dl_sub_url = None
        is_bundle = False
        
        # 1st Pass: Match version code explicitly from row text
        if version_code:
            for target_type in ["APK", "BUNDLE"]:
                for row in reversed(rows):
                    cells = row.select("div.table-cell")
                    if len(cells) < 4: continue
                    badge = cells[0].select_one(".apkm-badge")
                    b_type = badge.get_text(strip=True).upper() if badge else "APK"
                    if b_type != target_type: continue
                    
                    arch_text = cells[1].get_text(strip=True)
                    dpi_text = cells[3].get_text(strip=True)
                    row_text = row.get_text()
                    
                    dpi_ok = not dpi_text or re.match(r"\d+-640dpi", dpi_text) or dpi_text in {"nodpi", "anydpi"} or (dpi and dpi in dpi_text)
                    vcode_ok = version_code in row_text

                    if arch_text in apparch and dpi_ok and vcode_ok:
                        link = row.find("a", href=re.compile(r"/download/")) or cells[0].find("a")
                        if link and link.get("href"):
                            dl_sub_url = urljoin("https://www.apkmirror.com", link["href"])
                            is_bundle = (target_type == "BUNDLE")
                            break
                if dl_sub_url: break

        # 2nd Pass: Fallback matching version string only
        if not dl_sub_url:
            for target_type in ["APK", "BUNDLE"]:
                for row in reversed(rows):
                    cells = row.select("div.table-cell")
                    if len(cells) < 4: continue
                    badge = cells[0].select_one(".apkm-badge")
                    b_type = badge.get_text(strip=True).upper() if badge else "APK"
                    if b_type != target_type: continue
                    
                    arch_text = cells[1].get_text(strip=True)
                    dpi_text = cells[3].get_text(strip=True)
                    
                    dpi_ok = not dpi_text or re.match(r"\d+-640dpi", dpi_text) or dpi_text in {"nodpi", "anydpi"} or (dpi and dpi in dpi_text)

                    if arch_text in apparch and dpi_ok:
                        link = row.find("a", href=re.compile(r"/download/")) or cells[0].find("a")
                        if link and link.get("href"):
                            dl_sub_url = urljoin("https://www.apkmirror.com", link["href"])
                            is_bundle = (target_type == "BUNDLE")
                            break
                if dl_sub_url: break

            
        if not dl_sub_url:
            sys.exit(1)
            
        soup_dl, _ = scraper.get_soup(dl_sub_url, referer=release_url)
        if not soup_dl:
            sys.exit(1)
            
        btn = soup_dl.select_one("a.downloadButton") or soup_dl.select_one("a.btn") or soup_dl.find("a", class_=re.compile("download"))
        if not btn:
            sys.exit(1)
            
        btn_url = urljoin("https://www.apkmirror.com", btn["href"])
        soup_final, _ = scraper.get_soup(btn_url, referer=dl_sub_url)
        if not soup_final:
            sys.exit(1)
            
        dl_link = soup_final.select_one("a[data-google-vignette='false'][rel='nofollow']") or soup_final.select_one("span > a[rel=nofollow]") or soup_final.find("a", string=re.compile("here", re.I))
        if not dl_link:
            sys.exit(1)
            
        final_download_url = urljoin("https://www.apkmirror.com", dl_link["href"])
        scraper.download(final_download_url, dest_path, is_bundle, btn_url)

    # ------------------ UPTODOWN HANDLERS ------------------
    elif mode == "uptodown_pkg":
        resolved_pkg = None
        if "youtube-music" in url: resolved_pkg = "com.google.android.apps.youtube.music"
        elif "youtube" in url: resolved_pkg = "com.google.android.youtube"
        elif "photos" in url: resolved_pkg = "com.google.android.apps.photos"
        elif "reddit" in url: resolved_pkg = "com.reddit.frontpage"
        elif "twitter" in url or "x-corp" in url: resolved_pkg = "com.twitter.android"
        elif "messenger" in url: resolved_pkg = "com.facebook.orca"
        elif "facebook" in url: resolved_pkg = "com.facebook.katana"
        elif "threads" in url: resolved_pkg = "com.instagram.barcelona"
        elif "instagram" in url: resolved_pkg = "com.instagram.android"

        soup, _ = scraper.get_soup(f"{url}/download")
        if soup:
            th = soup.find(lambda e: e.name in ("th", "td") and "package name" in e.text.lower())
            if th and th.find_next_sibling("td"):
                pkg = th.find_next_sibling("td").get_text(strip=True)
                if pkg and "." in pkg:
                    print(f"PKG:{pkg}")
                    return
            m = re.search(r'play\.google\.com/store/apps/details\?id=([\w.]+)', str(soup))
            if m:
                print(f"PKG:{m.group(1)}")
                return
        print(f"PKG:{resolved_pkg}" if resolved_pkg else "PKG:UNKNOWN")

    elif mode == "uptodown_vers":
        soup, _ = scraper.get_soup(f"{url}/versions")
        if soup:
            for el in soup.select(".version"):
                if t := el.get_text(strip=True): print(t)

    elif mode == "uptodown_dl":
        version = sys.argv[3].strip() if len(sys.argv) > 3 else ""
        dest_path = sys.argv[4].strip() if len(sys.argv) > 4 else ""
        arch = sys.argv[5].strip() if len(sys.argv) > 5 else "all"
        dpi = sys.argv[6].strip() if len(sys.argv) > 6 else ""
        version_code = sys.argv[7].strip() if len(sys.argv) > 7 else ""
        if arch == "arm-v7a": arch = "armeabi-v7a"
        
        soup, _ = scraper.get_soup(f"{url}/versions")
        
        def get_data_code(s):
            if not s: return None
            detail_app = s.select_one("#detail-app-name")
            if detail_app and "data-code" in detail_app.attrs:
                return detail_app["data-code"]
            elem = s.find(attrs={"data-code": True})
            if elem:
                return elem["data-code"]
            m = re.search(r'data-code=["\'](\d+)["\']', str(s))
            if m:
                return m.group(1)
            return None

        data_code = get_data_code(soup)
        if not data_code:
            log(f"Uptodown data-code not found, forcing Cloudflare solver for {url}...")
            soup, _ = scraper.get_soup(f"{url}/versions", force_solve=True)
            data_code = get_data_code(soup)

        if not data_code:
            log(f"Detail app data-code not found on Uptodown page for {url}")
            sys.exit(1)
            
        ver_url_data = None
        is_bundle = False

        def find_version(match_code=True):
            for i in range(1, 21):
                _, r = scraper.get_soup(f"{url}/apps/{data_code}/versions/{i}")
                if not r or not r.text: continue
                try:
                    data = json.loads(r.text).get("data", [])
                except Exception:
                    continue
                for entry in data:
                    if entry.get("version") == version:
                        if match_code and version_code and str(entry.get("versionCode", "")) != str(version_code):
                            continue
                        return entry.get("versionURL", {}), (entry.get("kindFile") == "xapk")
            return None, False

        ver_url_data, is_bundle = find_version(match_code=True)
        if not ver_url_data and version_code:
            ver_url_data, is_bundle = find_version(match_code=False)

        if not ver_url_data:
            log(f"Uptodown version {version} not found.")
            sys.exit(1)

        ver_url = f"{ver_url_data.get('url', '')}/{ver_url_data.get('extraURL', '')}/{ver_url_data.get('versionID', '')}"
        soup_ver, _ = scraper.get_soup(ver_url)
        if not soup_ver: sys.exit(1)
        
        btn_variants = soup_ver.select_one(".button.variants")

        if btn_variants and (data_version := btn_variants.get("data-version")):
            apparch = {"arm64-v8a, armeabi-v7a, x86_64", "arm64-v8a, armeabi-v7a, x86, x86_64", "arm64-v8a, armeabi-v7a"}
            if arch != "all": apparch.add(arch)

            base_url = url.rsplit("/", 1)[0]
            _, r_files = scraper.get_soup(f"{base_url}/app/{data_code}/version/{data_version}/files")
            files_html = json.loads(r_files.text).get("content", "") if r_files else ""
            soup_files = BeautifulSoup(files_html, 'html.parser')
            content = soup_files.select_one(".content")
            
            matched_id = None
            if content:
                for child in content.children:
                    if not getattr(child, "name", None): continue
                    if "variant" not in child.get("class", []):
                        node_arch = child.get_text(strip=True)
                        continue
                    if not node_arch or node_arch not in apparch:
                        continue
                    
                    file_type_tag = child.select_one(".v-file > span")
                    is_bundle = file_type_tag.get_text(strip=True) == "xapk" if file_type_tag else False
                    try:
                        matched_id = child.select_one(".v-report")["data-file-id"]
                        break
                    except Exception: continue

            if matched_id:
                soup_ver, _ = scraper.get_soup(f"{url}/download/{matched_id}-x")

        dl_btn = soup_ver.select_one("#detail-download-button") if soup_ver else None
        if not dl_btn or "data-url" not in dl_btn.attrs:
            log("Uptodown download button missing.")
            sys.exit(1)
            
        dl_url = dl_btn["data-url"]
        scraper.download(f"https://dw.uptodown.com/dwn/{dl_url}", dest_path, is_bundle, None)

if __name__ == "__main__":
    main()
EOF
	fi
}

run_python_backend() {
	python3 -u "$TEMP_DIR/network_engine.py" "$@"
}

setup_python_backend

# -------------------- github wrappers --------------------
get_github_resp() {
	__GITHUB_URL__="${1%/}"
	__GITHUB_RESP__=$(run_python_backend "github_pkg" "$__GITHUB_URL__") || return 1
}

get_github_pkg_name() { 
	local pkg=$(grep -oP '^PKG:\K.*' <<<"${__GITHUB_RESP__:-}" | head -1)
	echo "${pkg:-UNKNOWN}"
}

get_github_vers() { 
	run_python_backend "github_vers" "${__GITHUB_URL__:-}"
}

dl_github() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"

	if ! run_python_backend "github_dl" "$url" "$version" "$output" "$arch" "$dpi" "$vcode" >/dev/null; then
		return 1
	fi

	if [[ -f "${output}.is_bundle" && "$(cat "${output}.is_bundle")" == "true" ]] || [[ -f "${output}.apkm.is_bundle" ]]; then
		merge_splits "${output}.apkm" "${output}"
	fi
	[[ -f "$output" ]]
}

# -------------------- apkmirror wrappers --------------------
get_apkmirror_resp() {
	__APKMIRROR_URL__="${1%/}"
	__APKMIRROR_CAT__="${__APKMIRROR_URL__##*/}"
	__APKMIRROR_RESP__=$(run_python_backend "apkmirror_pkg" "$__APKMIRROR_URL__") || return 1
}

get_apkmirror_pkg_name() { 
	local pkg=$(grep -oP '^PKG:\K.*' <<<"${__APKMIRROR_RESP__:-}" | head -1)
	if [ -z "$pkg" ] || [ "$pkg" = "UNKNOWN" ]; then
		case "${__APKMIRROR_URL__,,}" in
			*youtube-music*) pkg="com.google.android.apps.youtube.music" ;;
			*youtube*) pkg="com.google.android.youtube" ;;
			*photos*) pkg="com.google.android.apps.photos" ;;
			*reddit*) pkg="com.reddit.frontpage" ;;
			*twitter*|*x*) pkg="com.twitter.android" ;;
			*messenger*) pkg="com.facebook.orca" ;;
			*facebook*) pkg="com.facebook.katana" ;;
			*threads*) pkg="com.instagram.barcelona" ;;
			*instagram*) pkg="com.instagram.android" ;;
		esac
	fi
	echo "${pkg:-UNKNOWN}"
}

get_apkmirror_vers() { run_python_backend "apkmirror_vers" "${__APKMIRROR_URL__:-}"; }

dl_apkmirror() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	if [ -f "${output}.apkm" ]; then
		merge_splits "${output}.apkm" "${output}"
		return 0
	fi
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"
	
	if ! run_python_backend "apkmirror_dl" "$url" "$version" "$output" "$arch" "$dpi" "$vcode" >/dev/null; then
		return 1
	fi
	
	if [[ -f "${output}.is_bundle" && "$(cat "${output}.is_bundle")" == "true" ]] || [[ -f "${output}.apkm.is_bundle" ]]; then
		merge_splits "${output}.apkm" "${output}"
	fi
	[[ -f "$output" ]]
}

# -------------------- uptodown wrappers --------------------
get_uptodown_resp() { 
	__UPTODOWN_URL__="${1%/}"
	__UPTODOWN_RESP__=$(run_python_backend "uptodown_pkg" "$__UPTODOWN_URL__") || return 1
}

get_uptodown_pkg_name() { 
	local pkg=$(grep -oP '^PKG:\K.*' <<<"${__UPTODOWN_RESP__:-}" | head -1)
	if [ -z "$pkg" ] || [ "$pkg" = "UNKNOWN" ]; then
		case "${__UPTODOWN_URL__,,}" in
			*youtube-music*) pkg="com.google.android.apps.youtube.music" ;;
			*youtube*) pkg="com.google.android.youtube" ;;
			*photos*) pkg="com.google.android.apps.photos" ;;
			*reddit*) pkg="com.reddit.frontpage" ;;
			*twitter*|*x*) pkg="com.twitter.android" ;;
			*messenger*) pkg="com.facebook.orca" ;;
			*facebook*) pkg="com.facebook.katana" ;;
			*threads*) pkg="com.instagram.barcelona" ;;
			*instagram*) pkg="com.instagram.android" ;;
		esac
	fi
	echo "${pkg:-UNKNOWN}"
}

get_uptodown_vers() { run_python_backend "uptodown_vers" "${__UPTODOWN_URL__:-}"; }

dl_uptodown() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"
	
	if ! run_python_backend "uptodown_dl" "$url" "$version" "$output" "$arch" "$dpi" "$vcode" >/dev/null; then
		return 1
	fi
	
	if [[ -f "${output}.is_bundle" && "$(cat "${output}.is_bundle")" == "true" ]] || [[ -f "${output}.apkm.is_bundle" ]]; then
		merge_splits "${output}.apkm" "${output}"
	fi
	[[ -f "$output" ]]
}

# -------------------- archive --------------------
dl_archive() {
	local url=$1 version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	local path output_m version=${version// /}
	local version_f=${version#v}

	if [ -f "${output}.apkm" ]; then
		merge_splits "${output}.apkm" "$output"
		return 0
	fi

	local arch_query="${arch// /}"
	if [ "$arch_query" = "arm-v7a" ]; then arch_query="armeabi-v7a"; fi

	if ! path=$(grep -m1 "${version_f}-${arch_query}" <<<"${__ARCHIVE_RESP__:-}"); then
		if ! path=$(grep -m1 "${version_f}-${arch// /}" <<<"${__ARCHIVE_RESP__:-}"); then
			path=$(grep -m1 "${version_f}-all" <<<"${__ARCHIVE_RESP__:-}") || return 1
		fi
	fi

	if [ "${path##*.}" = "apkm" ]; then
		req "${url}/${path}" "${output}.apkm" || return 1
		merge_splits "${output}.apkm" "$output"
	else
		req "${url}/${path}" "${output}" || return 1
	fi
}
get_archive_resp() {
	local r
	r=$(req "$1" -) || return 1
	__ARCHIVE_RESP__=$(sed -n 's;^<a href="\(.*\)"[^"]*;\1;p' <<<"$r")
	__ARCHIVE_PKG_NAME__=$(awk -F/ '{print $NF}' <<<"$1")
}
get_archive_vers() { sed 's/^[^-]*-//;s/-\(all\|arm64-v8a\|arm-v7a\|armeabi-v7a\|x86_64\|x86\)\.apk//g' <<<"${__ARCHIVE_RESP__:-}"; }
get_archive_pkg_name() { echo "${__ARCHIVE_PKG_NAME__:-UNKNOWN}"; }

# -------------------- direct --------------------
dl_direct() {
	local url=$1 version=${2// /-} output=$3 arch=$4 _dpi=$5 vcode=${6:-}
	local version_f=${version#v}
	if ! grep -q "${version_f}-${arch// /}" <<<"$url"; then
		epr "Given direct-dlurl for $output is not compatible. Set proper 'arch' and 'version' options."
		return 1
	fi
	if [[ "${url##*.}" == "apkm" ]]; then
		req "$url" "${output}.apkm" || return 1
		merge_splits "${output}.apkm" "$output"
	else
		req "$url" "${output}" || return 1
	fi
}
get_direct_vers() { cut -d- -f2 <<<"${__DIRECT_APKNAME__:-}"; }
get_direct_pkg_name() { cut -d- -f1 <<<"${__DIRECT_APKNAME__:-}"; }
get_direct_resp() { __DIRECT_APKNAME__=$(awk -F/ '{print $NF}' <<<"$1"); }
# --------------------------------------------------

patch_apk() {
	local stock_input=$1 patched_apk=$2 patcher_args=$3 cli_jar=$4 patches_jars=$5
	local tmp_files
	tmp_files="$(pwd)/$(mktemp -d -p "$TEMP_DIR")"

	local p_flags=()
	for pj in $patches_jars; do
		p_flags+=("-p" "$pj")
	done

	local cmd="java -jar '$cli_jar' patch '$stock_input' -o '$patched_apk' "${p_flags[@]}" --keystore=ks.keystore \
    --keystore-entry-password=123456789 --keystore-password=123456789 --signer=jhc --keystore-entry-alias=jhc -t '$patched_apk-tmp' $patcher_args"

	local cli_name
	cli_name=$(basename "$cli_jar")
	if [[ "${cli_name::8}" == revanced ]]; then cmd+=" -b"; fi

	if [[ "$OS" == Android ]]; then cmd+=" --custom-aapt2-binary='${AAPT2}'"; fi
	pr "$cmd"
	if (set -o pipefail; eval "$cmd" 2>&1 | grep -vE "INFO: Processing|INFO: Writing|INFO: Wrote|INFO: Stripping|INFO: Compiling"); then
		[[ -f "$patched_apk" ]]
	else
		rm -f "$patched_apk" 2>/dev/null || :
		return 1
	fi
}

check_sig() {
	local file=$1 pkg_name=$2
	local sig
	if grep -q "$pkg_name" sig.txt; then
		sig=$(java -jar "$APKSIGNER" verify --print-certs "$file" | grep ^Signer | grep SHA-256 | tail -1 | awk '{print $NF}')
		echo "$pkg_name signature: ${sig}"
		grep -qFx "$sig $pkg_name" sig.txt
	fi
}

export __TARGET_VERSION_CODE__=""
export __TARGET_VERSION__=""

get_patch_last_supported_ver() {
	local list_patches=$1 pkg_name=$2 inc_sel=${3:-} is_experimental=${4:-false} arch=${5:-arm64-v8a}
	local op
	__TARGET_VERSION_CODE__=""
	__TARGET_VERSION__=""

	local arch_key="ARM64_V8A"
	if [[ "$arch" == "arm-v7a" ]]; then arch_key="ARMEABI_V7A"
	elif [[ "$arch" == "x86" ]]; then arch_key="X86"
	elif [[ "$arch" == "x86_64" ]]; then arch_key="X86_64"; fi

	if [[ -n "$inc_sel" ]]; then
		if ! op=$(awk '{$1=$1}1' <<<"$list_patches"); then
			epr "list-patches: '$op'"
			return 1
		fi
		local ver vers="" NL=$'\n'
		while IFS= read -r line; do
			line="${line:1:${#line}-2}"
			ver=$(sed -n "/^Name: $line\$/,/^\$/p" <<<"$op" | sed -n "/^Compatible versions:\$/,/^\$/p" | tail -n +2)
			vers=${ver}${NL}
		done <<<"$(list_args "$inc_sel")"
		vers=$(awk '{$1=$1}1' <<<"$vers")
		if [[ -n "$vers" ]]; then
			local best_ver=$(get_highest_ver <<<"$vers")
			if [[ -n "$best_ver" ]]; then
				if [[ "$best_ver" =~ $arch_key=([0-9]+) ]]; then
					__TARGET_VERSION_CODE__="${BASH_REMATCH[1]}"
				fi
				local clean_ver="${best_ver%%\[*}"
				__TARGET_VERSION__=$(echo "${clean_ver}" | tr -d '[:space:]')
				return 0
			fi
		fi
	fi
	if ! op=$(patches_list_versions "${args[cli]}" "${args[ptjar]}" "$pkg_name" "$is_experimental"); then
		return 1
	fi
	op=$(sed -n '/Most common compatible versions:/,$p' <<<"$op" | sed '1d' | awk '{$1=$1}1')
	if [[ "$op" == "Any" ]]; then return; fi
	pcount=$(head -1 <<<"$op") pcount=${pcount#*(} pcount=${pcount% *}
	if [[ -z "$pcount" ]]; then
		if grep -Fq "$pkg_name" <<<"$list_patches"; then
			return
		else
			abort "No patches found for '$pkg_name' in patches '${args[ptjar]}'"
		fi
	fi
	local best_ver=$(grep -F "($pcount patch" <<<"$op" | sed 's/ (.* patch.*//' | get_highest_ver || true)
	if [[ -n "$best_ver" ]]; then
		if [[ "$best_ver" =~ $arch_key=([0-9]+) ]]; then
			__TARGET_VERSION_CODE__="${BASH_REMATCH[1]}"
		fi
		local clean_ver="${best_ver%%\[*}"
		__TARGET_VERSION__=$(echo "${clean_ver}" | tr -d '[:space:]')
		return 0
	fi
	return 1
}

patches_list_versions() {
	local cli_jar=$1 patches_jars=$2 pkg_name=$3 is_experimental=$4
	local combined_op="" op="" cmd cmd_base="java -jar '$cli_jar' list-versions"
	local cli_name
	cli_name=$(basename "$cli_jar")
	if [ "${cli_name::8}" = "revanced" ]; then
		cmd_base+=" -b"
	elif [ "$is_experimental" = "true" ]; then
		cmd_base+=" -x"
	fi

	for pj in $patches_jars; do
		cmd="${cmd_base} --patches='$pj' -f '$pkg_name'"
		if op=$(eval "$cmd" 2>&1); then
			combined_op+="$op"$'\n'
			continue
		fi
		cmd="${cmd_base} '$pj' -f '$pkg_name'"
		if op=$(eval "$cmd" 2>&1); then
			combined_op+="$op"$'\n'
		fi
	done

	if [[ -n "$combined_op" ]]; then
		echo "$combined_op"
		return 0
	fi
	epr "Could not list versions ($pkg_name) $cli_jar"
	return 1
}

patches_list() {
	local cli_jar=$1 patches_jars=$2 pkg_name=$3 is_experimental=$4
	local combined_op="" op=""
	for pj in $patches_jars; do
		if op=$(java -jar "$cli_jar" list-patches -p "$pj" --filter-package-name "$pkg_name" --versions --packages -b 2>&1); then
			combined_op+="$op"$'\n'
		else
			local cmd="java -jar '$cli_jar' list-patches --patches '$pj' -f '$pkg_name' --with-versions --with-packages"
			if [ "$is_experimental" = "true" ]; then cmd+=" -x"; fi
			if op=$(eval "$cmd" 2>&1); then
				combined_op+="$op"$'\n'
			fi
		fi
	done

	if [[ -z "$combined_op" ]]; then
		epr "Could not get patches list ($pkg_name) $cli_jar"
		return 1
	fi
	echo "$combined_op"
}

isoneof() {
	local i=$1 v
	shift
	for v; do [[ "$v" == "$i" ]] && return 0; done
	return 1
}

merge_splits() {
	local bundle=$1 output=$2
	pr "Merging splits"
	gh_dl "$TEMP_DIR/apkeditor.jar" "https://github.com/REAndroid/APKEditor/releases/download/V1.4.8/APKEditor-1.4.8.jar" >/dev/null || return 1
	if ! OP=$(java -jar "$TEMP_DIR/apkeditor.jar" merge -i "$bundle" -o "${output}-unsigned" -clean-meta -f 2>&1); then
		epr "APKEditor error: $OP"
		return 1
	fi
	if ! OP=$(java -jar "$APKSIGNER" sign --ks ks-p12.keystore --ks-pass pass:123456789 --key-pass pass:123456789 --ks-key-alias jhc \
		--out "${output}" "${output}-unsigned"); then
		epr "apksigner error: $OP"
		return 1
	fi
	rm "${output}.idsig" "${output}-unsigned" 2>/dev/null || :
	return 0
}

# ----------------- Pure Python Independent Engine -----------------
setup_python_backend() {
	mkdir -p "$TEMP_DIR"
	if [ ! -f "$TEMP_DIR/network_engine.py" ]; then
		export PIP_BREAK_SYSTEM_PACKAGES=1
		python3 -m pip install -q "curl_cffi>=0.7.0" beautifulsoup4 urllib3 requests 2>/dev/null || true
		cat << 'EOF' > "$TEMP_DIR/network_engine.py"
import sys, os, re, time, json, random
from urllib.parse import urljoin

def log(msg):
    sys.stderr.write(f"[Scraper] {msg}\n")
    sys.stderr.flush()

try:
    from curl_cffi import requests as cffi_requests
    from bs4 import BeautifulSoup
    import requests
except ImportError as e:
    log(f"Fatal Import Error: {e}. Missing dependencies.")
    if len(sys.argv) > 1 and sys.argv[1].endswith("_pkg"):
        print("PKG:UNKNOWN")
        sys.exit(0)
    sys.exit(1)

COOKIE_JAR = "/tmp/apkmirror_cookies.json"
BROWSER_CFG = "/tmp/apkmirror_browser.txt"
SOLVER_URL = os.getenv("CF_SOLVER_URL", "http://localhost:8000")

class Scraper:
    def __init__(self):
        self.session = None
        self.current_browser = "chrome120"
        
    def _create_session(self, browser):
        sess = cffi_requests.Session(impersonate=browser)
        sess.headers.update({
            "Accept-Language": "en-US,en;q=0.9",
            "Sec-Ch-Ua-Mobile": "?0",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Upgrade-Insecure-Requests": "1"
        })
        return sess

    def save_state(self):
        if self.session and self.current_browser:
            try:
                with open(BROWSER_CFG, "w") as f: f.write(self.current_browser)
                with open(COOKIE_JAR, "w") as f: json.dump(self.session.cookies.get_dict(), f)
            except Exception: pass

    def load_state(self):
        try:
            if os.path.exists(BROWSER_CFG) and os.path.exists(COOKIE_JAR):
                with open(BROWSER_CFG, "r") as f: self.current_browser = f.read().strip()
                self.session = self._create_session(self.current_browser)
                with open(COOKIE_JAR, "r") as f:
                    for k, v in json.load(f).items():
                        self.session.cookies.set(k, v)
                return True
        except Exception: pass
        return False

    def clear_state(self):
        try:
            if os.path.exists(BROWSER_CFG): os.remove(BROWSER_CFG)
            if os.path.exists(COOKIE_JAR): os.remove(COOKIE_JAR)
        except Exception: pass

    def _solve_via_docker_service(self, url):
        try:
            log(f"Attempting Cloudflare solve via local API for {url}...")
            resp = requests.get(f"{SOLVER_URL}/cookies", params={"url": url}, timeout=60)
            if resp.status_code != 200:
                return False
            data = resp.json()
            cookies = data.get("cookies", {})
            user_agent = data.get("user_agent")
            if not cookies or not user_agent:
                return False

            self.clear_state()
            self.current_browser = "chrome120"
            sess = self._create_session("chrome120")
            
            if isinstance(cookies, dict):
                for k, v in cookies.items():
                    sess.cookies.set(k, v)
            elif isinstance(cookies, list):
                for c in cookies:
                    if isinstance(c, dict) and "name" in c and "value" in c:
                        sess.cookies.set(c["name"], c["value"])

            sess.headers["User-Agent"] = user_agent
            self.session = sess
            self.save_state()
            log("Cloudflare bypass cookies synchronized successfully.")
            return True
        except Exception:
            return False

    def is_challenge(self, r):
        if not r: return True
        if r.status_code in (403, 503, 429): return True
        body = (r.text or "").lower()
        return "cf-browser-verification" in body or "just a moment" in body or "attention required" in body

    def get_soup(self, url, referer=None, force_solve=False):
        headers = {"Referer": referer} if referer else {}
        time.sleep(random.uniform(1.5, 3.0))
        
        if not force_solve and (self.load_state() or self.session):
            try:
                r = self.session.get(url, headers=headers, timeout=20, allow_redirects=True)
                if not self.is_challenge(r):
                    self.save_state()
                    return BeautifulSoup(r.text, 'html.parser'), r
            except Exception:
                pass

        if force_solve or self._solve_via_docker_service(url):
            if force_solve:
                self._solve_via_docker_service(url)
            try:
                r = self.session.get(url, headers=headers, timeout=20, allow_redirects=True)
                if not self.is_challenge(r):
                    self.save_state()
                    return BeautifulSoup(r.text, 'html.parser'), r
            except Exception:
                pass

        self.clear_state()
        browsers = ["chrome124", "chrome120", "edge99", "safari15_5", "chrome116", "chrome110"]
        random.shuffle(browsers)
        
        for browser in browsers:
            try:
                time.sleep(random.uniform(2.5, 4.5))
                new_session = self._create_session(browser)
                r = new_session.get(url, headers=headers, timeout=20, allow_redirects=True)
                
                if self.is_challenge(r):
                    continue
                    
                self.session = new_session
                self.current_browser = browser
                self.save_state()
                return BeautifulSoup(r.text, 'html.parser'), r
            except Exception:
                time.sleep(1)
                
        log("All browsers failed Cloudflare checks.")
        return None, None

    def download(self, url, dest_path, is_bundle, referer):
        headers = {"Referer": referer} if referer else {}
        real_dest = f"{dest_path}.apkm" if is_bundle else dest_path
        
        log(f"Downloading file: {url}")
        r_file = self.session.get(url, headers=headers, timeout=300)
        
        if r_file.status_code == 200 and r_file.content.startswith(b"PK"):
            with open(real_dest, "wb") as f: f.write(r_file.content)
            with open(f"{dest_path}.is_bundle", "w") as f: f.write("true" if is_bundle else "false")
            log("SUCCESS")
        else:
            log(f"Download failed. HTTP {r_file.status_code}. Valid Zip: {r_file.content.startswith(b'PK')}")
            sys.exit(1)

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    url = sys.argv[2] if len(sys.argv) > 2 else ""
    
    scraper = Scraper()
    
    # ------------------ GITHUB HANDLERS ------------------
    if mode.startswith("github_"):
        gh_token = os.environ.get("GITHUB_TOKEN", "")
        gh_headers = {"User-Agent": "Morphe-DeVanced-Builder"}
        if gh_token:
            gh_headers["Authorization"] = f"token {gh_token}"

        gh_match = re.search(r"github\.com/([^/]+)/([^/]+)/releases/tags?/([^/]+)", url)
        if not gh_match:
            log(f"Invalid GitHub release URL: {url}")
            sys.exit(1)

        owner, repo, tag = gh_match.groups()
        api_url = f"https://api.github.com/repos/{owner}/{repo}/releases/tags/{tag}"

        try:
            r = requests.get(api_url, headers=gh_headers, timeout=20)
            if r.status_code != 200:
                log(f"GitHub API error {r.status_code}: {r.text}")
                sys.exit(1)
            release_data = r.json()
        except Exception as e:
            log(f"Failed to fetch GitHub release: {e}")
            sys.exit(1)

        arch_suffix = re.compile(r"(?:-(all|arm64-v8a|armeabi-v7a|x86_64|x86))?(?:\.apk\.apkm|\.apk|\.apkm)$", re.I)

        if mode == "github_pkg":
            pkg_name = release_data.get("name") or release_data.get("tag_name") or "UNKNOWN"
            print(f"PKG:{pkg_name}")

        elif mode == "github_vers":
            pkg_name = release_data.get("name") or release_data.get("tag_name") or ""
            prefix = f"{pkg_name}-"
            seen = {}
            for asset in release_data.get("assets", []):
                name = asset.get("name", "")
                if name.startswith(prefix) and name.endswith((".apk", ".apkm")):
                    ver = arch_suffix.sub("", name[len(prefix):])
                    seen[ver] = None
            versions = list(seen.keys()) or [release_data.get("tag_name", "")]
            for v in versions:
                if v:
                    print(v)

        elif mode == "github_dl":
            version = sys.argv[3].strip() if len(sys.argv) > 3 else ""
            dest_path = sys.argv[4].strip() if len(sys.argv) > 4 else ""
            arch = sys.argv[5].strip() if len(sys.argv) > 5 else "all"
            dpi = sys.argv[6].strip() if len(sys.argv) > 6 else ""
            version_code = sys.argv[7].strip() if len(sys.argv) > 7 else ""

            if arch == "arm-v7a":
                arch = "armeabi-v7a"
            version_f = version.replace(" ", "").lstrip("v")

            apk_assets = [a for a in release_data.get("assets", []) if a.get("name", "").endswith((".apk", ".apkm"))]
            target_asset = None

            # 1st Pass: Match version string AND version code
            if version_code:
                for a in apk_assets:
                    name = a.get("name", "")
                    if version_f not in name or version_code not in name:
                        continue
                    m = arch_suffix.search(name)
                    file_arch = m.group(1).lower() if m and m.group(1) else "all"
                    if arch in ("all", "both") and file_arch != "all": continue
                    if arch not in ("all", "both") and file_arch not in (arch, "all"): continue
                    target_asset = a
                    break

            # 2nd Pass: Fallback matching version string only
            if not target_asset:
                for a in apk_assets:
                    name = a.get("name", "")
                    if version_f and version_f not in name:
                        continue
                    m = arch_suffix.search(name)
                    file_arch = m.group(1).lower() if m and m.group(1) else "all"
                    if arch in ("all", "both") and file_arch != "all": continue
                    if arch not in ("all", "both") and file_arch not in (arch, "all"): continue
                    target_asset = a
                    break

            if not target_asset and apk_assets:
                target_asset = apk_assets[0]

            if not target_asset:
                log(f"No matching GitHub asset found for arch '{arch}' and version '{version}'")
                sys.exit(1)

            dl_url = target_asset.get("browser_download_url")
            is_bundle = target_asset.get("name", "").endswith(".apkm")
            real_dest = f"{dest_path}.apkm" if is_bundle else dest_path

            log(f"Downloading GitHub asset: {target_asset.get('name')}")
            dl_headers = gh_headers.copy()
            dl_headers["Accept"] = "application/octet-stream"

            r_file = requests.get(dl_url, headers=dl_headers, timeout=300, allow_redirects=True)
            if r_file.status_code == 200 and r_file.content.startswith(b"PK"):
                with open(real_dest, "wb") as f:
                    f.write(r_file.content)
                with open(f"{dest_path}.is_bundle", "w") as f:
                    f.write("true" if is_bundle else "false")
                log("SUCCESS")
            else:
                log(f"Download failed. HTTP {r_file.status_code}")
                sys.exit(1)

    # ------------------ APKMIRROR HANDLERS ------------------
    elif mode == "apkmirror_pkg":
        resolved_pkg = None
        if "youtube-music" in url: resolved_pkg = "com.google.android.apps.youtube.music"
        elif "youtube" in url: resolved_pkg = "com.google.android.youtube"
        elif "photos" in url: resolved_pkg = "com.google.android.apps.photos"
        elif "reddit" in url: resolved_pkg = "com.reddit.frontpage"
        elif "twitter" in url or "x-corp" in url: resolved_pkg = "com.twitter.android"
        elif "messenger" in url: resolved_pkg = "com.facebook.orca"
        elif "facebook" in url: resolved_pkg = "com.facebook.katana"
        elif "threads" in url: resolved_pkg = "com.instagram.barcelona"
        elif "instagram" in url: resolved_pkg = "com.instagram.android"

        soup, r = scraper.get_soup(url)
        if r and r.text:
            m = re.search(r"play\.google\.com/store/apps/details\?id=([\w.]+)", r.text)
            if m: 
                print(f"PKG:{m.group(1)}")
                return
        print(f"PKG:{resolved_pkg}" if resolved_pkg else "PKG:UNKNOWN")

    elif mode == "apkmirror_vers":
        cat = url.rstrip("/").split("/")[-1]
        soup, _ = scraper.get_soup(f"https://www.apkmirror.com/uploads/?appcategory={cat}")
        if soup:
            for a in soup.select("#primary a.fontBlack[href*='-release/']"):
                txt = a.get_text(strip=True)
                if txt and "beta" not in txt.lower() and "alpha" not in txt.lower():
                    print(txt.split()[-1])

    elif mode == "apkmirror_dl":
        version = sys.argv[3].strip() if len(sys.argv) > 3 else ""
        dest_path = sys.argv[4].strip() if len(sys.argv) > 4 else ""
        arch = sys.argv[5].strip() if len(sys.argv) > 5 else "all"
        dpi = sys.argv[6].strip() if len(sys.argv) > 6 else ""
        version_code = sys.argv[7].strip() if len(sys.argv) > 7 else ""
        if arch == "arm-v7a": arch = "armeabi-v7a"
        
        cat = url.rstrip("/").split("/")[-1]
        
        release_url = None
        
        # Priority 1: Match directly via exact path URL pattern (Robust against hyphens)
        search_url = f"{url.rstrip('/')}/?s={version}"
        log(f"Searching APKMirror via exact path: {search_url}")
        soup_search, _ = scraper.get_soup(search_url)
        
        if soup_search:
            for a in soup_search.select("a.fontBlack[href*='-release/']"):
                if version in a.get_text() and f"/{cat}/" in a.get("href", ""):
                    release_url = urljoin("https://www.apkmirror.com", a["href"])
                    break
                    
        # Priority 2: Fallback to global search if path lookup fails
        if not release_url:
            log("APKMirror release URL not found via path search, trying global search...")
            search_term = version.split("-")[0].strip()
            global_search_url = f"https://www.apkmirror.com/?post_type=app_release&searchtype=apk&s={cat}+{search_term}"
            if version_code:
                global_search_url += f"+{version_code}"

            soup_search, _ = scraper.get_soup(global_search_url)
            if soup_search:
                clean_target = re.sub(r'[^a-zA-Z0-9]', '', version.lower())
                for a in soup_search.select("a.fontBlack[href*='-release/']"):
                    txt = a.get_text(strip=True)
                    href = a.get("href", "")
                    clean_slug = re.sub(r'[^a-zA-Z0-9]', '', href.lower())
                    clean_txt = re.sub(r'[^a-zA-Z0-9]', '', txt.lower())
                    if clean_target in clean_slug or clean_target in clean_txt:
                        release_url = urljoin("https://www.apkmirror.com", href)
                        break

        if not release_url:
            log("APKMirror release URL not found.")
            sys.exit(1)
            
        soup_rel, r_rel = scraper.get_soup(release_url, referer=search_url)
        if not soup_rel:
            sys.exit(1)
            
        rows = soup_rel.select("div.table-row.headerFont")
        if not rows:
            rows = [r for r in soup_rel.select("div.table-row") if len(r.select("div.table-cell")) >= 4]
        
        apparch = {"universal", "noarch", "arm64-v8a + armeabi-v7a", "arm64-v8a + armeabi"}
        if arch != "all": apparch.add(arch)
        
        dl_sub_url = None
        is_bundle = False
        
        # 1st Pass: Match version code explicitly from row text
        if version_code:
            for target_type in ["APK", "BUNDLE"]:
                for row in reversed(rows):
                    cells = row.select("div.table-cell")
                    if len(cells) < 4: continue
                    badge = cells[0].select_one(".apkm-badge")
                    b_type = badge.get_text(strip=True).upper() if badge else "APK"
                    if b_type != target_type: continue
                    
                    arch_text = cells[1].get_text(strip=True)
                    dpi_text = cells[3].get_text(strip=True)
                    row_text = row.get_text()
                    
                    dpi_ok = not dpi_text or re.match(r"\d+-640dpi", dpi_text) or dpi_text in {"nodpi", "anydpi"} or (dpi and dpi in dpi_text)
                    vcode_ok = version_code in row_text

                    if arch_text in apparch and dpi_ok and vcode_ok:
                        link = row.find("a", href=re.compile(r"/download/")) or cells[0].find("a")
                        if link and link.get("href"):
                            dl_sub_url = urljoin("https://www.apkmirror.com", link["href"])
                            is_bundle = (target_type == "BUNDLE")
                            break
                if dl_sub_url: break

        # 2nd Pass: Fallback matching version string only
        if not dl_sub_url:
            for target_type in ["APK", "BUNDLE"]:
                for row in reversed(rows):
                    cells = row.select("div.table-cell")
                    if len(cells) < 4: continue
                    badge = cells[0].select_one(".apkm-badge")
                    b_type = badge.get_text(strip=True).upper() if badge else "APK"
                    if b_type != target_type: continue
                    
                    arch_text = cells[1].get_text(strip=True)
                    dpi_text = cells[3].get_text(strip=True)
                    
                    dpi_ok = not dpi_text or re.match(r"\d+-640dpi", dpi_text) or dpi_text in {"nodpi", "anydpi"} or (dpi and dpi in dpi_text)

                    if arch_text in apparch and dpi_ok:
                        link = row.find("a", href=re.compile(r"/download/")) or cells[0].find("a")
                        if link and link.get("href"):
                            dl_sub_url = urljoin("https://www.apkmirror.com", link["href"])
                            is_bundle = (target_type == "BUNDLE")
                            break
                if dl_sub_url: break

            
        if not dl_sub_url:
            sys.exit(1)
            
        soup_dl, _ = scraper.get_soup(dl_sub_url, referer=release_url)
        if not soup_dl:
            sys.exit(1)
            
        btn = soup_dl.select_one("a.downloadButton") or soup_dl.select_one("a.btn") or soup_dl.find("a", class_=re.compile("download"))
        if not btn:
            sys.exit(1)
            
        btn_url = urljoin("https://www.apkmirror.com", btn["href"])
        soup_final, _ = scraper.get_soup(btn_url, referer=dl_sub_url)
        if not soup_final:
            sys.exit(1)
            
        dl_link = soup_final.select_one("a[data-google-vignette='false'][rel='nofollow']") or soup_final.select_one("span > a[rel=nofollow]") or soup_final.find("a", string=re.compile("here", re.I))
        if not dl_link:
            sys.exit(1)
            
        final_download_url = urljoin("https://www.apkmirror.com", dl_link["href"])
        scraper.download(final_download_url, dest_path, is_bundle, btn_url)

    # ------------------ UPTODOWN HANDLERS ------------------
    elif mode == "uptodown_pkg":
        resolved_pkg = None
        if "youtube-music" in url: resolved_pkg = "com.google.android.apps.youtube.music"
        elif "youtube" in url: resolved_pkg = "com.google.android.youtube"
        elif "photos" in url: resolved_pkg = "com.google.android.apps.photos"
        elif "reddit" in url: resolved_pkg = "com.reddit.frontpage"
        elif "twitter" in url or "x-corp" in url: resolved_pkg = "com.twitter.android"
        elif "messenger" in url: resolved_pkg = "com.facebook.orca"
        elif "facebook" in url: resolved_pkg = "com.facebook.katana"
        elif "threads" in url: resolved_pkg = "com.instagram.barcelona"
        elif "instagram" in url: resolved_pkg = "com.instagram.android"

        soup, _ = scraper.get_soup(f"{url}/download")
        if soup:
            th = soup.find(lambda e: e.name in ("th", "td") and "package name" in e.text.lower())
            if th and th.find_next_sibling("td"):
                pkg = th.find_next_sibling("td").get_text(strip=True)
                if pkg and "." in pkg:
                    print(f"PKG:{pkg}")
                    return
            m = re.search(r'play\.google\.com/store/apps/details\?id=([\w.]+)', str(soup))
            if m:
                print(f"PKG:{m.group(1)}")
                return
        print(f"PKG:{resolved_pkg}" if resolved_pkg else "PKG:UNKNOWN")

    elif mode == "uptodown_vers":
        soup, _ = scraper.get_soup(f"{url}/versions")
        if soup:
            for el in soup.select(".version"):
                if t := el.get_text(strip=True): print(t)

    elif mode == "uptodown_dl":
        version = sys.argv[3].strip() if len(sys.argv) > 3 else ""
        dest_path = sys.argv[4].strip() if len(sys.argv) > 4 else ""
        arch = sys.argv[5].strip() if len(sys.argv) > 5 else "all"
        dpi = sys.argv[6].strip() if len(sys.argv) > 6 else ""
        version_code = sys.argv[7].strip() if len(sys.argv) > 7 else ""
        if arch == "arm-v7a": arch = "armeabi-v7a"
        
        soup, _ = scraper.get_soup(f"{url}/versions")
        
        def get_data_code(s):
            if not s: return None
            detail_app = s.select_one("#detail-app-name")
            if detail_app and "data-code" in detail_app.attrs:
                return detail_app["data-code"]
            elem = s.find(attrs={"data-code": True})
            if elem:
                return elem["data-code"]
            m = re.search(r'data-code=["\'](\d+)["\']', str(s))
            if m:
                return m.group(1)
            return None

        data_code = get_data_code(soup)
        if not data_code:
            log(f"Uptodown data-code not found, forcing Cloudflare solver for {url}...")
            soup, _ = scraper.get_soup(f"{url}/versions", force_solve=True)
            data_code = get_data_code(soup)

        if not data_code:
            log(f"Detail app data-code not found on Uptodown page for {url}")
            sys.exit(1)
            
        ver_url_data = None
        is_bundle = False

        def find_version(match_code=True):
            for i in range(1, 21):
                _, r = scraper.get_soup(f"{url}/apps/{data_code}/versions/{i}")
                if not r or not r.text: continue
                try:
                    data = json.loads(r.text).get("data", [])
                except Exception:
                    continue
                for entry in data:
                    if entry.get("version") == version:
                        if match_code and version_code and str(entry.get("versionCode", "")) != str(version_code):
                            continue
                        return entry.get("versionURL", {}), (entry.get("kindFile") == "xapk")
            return None, False

        ver_url_data, is_bundle = find_version(match_code=True)
        if not ver_url_data and version_code:
            ver_url_data, is_bundle = find_version(match_code=False)

        if not ver_url_data:
            log(f"Uptodown version {version} not found.")
            sys.exit(1)

        ver_url = f"{ver_url_data.get('url', '')}/{ver_url_data.get('extraURL', '')}/{ver_url_data.get('versionID', '')}"
        soup_ver, _ = scraper.get_soup(ver_url)
        if not soup_ver: sys.exit(1)
        
        btn_variants = soup_ver.select_one(".button.variants")

        if btn_variants and (data_version := btn_variants.get("data-version")):
            apparch = {"arm64-v8a, armeabi-v7a, x86_64", "arm64-v8a, armeabi-v7a, x86, x86_64", "arm64-v8a, armeabi-v7a"}
            if arch != "all": apparch.add(arch)

            base_url = url.rsplit("/", 1)[0]
            _, r_files = scraper.get_soup(f"{base_url}/app/{data_code}/version/{data_version}/files")
            files_html = json.loads(r_files.text).get("content", "") if r_files else ""
            soup_files = BeautifulSoup(files_html, 'html.parser')
            content = soup_files.select_one(".content")
            
            matched_id = None
            if content:
                for child in content.children:
                    if not getattr(child, "name", None): continue
                    if "variant" not in child.get("class", []):
                        node_arch = child.get_text(strip=True)
                        continue
                    if not node_arch or node_arch not in apparch:
                        continue
                    
                    file_type_tag = child.select_one(".v-file > span")
                    is_bundle = file_type_tag.get_text(strip=True) == "xapk" if file_type_tag else False
                    try:
                        matched_id = child.select_one(".v-report")["data-file-id"]
                        break
                    except Exception: continue

            if matched_id:
                soup_ver, _ = scraper.get_soup(f"{url}/download/{matched_id}-x")

        dl_btn = soup_ver.select_one("#detail-download-button") if soup_ver else None
        if not dl_btn or "data-url" not in dl_btn.attrs:
            log("Uptodown download button missing.")
            sys.exit(1)
            
        dl_url = dl_btn["data-url"]
        scraper.download(f"https://dw.uptodown.com/dwn/{dl_url}", dest_path, is_bundle, None)

if __name__ == "__main__":
    main()
EOF
	fi
}

run_python_backend() {
	python3 -u "$TEMP_DIR/network_engine.py" "$@"
}

setup_python_backend

# -------------------- github wrappers --------------------
get_github_resp() {
	__GITHUB_URL__="${1%/}"
	__GITHUB_RESP__=$(run_python_backend "github_pkg" "$__GITHUB_URL__") || return 1
}

get_github_pkg_name() { 
	local pkg=$(grep -oP '^PKG:\K.*' <<<"${__GITHUB_RESP__:-}" | head -1)
	echo "${pkg:-UNKNOWN}"
}

get_github_vers() { 
	run_python_backend "github_vers" "${__GITHUB_URL__:-}"
}

dl_github() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"

	if ! run_python_backend "github_dl" "$url" "$version" "$output" "$arch" "$dpi" "$vcode" >/dev/null; then
		return 1
	fi

	if [[ -f "${output}.is_bundle" && "$(cat "${output}.is_bundle")" == "true" ]] || [[ -f "${output}.apkm.is_bundle" ]]; then
		merge_splits "${output}.apkm" "${output}"
	fi
	[[ -f "$output" ]]
}

# -------------------- apkmirror wrappers --------------------
get_apkmirror_resp() {
	__APKMIRROR_URL__="${1%/}"
	__APKMIRROR_CAT__="${__APKMIRROR_URL__##*/}"
	__APKMIRROR_RESP__=$(run_python_backend "apkmirror_pkg" "$__APKMIRROR_URL__") || return 1
}

get_apkmirror_pkg_name() { 
	local pkg=$(grep -oP '^PKG:\K.*' <<<"${__APKMIRROR_RESP__:-}" | head -1)
	if [ -z "$pkg" ] || [ "$pkg" = "UNKNOWN" ]; then
		case "${__APKMIRROR_URL__,,}" in
			*youtube-music*) pkg="com.google.android.apps.youtube.music" ;;
			*youtube*) pkg="com.google.android.youtube" ;;
			*photos*) pkg="com.google.android.apps.photos" ;;
			*reddit*) pkg="com.reddit.frontpage" ;;
			*twitter*|*x*) pkg="com.twitter.android" ;;
			*messenger*) pkg="com.facebook.orca" ;;
			*facebook*) pkg="com.facebook.katana" ;;
			*threads*) pkg="com.instagram.barcelona" ;;
			*instagram*) pkg="com.instagram.android" ;;
		esac
	fi
	echo "${pkg:-UNKNOWN}"
}

get_apkmirror_vers() { run_python_backend "apkmirror_vers" "${__APKMIRROR_URL__:-}"; }

dl_apkmirror() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	if [ -f "${output}.apkm" ]; then
		merge_splits "${output}.apkm" "${output}"
		return 0
	fi
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"
	
	if ! run_python_backend "apkmirror_dl" "$url" "$version" "$output" "$arch" "$dpi" "$vcode" >/dev/null; then
		return 1
	fi
	
	if [[ -f "${output}.is_bundle" && "$(cat "${output}.is_bundle")" == "true" ]] || [[ -f "${output}.apkm.is_bundle" ]]; then
		merge_splits "${output}.apkm" "${output}"
	fi
	[[ -f "$output" ]]
}

# -------------------- uptodown wrappers --------------------
get_uptodown_resp() { 
	__UPTODOWN_URL__="${1%/}"
	__UPTODOWN_RESP__=$(run_python_backend "uptodown_pkg" "$__UPTODOWN_URL__") || return 1
}

get_uptodown_pkg_name() { 
	local pkg=$(grep -oP '^PKG:\K.*' <<<"${__UPTODOWN_RESP__:-}" | head -1)
	if [ -z "$pkg" ] || [ "$pkg" = "UNKNOWN" ]; then
		case "${__UPTODOWN_URL__,,}" in
			*youtube-music*) pkg="com.google.android.apps.youtube.music" ;;
			*youtube*) pkg="com.google.android.youtube" ;;
			*photos*) pkg="com.google.android.apps.photos" ;;
			*reddit*) pkg="com.reddit.frontpage" ;;
			*twitter*|*x*) pkg="com.twitter.android" ;;
			*messenger*) pkg="com.facebook.orca" ;;
			*facebook*) pkg="com.facebook.katana" ;;
			*threads*) pkg="com.instagram.barcelona" ;;
			*instagram*) pkg="com.instagram.android" ;;
		esac
	fi
	echo "${pkg:-UNKNOWN}"
}

get_uptodown_vers() { run_python_backend "uptodown_vers" "${__UPTODOWN_URL__:-}"; }

dl_uptodown() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"
	
	if ! run_python_backend "uptodown_dl" "$url" "$version" "$output" "$arch" "$dpi" "$vcode" >/dev/null; then
		return 1
	fi
	
	if [[ -f "${output}.is_bundle" && "$(cat "${output}.is_bundle")" == "true" ]] || [[ -f "${output}.apkm.is_bundle" ]]; then
		merge_splits "${output}.apkm" "${output}"
	fi
	[[ -f "$output" ]]
}

# -------------------- archive --------------------
dl_archive() {
	local url=$1 version=$2 output=$3 arch=$4 dpi=$5 vcode=${6:-}
	local path output_m version=${version// /}
	local version_f=${version#v}

	if [ -f "${output}.apkm" ]; then
		merge_splits "${output}.apkm" "$output"
		return 0
	fi

	local arch_query="${arch// /}"
	if [ "$arch_query" = "arm-v7a" ]; then arch_query="armeabi-v7a"; fi

	if ! path=$(grep -m1 "${version_f}-${arch_query}" <<<"${__ARCHIVE_RESP__:-}"); then
		if ! path=$(grep -m1 "${version_f}-${arch// /}" <<<"${__ARCHIVE_RESP__:-}"); then
			path=$(grep -m1 "${version_f}-all" <<<"${__ARCHIVE_RESP__:-}") || return 1
		fi
	fi

	if [ "${path##*.}" = "apkm" ]; then
		req "${url}/${path}" "${output}.apkm" || return 1
		merge_splits "${output}.apkm" "$output"
	else
		req "${url}/${path}" "${output}" || return 1
	fi
}
get_archive_resp() {
	local r
	r=$(req "$1" -) || return 1
	__ARCHIVE_RESP__=$(sed -n 's;^<a href="\(.*\)"[^"]*;\1;p' <<<"$r")
	__ARCHIVE_PKG_NAME__=$(awk -F/ '{print $NF}' <<<"$1")
}
get_archive_vers() { sed 's/^[^-]*-//;s/-\(all\|arm64-v8a\|arm-v7a\|armeabi-v7a\|x86_64\|x86\)\.apk//g' <<<"${__ARCHIVE_RESP__:-}"; }
get_archive_pkg_name() { echo "${__ARCHIVE_PKG_NAME__:-UNKNOWN}"; }

# -------------------- direct --------------------
dl_direct() {
	local url=$1 version=${2// /-} output=$3 arch=$4 _dpi=$5 vcode=${6:-}
	local version_f=${version#v}
	if ! grep -q "${version_f}-${arch// /}" <<<"$url"; then
		epr "Given direct-dlurl for $output is not compatible. Set proper 'arch' and 'version' options."
		return 1
	fi
	if [[ "${url##*.}" == "apkm" ]]; then
		req "$url" "${output}.apkm" || return 1
		merge_splits "${output}.apkm" "$output"
	else
		req "$url" "${output}" || return 1
	fi
}
get_direct_vers() { cut -d- -f2 <<<"${__DIRECT_APKNAME__:-}"; }
get_direct_pkg_name() { cut -d- -f1 <<<"${__DIRECT_APKNAME__:-}"; }
get_direct_resp() { __DIRECT_APKNAME__=$(awk -F/ '{print $NF}' <<<"$1"); }
# --------------------------------------------------

patch_apk() {
	local stock_input=$1 patched_apk=$2 patcher_args=$3 cli_jar=$4 patches_jars=$5
	local tmp_files
	tmp_files="$(pwd)/$(mktemp -d -p "$TEMP_DIR")"

	local p_flags=()
	for pj in $patches_jars; do
		p_flags+=("-p" "$pj")
	done

	local cmd="java -jar '$cli_jar' patch '$stock_input' -o '$patched_apk' "${p_flags[@]}" --keystore=ks.keystore \
    --keystore-entry-password=123456789 --keystore-password=123456789 --signer=jhc --keystore-entry-alias=jhc -t '$patched_apk-tmp' $patcher_args"

	local cli_name
	cli_name=$(basename "$cli_jar")
	if [[ "${cli_name::8}" == revanced ]]; then cmd+=" -b"; fi

	if [[ "$OS" == Android ]]; then cmd+=" --custom-aapt2-binary='${AAPT2}'"; fi
	pr "$cmd"
	if (set -o pipefail; eval "$cmd" 2>&1 | grep -vE "INFO: Processing|INFO: Writing|INFO: Wrote|INFO: Stripping|INFO: Compiling"); then
		[[ -f "$patched_apk" ]]
	else
		rm -f "$patched_apk" 2>/dev/null || :
		return 1
	fi
}

check_sig() {
	local file=$1 pkg_name=$2
	local sig
	if grep -q "$pkg_name" sig.txt; then
		sig=$(java -jar "$APKSIGNER" verify --print-certs "$file" | grep ^Signer | grep SHA-256 | tail -1 | awk '{print $NF}')
		echo "$pkg_name signature: ${sig}"
		grep -qFx "$sig $pkg_name" sig.txt
	fi
}

export __TARGET_VERSION_CODE__=""
export __TARGET_VERSION__=""

get_patch_last_supported_ver() {
	local list_patches=$1 pkg_name=$2 inc_sel=${3:-} is_experimental=${4:-false} arch=${5:-arm64-v8a}
	local op
	__TARGET_VERSION_CODE__=""
	__TARGET_VERSION__=""

	local arch_key="ARM64_V8A"
	if [[ "$arch" == "arm-v7a" ]]; then arch_key="ARMEABI_V7A"
	elif [[ "$arch" == "x86" ]]; then arch_key="X86"
	elif [[ "$arch" == "x86_64" ]]; then arch_key="X86_64"; fi

	if [[ -n "$inc_sel" ]]; then
		if ! op=$(awk '{$1=$1}1' <<<"$list_patches"); then
			epr "list-patches: '$op'"
			return 1
		fi
		local ver vers="" NL=$'\n'
		while IFS= read -r line; do
			line="${line:1:${#line}-2}"
			ver=$(sed -n "/^Name: $line\$/,/^\$/p" <<<"$op" | sed -n "/^Compatible versions:\$/,/^\$/p" | tail -n +2)
			vers=${ver}${NL}
		done <<<"$(list_args "$inc_sel")"
		vers=$(awk '{$1=$1}1' <<<"$vers")
		if [[ -n "$vers" ]]; then
			local best_ver=$(get_highest_ver <<<"$vers")
			if [[ -n "$best_ver" ]]; then
				if [[ "$best_ver" =~ $arch_key=([0-9]+) ]]; then
					export __TARGET_VERSION_CODE__="${BASH_REMATCH[1]}"
				fi
				local clean_ver="${best_ver%%\[*}"
				export __TARGET_VERSION__=$(echo "${clean_ver}" | tr -d '[:space:]')
				return 0
			fi
		fi
	fi
	if ! op=$(patches_list_versions "${args[cli]}" "${args[ptjar]}" "$pkg_name" "$is_experimental"); then
		return 1
	fi
	op=$(sed -n '/Most common compatible versions:/,$p' <<<"$op" | sed '1d' | awk '{$1=$1}1')
	if [[ "$op" == "Any" ]]; then return; fi
	pcount=$(head -1 <<<"$op") pcount=${pcount#*(} pcount=${pcount% *}
	if [[ -z "$pcount" ]]; then
		if grep -Fq "$pkg_name" <<<"$list_patches"; then
			return
		else
			abort "No patches found for '$pkg_name' in patches '${args[ptjar]}'"
		fi
	fi
	local best_ver=$(grep -F "($pcount patch" <<<"$op" | sed 's/ (.* patch.*//' | get_highest_ver || true)
	if [[ -n "$best_ver" ]]; then
		if [[ "$best_ver" =~ $arch_key=([0-9]+) ]]; then
			export __TARGET_VERSION_CODE__="${BASH_REMATCH[1]}"
		fi
		local clean_ver="${best_ver%%\[*}"
		export __TARGET_VERSION__=$(echo "${clean_ver}" | tr -d '[:space:]')
		return 0
	fi
	return 1
}

patches_list_versions() {
	local cli_jar=$1 patches_jars=$2 pkg_name=$3 is_experimental=$4
	local combined_op="" op="" cmd cmd_base="java -jar '$cli_jar' list-versions"
	local cli_name
	cli_name=$(basename "$cli_jar")
	if [ "${cli_name::8}" = "revanced" ]; then
		cmd_base+=" -b"
	elif [ "$is_experimental" = "true" ]; then
		cmd_base+=" -x"
	fi

	for pj in $patches_jars; do
		cmd="${cmd_base} --patches='$pj' -f '$pkg_name'"
		if op=$(eval "$cmd" 2>&1); then
			combined_op+="$op"$'\n'
			continue
		fi
		cmd="${cmd_base} '$pj' -f '$pkg_name'"
		if op=$(eval "$cmd" 2>&1); then
			combined_op+="$op"$'\n'
		fi
	done

	if [[ -n "$combined_op" ]]; then
		echo "$combined_op"
		return 0
	fi
	epr "Could not list versions ($pkg_name) $cli_jar"
	return 1
}

patches_list() {
	local cli_jar=$1 patches_jars=$2 pkg_name=$3 is_experimental=$4
	local combined_op="" op=""
	for pj in $patches_jars; do
		if op=$(java -jar "$cli_jar" list-patches -p "$pj" --filter-package-name "$pkg_name" --versions --packages -b 2>&1); then
			combined_op+="$op"$'\n'
		else
			local cmd="java -jar '$cli_jar' list-patches --patches '$pj' -f '$pkg_name' --with-versions --with-packages"
			if [ "$is_experimental" = "true" ]; then cmd+=" -x"; fi
			if op=$(eval "$cmd" 2>&1); then
				combined_op+="$op"$'\n'
			fi
		fi
	done

	if [[ -z "$combined_op" ]]; then
		epr "Could not get patches list ($pkg_name) $cli_jar"
		return 1
	fi
	echo "$combined_op"
}

build_rv() {
	eval "declare -A args=${1#*=}"
	export __TARGET_VERSION_CODE__=""
	export __TARGET_VERSION__=""
	local version="" pkg_name=""
	local mode_arg=${args[build_mode]:-} version_mode=${args[version]:-}
	local app_name=${args[app_name]:-}
	local app_name_l=${app_name,,}
	app_name_l=${app_name_l// /-}
	local table=${args[table]:-}
	local dl_from=${args[dl_from]:-}
	local arch=${args[arch]:-}
	local arch_f="${arch// /}"

	local p_patcher_args=()
	if [[ -n "${args[excluded_patches]:-}" ]]; then p_patcher_args+=("$(join_args "${args[excluded_patches]}" -d)"); fi
	if [[ -n "${args[included_patches]:-}" ]]; then p_patcher_args+=("$(join_args "${args[included_patches]}" -e)"); fi
	[[ "${args[exclusive_patches]:-}" == true ]] && p_patcher_args+=("--exclusive")

	local tried_dl=()
	if [[ -n "${args[pkg_name]:-}" ]]; then
		pkg_name="${args[pkg_name]}"
	else
		for dl_p in "${DL_SRCS[@]}"; do
			if [[ -z "${args[${dl_p}_dlurl]:-}" ]]; then continue; fi
			if ! get_${dl_p}_resp "${args[${dl_p}_dlurl]}" || ! pkg_name=$(get_"${dl_p}"_pkg_name); then
				args[${dl_p}_dlurl]=""
				epr "ERROR: Could not find ${table} in ${dl_p}"
				continue
			fi
			tried_dl+=("$dl_p")
			dl_from=$dl_p
			break
		done
	fi

	if [[ -z "$pkg_name" || "$pkg_name" == "UNKNOWN" ]]; then
		epr "empty pkg name, not building ${table}."
		return 0
	fi
	pr "Package name of '${table}' is '$pkg_name'"

	local list_patches
	local is_experimental="false"
	if [ "$version_mode" = "experimental" ]; then is_experimental="true"; fi
	list_patches=$(patches_list "${args[cli]}" "${args[ptjar]}" "$pkg_name" "$is_experimental") || return 1

	local get_latest_ver=false
	if isoneof "$version_mode" "auto" "experimental"; then
		get_patch_last_supported_ver "$list_patches" "$pkg_name" "${args[included_patches]:-}" "$is_experimental" "${args[arch]}" || true
		if [[ -z "$__TARGET_VERSION__" ]]; then 
			get_latest_ver="true"
		else
			version="$__TARGET_VERSION__"
		fi
	elif [ "$version_mode" = "latest" ]; then
		get_latest_ver="true"
		p_patcher_args+=("-f")
	elif [ "$version_mode" = "beta" ]; then
		get_latest_ver="true"
		p_patcher_args+=("-f")
	else
		version=$version_mode
		p_patcher_args+=("-f")
	fi

	if [[ $get_latest_ver == true ]]; then
		if [[ "$version_mode" == beta ]]; then __AAV__="true"; else __AAV__="false"; fi
		
		# Scan through sources in priority order to securely fetch the latest version
		for dl_p in "${DL_SRCS[@]}"; do
			if [[ -n "${args[${dl_p}_dlurl]:-}" ]]; then
				dl_from=$dl_p
				
				# Initialize the URL variable to prevent unbound variable errors
				if [[ "$dl_p" == "apkmirror" ]]; then __APKMIRROR_URL__="${args[${dl_p}_dlurl]}"
				elif [[ "$dl_p" == "uptodown" ]]; then __UPTODOWN_URL__="${args[${dl_p}_dlurl]}"
				elif [[ "$dl_p" == "github" ]]; then __GITHUB_URL__="${args[${dl_p}_dlurl]}"
				elif [[ "$dl_p" == "archive" ]]; then __ARCHIVE_URL__="${args[${dl_p}_dlurl]}"
				elif [[ "$dl_p" == "direct" ]]; then __DIRECT_APKNAME__=$(awk -F/ '{print $NF}' <<<"${args[${dl_p}_dlurl]}"); fi
				
				if ! get_${dl_p}_resp "${args[${dl_p}_dlurl]}"; then
					continue
				fi
				pkgvers=$(get_"${dl_from}"_vers)
				version=$(get_highest_ver <<<"$pkgvers") || version=$(head -1 <<<"$pkgvers")
				
				# Break out of the loop once a valid version is found
				if [[ -n "$version" ]]; then 
					break
				fi
			fi
		done
	fi
	
	if [[ -z "$version" ]]; then
		epr "empty version, not building ${table}."
		return 0
	fi

	if [[ "$mode_arg" == module ]]; then
		build_mode_arr=(module)
	elif [[ "$mode_arg" == apk ]]; then
		build_mode_arr=(apk)
	elif [[ "$mode_arg" == both ]]; then
		build_mode_arr=(apk module)
	fi

	local version_f=${version// /}
	version_f=${version_f#v}

	if [[ -n "${__TARGET_VERSION_CODE__:-}" ]]; then
		pr "Choosing version '${version_f}' (Code: ${__TARGET_VERSION_CODE__}) for ${table}"
	else
		pr "Choosing version '${version_f}' for ${table}"
	fi

	local stock_apk="${TEMP_DIR}/${pkg_name}-${version_f}-${arch_f}.apk"
	if [[ ! -f "$stock_apk" ]]; then
		for dl_p in "${DL_SRCS[@]}"; do
			if [[ -z "${args[${dl_p}_dlurl]:-}" ]]; then continue; fi
			pr "Downloading '${table}' from '${dl_p}'"
			if ! isoneof $dl_p "${tried_dl[@]}"; then
				if ! get_${dl_p}_resp "${args[${dl_p}_dlurl]}"; then
					epr "ERROR: Could not get '${table}' from '${dl_p}'"
					continue
				fi
			fi
			if ! dl_${dl_p} "${args[${dl_p}_dlurl]}" "$version_f" "$stock_apk" "$arch" "${args[dpi]:-}" "${__TARGET_VERSION_CODE__:-}"; then
				epr "ERROR: Could not download '${table}' from '${dl_p}' with version '${version_f}', arch '${arch}', dpi '${args[dpi]:-}'"
				continue
			fi
			break
		done
		if [[ ! -f "$stock_apk" ]]; then
			epr "Stock apk not found ($stock_apk)"
			return 0
		fi
	fi

	local sig_op
	if [[ -f "${stock_apk}.apkm" ]]; then
		rm -rf "${stock_apk}-zip" || :
		unzip -j "${stock_apk}.apkm" -d "${stock_apk}-zip" >/dev/null
		for a in "${stock_apk}"-zip/*.apk; do
			if ! sig_op=$(check_sig "$a" "$pkg_name" 2>&1); then
				epr "Not building $table, apk signature mismatch '$a': $sig_op"
				return 0
			fi
		done
		rm -rf "${stock_apk}-zip" || :
	else
		if ! sig_op=$(check_sig "$stock_apk" "$pkg_name" 2>&1); then
			epr "Not building $table, apk signature mismatch '$stock_apk': $sig_op"
			return 0
		fi
	fi
	
	log "📱 » **${table}** (${arch_f}): \`${version_f}\`  "

	local microg_patch
	microg_patch=$(grep "^Name: " <<<"$list_patches" | grep -i "gmscore\|microg" || :) microg_patch=${microg_patch#*: }
	if [[ -n "$microg_patch" && ${p_patcher_args[*]} =~ $microg_patch ]]; then
		wpr "You cant include/exclude microg patch as that's done by rvmm builder automatically."
		p_patcher_args=("${p_patcher_args[@]//-[ei] ${microg_patch}/}")
	fi

	local patcher_args patched_apk build_mode
	local rv_brand_f=${args[rv_brand],,}
	rv_brand_f=${rv_brand_f// /-}
	if [[ -n "${args[patcher_args]:-}" ]]; then p_patcher_args+=("${args[patcher_args]}"); fi
	for build_mode in "${build_mode_arr[@]}"; do
		patcher_args=("${p_patcher_args[@]}")
		
		local display_mode
		if [[ "$build_mode" == "apk" ]]; then
			display_mode="APK"
		else
			display_mode="Module"
		fi
		pr "running compilation context: building \"${display_mode}\" variant of ${table}"
		
		if [[ -n "$microg_patch" ]]; then
			patched_apk="${TEMP_DIR}/${app_name_l}-${rv_brand_f}-${version_f}-${arch_f}-${build_mode}.apk"
		else
			patched_apk="${TEMP_DIR}/${app_name_l}-${rv_brand_f}-${version_f}-${arch_f}.apk"
		fi
		if [[ -n "$microg_patch" ]]; then
			if [[ "$build_mode" == apk ]]; then
				patcher_args+=("-e \"${microg_patch}\"")
			elif [[ "$build_mode" == module ]]; then
				patcher_args+=("-d \"${microg_patch}\"")
			fi
		fi

		local stock_apk_to_patch="${stock_apk}.stripped.apk"
		cp -f "$stock_apk" "$stock_apk_to_patch"
		if [[ "$build_mode" == module ]]; then
			zip -d "$stock_apk_to_patch" "lib/*" >/dev/null 2>&1 || :
		else
			if [[ "$arch" == "arm64-v8a" ]]; then
				zip -d "$stock_apk_to_patch" "lib/armeabi-v7a/*" "lib/x86_64/*" "lib/x86/*" >/dev/null 2>&1 || :
			elif [[ "$arch" == "arm-v7a" ]]; then
				zip -d "$stock_apk_to_patch" "lib/arm64-v8a/*" "lib/x86_64/*" "lib/x86/*" >/dev/null 2>&1 || :
			elif [[ "$arch" == "x86" ]]; then
				zip -d "$stock_apk_to_patch" "lib/arm64-v8a/*" "lib/x86_64/*" "lib/armeabi-v7a/*" >/dev/null 2>&1 || :
			elif [[ "$arch" == "x86_64" ]]; then
				zip -d "$stock_apk_to_patch" "lib/arm64-v8a/*" "lib/armeabi-v7a/*" "lib/x86/*" >/dev/null 2>&1 || :
			else
				zip -d "$stock_apk_to_patch" "lib/x86_64/*" "lib/x86/*" >/dev/null 2>&1 || :
			fi
		fi

		local apk_output="${BUILD_DIR}/${app_name_l}-${rv_brand_f}-v${version_f}-${arch_f}.apk"
		if [[ "${NORB:-}" != true || ( ! -f "$patched_apk" && ! -f "$apk_output" ) ]]; then
			if ! patch_apk "$stock_apk_to_patch" "$patched_apk" "${patcher_args[*]}" "${args[cli]}" "${args[ptjar]}"; then
				epr "Building '${table}' failed!"
				return 0
			fi
		fi
		rm "$stock_apk_to_patch"
		if [[ "$build_mode" == apk ]]; then
			if [[ "${NORB:-}" != true || ( ! -f "$patched_apk" && ! -f "$apk_output" ) ]]; then
				mv -f "$patched_apk" "$apk_output"
			else
				cp -f "$patched_apk" "$apk_output"
			fi
			pr "Built ${table} (non-root): '${apk_output}'"
			continue
		fi
		local base_template
		base_template=$(mktemp -d -p "$TEMP_DIR")
		cp -a $MODULE_TEMPLATE_DIR/. "$base_template"
		local upj="${table,,}-update.json"

		module_config "$base_template" "$pkg_name" "$version_f" "$arch"

		local p_vers=()
		for pj in ${args[ptjar]}; do
			p_vers+=("${pj##*-}")
		done
		local patches_ver="${p_vers[*]}"

		module_prop \
			"${args[module_prop_name]:-}" \
			"${app_name} ${args[rv_brand]:-}" \
			"${version_f} (patches ${patches_ver})" \
			"${app_name} ${args[rv_brand]:-} module" \
			"https://raw.githubusercontent.com/${GITHUB_REPOSITORY-}/update/${upj}" \
			"$base_template"

		local module_output="${app_name_l}-${rv_brand_f}-module-v${version_f}-${arch_f}.zip"
		pr "Packing module ${table}"
		cp -f "$patched_apk" "${base_template}/base.apk"

		if [[ "${args[include_stock]:-}" != "disable" ]]; then
			mkdir -p "${base_template}/stock/"
			if [[ "${args[include_stock]:-}" == "merged" ]]; then
				cp -f "$stock_apk" "${base_template}/stock/base.apk"
			elif [[ "${args[include_stock]:-}" == "split" ]]; then
				if [[ ! -f "${stock_apk}.apkm" ]]; then
					epr "Cannot include as 'split' because stock apk of $table is not a bundle"
					return 0
				fi
				if [[ "$arch" == "arm64-v8a" ]]; then
					unzip -j "${stock_apk}.apkm" '*.apk' -x '*x86_64.apk' -x '*x86.apk' -x '*armeabi_v7a.apk' -d "${base_template}/stock/" >/dev/null 2>&1
				elif [[ "$arch" == "arm-v7a" ]]; then
					unzip -j "${stock_apk}.apkm" '*.apk' -x '*x86_64.apk' -x '*x86.apk' -x '*arm64_v8a.apk' -d "${base_template}/stock/" >/dev/null 2>&1
				elif [[ "$arch" == "x86" ]]; then
					unzip -j "${stock_apk}.apkm" '*.apk' -x '*x86_64.apk' -x '*arm64_v8a.apk' -x '*armeabi_v7a.apk' -d "${base_template}/stock/" >/dev/null 2>&1
				elif [[ "$arch" == "x86_64" ]]; then
					unzip -j "${stock_apk}.apkm" '*.apk' -x '*x86.apk' -x '*arm64_v8a.apk' -x '*armeabi_v7a.apk' -d "${base_template}/stock/" >/dev/null 2>&1
				else
					unzip -j "${stock_apk}.apkm" '*.apk' -x '*x86_64.apk' -x '*x86.apk' -d "${base_template}/stock/" >/dev/null 2>&1
				fi
			fi
		fi

		pushd >/dev/null "$base_template" || abort "Module template dir not found"
		zip -"$COMPRESSION_LEVEL" -FSqr "${CWD}/${BUILD_DIR}/${module_output}" .
		popd >/dev/null || :
		pr "Built ${table} (root): '${BUILD_DIR}/${module_output}'"
	done
}

list_args() { tr -d '\t\r' <<<"$1" | tr -s ' ' | sed 's/" "/"\n"/g' | sed 's/\([^"]\)"\([^"]\)/\1'\''\2/g' | grep -v '^$' || :; }
join_args() { list_args "$1" | sed "s/^/${2} /" | paste -sd " " - || :; }

module_config() {
	local ma=""
	if [[ "$4" == "arm64-v8a" ]]; then
		ma="arm64"
	elif [[ "$4" == "arm-v7a" ]]; then
		ma="arm"
	fi
	echo "PKG_NAME=$2
PKG_VER=$3
MODULE_ARCH=$ma" >"$1/config"
}
module_prop() {
	echo "id=${1}
name=${2}
version=v${3}
versionCode=${NEXT_VER_CODE}
author=dj_tanjid | j-hc
banner=https://raw.githubusercontent.com/dj-tanjid/Morphe-ReVancedX-Builder/teejay/${1}/banner.webp
description=${4}" >"${6}/module.prop"

	if [[ "$ENABLE_MODULE_UPDATE" == true ]]; then echo "updateJson=${5}" >>"${6}/module.prop"; fi
}
