📱 » **Gboard-Jason** (arm64-v8a): `18.5.4.993608717-release-arm64-v8a`    
📱 » **Google-Photos-Akash** (arm64-v8a): `7.99.0.1007655401`    
📱 » **Instagram-SysAdminDoc-APK** (arm64-v8a): `456.0.0.53.78`    
📱 » **Instagram-SysAdminDoc-Root** (arm64-v8a): `456.0.0.53.78`    
📱 » **Proton-VPN-HXReborn** (all): `5.21.57.0`    
📱 » **Reddit-Morphe** (all): `2026.46.0`    
📱 » **TeraBox-HXReborn** (arm64-v8a): `4.28.5`    
📱 » **Turbo-VPN-D-moniak** (all): `4.3.2.2`    
📱 » **Twitter-Piko** (all): `12.43.0-prod.01`    
📱 » **X-Piko** (all): `12.43.0-prod.01`    
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
  
> ⚙️ » Patches: `jasonwu1994/patches-4.4.0-dev.3.mpp` ([Changelog](https://github.com/jasonwu1994/Gboard-patches/releases/tag/v4.4.0-dev.3))
 ⚙️ » Patches: `Akash-Sriram/patches-1.18.0.mpp` ([Changelog](https://github.com/Akash-Sriram/morphe-google-photos/releases/tag/v1.18.0))
 ⚙️ » Patches: `SysAdminDoc/patches-0.0.21.mpp` ([Changelog](https://github.com/SysAdminDoc/HushGram/releases/tag/v0.0.21))
 ⚙️ » Patches: `hxreborn/patches-1.83.0.mpp` ([Changelog](https://github.com/hxreborn/morphe-patches/releases/tag/v1.83.0))
 ⚙️ » Patches: `MorpheApp/patches-2.4.0-dev.5.mpp` ([Changelog](https://github.com/MorpheApp/morphe-patches/releases/tag/v2.4.0-dev.5))
 ⚙️ » Patches: `SatanMerde/patches-1.1.0.mpp` ([Changelog](https://github.com/SatanMerde/D-moniakPatches-dev/releases/tag/v1.1.0))
 ⚙️ » Patches: `crimera/patches-3.12.0-dev.4.mpp` ([Changelog](https://github.com/crimera/piko/releases/tag/v3.12.0-dev.4))
  
> ⚙️ » CLI: `MorpheApp/morphe-desktop-2.2.0-all.jar`
  
