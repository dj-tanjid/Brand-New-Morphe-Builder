# Configuration Guide

Adding an app is as simple as defining a table entry with download sources and patch settings:

```toml
[YouTube-Morphe]
apkmirror-dlurl = "[https://www.apkmirror.com/apk/google-inc/youtube](https://www.apkmirror.com/apk/google-inc/youtube)"
# uptodown-dlurl = "[https://youtube.en.uptodown.com/android](https://youtube.en.uptodown.com/android)"
# github-dlurl = "[https://github.com/owner/repo/releases/tag/com.google.android.youtube](https://github.com/owner/repo/releases/tag/com.google.android.youtube)"
```

> [!WARNING]
> When a patch name contains single quotes, double it inside the string (e.g., `'Hide ''Get Music Premium'''`).

---

## Enhanced Features & Key Differences from Upstream

* **Multi-Host Source Schemes (`github:` & `gitlab:`)**: `patches-source` and `cli-source` accept explicit host prefixes (`github:owner/repo` or `gitlab:group/repo`).
* **Multiple Patch Sources**: Multiple patch bundles can be supplied as a TOML array or multiline string. The builder will download all bundles and pass them concurrently to the CLI patcher.
* **New Download Sources**: Native support for **GitHub Releases** (`github-dlurl`) and **Archive.org** (`archive-dlurl`) alongside APKMirror and Uptodown.
* **Prioritized Download Fallback**: If a download source fails or is blocked, the builder automatically falls back in order: **APKMirror → Uptodown → GitHub → Direct → Archive**.
* **Explicit Package Overrides (`pkg-name`)**: You can define `pkg-name` directly in `config.toml` to prevent package resolution errors when scraping.
* **Updated Default Tooling**: Defaults to `github:MorpheApp/morphe-patches` and `github:MorpheApp/morphe-desktop`.

---

## Global Options

Global options apply to all app targets unless overridden inside an individual app table.

```toml
parallel-jobs = 1                    # Enforces sequential execution for live GitHub Action streaming
compression-level = 9                # Module zip compression level (0–9)
remove-rv-integrations-checks = true # Automatically patch shared integration checks

# Default tool sources (Supports 'github:' and 'gitlab:' prefixes)
patches-source = "github:MorpheApp/morphe-patches"
cli-source = "github:MorpheApp/morphe-desktop"
rv-brand = "Morphe"                  # Default brand name for patches

patches-version = "latest"           # 'latest', 'dev', or a specific release tag
cli-version = "latest"               # 'latest', 'dev', or a specific release tag
```

---

## App Options Reference

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `enabled` | `boolean` | `true` | Set to `false` to skip compiling this application. |
| `app-name` | `string` | Table Name | Display name used in Magisk module properties and release logs. |
| `pkg-name` | `string` | *(Auto-detected)* | Explicit Android package name (e.g. `com.facebook.katana`). |
| `rv-brand` | `string` | `"Morphe"` | Rebrands patched output APK and module names. |
| `build-mode` | `string` | `"apk"` | Target format: `'apk'`, `'module'`, or `'both'`. |
| `arch` | `string` | `"all"` | Target architecture: `'arm64-v8a'`, `'arm-v7a'`, `'x86'`, `'x86_64'`, `'all'`, or `'both'`. |
| `version` | `string` | `"auto"` | Target version: `'auto'`, `'experimental'`, `'latest'`, `'beta'`, or a fixed version string. |
| `dpi` | `string` | `""` | Filter screen density variant (e.g. `'nodpi'`, `'120-640dpi'`). |
| `patches-source` | `string` / `array` | Global Default | One or more patch bundles (`github:owner/repo` or `gitlab:group/repo`). |
| `patches-version`| `string` / `array` | Global Default | Version tag(s) or `'dev'` / `'latest'` matching the patch sources. |
| `cli-source` | `string` | Global Default | CLI executable repository. |
| `cli-version` | `string` | Global Default | CLI version tag or `'latest'` / `'dev'`. |
| `included-patches` | `string` | `""` | Quoted list of non-default patches to include. |
| `excluded-patches` | `string` | `""` | Quoted list of default patches to exclude. |
| `exclusive-patches`| `boolean` | `false` | When `true`, only patches in `included-patches` will be applied. |
| `include-stock` | `string` | `"merged"` | Include stock APK in root module: `'merged'`, `'split'`, or `'disable'`. |
| `patcher-args` | `string` | `""` | Extra CLI arguments passed directly to the patch command. |
| `apkmirror-dlurl` | `string` | `""` | APKMirror application category or release page URL. |
| `uptodown-dlurl` | `string` | `""` | Uptodown application base page URL. |
| `github-dlurl` | `string` | `""` | GitHub Release tag URL holding raw APK/APKM assets. |
| `archive-dlurl` | `string` | `""` | Archive.org APK repository directory URL. |
| `direct-dlurl` | `string` | `""` | Direct link pointing to a standalone `.apk` or `.apkm` file. |

