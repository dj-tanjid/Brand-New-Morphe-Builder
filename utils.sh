#!/usr/bin/env bash

MODULE_TEMPLATE_DIR="module"
CWD=$(pwd)
TEMP_DIR="temp"
BIN_DIR="bin"
BUILD_DIR="build"
DL_SRCS=("direct" "github" "archive" "apkmirror" "uptodown")

if [ "${GITHUB_TOKEN-}" ]; then GH_HEADER="Authorization: token ${GITHUB_TOKEN}"; else GH_HEADER=; fi
NEXT_VER_CODE=${NEXT_VER_CODE:-$(date +'%Y%m%d')}
OS=$(uname -o)

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
	op=$(jq -r ".\"${2}\" | values" <<<"$1" 2>/dev/null)
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
	local cli_src=${1:-} cli_ver=${2:-latest} patches_src=${3:-} patches_ver=${4:-latest}
	pr "Getting prebuilts (${patches_src%/*})" >&2
	local cl_dir=${patches_src%/*}
	cl_dir=${TEMP_DIR}/${cl_dir,,}-rv
	[[ -d "$cl_dir" ]] || mkdir -p "$cl_dir"

	for src_ver in "Patches $patches_src $patches_ver" "CLI $cli_src $cli_ver"; do
		set -- $src_ver
		local tag=$1 src=$2 ver=${3-}

		local dir=${src%/*}
		dir=${TEMP_DIR}/${dir,,}-rv
		[[ -d "$dir" ]] || mkdir -p "$dir"

		local rv_rel="https://api.github.com/repos/${src}/releases" name_ver
		if [[ "$ver" == "dev" ]]; then
			local resp
			resp=$(gh_req "$rv_rel" -) || return 1
			ver=$(jq -e -r '.[] | .tag_name' <<<"$resp" | get_highest_ver) || return 1
		fi
		if [[ "$ver" == "latest" ]]; then
			rv_rel+="/latest"
			name_ver="*"
		else
			rv_rel+="/tags/${ver}"
			name_ver="$ver"
		fi

		local file
		if [ "$tag" = "CLI" ]; then
			file=$(find "$dir" -maxdepth 1 -name "*cli-${name_ver#v}*.jar" -o -name "*desktop-${name_ver#v}*.jar" -type f 2>/dev/null)
			local grab_cl=false
		elif [ "$tag" = "Patches" ]; then
			file=$(find "$dir" -maxdepth 1 -name "*patches-${name_ver#v}.*" -type f 2>/dev/null)
			local grab_cl=true
		else abort unreachable; fi

		local url tag_name matches
		if [ "$ver" = "latest" ]; then
			file=$(grep -v '/[^/]*dev[^/]*$' <<<"$file" | head -1)
		else
			file=$(grep "/[^/]*${ver#v}[^/]*\$" <<<"$file" | head -1)
		fi
		if [[ -z "$file" ]]; then
			local resp asset name
			resp=$(gh_req "$rv_rel" -) || return 1
			tag_name=$(jq -r '.tag_name' <<<"$resp") || return 1
			matches=$(jq -e '.assets | map(select(.name | (endswith("asc") or endswith("json")) | not))' <<<"$resp") || return 1
			if [[ "$(jq 'length' <<<"$matches")" -gt 1 ]]; then
				local matches_new
				matches_new=$(jq -e -r 'map(select(.name | contains("-dev") | not))' <<<"$matches")
				if [[ "$(jq 'length' <<<"$matches_new")" -eq 1 ]]; then
					matches=$matches_new
				fi
			fi
			if [[ "$(jq 'length' <<<"$matches")" -eq 0 ]]; then
				epr "No asset was found"
				return 1
			elif [[ "$(jq 'length' <<<"$matches")" -ne 1 ]]; then
				wpr "More than 1 asset was found for this release. Falling back to the first one found..."
			fi
			asset=$(jq -r ".[0]" <<<"$matches")
			url=$(jq -r .url <<<"$asset")
			name=$(jq -r .name <<<"$asset")
			file="${dir}/${name}"
			gh_dl "$file" >&2 "$url" || return 1
			echo "$tag: $(cut -d/ -f1 <<<"$src")/${name}  " >>"${cl_dir}/changelog.md"
		else
			grab_cl=false
			name=$(basename "$file")
			tag_name=$(cut -d'-' -f3- <<<"$name")
			tag_name=v${tag_name%.*}
		fi

		if [[ "$tag" == "Patches" ]]; then
			if [[ "$grab_cl" == true ]]; then echo -e "[Changelog](https://github.com/${src}/releases/tag/${tag_name})\n" >>"${cl_dir}/changelog.md"; fi
			if [[ "${REMOVE_RV_INTEGRATIONS_CHECKS:-}" == true ]]; then
				local extensions_ext
				extensions_ext=$(unzip -l "${file}" "extensions/shared.*" | grep -o "shared\..*") extensions_ext="${extensions_ext#*.}"
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
				rm -r "${file}-zip" || :
			fi
		fi
		echo -n "$file "
	done
	echo
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
		if [[ -v sources["$PATCHES_SRC/$PATCHES_VER"] ]]; then
			if [ "${sources["$PATCHES_SRC/$PATCHES_VER"]}" = 1 ]; then upped+=("$table_name"); fi
		else
			sources["$PATCHES_SRC/$PATCHES_VER"]=0
			local rv_rel="https://api.github.com/repos/${PATCHES_SRC}/releases"
			if [ "$PATCHES_VER" = "dev" ]; then
				last_patches=$(gh_req "$rv_rel" - | jq -e -r '.[0]') || continue
			elif [ "$PATCHES_VER" = "latest" ]; then
				last_patches=$(gh_req "$rv_rel/latest" -) || continue
			else
				last_patches=$(gh_req "$rv_rel/tags/${PATCHES_VER}" -) || continue
			fi
			if ! last_patches=$(jq -e -r '.assets[] | select(.name | (endswith("asc") or endswith("json")) | not) | .name' <<<"$last_patches"); then
				abort "config_update error: '$last_patches'"
			fi
			if [ "$last_patches" ]; then
				if ! OP=$(grep "^Patches: ${PATCHES_SRC%%/*}/" build.md | grep -m1 "$last_patches"); then
					sources["$PATCHES_SRC/$PATCHES_VER"]=1
					prcfg=true
					upped+=("$table_name")
				else
					echo "$OP" >>"$TEMP_DIR"/skipped
				fi
			fi
		fi
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

# Resolves the SIGPIPE broken pipe error that aborts GitHub Action workflows
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

# Integrated Upstream PR Changes
get_patch_last_supported_ver() {
	local list_patches=$1 pkg_name=$2 inc_sel=${3:-} is_experimental=${4:-false}
	local op
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
			get_highest_ver <<<"$vers"
			return
		fi
	fi
	op=$(patches_list_versions "$cli_jar" "$patches_jar" "$pkg_name" "$is_experimental") || return 1
	op=$(sed -n '/Most common compatible versions:/,$p' <<<"$op" | sed '1d' | awk '{$1=$1}1')
	if [[ "$op" == "Any" ]]; then return; fi
	pcount=$(head -1 <<<"$op") pcount=${pcount#*(} pcount=${pcount% *}
	if [[ -z "$pcount" ]]; then
		abort "No patches found for '$pkg_name' in patches '$patches_jar'"
	fi
	grep -F "($pcount patch" <<<"$op" | sed 's/ (.* patch.*//' | get_highest_ver || return 1
}

