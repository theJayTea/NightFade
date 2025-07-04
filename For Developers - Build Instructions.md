# Build Instructions

## Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later
- Swift 5.5 or later

## Building from source

### 1. Clone the repository
```bash
git clone https://github.com/theJayTea/NightFade.git
cd NightFade
```

### 2. Open the project in Xcode
```bash
open "Night Fade.xcodeproj"
```

### 3. Build and run
- Select your target device (Mac)
- Press `Cmd + R` to build and run

## Creating a release build

### 1. Archive the app
- In Xcode, select **Product** → **Archive**
- Wait for the archive process to complete

### 2. Export the app
- Once archived, select **Distribute App**
- Choose **Copy App**
- Select a destination folder for the exported app

### 3. Create a DMG for distribution
- Use the provided `create_dmg.sh` script in the repository:
  ```bash
  ./create_dmg.sh
  ```
- This will create a distributable DMG file with the app and the `Please Read This.rtf` open-unnotarized app documentation

## Troubleshooting

### Code signing issues
- For local development, automatic signing should work
- Make sure your development team is selected in the project settings

### Build errors
- Clean the build folder: `Cmd + Shift + K`
- Delete derived data: `~/Library/Developer/Xcode/DerivedData`
- Restart Xcode if issues persist

### Testing on other Macs
- The exported app will show Gatekeeper warnings on other machines
- Follow the instructions in the `Please Read This.rtf` file included in the DMG
