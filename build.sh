#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

source utils.sh

# --- Global Environment Export Setup ---
for func_name in _req req gh_req gh_dl build_rv patches_list patches_list_versions toml_get toml_get_table toml_get_table_names toml_get_table_main dl_direct dl_github dl_archive dl_apkmirror dl_uptodown get_direct_vers get_github_vers get_archive_vers get_apkmirror_vers get_uptodown_vers get_direct_pkg_name get_github_pkg_name get_archive_pkg_name get_apkmirror_pkg_name get_uptodown_pkg_name get_direct_resp get_github_resp get_archive_resp get_apkmirror_resp get_uptodown_resp apkmirror_search merge_splits check_sig patch_apk isoneof log get_highest_ver semver_validate get_patch_last_supported_ver list_args join_args module_config module_prop abort epr wpr pr java run_python_backend; do
    export -f "$func_name" 2>/dev/null || true
done
export MODULE_TEMPLATE_DIR CWD TEMP_DIR BIN_DIR BUILD_DIR DL_SRCS GH_HEADER NEXT_VER_CODE OS
# ---------------------------------------

trap "abort" INT

if [ "${1-}" = "clean" ]; then
	rm -rf "$TEMP_DIR" "$BUILD_DIR" build.md
	exit 0
fi

jq --version >/dev/null || abort "\`jq\` is not installed. install it with 'apt install jq' or equivalent"
java --version >/dev/null || abort "\`java\` is not installed. install it with 'apt install openjdk-21-jre' or equivalent"
zip --version >/dev/null || abort "\`zip\` is not installed. install it with 'apt install zip' or equivalent"

set_prebuilts

vtf() { if ! isoneof "${1}" "true" "false"; then abort "ERROR: '${1}' is not a valid option for '${2}': only true or false is allowed"; fi; }

# -- Main config --
toml_prep "${1:-config.toml}" || abort "could not find config file '${1:-config.toml}'\n\tUsage: $0 <config.toml>"
main_config_t=$(toml_get_table_main)
COMPRESSION_LEVEL=$(toml_get "$main_config_t" compression-level) || COMPRESSION_LEVEL="9"

# Strictly enforce sequential execution to ensure live-streaming output in GitHub Actions
PARALLEL_JOBS=1 

REMOVE_RV_INTEGRATIONS_CHECKS=$(toml_get "$main_config_t" remove-rv-integrations-checks) || REMOVE_RV_INTEGRATIONS_CHECKS="true"
DEF_PATCHES_VER=$(toml_get "$main_config_t" patches-version) || DEF_PATCHES_VER="latest"
DEF_CLI_VER=$(toml_get "$main_config_t" cli-version) || DEF_CLI_VER="latest"
DEF_PATCHES_SRC=$(toml_get "$main_config_t" patches-source) || DEF_PATCHES_SRC="github:MorpheApp/morphe-patches"
DEF_CLI_SRC=$(toml_get "$main_config_t" cli-source) || DEF_CLI_SRC="github:MorpheApp/morphe-desktop"
DEF_RV_BRAND=$(toml_get "$main_config_t" rv-brand) || DEF_RV_BRAND="ReVanced"
mkdir -p "$TEMP_DIR" "$BUILD_DIR"

if [ "${2-}" = "--config-update" ]; then
	config_update
	exit 0
fi

: >build.md
ENABLE_MODULE_UPDATE=$(toml_get "$main_config_t" enable-module-update) || ENABLE_MODULE_UPDATE=true
if [ "$ENABLE_MODULE_UPDATE" = true ] && [ -z "${GITHUB_REPOSITORY-}" ]; then
	pr "You are building locally. Module updates will not be enabled."
	ENABLE_MODULE_UPDATE=false
fi
if ((COMPRESSION_LEVEL > 9)) || ((COMPRESSION_LEVEL < 0)); then abort "compression-level must be within 0-9"; fi