# Integrated Upstream PR Changes
patches_list_versions() {
	local cli_jar=$1 patches_jar=$2 pkg_name=$3 is_experimental=$4 op cmd
	local cmd_base="java -jar '$cli_jar' list-versions"

	local cli_name
	cli_name=$(basename "$cli_jar")
	if [ "${cli_name::8}" = "revanced" ]; then
		cmd_base+=" -b"
	elif [ "$is_experimental" = "true" ]; then
		cmd_base+=" -x"
	fi

	cmd="${cmd_base} --patches='$patches_jar' -f '$pkg_name'"
	if op=$(eval "$cmd" 2>&1); then
		echo "$op"
		return
	fi

	cmd="${cmd_base} '$patches_jar' -f '$pkg_name'"
	if op=$(eval "$cmd" 2>&1); then
		echo "$op"
		return
	fi

	epr "Could not list versions ($pkg_name) $cli_jar: '$op'"
	return 1
}

# Integrated Upstream PR Changes
patches_list() {
	local cli_jar=$1 patches_jar=$2 pkg_name=$3 is_experimental=$4 op
	if ! op=$(java -jar "$cli_jar" list-patches -p "$patches_jar" --filter-package-name "$pkg_name" --versions --packages -b 2>&1); then
		local cmd="java -jar '$cli_jar' list-patches --patches '$patches_jar' -f '$pkg_name' --with-versions --with-packages"
		if [ "$is_experimental" = "true" ]; then cmd+=" -x"; fi
		if ! op=$(eval "$cmd" 2>&1); then
			epr "Could not get patches list ($pkg_name) $cli_jar: '$op'"
			return 1
		fi
	fi
	echo "$op"
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
		python3 -m pip install -q "curl_cffi>=0.7.0" beautifulsoup4 urllib3 2>/dev/null || true
		cat << 'EOF' > "$TEMP_DIR/network_engine.py"
import sys, os, re, time, json, random
from urllib.parse import urljoin

def log(msg):
    sys.stderr.write(f"[Scraper] {msg}\n")
    sys.stderr.flush()

try:
    from curl_cffi import requests
    from bs4 import BeautifulSoup
except ImportError as e:
    log(f"Fatal Import Error: {e}. Missing dependencies.")
    if len(sys.argv) > 1 and sys.argv[1].endswith("_pkg"):
        print("PKG:UNKNOWN")
        sys.exit(0)
    sys.exit(1)

COOKIE_JAR = "/tmp/apkmirror_cookies.json"
BROWSER_CFG = "/tmp/apkmirror_browser.txt"

class Scraper:
    def __init__(self):
        self.session = None
        self.current_browser = "chrome120"
        
    def save_state(self):
        if self.session and self.current_browser:
            try:
                with open(BROWSER_CFG, "w") as f: f.write(self.current_browser)
                with open(COOKIE_JAR, "w") as f: json.dump(self.session.cookies.get_dict(), f)
            except: pass

    def load_state(self):
        try:
            if os.path.exists(BROWSER_CFG) and os.path.exists(COOKIE_JAR):
                with open(BROWSER_CFG, "r") as f: self.current_browser = f.read().strip()
                self.session = requests.Session(impersonate=self.current_browser)
                with open(COOKIE_JAR, "r") as f:
                    for k, v in json.load(f).items():
                        self.session.cookies.set(k, v)
                return True
        except: pass
        return False

    def clear_state(self):
        try:
            if os.path.exists(BROWSER_CFG): os.remove(BROWSER_CFG)
            if os.path.exists(COOKIE_JAR): os.remove(COOKIE_JAR)
        except: pass

    def get_soup(self, url, referer=None):
        headers = {"Referer": referer} if referer else {}
        time.sleep(random.uniform(2.0, 4.0))
        
        if self.load_state() or self.session:
            try:
                r = self.session.get(url, headers=headers, timeout=20, allow_redirects=True)
                if r.status_code < 400 and "cf-browser-verification" not in r.text and "Just a moment" not in r.text:
                    self.save_state()
                    return BeautifulSoup(r.text, 'html.parser'), r
            except Exception as e:
                pass

        self.clear_state()
        browsers = ["chrome124", "chrome120", "edge99", "safari15_5", "chrome116", "chrome110"]
        random.shuffle(browsers)
        
        for browser in browsers:
            try:
                time.sleep(random.uniform(3.5, 6.0))
                new_session = requests.Session(impersonate=browser)
                r = new_session.get(url, headers=headers, timeout=20, allow_redirects=True)
                
                if r.status_code in (403, 503) or "Just a moment" in r.text or "cf-browser-verification" in r.text:
                    continue
                    
                self.session = new_session
                self.current_browser = browser
                self.save_state()
                return BeautifulSoup(r.text, 'html.parser'), r
            except Exception as e:
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
    
    if mode == "apkmirror_pkg":
        resolved_pkg = None
        if "youtube-music" in url: resolved_pkg = "com.google.android.apps.youtube.music"
        elif "youtube" in url: resolved_pkg = "com.google.android.youtube"
        elif "photos" in url: resolved_pkg = "com.google.android.apps.photos"
        elif "reddit" in url: resolved_pkg = "com.reddit.frontpage"
        elif "twitter" in url or "x-corp" in url: resolved_pkg = "com.twitter.android"

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
            for a in soup.find_all("a", href=re.compile(r"-release/$")):
                txt = a.text.strip()
                if txt and "beta" not in txt.lower() and "alpha" not in txt.lower():
                    print(txt.split()[-1])

    elif mode == "apkmirror_dl":
        version, dest_path, arch, dpi = sys.argv[3:7]
        if arch == "arm-v7a": arch = "armeabi-v7a"
        
        cat = url.rstrip("/").split("/")[-1]
        log(f"Searching APKMirror for version {version} ({cat})")
        
        search_term = version.split("-")[0].strip()
        search_url = f"https://www.apkmirror.com/?post_type=app_release&searchtype=apk&s={cat}+{search_term}"
        
        soup_search, _ = scraper.get_soup(search_url)
        if not soup_search: 
            sys.exit(1)
        
        release_url = None
        clean_target = re.sub(r'[^a-zA-Z0-9]', '', version.lower())
        
        for a in soup_search.find_all("a", href=re.compile(r"-release/$")):
            txt = a.text.strip()
            href = a.get("href", "")
            
            clean_slug = re.sub(r'[^a-zA-Z0-9]', '', href.lower())
            clean_txt = re.sub(r'[^a-zA-Z0-9]', '', txt.lower())
            
            if clean_target in clean_slug or clean_target in clean_txt:
                release_url = urljoin("https://www.apkmirror.com", href)
                break
                
        if not release_url:
            sys.exit(1)
            
        soup_rel, r_rel = scraper.get_soup(release_url, referer=search_url)
        if not soup_rel:
            sys.exit(1)
            
        rows = [r for r in soup_rel.select("div.table-row") if len(r.select("div.table-cell")) >= 4]
        
        apparch = {"universal", "noarch", "arm64-v8a + armeabi-v7a", "arm64-v8a + armeabi"}
        if arch != "all": apparch.add(arch)
        
        dl_sub_url = None
        is_bundle = False
        
        for target_type in ["APK", "BUNDLE"]:
            for row in reversed(rows):
                cells = row.select("div.table-cell")
                badge = cells[0].select_one(".apkm-badge")
                b_type = badge.get_text(strip=True).upper() if badge else "APK"
                
                if b_type != target_type: continue
                
                arch_text = cells[1].get_text(strip=True)
                dpi_text = cells[3].get_text(strip=True)
                
                dpi_ok = not dpi_text or "nodpi" in dpi_text or "anydpi" in dpi_text or (dpi and dpi in dpi_text)
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

    elif mode == "uptodown_pkg":
        resolved_pkg = None
        if "youtube-music" in url: resolved_pkg = "com.google.android.apps.youtube.music"
        elif "youtube" in url: resolved_pkg = "com.google.android.youtube"
        elif "photos" in url: resolved_pkg = "com.google.android.apps.photos"
        elif "reddit" in url: resolved_pkg = "com.reddit.frontpage"
        elif "twitter" in url or "x-corp" in url: resolved_pkg = "com.twitter.android"

        soup, _ = scraper.get_soup(f"{url}/download")
        if soup:
            th = soup.find("th", string=re.compile("Package Name", re.I))
            if th and th.find_next_sibling("td"):
                print(f"PKG:{th.find_next_sibling('td').get_text(strip=True)}")
                return
        print(f"PKG:{resolved_pkg}" if resolved_pkg else "PKG:UNKNOWN")

    elif mode == "uptodown_vers":
        soup, _ = scraper.get_soup(f"{url}/versions")
        if soup:
            for el in soup.select(".version"):
                if t := el.get_text(strip=True): print(t)

    elif mode == "uptodown_dl":
        version, dest_path, arch, dpi = sys.argv[3:7]
        if arch == "arm-v7a": arch = "armeabi-v7a"
        
        soup, _ = scraper.get_soup(f"{url}/versions")
        if not soup:
            log(f"Uptodown versions page failed to load for {url}")
            sys.exit(1)
        
        detail_app = soup.select_one("#detail-app-name")
        if not detail_app or "data-code" not in detail_app.attrs:
            log(f"Detail app name not found on Uptodown page for {url}")
            sys.exit(1)
            
        data_code = detail_app["data-code"]
        
        ver_url_data = None
        is_bundle = False
        for i in range(1, 21):
            _, r = scraper.get_soup(f"{url}/apps/{data_code}/versions/{i}")
            if not r or not r.text: continue
            try:
                data = json.loads(r.text).get("data", [])
            except Exception:
                continue
            for entry in data:
                if entry.get("version") == version:
                    ver_url_data = entry.get("versionURL", {})
                    is_bundle = (entry.get("kindFile") == "xapk")
                    break
            if ver_url_data: break

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
                    except: continue

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

# -------------------- apkmirror wrappers --------------------
get_apkmirror_resp() {
	__APKMIRROR_URL__="${1%/}"
	__APKMIRROR_CAT__="${__APKMIRROR_URL__##*/}"
	__APKMIRROR_RESP__=$(run_python_backend "apkmirror_pkg" "$__APKMIRROR_URL__") || return 1
}

get_apkmirror_pkg_name() { 
	local pkg=$(grep -oP '^PKG:\K.*' <<<"$__APKMIRROR_RESP__" | head -1)
	if [ -z "$pkg" ] || [ "$pkg" = "UNKNOWN" ]; then
		case "${__APKMIRROR_URL__,,}" in
			*youtube-music*) pkg="com.google.android.apps.youtube.music" ;;
			*youtube*) pkg="com.google.android.youtube" ;;
			*photos*) pkg="com.google.android.apps.photos" ;;
			*reddit*) pkg="com.reddit.frontpage" ;;
			*twitter*|*x*) pkg="com.twitter.android" ;;
		esac
	fi
	echo "${pkg:-UNKNOWN}"
}

