📱 » **Facebook-Messenger-SysAdminDoc** (arm64-v8a): `585.0.0.53.94`    
📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `585.0.0.47.54`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `585.0.0.47.54`    
📱 » **Gboard-Jason** (arm64-v8a): `18.5.4.993608717-release-arm64-v8a`    
📱 » **Google-Maps-BearInMindCat-APK** (arm64-v8a): `26.36.04.973607363`    
📱 » **Google-Maps-BearInMindCat-Root** (arm64-v8a): `26.36.04.973607363`    
📱 » **Google-Photos-Akash** (arm64-v8a): `7.99.0.1007655401`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `453.0.0.57.79`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `453.0.0.57.79`    
📱 » **Reddit-Morphe** (all): `2026.44.0`    
📱 » **TeraBox-HXReborn** (arm64-v8a): `4.27.5`    
📱 » **Twitter-Piko-NewX** (all): `12.39.0-prod.01`    
📱 » **Waze-BearInMindCat-APK** (arm64-v8a): `5.24.5.0`    
📱 » **Waze-BearInMindCat-Root** (arm64-v8a): `5.24.5.0`    
📱 » **X-Piko-NewX** (all): `12.39.0-prod.01`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.43.51`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.44.528`    

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
  
> ⚙️ » Patches: `SysAdminDoc/patches-0.28.0.mpp` ([Changelog](https://github.com/SysAdminDoc/HushMessenger/releases/tag/v0.28.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.20.0.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.20.0))
 ⚙️ » Patches: `jasonwu1994/patches-4.2.0-dev.2.mpp` ([Changelog](https://github.com/jasonwu1994/Gboard-patches/releases/tag/v4.2.0-dev.2))
 ⚙️ » Patches: `bearinmindcat/patches-2.8.3.mpp` ([Changelog](https://github.com/bearinmindcat/morphe-patches/releases/tag/v2.8.3))
 ⚙️ » Patches: `Akash-Sriram/patches-1.17.6.mpp` ([Changelog](https://github.com/Akash-Sriram/morphe-google-photos/releases/tag/v1.17.6))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.18.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.18))
 ⚙️ » Patches: `MorpheApp/patches-2.1.0-dev.5.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v2.1.0-dev.5))
 ⚙️ » Patches: `hxreborn/patches-1.68.0.mpp` ([Changelog](https://github.com/hxreborn/morphe-patches/releases/tag/v1.68.0))
 ⚙️ » Patches: `crimera/patches-3.73.0.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.73.0))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.20.0-all.jar`
  
