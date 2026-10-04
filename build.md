📱 » **Facebook-SysAdminDoc-APK** (arm64-v8a): `581.0.0.45.58`    
📱 » **Facebook-SysAdminDoc-Root** (arm64-v8a): `581.0.0.45.58`    
📱 » **Gboard-Jason** (arm64-v8a): `18.0.3.954559732-release-arm64-v8a`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `449.0.0.52.84`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `449.0.0.52.84`    
📱 » **Reddit-Morphe** (all): `2026.40.0`    
📱 » **Threads-SysAdminDoc** (arm64-v8a): `449.0.0.54.82`    
📱 » **Twitter-Piko-NewX** (all): `12.29.1-prod.01`    
📱 » **X-Piko-NewX** (all): `12.29.1-prod.01`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.39.52`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.39.522`    

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
  
> ⚙️ » Patches: `SysAdminDoc/patches-0.7.1.mpp` ([Changelog](https://github.com/SysAdminDoc/Hushfacebook/releases/tag/v0.7.1))
 ⚙️ » Patches: `jasonwu1994/patches-3.12.0.mpp` ([Changelog](https://github.com/jasonwu1994/Gboard-patches/releases/tag/v3.12.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.5.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.5))
 ⚙️ » Patches: `MorpheApp/patches-1.46.0-dev.2.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.46.0-dev.2))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.10.mpp` ([Changelog](https://github.com/SysAdminDoc/HushThreads/releases/tag/v0.0.10))
 ⚙️ » Patches: `crimera/patches-3.51.0.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.51.0))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.18.0-all.jar`
  
