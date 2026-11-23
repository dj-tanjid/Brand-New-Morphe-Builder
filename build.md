📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `588.0.0.42.55`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `588.0.0.42.55`    
📱 » **Gboard-Jason** (arm64-v8a): `18.5.4.993608717-release-arm64-v8a`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `456.0.0.53.78`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `456.0.0.53.78`    
📱 » **Reddit-Morphe** (all): `2026.47.0`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.46.51`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.46.522`    

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
  
> ⚙️ » Patches: `SysAdminDoc/patches-0.24.0.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.24.0))
 ⚙️ » Patches: `jasonwu1994/patches-4.5.0-dev.2.mpp` ([Changelog](https://github.com/jasonwu1994/Gboard-patches/releases/tag/v4.5.0-dev.2))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.22.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.22))
 ⚙️ » Patches: `MorpheApp/patches-2.4.0-dev.9.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v2.4.0-dev.9))
 ⚙️ » Patches: `hxreborn/patches-1.86.0.mpp` ([Changelog](https://github.com/hxreborn/morphe-patches/releases/tag/v1.86.0))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-2.3.0-all.jar`
  