get_apkmirror_vers() { run_python_backend "apkmirror_vers" "$__APKMIRROR_URL__"; }

dl_apkmirror() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5
	if [ -f "${output}.apkm" ]; then
		merge_splits "${output}.apkm" "${output}"
		return 0
	fi
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"
	
	if ! run_python_backend "apkmirror_dl" "$url" "$version" "$output" "$arch" "$dpi" >/dev/null; then
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
	local pkg=$(grep -oP '^PKG:\K.*' <<<"$__UPTODOWN_RESP__" | head -1)
	if [ -z "$pkg" ] || [ "$pkg" = "UNKNOWN" ]; then
		case "${__UPTODOWN_URL__,,}" in
			*youtube-music*) pkg="com.google.android.apps.youtube.music" ;;
			*youtube*) pkg="com.google.android.youtube" ;;
			*photos*) pkg="com.google.android.apps.photos" ;;
			*reddit*) pkg="com.reddit.frontpage" ;;
			*twitter*|*x*) pkg="com.twitter.android" ;;
		esac
	fi
	echo "${pkg:-UNKNOWN}"
}

get_uptodown_vers() { run_python_backend "uptodown_vers" "$__UPTODOWN_URL__"; }

dl_uptodown() {
	local url="${1%/}" version=$2 output=$3 arch=$4 dpi=$5
	rm -f "${output}.is_bundle" "${output}.apkm.is_bundle"
	
	if ! run_python_backend "uptodown_dl" "$url" "$version" "$output" "$arch" "$dpi" >/dev/null; then
		return 1
	fi
	
	if [[ -f "${output}.is_bundle" && "$(cat "${output}.is_bundle")" == "true" ]] || [[ -f "${output}.apkm.is_bundle" ]]; then
		merge_splits "${output}.apkm" "${output}"
	fi
	[[ -f "$output" ]]
}

