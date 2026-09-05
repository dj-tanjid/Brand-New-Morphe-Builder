📱 » **Instagram-Piko** (arm64-v8a): `439.0.0.37.89`    
📱 » **Reddit-Morphe** (all): `2026.35.0`    
📱 » **Twitter-Piko** (all): `12.19.1-release.0`    
📱 » **X-Piko** (all): `12.19.1-release.0`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.35.54`    
📱 » **YouTube-Morphe** (arm64-v8a): `21.35.442-SECONDARY`    
📱 » **Twitter-Piko-NewX** (all): `12.23.1-prod.01`    
📱 » **X-Piko-NewX** (all): `12.23.1-prod.01`    

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
  
> ⚙️ » Patches: `crimera/patches-3.10.1.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.10.1))
 ⚙️ » Patches: `MorpheApp/patches-1.42.0-dev.3.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.42.0-dev.3))
 ⚙️ » Patches: `crimera/patches-3.10.1.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.10.1))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.15.0-all.jar`
  
