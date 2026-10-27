📱 » **Discord-Venus** (arm64-v8a): `350.8 - Stable`    
📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `584.0.0.51.56`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `584.0.0.51.56`    
📱 » **Gboard-Jason** (arm64-v8a): `18.5.4.993608717-release-arm64-v8a`    
📱 » **Google-Maps-BearInMindCat-APK** (arm64-v8a): `26.36.04.973607363`    
📱 » **Google-Maps-BearInMindCat-Root** (arm64-v8a): `26.36.04.973607363`    
📱 » **Pixel-Camera-Basic-Akshayykadam** (all): `11.1.040.982810059.19`    
📱 » **Pixel-Camera-Pro-Akshayykadam** (all): `11.1.040.982810059.19`    
📱 » **Proton-VPN-HXReborn** (all): `5.20.39.0`    
📱 » **Reddit-Morphe** (all): `2026.43.0`    
📱 » **Waze-BearInMindCat-APK** (arm64-v8a): `5.24.5.0`    
📱 » **Waze-BearInMindCat-Root** (arm64-v8a): `5.24.5.0`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.42.52`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.43.523-SECONDARY`    

<br>
  

**⚠️ Disclaimer:**  
- Recent YouTube versions above **21.34.\*\*\*** ship a new fullscreen behavior that can randomly trigger. If your device's **Smallest Width (DPI)** is set higher than **499**, swiping up or tapping the on-screen fullscreen button may fail to switch to landscape fullscreen and instead stay stuck in vertical/portrait fullscreen.  
- **Fix:** Open YouTube → **Settings** → **Morphe** → **Debugging** → **Feature flags** → search for flag **`45831136`** → toggle it to **Disabled** (force to `false`/blocked) → save and restart the app.  
- You can also import my [**Custom Feature Flags**](../teejay/custom_settings-by_tanjid/YouTube_Feature_Flags_2026-09-01.txt) file directly instead of toggling it manually.  

<br>
  

**Note:**  
- Install and login via [ReVanced GmsCore](https://github.com/ReVanced/GmsCore/releases/latest) or [Morphe MicroG-RE](https://github.com/MorpheApp/MicroG-RE/releases/latest) or for non-root APKs.  
- (Optional) Use [zygisk-detach](https://github.com/j-hc/zygisk-detach) to detach YouTube and YT Music modules from Google Play Store or even better use [**HMA-OSS**](https://github.com/frknkrc44/HMA-OSS/releases).  
- (Optional) Import my [**Custom Settings**](../teejay/custom_settings-by_tanjid) into your application. [*How to do this?*](../teejay/?tab=readme-ov-file#import-custom-settings-in-revancedmorphe-applications).  

<br>
  
Patches and CLI Sources :
  
> ⚙️ » Patches: `VenusIsJaded/patches-1.19.0.mpp` ([Changelog](https://github.com/VenusIsJaded/Venus-Patches/releases/tag/v1.19.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.18.1.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.18.1))
 ⚙️ » Patches: `jasonwu1994/patches-4.0.0.mpp` ([Changelog](https://github.com/jasonwu1994/Gboard-patches/releases/tag/v4.0.0))
 ⚙️ » Patches: `bearinmindcat/patches-2.7.1.mpp` ([Changelog](https://github.com/bearinmindcat/morphe-patches/releases/tag/v2.7.1))
 ⚙️ » Patches: `Akshayykadam/morphe-patches-pixelcamera-1.0.6.mpp` ([Changelog](https://github.com/Akshayykadam/Pixel-Camera/releases/tag/1.0.6))
 ⚙️ » Patches: `hxreborn/patches-1.64.0.mpp` ([Changelog](https://github.com/hxreborn/morphe-patches/releases/tag/v1.64.0))
 ⚙️ » Patches: `MorpheApp/patches-1.49.0-dev.8.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.49.0-dev.8))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.19.1-all.jar`
  
