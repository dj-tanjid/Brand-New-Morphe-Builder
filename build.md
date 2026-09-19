📱 » **Facebook-Andrew** (arm64-v8a): `577.0.0.50.72`    
📱 » **Google-Photos-Akash** (arm64-v8a): `7.93.0.982110057`    
📱 » **Reddit-Morphe** (all): `2026.38.0`    
📱 » **Twitter-Piko-NewX** (all): `12.27.0-prod.01`    
📱 » **X-Piko-NewX** (all): `12.27.0-prod.01`    
📱 » **YT-Music-Morphe** (arm64-v8a): `9.36.50`    
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
  
> ⚙️ » Patches: `andrewliang25/patches-3.1.0.mpp` ([Changelog](https://github.com/andrewliang25/morphe-patches/releases/tag/v3.1.0))
 ⚙️ » Patches: `Akash-Sriram/patches-1.4.1.mpp` ([Changelog](https://github.com/Akash-Sriram/De-Vanced/releases/tag/v1.4.1))
 ⚙️ » Patches: `MorpheApp/patches-1.44.0-dev.9.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v1.44.0-dev.9))
 ⚙️ » Patches: `crimera/patches-3.29.0.mpp` ([Changelog](https://github.com/crimera/piko-newx/releases/tag/v3.29.0))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-1.16.0-all.jar`
  
