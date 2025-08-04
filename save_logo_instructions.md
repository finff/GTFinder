# GTFinder Logo Setup Instructions

## Step-by-Step Guide to Set Your Logo as App Icon

### Method 2: Using Flutter Package (Automated) - RECOMMENDED

#### Step 1: Save Your Logo Image
1. Right-click on the GTFinder logo image you shared in the chat
2. Select "Save image as..." 
3. Save it as `gtfinder_logo.png` in the `assets/images/` folder of your project
4. Make sure the file path is: `assets/images/gtfinder_logo.png`

#### Step 2: Install Dependencies and Generate Icons
Run these commands in your terminal:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

#### Step 3: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Alternative Method 1: Manual Replacement

If the automated method doesn't work, you can manually replace the icons:

#### For Android:
Replace these files with your logo (resized to the specified dimensions):
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

#### For iOS:
Replace all files in: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Tools to Resize Images:
- **Online**: AppIcon.co, MakeAppIcon.com
- **Software**: GIMP, Photoshop, or any image editor
- **Mobile Apps**: Icon resizer apps

### Important Notes:
- Logo should be square (1:1 aspect ratio)
- Recommended size: 1024x1024 pixels for best quality
- Use PNG format with transparent background if needed
- Test on both Android and iOS devices after changes

### Troubleshooting:
- If icons don't update, try `flutter clean` and rebuild
- Clear app data/reinstall the app on test devices
- Check that the image path in pubspec.yaml is correct 