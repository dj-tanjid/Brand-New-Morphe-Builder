📱 » **Discord-Venus** (arm64-v8a): `350.8 - Stable`    
📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `584.0.0.51.56`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `584.0.0.51.56`    
📱 » **Gboard-Jason** (arm64-v8a): `18.5.3.993608717-release-arm64-v8a`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `452.1.0.53.64`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `452.1.0.53.64`    
📱 » **Proton-VPN-HXReborn** (all): `5.20.39.0`    
📱 » **Reddit-Morphe** (all): `2026.42.0`    
📱 » **Twitter-Piko-NewX** (all): `12.37.2-prod.01`    
📱 » **Waze-BearInMindCat-APK** (arm64-v8a): `5.24.5.0`    
📱 » **Waze-BearInMindCat-Root** (arm64-v8a): `5.24.5.0`    
📱 » **X-Piko-NewX** (all): `12.37.2-prod.01`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.42.52`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.43.523`    

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
  
> ⚙️ » Patches: `VenusIsJaded/patches-1.18.0.mpp` ([Changelog](https://github.com/VenusIsJaded/Venus-Patches/releases/tag/v1.18.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.18.0.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.18.0))
 ⚙️ » Patches: `jasonwu1994/patches-4.0.0-dev.3.mpp` ([Changelog](https://github.com/jasonwu1994/Gboard-patches/releases/tag/v4.0.0-dev.3))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.16.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.16))
 ⚙️ » Patches: `hxreborn/patches-1.60.0.mpp` ([Changelog](https://github.com/hxreborn/morphe-patches/releases/tag/v1.60.0))
 ⚙️ » Patches: `MorpheApp/patches-1.49.0-dev.5.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.49.0-dev.5))
 ⚙️ » Patches: `crimera/patches-3.64.0.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.64.0))
 ⚙️ » Patches: `bearinmindcat/patches-2.5.7.mpp` ([Changelog](https://github.com/bearinmindcat/morphe-patches/releases/tag/v2.5.7))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.19.0-all.jar`
  
