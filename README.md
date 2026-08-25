<div align="center">

# ⚡ Morphe x De-Vanced Builder

<p align="center">
  <b>Automated, high-performance CI/CD pipeline for building root Magisk/KernelSU modules and non-root APKs.</b><br>
  Powered by <a href="https://github.com/MorpheApp">Morphe</a>, <a href="https://github.com/RookieEnough/De-Vanced">De-Vanced</a>, <a href="https://github.com/crimera/piko">Piko</a>, and <a href="https://github.com/anddea/revanced-patches">ReVanced Extended</a>.
</p>

[![GitHub License](https://img.shields.io/github/license/dj-tanjid/Morphe-DeVanced-Builder?logo=github&label=License&color=blue)](https://github.com/dj-tanjid/Morphe-DeVanced-Builder/blob/main/LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/dj-tanjid/Morphe-DeVanced-Builder?label=Latest%20Release&logo=android&color=success)](../../releases/latest)
[![GitHub Downloads](https://img.shields.io/github/downloads/dj-tanjid/Morphe-DeVanced-Builder/total?logo=github&label=Downloads&color=orange)](https://github.com/dj-tanjid/Morphe-DeVanced-Builder/releases)
[![Build Workflow](https://img.shields.io/github/actions/workflow/status/dj-tanjid/Morphe-DeVanced-Builder/build.yml?label=Build%20Status&logo=githubactions&logoColor=white)](../../actions/workflows/build.yml)

</div>

> [!CAUTION]
> **Security Notice:** Avoid downloading modified APKs or Magisk modules from untrusted third-party websites or Telegram channels. They may contain malicious code and impersonate official projects. Always build your own or download directly from trusted open-source repositories like this one[span_2](start_span)[span_2](end_span).

---

## 🌟 Unique Features of this Fork

This builder is an advanced, hardened fork of [j-hc's revanced-magisk-module](https://github.com/j-hc/revanced-magisk-module) engineered by **TanJid Creations**, featuring extended scraping engines and multi-source patch support[span_3](start_span)[span_3](end_span):

* **Dual-Host Toolchain Fetching (`github:` & `gitlab:`)**: Fetch patch bundles and CLI binaries across both **GitHub Releases** and **GitLab API** endpoints with unified prefix formatting.
* **Multi-Bundle Patch Support**: Combine multiple independent patch repositories (e.g., `crimera/piko` + `inotia00/x-shim`) in a single compilation run for an app target.
* **5-Tier Resilient Download Engine**: Automatically resolves APKs using an intelligent fallback pipeline:
  $$\text{APKMirror} \longrightarrow \text{Uptodown} \longrightarrow \text{GitHub Releases} \longrightarrow \text{Direct DL} \longrightarrow \text{Archive.org}$$
* **Explicit Package ID Overrides (`pkg-name`)**: Eliminates scraping dependencies and guarantees continuous builds even during anti-bot protection updates.
* **Multi-Architecture Matrix Compilation (`arch = "both"`)**: Concurrently packages architecture-tailored APKs and universal root modules (`arm64-v8a`, `armeabi-v7a`, `x86_64`) with automated odex optimization.

---

## 📱 Supported Applications

<table>
  <tr>
    <th>Application</th>
    <th>Patches Source</th>
    <th>Variants Built</th>
  </tr>
  <tr>
    <td><b>YouTube</b></td>
    <td>Morphe / Anddea</td>
    <td>Non-Root APK + Magisk/KSU Module</td>
  </tr>
  <tr>
    <td><b>YouTube Music</b></td>
    <td>Morphe / Anddea</td>
    <td>Non-Root APK + Magisk/KSU Module</td>
  </tr>
  <tr>
    <td><b>Google Photos</b></td>
    <td>De-Vanced / Rushi</td>
    <td>Non-Root APK + Magisk/KSU Module</td>
  </tr>
  <tr>
    <td><b>Reddit</b></td>
    <td>Morphe</td>
    <td>Non-Root APK + Magisk/KSU Module</td>
  </tr>
  <tr>
    <td><b>Twitter / X</b></td>
    <td>Piko / Morphe</td>
    <td>Non-Root APK</td>
  </tr>
  <tr>
    <td><b>Instagram</b></td>
    <td>Piko</td>
    <td>Non-Root APK</td>
  </tr>
  <tr>
    <td><b>Facebook & Messenger</b></td>
    <td>De-Vanced / Rushi</td>
    <td>Non-Root APK</td>
  </tr>
  <tr>
    <td><b>Threads</b></td>
    <td>De-Vanced</td>
    <td>Non-Root APK</td>
  </tr>
</table>

---

## 🚀 Installation Guide

### 🔹 Non-Root Users
1. Download and install [ReVanced GmsCore](https://github.com/ReVanced/GmsCore/releases/latest) or [Morphe MicroG-RE](https://github.com/MorpheApp/MicroG-RE/releases/latest)[span_4](start_span)[span_4](end_span).
2. Download your preferred patched APK from the [Releases Page](../../releases/latest)[span_5](start_span)[span_5](end_span).
3. *(Optional)* Import custom clean settings via the in-app settings menu[span_6](start_span)[span_6](end_span).

### 🔹 Root Users (Magisk / KernelSU / APatch)
1. Flash the generated `.zip` module from the [Releases Page](../../releases/latest)[span_7](start_span)[span_7](end_span).
2. Reboot your device.
3. *(Optional)* Use [zygisk-detach](https://github.com/j-hc/zygisk-detach) to detach YouTube and YT Music from Google Play Store auto-updates[span_8](start_span)[span_8](end_span).

---

## ⚙️ Custom Settings Import

If you prefer clean, uncluttered interfaces with optimal playback and layout defaults, you can import custom preset settings[span_9](start_span)[span_9](end_span):

1. Open the application (**YouTube** or **YouTube Music**)[span_10](start_span)[span_10](end_span).
2. Navigate to: **Settings** &rarr; **Morphe / ReVanced Extended** &rarr; **Miscellaneous** &rarr; **Import/Export Settings**[span_11](start_span)[span_11](end_span).
3. Import the preset from [custom_settings-by_tanjid](../teejay/custom_settings-by_tanjid)[span_12](start_span)[span_12](end_span).

---

## 🛠️ Build Your Own

1. Fork this repository or click **Use this template**[span_13](start_span)[span_13](end_span).
2. Customize your build matrix in [`config.toml`](./config.toml)[span_14](start_span)[span_14](end_span).
   *(For a detailed breakdown of all configuration options, please refer to the [**Configuration Guide (`CONFIG.md`)**](./CONFIG.md))[span_15](start_span)[span_15](end_span).*
3. Go to **Actions** &rarr; **Build Modules** &rarr; **Run workflow**[span_16](start_span)[span_16](end_span).
4. Download your custom binaries directly from your GitHub Releases tab[span_17](start_span)[span_17](end_span)!

---

## 🔧 Troubleshooting & Magisk Mount Issues

If you are experiencing issues with the classic Magisk/KernelSU mount method for your modules, such as[span_18](start_span)[span_18](end_span):

* ❌ **"Reflash needed"** errors appearing after device reboots[span_19](start_span)[span_19](end_span).
* ⚠️ **"Suspicious mount detected"** warnings triggered by root-detector or banking apps[span_20](start_span)[span_20](end_span).

**💡 Solution:** You can consider using the [**rvmm-zygisk-mount**](https://github.com/j-hc/rvmm-zygisk-mount) module alongside your installations to bypass these classic mounting issues[span_21](start_span)[span_21](end_span).

---

## 🤝 Credits

Special thanks to the open-source developers who make this ecosystem possible[span_22](start_span)[span_22](end_span):

* [j-hc](https://github.com/j-hc) — Original creator of the ReVanced Magisk Module builder[span_23](start_span)[span_23](end_span).
* [Peter Noël Muller](https://github.com/peternmuller) & [Nguyễn Văn Bằng](https://github.com/nvbangg) — For foundational scripts and inspirations[span_24](start_span)[span_24](end_span).
* [Morphe Team](https://github.com/MorpheApp) — Next-generation patcher and desktop CLI[span_25](start_span)[span_25](end_span).
* [crimera](https://github.com/crimera) — Developer of the Piko patches for Twitter/X and Instagram.
* [Aaron Veil (anddea)](https://github.com/anddea) — ReVanced Extended ecosystem patches[span_26](start_span)[span_26](end_span).
* [Sarthak Sinha (RookieEnough)](https://github.com/RookieEnough/) — De-Vanced patches[span_27](start_span)[span_27](end_span).
* [ReVanced Team](https://github.com/ReVanced) — Original patcher framework and bytecode tooling[span_28](start_span)[span_28](end_span).

---

<div align="center">

⭐ **Star this repository if you find it helpful!**  
Maintained with ❤️ by [TanJid Creations](https://github.com/dj-tanjid)[span_29](start_span)[span_29](end_span)

</div>

---

## 📄 License

```text
Copyright (C) 2024-2026 Tanjidul Hossain (TanJid Creations)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
