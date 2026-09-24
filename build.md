📱 » **Facebook-Andrew** (arm64-v8a): `577.0.0.50.72`    
📱 » **Google-Camera-Akshayykadam** (all): `11.0.073.972752740.32`    
📱 » **Reddit-Morphe** (all): `2026.38.0`    
📱 » **Twitter-Piko-NewX** (all): `12.28.0-prod.01`    
📱 » **X-Piko-NewX** (all): `12.28.0-prod.01`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.38.51`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.38.123`    

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
  
> ⚙️ » Patches: `andrewliang25/patches-3.2.0.mpp` ([Changelog](https://github.com/andrewliang25/morphe-patches/releases/tag/v3.2.0))
 ⚙️ » Patches: `Akshayykadam/morphe-patches-pixelcamera-1.0.3.mpp` ([Changelog](https://github.com/Akshayykadam/Pixel-Camera/releases/tag/1.0.3))
 ⚙️ » Patches: `MorpheApp/patches-1.45.0-dev.12.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.45.0-dev.12))
 ⚙️ » Patches: `crimera/patches-3.37.1.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.37.1))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.17.0-all.jar`
  
