# Screenshots Guide for Medicinder

This guide helps you take and organize screenshots for the README.md file.

## Required Screenshots

Based on the README structure, you need the following screenshots:

### 1. `home_screen.png` - Main Interface
**What to capture:**
- Home page showing medication list
- At least 2-3 medications visible
- Show dose tracking (taken/not taken status)
- Include the app bar with settings icon

**Recommended devices:**
- Android phone (portrait)
- iPhone (portrait)
- Desktop/tablet (landscape)

### 2. `add_medication.png` - Add Medication Form
**What to capture:**
- Add medication form/screen
- Show form fields (name, usage, dosage, timing options)
- Include meal time selector if visible
- Show the save button

**Recommended devices:**
- Android phone (portrait)
- iPhone (portrait)

### 3. `settings.png` - Settings & Localization
**What to capture:**
- Settings page
- Language selection (English/Arabic)
- Meal time configuration
- Any other settings options

**Recommended devices:**
- Android phone (portrait)
- iPhone (portrait)

### 4. `notifications.png` - Notification System
**What to capture:**
- Active notification with action buttons
- Show "Done" and "Remind Me Later" buttons
- Medication name and dosage in notification

**Recommended devices:**
- Android phone (notification panel)
- iPhone (notification center)

## How to Take Screenshots

### Android
1. **App Screenshots:**
   - Press `Power + Volume Down` buttons simultaneously
   - Or use Android Studio's screenshot tool

2. **Notification Screenshots:**
   - Pull down notification panel
   - Take screenshot of the notification

### iOS
1. **App Screenshots:**
   - Press `Power + Volume Up` buttons simultaneously
   - Or use Xcode's simulator screenshot tool

2. **Notification Screenshots:**
   - Pull down notification center
   - Take screenshot of the notification

### Desktop (Windows/macOS/Linux)
1. **Flutter Web/Desktop:**
   - Use `flutter run -d chrome` for web
   - Use `flutter run -d windows/macos/linux` for desktop
   - Take screenshots using OS tools

## Screenshot Guidelines

### Image Quality
- **Resolution:** Minimum 1080p (1920x1080) for mobile
- **Format:** PNG or JPG
- **Size:** Keep under 1MB per image for GitHub
- **Aspect Ratio:** Use device-appropriate ratios

### Content Guidelines
- **Clean UI:** Remove any personal data
- **Good Lighting:** Ensure text is readable
- **Consistent Style:** Use same device/theme for all screenshots
- **Show Features:** Highlight key app features

### File Naming
Use the exact filenames specified in the README:
- `home_screen.png`
- `add_medication.png`
- `settings.png`
- `notifications.png`

## Organizing Screenshots

### Directory Structure
```
assets/
└── screenshots/
    ├── home_screen.png
    ├── add_medication.png
    ├── settings.png
    └── notifications.png
```

### Optional: Multiple Device Screenshots
If you want to show the app on different devices, you can create subdirectories:

```
assets/
└── screenshots/
    ├── android/
    │   ├── home_screen.png
    │   └── add_medication.png
    ├── ios/
    │   ├── home_screen.png
    │   └── add_medication.png
    └── desktop/
        └── home_screen.png
```

Then update the README paths accordingly.

## Alternative: Using GitHub Issues for Screenshots

If you want to use GitHub's built-in image hosting:

1. **Create a GitHub Issue**
2. **Drag and drop your screenshots** into the issue
3. **Copy the generated URLs** (they look like `https://user-images.githubusercontent.com/...`)
4. **Use these URLs in your README** instead of local paths

Example:
```markdown
![Home Screen](https://user-images.githubusercontent.com/your-username/your-repo/main/assets/screenshots/home_screen.png)
```

## Updating the README

After adding your screenshots:

1. **Replace the placeholder text** in README.md
2. **Update image paths** if using different filenames
3. **Add descriptive captions** for each screenshot
4. **Test the links** to ensure images load correctly

## Tips for Better Screenshots

1. **Use Real Data:** Add some sample medications to make screenshots more realistic
2. **Show Different States:** Include screenshots showing both empty and populated states
3. **Highlight Features:** Use arrows or annotations to point out key features
4. **Consistent Theme:** Use the same theme (light/dark) across all screenshots
5. **Multiple Languages:** Consider showing both English and Arabic versions

## Troubleshooting

### Images Not Showing
- Check file paths are correct
- Ensure images are committed to git
- Verify file extensions match exactly

### Large File Sizes
- Compress images using tools like TinyPNG
- Use appropriate image formats (PNG for screenshots, JPG for photos)
- Consider using GitHub's image hosting for large files

### Git Issues
- Add screenshots to `.gitignore` if they're too large
- Use Git LFS for large image files
- Commit screenshots separately from code changes 