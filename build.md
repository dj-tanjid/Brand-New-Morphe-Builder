📱 » **Facebook-Messenger-SysAdminDoc** (arm64-v8a): `581.0.0.49.91`    
📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `581.0.0.45.58`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `581.0.0.45.58`    
📱 » **Google-Camera-Pro-Akshayykadam** (all): `11.0.073.972752740.32`    
📱 » **Google-Camera-nonPro-Akshayykadam** (all): `11.0.073.972752740.32`    
📱 » **Instagram-Piko** (arm64-v8a): `447.0.0.55.81`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `450.0.0.50.77`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `450.0.0.50.77`    
📱 » **Reddit-Morphe** (all): `2026.40.0`    
📱 » **Threads-SysAdminDoc** (arm64-v8a): `450.0.0.51.78`    
📱 » **Twitter-Piko** (all): `12.19.1-release.0`    
📱 » **Twitter-Piko-NewX** (all): `12.30.0-prod.01`    
📱 » **X-Piko** (all): `12.19.1-release.0`    
📱 » **X-Piko-NewX** (all): `12.30.0-prod.01`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.40.51`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.40.161`    

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
  
> ⚙️ » Patches: `SysAdminDoc/patches-0.22.0.mpp` ([Changelog](https://github.com/SysAdminDoc/HushMessenger/releases/tag/v0.22.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.8.0.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.8.0))
 ⚙️ » Patches: `Akshayykadam/morphe-patches-pixelcamera-1.0.4.mpp` ([Changelog](https://github.com/Akshayykadam/Pixel-Camera/releases/tag/1.0.4))
 ⚙️ » Patches: `crimera/patches-3.10.0-dev.13.mpp` ([Changelog](https://github.com/crimera/piko/releases/tag/v3.10.0-dev.13))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.7.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.7))
 ⚙️ » Patches: `MorpheApp/patches-1.47.0-dev.12.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.47.0-dev.12))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.12.mpp` ([Changelog](https://github.com/SysAdminDoc/HushThreads/releases/tag/v0.0.12))
 ⚙️ » Patches: `crimera/patches-3.54.0.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.54.0))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.18.1-all.jar`
  