---

## Configuration Examples

### 1. Multi-Source Patching (Combining GitHub & GitLab Patches)
Apply multiple patch sources simultaneously using a TOML array:

```toml
[Twitter-Piko]
enabled = true
app-name = "Twitter"
patches-source = ["github:crimera/piko", "gitlab:inotia00/x-shim"]
patches-version = ["dev", "latest"]
cli-source = "github:MorpheApp/morphe-desktop"
rv-brand = "Piko"
build-mode = "apk"
arch = "arm64-v8a"
version = "latest"
included-patches = """\
    'Bring back twitter' \
    'Dynamic color' \
    """
github-dlurl = "[https://github.com/dj-tanjid/AppRepo/releases/tag/com.twitter.android](https://github.com/dj-tanjid/AppRepo/releases/tag/com.twitter.android)"
apkmirror-dlurl = "[https://www.apkmirror.com/apk/x-corp/twitter](https://www.apkmirror.com/apk/x-corp/twitter)"
```

### 2. Multi-Architecture Building (`arch = "both"`)
Compile separate `arm64-v8a` and `arm-v7a` root modules and APKs automatically in a single run:

```toml
[YouTube-Morphe]
enabled = true
app-name = "YouTube"
patches-source = "github:MorpheApp/morphe-patches"
cli-source = "github:MorpheApp/morphe-desktop"
rv-brand = "Morphe"
build-mode = "both"
arch = "both"
version = "21.34.243-SECONDARY"
excluded-patches = """\
    'Custom branding name for YouTube' \
    'Custom branding icon for YouTube' \
    'Custom branding' \
    """
apkmirror-dlurl = "[https://www.apkmirror.com/apk/google-inc/youtube](https://www.apkmirror.com/apk/google-inc/youtube)"
uptodown-dlurl = "[https://youtube.en.uptodown.com/android](https://youtube.en.uptodown.com/android)"
github-dlurl = "[https://github.com/dj-tanjid/AppRepo/releases/tag/com.google.android.youtube](https://github.com/dj-tanjid/AppRepo/releases/tag/com.google.android.youtube)"
```

### 3. Setting an Explicit Package Name (`pkg-name`)
Bypasses web scraping for package identification, ensuring robust builds even when Cloudflare challenges occur:

```toml
[Threads-De-Vanced]
enabled = true
app-name = "Threads"
pkg-name = "com.instagram.barcelona"
patches-source = "github:RookieEnough/De-Vanced"
cli-source = "github:MorpheApp/morphe-desktop"
rv-brand = "De-Vanced"
arch = "arm64-v8a"
version = "latest"
build-mode = "apk"
patches-version = "dev"
github-dlurl = "[https://github.com/dj-tanjid/AppRepo/releases/tag/com.instagram.barcelona](https://github.com/dj-tanjid/AppRepo/releases/tag/com.instagram.barcelona)"
apkmirror-dlurl = "[https://www.apkmirror.com/apk/instagram/threads-an-instagram-app](https://www.apkmirror.com/apk/instagram/threads-an-instagram-app)"
uptodown-dlurl = "[https://threads.en.uptodown.com/android](https://threads.en.uptodown.com/android)"
```
