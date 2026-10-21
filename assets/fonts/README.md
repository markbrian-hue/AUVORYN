# Local typography installation

The app's intended brand typography is Instrument Serif (display) and Manrope (UI). **No font files are distributed with this source package.**

1. Download the official, appropriately licensed font assets directly from https://fonts.google.com/specimen/Instrument+Serif and https://fonts.google.com/specimen/Manrope.
2. Place the approved font files in this directory on your development machine, and include the original license texts in your own app project.
3. Declare the *actual filenames* and available weights in `pubspec.yaml`, for example:

```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: InstrumentSerif
      fonts:
        - asset: assets/fonts/InstrumentSerif-Regular.ttf
          weight: 400
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-Regular.ttf
          weight: 400
        - asset: assets/fonts/Manrope-SemiBold.ttf
          weight: 600
```

4. Once the files are present, set `fontFamily: 'Manrope'` on the application's UI text theme and preserve font fallbacks for glyphs absent from the source files. The editorial style already requests `InstrumentSerif` and falls back until installed.

Do not add font asset declarations until those files exist, or Flutter asset bundling will fail. These paths are examples only: downloaded filenames may differ.