# -------------------- archive --------------------
dl_archive() {
	local url=$1 version=$2 output=$3 arch=$4
	local path output_m version=${version// /}
	local version_f=${version#v}

	if [ -f "${output}.apkm" ]; then
		merge_splits "${output}.apkm" "$output"
		return 0
	fi

	path=$(grep -m1 "${version_f}-${arch// /}" <<<"$__ARCHIVE_RESP__" || grep -m1 "${version_f}" <<<"$__ARCHIVE_RESP__") || return 1
	if [[ "${path##*.}" == "apkm" ]]; then output_m="${output}.apkm"; else output_m=$output; fi
	_req "${url}/${path}" "$output_m" || return 1
	if [[ "${path##*.}" == "apkm" ]]; then merge_splits "$output_m" "$output"; fi
}
get_archive_resp() {
	local r
	r=$(req "$1" -)
	if [ -z "$r" ]; then return 1; else __ARCHIVE_RESP__=$(sed -n 's;^<a href="\(.*\)"[^"]*;\1;p' <<<"$r"); fi
	__ARCHIVE_PKG_NAME__=$(awk -F/ '{print $NF}' <<<"$1")
}
get_archive_vers() { sed 's/^[^-]*-//;s/-\(all\|arm64-v8a\|arm-v7a\)\.apk//g' <<<"$__ARCHIVE_RESP__"; }
get_archive_pkg_name() { echo "$__ARCHIVE_PKG_NAME__"; }

# -------------------- github --------------------
get_github_resp() {
	local url=$1 owner repo tag api_url
	if [[ "$url" =~ github\.com/([^/]+)/([^/]+)/releases/tag/([^/]+) ]]; then
		owner="${BASH_REMATCH[1]}"
		repo="${BASH_REMATCH[2]}"
		tag="${BASH_REMATCH[3]}"
	else
		return 1
	fi
	api_url="https://api.github.com/repos/${owner}/${repo}/releases/tags/${tag}"
	__GITHUB_RESP__=$(gh_req "$api_url" -) || return 1
}
get_github_vers() {
	local name prefix ver versions=()
	name=$(jq -r '.name // empty' <<<"$__GITHUB_RESP__")
	[[ -z "$name" ]] && jq -r '.tag_name' <<<"$__GITHUB_RESP__" && return
	prefix="${name}-"
	
	while read -r asset_name; do
		[[ ! "$asset_name" =~ \.(apk|apkm)$ ]] && continue
		[[ "$asset_name" != "$prefix"* ]] && continue
		ver="${asset_name#"$prefix"}"
		ver=$(sed -E 's/(-(all|arm64-v8a|armeabi-v7a|x86_64|x86))?(\.apk\.apkm|\.apk|\.apkm)$//I' <<<"$ver")
		versions+=("$ver")
	done < <(jq -r '.assets[].name' <<<"$__GITHUB_RESP__")
	
	if [[ ${#versions[@]} -eq 0 ]]; then
		jq -r '.tag_name' <<<"$__GITHUB_RESP__"
	else
		echo "${versions[@]}" | tr ' ' '\n' | sort -u
	fi
}
get_github_pkg_name() { jq -r '.name // .tag_name' <<<"$__GITHUB_RESP__"; }
dl_github() {
	local url=$1 version=$2 output=$3 arch=$4 dpi=$5 is_bundle=false
	local version_f asset matches=() target_asset=""
	version_f=$(echo "${version// /}" | sed 's/^v//')

	if [[ "$arch" == "arm-v7a" ]]; then arch="armeabi-v7a"; fi

	while read -r row; do
		local name url_dl
		name=$(cut -f1 <<<"$row")
		url_dl=$(cut -f2 <<<"$row")
		[[ ! "$name" =~ \.(apk|apkm)$ ]] && continue
		if [[ -n "$version_f" && "$name" != *"$version_f"* ]]; then continue; fi
		
		local file_arch="all"
		if [[ "$name" =~ -(all|arm64-v8a|armeabi-v7a|x86_64|x86) ]]; then
			file_arch="${BASH_REMATCH[1]}"
		fi

		if [[ "$arch" == "all" || "$arch" == "both" ]]; then
			[[ "$file_arch" == "all" ]] && matches+=("$name|$url_dl")
		else
			{ [[ "$file_arch" == "$arch" ]] || [[ "$file_arch" == "all" ]]; } && matches+=("$name|$url_dl")
		fi
	done < <(jq -r '.assets[] | \(.name)\t\(.browser_download_url)' <<<"$__GITHUB_RESP__")

	for pair in "${matches[@]}"; do
		local n="${pair%%|*}" u="${pair#*|}"
		if [[ "$n" =~ -"$arch" ]] && [[ "$n" =~ \.apk$ ]]; then
			target_asset="$u"; [[ "$n" == "*.apkm" ]] && is_bundle=true; break
		fi
	done
	if [[ -z "$target_asset" ]]; then
		for pair in "${matches[@]}"; do
			local n="${pair%%|*}" u="${pair#*|}"
			if [[ "$n" =~ \.apk$ ]]; then
				target_asset="$u"; break
			fi
		done
	fi
	if [[ -z "$target_asset" && ${#matches[@]} -gt 0 ]]; then
		local pair="${matches[0]}"
		local n="${pair%%|*}" u="${pair#*|}"
		target_asset="$u"
		[[ "$n" == *.apkm ]] && is_bundle=true
	fi

	if [[ -z "$target_asset" ]]; then epr "No matching asset variant found on GitHub Release"; return 1; fi

	if [[ "$is_bundle" == true ]]; then
		gh_dl "${output}.apkm" "$target_asset" || return 1
		merge_splits "${output}.apkm" "${output}"
	else
		gh_dl "${output}" "$target_asset" || return 1
	fi
}

# -------------------- direct --------------------
dl_direct() {
	local url=$1 version=${2// /-} output=$3 arch=$4 _dpi=$5
	if ! grep -q "${version_f#v}-${arch// /}" <<<"$url"; then
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
get_direct_vers() { cut -d- -f2 <<<"$__DIRECT_APKNAME__"; }
get_direct_pkg_name() { cut -d- -f1 <<<"$__DIRECT_APKNAME__"; }
get_direct_resp() { __DIRECT_APKNAME__=$(awk -F/ '{print $NF}' <<<"$1"); }
# --------------------------------------------------

patch_apk() {
	local stock_input=$1 patched_apk=$2 patcher_args=$3 cli_jar=$4 patches_jar=$5
	local tmp_files
	tmp_files="$(pwd)/$(mktemp -d -p "$TEMP_DIR")"

	local cmd="java -jar '$cli_jar' patch '$stock_input' -o '$patched_apk' -p '$patches_jar' --keystore=ks.keystore \
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

build_rv() {
	eval "declare -A args=${1#*=}"
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
		if ! version=$(get_patch_last_supported_ver "$list_patches" "$pkg_name" "${args[included_patches]:-}" "$is_experimental"); then
			epr "get_patch_last_supported_ver failed '$list_patches'"
			return
		elif [ -z "$version" ]; then get_latest_ver="true"; fi
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
		pkgvers=$(get_"${dl_from}"_vers)
		version=$(get_highest_ver <<<"$pkgvers") || version=$(head -1 <<<"$pkgvers")
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

	pr "Choosing version '${version}' for ${table}"
	local version_f=${version// /}
	version_f=${version_f#v}
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
			if ! dl_${dl_p} "${args[${dl_p}_dlurl]}" "$version" "$stock_apk" "$arch" "${args[dpi]:-}" "$get_latest_ver"; then
				epr "ERROR: Could not download '${table}' from '${dl_p}' with version '${version}', arch '${arch}', dpi '${args[dpi]:-}'"
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
	log "${table}: ${version}"

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

		module_config "$base_template" "$pkg_name" "$version" "$arch"

		local patches_ver="${args[ptjar]##*-}"
		module_prop \
			"${args[module_prop_name]:-}" \
			"${app_name} ${args[rv_brand]:-}" \
			"${version} (patches ${patches_ver})" \
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
