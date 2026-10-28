📱 » **Facebook-Messenger-SysAdminDoc** (arm64-v8a): `584.1.0.61.98`    
📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `584.0.0.51.56`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `584.0.0.51.56`    
📱 » **Google-Maps-BearInMindCat-APK** (arm64-v8a): `26.36.04.973607363`    
📱 » **Google-Maps-BearInMindCat-Root** (arm64-v8a): `26.36.04.973607363`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `453.0.0.55.79`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `453.0.0.55.79`    
📱 » **Pixel-Camera-Basic-Akshayykadam** (all): `11.1.040.982810059.19`    
📱 » **Pixel-Camera-Pro-Akshayykadam** (all): `11.1.040.982810059.19`    
📱 » **Proton-VPN-HXReborn** (all): `5.20.39.0`    
📱 » **Reddit-Morphe** (all): `2026.43.0`    
📱 » **Twitter-Piko-NewX** (all): `12.37.2-prod.01`    
📱 » **Waze-BearInMindCat-APK** (arm64-v8a): `5.24.5.0`    
📱 » **Waze-BearInMindCat-Root** (arm64-v8a): `5.24.5.0`    
📱 » **X-Piko-NewX** (all): `12.37.2-prod.01`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.43.51`    
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
  
> ⚙️ » Patches: `SysAdminDoc/patches-0.27.0.mpp` ([Changelog](https://github.com/SysAdminDoc/HushMessenger/releases/tag/v0.27.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.19.0.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.19.0))
 ⚙️ » Patches: `bearinmindcat/patches-2.7.4.mpp` ([Changelog](https://github.com/bearinmindcat/morphe-patches/releases/tag/v2.7.4))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.17.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.17))
 ⚙️ » Patches: `Akshayykadam/morphe-patches-pixelcamera-1.0.7.mpp` ([Changelog](https://github.com/Akshayykadam/Pixel-Camera/releases/tag/1.0.7))
 ⚙️ » Patches: `hxreborn/patches-1.65.0.mpp` ([Changelog](https://github.com/hxreborn/morphe-patches/releases/tag/v1.65.0))
 ⚙️ » Patches: `MorpheApp/patches-1.49.0-dev.10.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.49.0-dev.10))
 ⚙️ » Patches: `crimera/patches-3.66.0.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.66.0))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.19.1-all.jar`
  
