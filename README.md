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
> **Security Notice:** Avoid downloading modified APKs or Magisk modules from untrusted third-party websites or Telegram channels. They may contain malicious code and impersonate official projects. Always build your own or download directly from trusted open-source repositories like this one.

---

## 🌟 Unique Features of this Fork

This builder is an advanced, hardened fork of [j-hc's revanced-magisk-module](https://github.com/j-hc/revanced-magisk-module) engineered by **TanJid Creations**, featuring extended scraping engines, anti-bot solvers, and multi-source patch support:

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
1. Download and install [ReVanced GmsCore](https://github.com/ReVanced/GmsCore/releases/latest) or [Morphe MicroG-RE](https://github.com/MorpheApp/MicroG-RE/releases/latest).
2. Download your preferred patched APK from the [Releases Page](../../releases/latest).
3. *(Optional)* Import custom clean settings via the in-app settings menu.

### 🔹 Root Users (Magisk / KernelSU / APatch)
1. Flash the generated `.zip` module from the [Releases Page](../../releases/latest) in Magisk, KernelSU, or APatch.
2. Reboot your device.
3. *(Optional)* Use [zygisk-detach](https://github.com/j-hc/zygisk-detach) to detach YouTube and YT Music from Google Play Store auto-updates.

---

## ⚙️ Custom Settings Import

If you prefer clean, uncluttered interfaces with optimal playback and layout defaults, you can import custom preset settings:

1. Open the application (**YouTube** or **YouTube Music**).
2. Navigate to: **Settings** &rarr; **Morphe / ReVanced Extended** &rarr; **Miscellaneous** &rarr; **Import/Export Settings**.
3. Import the preset from [custom_settings-by_tanjid](../teejay/custom_settings-by_tanjid).

---

## 🛠️ Build Your Own

1. Fork this repository or click **Use this template**.
2. Customize your build matrix in [`config.toml`](./config.toml) (see [`CONFIG.md`](./CONFIG.md) for documentation).
3. Go to **Actions** &rarr; **Build Modules** &rarr; **Run workflow**.
4. Download your custom binaries directly from your GitHub Releases tab!

---

## 🤝 Credits

Special thanks to the open-source developers who make this ecosystem possible:

* [j-hc](https://github.com/j-hc) — Original creator of the ReVanced Magisk Module builder.
* [Peter Noël Muller](https://github.com/peternmuller) & [Nguyễn Văn Bằng](https://github.com/nvbangg) — For foundational scripts and inspirations.
* [Morphe Team](https://github.com/MorpheApp) — Next-generation patcher and desktop CLI.
* [crimera](https://github.com/crimera) — Developer of the Piko patches for Twitter/X and Instagram.
* [Aaron Veil (anddea)](https://github.com/anddea) — ReVanced Extended ecosystem patches.
* [Sarthak Sinha (RookieEnough)](https://github.com/RookieEnough/) — De-Vanced patches.
* [ReVanced Team](https://github.com/ReVanced) — Original patcher framework and bytecode tooling.

---

<div align="center">

⭐ **Star this repository if you find it helpful!**  
Maintained with ❤️ by [TanJid Creations](https://github.com/dj-tanjid)

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
