📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `582.0.0.50.54`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `582.0.0.50.54`    
📱 » **Google-Camera-Pro-Akshayykadam** (all): `11.1.040.982810059.19`    
📱 » **Google-Camera-nonPro-Akshayykadam** (all): `11.1.040.982810059.19`    
📱 » **Google-Photos-Akash** (arm64-v8a): `7.96.0.996044120`    
📱 » **Instagram-Piko** (arm64-v8a): `447.0.0.55.81`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `450.0.0.50.77`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `450.0.0.50.77`    
📱 » **Reddit-Morphe** (all): `2026.41.0`    
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
  
> ⚙️ » Patches: `SysAdminDoc/patches-0.9.0.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.9.0))
 ⚙️ » Patches: `Akshayykadam/morphe-patches-pixelcamera-1.0.5.mpp` ([Changelog](https://github.com/Akshayykadam/Pixel-Camera/releases/tag/1.0.5))
 ⚙️ » Patches: `Akash-Sriram/patches-1.14.3.mpp` ([Changelog](https://github.com/Akash-Sriram/morphe-google-photos/releases/tag/v1.14.3))
 ⚙️ » Patches: `crimera/patches-3.10.0.mpp` ([Changelog](https://github.com/crimera/piko/releases/tag/v3.10.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.8.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.8))
 ⚙️ » Patches: `MorpheApp/patches-1.47.0-dev.20.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.47.0-dev.20))
 ⚙️ » Patches: `crimera/patches-3.54.2.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.54.2))
 ⚙️ » Patches: `MorpheApp/patches-1.47.0-dev.21.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.47.0-dev.21))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.18.1-all.jar`
  