rm -rf module/bin/*/tmp.*
rm -f "${TEMP_DIR}/patches_changelog.md" "${TEMP_DIR}/cli_changelog.md"

mkdir -p ${MODULE_TEMPLATE_DIR}/bin/arm64 ${MODULE_TEMPLATE_DIR}/bin/arm ${MODULE_TEMPLATE_DIR}/bin/x86 ${MODULE_TEMPLATE_DIR}/bin/x64
gh_dl "${MODULE_TEMPLATE_DIR}/bin/arm64/cmpr" "https://github.com/j-hc/cmpr/releases/latest/download/cmpr-arm64-v8a"
gh_dl "${MODULE_TEMPLATE_DIR}/bin/arm/cmpr" "https://github.com/j-hc/cmpr/releases/latest/download/cmpr-armeabi-v7a"
gh_dl "${MODULE_TEMPLATE_DIR}/bin/x86/cmpr" "https://github.com/j-hc/cmpr/releases/latest/download/cmpr-x86"
gh_dl "${MODULE_TEMPLATE_DIR}/bin/x64/cmpr" "https://github.com/j-hc/cmpr/releases/latest/download/cmpr-x86_64"

# Terminal banner for clear live logging visibility without breaking stream
print_banner() {
	echo -e "\n\033[1;35m============================================================\033[0m"
	echo -e "\033[1;36m  🚀 PROCESSING : $1\033[0m"
	echo -e "\033[1;35m============================================================\033[0m\n"
}

for table_name in $(toml_get_table_names); do
	if [ -z "$table_name" ]; then continue; fi
	t=$(toml_get_table "$table_name")
	enabled=$(toml_get "$t" enabled) || enabled=true
	vtf "$enabled" "enabled"
	if [ "$enabled" = false ]; then continue; fi

	declare -A app_args
	patches_src=$(toml_get "$t" patches-source) || patches_src=$DEF_PATCHES_SRC
	patches_ver=$(toml_get "$t" patches-version) || patches_ver=$DEF_PATCHES_VER
	cli_src=$(toml_get "$t" cli-source) || cli_src=$DEF_CLI_SRC
	cli_ver=$(toml_get "$t" cli-version) || cli_ver=$DEF_CLI_VER

	if ! PREBUILTS="$(get_prebuilts "$cli_src" "$cli_ver" "$patches_src" "$patches_ver")"; then
		epr "Could not get prebuilts"
		continue
	fi

	# Parse prebuilts dynamically (handles 1 or more patch jars + CLI jar as last element)
	read -r -a pb_all <<<"$PREBUILTS"
	cli_jar="${pb_all[-1]}"
	unset 'pb_all[-1]'
	patches_jar="${pb_all[*]}"

	app_args[cli]=$cli_jar
	app_args[ptjar]=$patches_jar
	app_args[rv_brand]=$(toml_get "$t" rv-brand) || app_args[rv_brand]=$DEF_RV_BRAND

	app_args[excluded_patches]=$(toml_get "$t" excluded-patches) || app_args[excluded_patches]=""
	if [ -n "${app_args[excluded_patches]}" ] && [[ ${app_args[excluded_patches]} != *'"'* ]]; then abort "patch names inside excluded-patches must be quoted"; fi
	app_args[included_patches]=$(toml_get "$t" included-patches) || app_args[included_patches]=""
	if [ -n "${app_args[included_patches]}" ] && [[ ${app_args[included_patches]} != *'"'* ]]; then abort "patch names inside included-patches must be quoted"; fi
	app_args[exclusive_patches]=$(toml_get "$t" exclusive-patches) && vtf "${app_args[exclusive_patches]}" "exclusive-patches" || app_args[exclusive_patches]=false
	app_args[version]=$(toml_get "$t" version) || app_args[version]="auto"
	app_args[app_name]=$(toml_get "$t" app-name) || app_args[app_name]=$table_name
	app_args[patcher_args]=$(toml_get "$t" patcher-args) || app_args[patcher_args]=""
	app_args[table]=$table_name
	app_args[build_mode]=$(toml_get "$t" build-mode) && {
		if ! isoneof "${app_args[build_mode]}" both apk module; then
			abort "ERROR: build-mode '${app_args[build_mode]}' is not a valid option for '${table_name}': only 'both', 'apk' or 'module' is allowed"
		fi
	} || app_args[build_mode]=apk
	app_args[include_stock]=$(toml_get "$t" include-stock) && {
		if ! isoneof "${app_args[include_stock]}" disable merged split; then
			abort "ERROR: include-stock '${app_args[include_stock]}' is not a valid option for '${table_name}': only 'disable', 'merged' or 'split' is allowed"
		fi
	} || app_args[include_stock]=merged

	for dl_from in "${DL_SRCS[@]}"; do
		if app_args[${dl_from}_dlurl]=$(toml_get "$t" "${dl_from}-dlurl"); then
			app_args[${dl_from}_dlurl]=${app_args[${dl_from}_dlurl]%/}
			app_args[${dl_from}_dlurl]=${app_args[${dl_from}_dlurl]%download}
			app_args[${dl_from}_dlurl]=${app_args[${dl_from}_dlurl]%/}
			app_args[dl_from]=${dl_from}
		else
			app_args[${dl_from}_dlurl]=""
		fi
	done
	if [ -z "${app_args[dl_from]-}" ]; then abort "ERROR: no 'dlurl' option was set for '$table_name'. (${DL_SRCS[*]})"; fi
	app_args[arch]=$(toml_get "$t" arch) || app_args[arch]="all"
	if ! isoneof "${app_args[arch]}" "both" "all" "arm64-v8a" "arm-v7a" "x86_64" "x86"; then
		abort "wrong arch '${app_args[arch]}' for '$table_name'"
	fi

	app_args[pkg_name]=$(toml_get "$t" pkg-name) || app_args[pkg_name]=""
	app_args[dpi]=$(toml_get "$t" dpi) || app_args[dpi]=""
	table_name_f=${table_name,,}
	table_name_f=${table_name_f// /-}
	app_args[module_prop_name]=$(toml_get "$t" module-prop-name) || app_args[module_prop_name]="${table_name_f}-jhc"

	if [ "${app_args[arch]}" = both ]; then
		app_args[table]="$table_name"
		app_args[arch]="arm64-v8a"
		module_prop_name_b=${app_args[module_prop_name]}
		app_args[module_prop_name]="${module_prop_name_b}-arm64"
		
		print_banner "${app_args[table]} (arm64-v8a)"
		build_rv "$(declare -p app_args)"
		
		app_args[table]="$table_name"
		app_args[arch]="arm-v7a"
		app_args[module_prop_name]="${module_prop_name_b}-arm"
		
		print_banner "${app_args[table]} (arm-v7a)"
		build_rv "$(declare -p app_args)"
	else
		if [ "${app_args[arch]}" = "arm64-v8a" ]; then
			app_args[module_prop_name]="${app_args[module_prop_name]}-arm64"
		elif [ "${app_args[arch]}" = "arm-v7a" ]; then
			app_args[module_prop_name]="${app_args[module_prop_name]}-arm"
		fi
		
		print_banner "${app_args[table]}"
		build_rv "$(declare -p app_args)"
	fi
done

_clean_tmp
if [ -z "$(ls -A1 "${BUILD_DIR}")" ]; then abort "All builds failed."; fi

log "\n<br>\n"
log "\n**Note:**"
log "```text\n• Install and login via ReVanced GmsCore or Morphe MicroG-RE for non-root APKs.\n• (Optional) Use zygisk-detach to detach YouTube and YT Music modules from Google Play Store or even better use HMA.\n• (Optional) Import my Custom Settings into your application.\n```"
log "\n<br>\n"

log "Patches and CLI Sources :\n"
if [ -s "${TEMP_DIR}/patches_changelog.md" ]; then
	# Prepend '>' only to the first line, and indent the rest cleanly
	sed '1s/^[ >]*/> /; 2,$s/^[ >]*/ /' "${TEMP_DIR}/patches_changelog.md" >> build.md || true
	log ""
fi

if [ -s "${TEMP_DIR}/cli_changelog.md" ]; then
	# Prepend '>' to the CLI string
	sed 's/^[ >]*/> /' "${TEMP_DIR}/cli_changelog.md" >> build.md || true
	log ""
fi

SKIPPED=$(cat "$TEMP_DIR"/skipped 2>/dev/null || :)
if [ -n "$SKIPPED" ]; then
	log "\nSkipped:"
	log "$SKIPPED"
fi

pr "Done"
