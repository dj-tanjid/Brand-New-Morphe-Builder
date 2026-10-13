📱 » **Facebook-Messenger-SysAdminDoc** (arm64-v8a): `582.0.0.61.92`    
📱 » **Gboard-Jason** (arm64-v8a): `18.0.3.954559732-release-arm64-v8a`    
📱 » **Reddit-Morphe** (all): `2026.41.0`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.41.52`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.41.525-SECONDARY`    

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
  
> ⚙️ » Patches: `SysAdminDoc/patches-0.23.0.mpp` ([Changelog](https://github.com/SysAdminDoc/HushMessenger/releases/tag/v0.23.0))
 ⚙️ » Patches: `jasonwu1994/patches-3.12.0.mpp` ([Changelog](https://github.com/jasonwu1994/Gboard-patches/releases/tag/v3.12.0))
 ⚙️ » Patches: `MorpheApp/patches-1.48.0-dev.6.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.48.0-dev.6))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.18.1-all.jar`
  
