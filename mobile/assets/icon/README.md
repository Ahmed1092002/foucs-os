# App Assets

## Required files:

### `icon.png` (1024x1024)
- App launcher icon
- Should be a square PNG, 1024x1024 pixels
- Used by `flutter_launcher_icons` to generate all required sizes

### `splash.png` (recommended: 2732x2732 or similar)
- Launch screen background image
- Used by `flutter_native_splash`
- Should work well on dark background (`#1E1E24` as configured)

## Generation

After adding the files, run:
```bash
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

## Design suggestions

For Focus OS (developer-focused learning app):
- Clean, minimal design
- Dark theme compatible
- Perhaps a focus/crosshair or brain/learning symbol
- Colors: Primary #5B8DEF (blue) on dark background #1E1E24