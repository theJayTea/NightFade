# NightFade Project Structure

## 📱 Overview

NightFade is a native macOS application that provides a beautiful GUI for scheduling Night Shift intensity changes throughout the day. Unlike other solutions, it leverages macOS's built-in launchd scheduler, meaning the app doesn't need to run in the background - schedules persist even after the app is closed or deleted.

## 🏗️ Architecture

### Design Philosophy
- **Single Source of Truth**: launchd plists are the authoritative data source
- **No Background Process**: Uses system scheduling instead of running continuously
- **Native Integration**: Leverages macOS APIs and system services
- **Glassmorphic UI**: Modern macOS aesthetic with blur effects

### Technology Stack
- **Language**: Swift 5
- **UI Framework**: SwiftUI
- **Minimum Target**: macOS 13.0 (Ventura)
- **Scheduling**: launchd (system-level)
- **Night Shift Control**: Bundled `nightlight` CLI binary

## 📁 Project Structure

```
NightFade/
├── NightFade.xcodeproj/          # Xcode project configuration
├── NightFade/                    # Main application code
   ├── NightFadeApp.swift        # App entry point
   ├── ContentView.swift         # Main UI and view composition
   ├── TimePickerView.swift      # Custom time picker component
   ├── Schedule.swift            # Data model for schedules
   ├── ScheduleManager.swift     # Core business logic
   ├── nightlight                # Bundled CLI binary (executable), compiled for arm64 from `https://github.com/smudge/nightlight`
   ├── Assets.xcassets/          # App icons and colors
   ├── Preview Content/          # SwiftUI preview assets
   └── NightFade.entitlements    # App entitlements (currently empty)
```

## 🔍 Component Details

### NightFadeApp.swift
**Purpose**: Application entry point and lifecycle management

```swift
@main
struct NightFadeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // ...
}
```

**Key Features**:
- Configures window to hide title bar for cleaner appearance
- Implements `AppDelegate` to quit app when window closes
- Sets up the main WindowGroup with ContentView

### ContentView.swift
**Purpose**: Main application UI and user interaction

**Structure**:
- **Header Section**: App title with refresh button
- **Schedule List**: Shows active schedules with visual warmth indicators
- **Empty State**: Friendly message when no schedules exist, with clickable "Remember to Sleep" preset option
- **Debug Tools**: Bottom section for testing intensity changes

**Key Features**:
- Glassmorphic background using custom `VisualEffectView`
- Auto-refresh when app becomes active
- Sheet presentation for adding new schedules
- Locked width resizing using WindowResizability: fixed width (480px), resizable height (min 500px)
- Orange theme for consistent branding

**State Management**:
- `@StateObject private var scheduleManager`: Main data source
- `@State private var showingAddSchedule`: Controls sheet presentation

### Schedule.swift
**Purpose**: Data model representing a Night Shift schedule

**Properties**:
```swift
struct Schedule: Identifiable, Codable {
    let id: UUID
    let hour: Int        // 24-hour format (0-23)
    let minute: Int      // 0-59
    let intensity: Int   // 0-100 percentage
}
```

**Computed Properties**:
- `timeString`: Localized time display (12/24 hour based on system)
- `warmthColor`: Visual representation of intensity
- `plistIdentifier`: Unique ID for launchd plist naming

**Color Algorithm**:
- 0%: Cool white with slight blue tint (rgb: 0.95, 0.95, 1.0)
- 50%: Neutral white (rgb: 1.0, 0.92, 0.85)
- 100%: Warm orange (rgb: 1.0, 0.75, 0.55) - realistic Night Shift color
- Semi-transparent display (50% opacity) with black outline for visibility

### ScheduleManager.swift
**Purpose**: Core business logic for managing launchd schedules

**Responsibilities**:
1. Creates/removes launchd plists in `~/Library/LaunchAgents/`
2. Parses existing plists on startup
3. Manages launchctl load/unload operations
4. Provides single source of truth for schedule data

**Key Methods**:
- `loadSchedules()`: Scans filesystem for existing NightFade plists
- `addSchedule(_:)`: Creates plist and loads with launchctl
- `removeSchedule(_:)`: Unloads and deletes plist
- `addRememberToSleepPreset()`: Adds a complete preset with 6 schedules (7PM-12AM) for gradual warmth increase

**launchd Plist Structure**:
```xml
<key>ProgramArguments</key>
<array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>
        # Play sound
        afplay /System/Library/Sounds/Submarine.aiff &
        
        # Show notification
        osascript -e 'display notification "Night Shift warming up to X%" with title "NightFade"'
        
        # Set nightlight intensity
        "/path/to/nightlight" temp X
    </string>
</array>
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key><integer>21</integer>
    <key>Minute</key><integer>0</integer>
</dict>
```

**Binary Path Resolution**:
1. Check app bundle resources
2. Check Homebrew paths (`/opt/homebrew/bin/`, `/usr/local/bin/`)
3. Assume in PATH as fallback

### TimePickerView.swift
**Purpose**: Custom time picker with intuitive UI and keyboard input

**Features**:
- Large, readable time display (48pt font)
- Up/down arrow buttons for adjustments
- AM/PM toggle buttons with orange highlights
- **Keyboard Input**: Direct typing with Tab navigation
- Converts between 12-hour display and 24-hour storage
- Focus highlighting with pastel background

**State Management**:
- Bindings to parent's hour/minute values
- Internal state for AM/PM display and text fields
- `@FocusState` for keyboard navigation
- Smart formatting (only when field loses focus)

**Keyboard Interaction**:
- Hour field focused by default
- Type numbers directly (e.g., "10" for 10 o'clock)
- Tab key moves from hour to minute field
- Input validation: Hour (1-12), Minute (0-59)
- Backspace works naturally without formatting interference

## 🔄 Data Flow

### Loading Schedules
```
App Launch → ScheduleManager.loadSchedules() → 
Scan ~/Library/LaunchAgents/com.nightfade.* → 
Parse plists → Extract schedule data → 
Update @Published schedules array → 
UI refreshes automatically
```

### Adding Schedule
```
User creates schedule → ScheduleManager.addSchedule() → 
Generate plist XML → Write to LaunchAgents → 
Execute launchctl load → Reload all schedules → 
UI updates to show new schedule
```

### Removing Schedule
```
User clicks delete → ScheduleManager.removeSchedule() → 
Execute launchctl unload → Delete plist file → 
Reload all schedules → UI updates
```

## 🚨 Important Considerations

### Permissions & Security
- **No Sandboxing**: App needs filesystem access for launchd
- **No Sudo Required**: Uses user-level LaunchAgents
- **Binary Permissions**: nightlight has 755 permissions

### Schedule Persistence
- All data stored in launchd plists
- No UserDefaults or app preferences
- Schedules survive app deletion
- Manual plist deletion reflected after refresh

### Error Handling
- Most errors printed to console only
- No user-facing error dialogs
- Operations continue even if individual schedules fail
- Debug logs available in `/tmp/nightfade-*.log`

### UI/UX Considerations
- **Window Sizing**: Fixed width (480px), resizable height (min 500px)
- **Quit Behavior**: App quits when window closes
- **Dark Mode**: Automatically adapts to system appearance
- **Refresh**: Manual button + auto-refresh on activation
- **Orange Theme**: Consistent orange branding throughout UI
- **Accessibility**: Focus indicators and keyboard navigation support

### Testing & Debugging
- **Debug Mode**: Toggle via File menu or Cmd+Shift+D to show/hide debug tools
- **Apply Now**: Immediate intensity testing when debug mode enabled
- **Refresh Button**: Manual schedule refresh (debug mode only)
- **Console Logs**: launchctl operations logged for troubleshooting

## Recent Improvements (Claude helped me pair code these imporvements below :3)

### Orange Theme Implementation
- **Consistent Branding**: Orange used for add button, AM/PM toggles, Save button
- **Native Styling**: Uses `.borderedProminent` with `.tint(.orange)` for native appearance
- **Visual Hierarchy**: Orange draws attention to primary actions

### Enhanced Time Picker
- **Keyboard-First Design**: Direct typing with visual focus indicators
- **Smart Formatting**: Minute formatting only when field loses focus
- **Better Spacing**: Increased arrow spacing (12pt) to avoid highlight clipping
- **Natural Input Flow**: Type "10:30" naturally without fighting auto-formatters

### Improved Visual Feedback
- **Warmth Colors**: Realistic Night Shift colors instead of scary red
- **Better Visibility**: Semi-transparent circles with black outlines
- **Responsive Layout**: Window adapts to content while maintaining fixed width

### Accessibility Enhancements
- **Focus Management**: Clear focus indicators and logical tab order
- **Input Validation**: Real-time validation with user-friendly behavior
- **Visual Contrast**: Improved text opacity and color contrast

### Debug Mode & Menu Bar Cleanup
- **Hidden Debug Tools**: Debug Tools section and refresh icon only visible when debug mode enabled
- **Debug Mode Toggle**: File menu option to Enable/Disable Debug Mode (Cmd+Shift+D)
- **Clean Menu Bar**: Removed unnecessary "New Window", "Show Tab Bar", and tab-related options
- **System Integration**: Uses `NSWindow.allowsAutomaticWindowTabbing = false` to disable tabbing features

## 🔧 Development Notes

### Building the Project
1. Open `NightFade.xcodeproj` in Xcode
2. Ensure signing team is set (or use ad-hoc signing)
3. Build with ⌘B or Product → Build
4. Run with ⌘R or Product → Run

### Adding New Features
- Follow existing patterns for consistency
- Update launchd plist format carefully
- Test schedule persistence after changes
- Verify nightlight binary compatibility

### Known Quirks
1. **Time Picker**: Uses 24-hour internal storage, 12-hour display
2. **Intensity Parsing**: Uses Scanner to extract from shell script
3. **Window Style**: Hidden title bar requires special handling
4. **Binary Path**: Multiple fallback locations checked
5. **Minute Input**: Smart formatting only applies when field loses focus
6. **State Management**: App is completely stateless - reads directly from launchd
7. **Schedule Sorting**: Uses 12pm as cutoff - times 12am-11:59am sort after 12pm-11:59pm for intuitive night schedule flow

## 📦 Distribution

### Creating Release Build

#### Building the App
1. Open Terminal and navigate to the project directory
2. Run: `xcodebuild -project NightFade.xcodeproj -scheme NightFade -configuration Release -derivedDataPath build`
3. The built app will be in: `build/Build/Products/Release/Night Fade.app`

#### Creating DMG for Distribution
1. Ensure you have:
   - The built app at `build/Build/Products/Release/Night Fade.app`
   - `Please Read This.rtf` in the project root (instructions for bypassing Gatekeeper)
   - `create_dmg.sh` script in the project root

2. Run the DMG creation script:
   ```bash
   ./create_dmg.sh
   ```

3. This will create `Night_Fade_v1.dmg` containing:
   - Night Fade.app
   - Please Read This.rtf (prominently displayed)
   - Applications folder shortcut

The DMG script (`create_dmg.sh`) does the following:
- Creates a temporary directory with app, README, and Applications symlink
- Generates a DMG with proper window layout (README at top, app and Applications below)
- Compresses the DMG for optimal size (~1.7MB)
- No background image needed - keeps it simple and clean

### Requirements for Users
- macOS 13.0 (Ventura) or later
- Night Shift capable Mac
- No additional dependencies
- Will need to bypass Gatekeeper on first run (instructions in README)

## 🐛 Troubleshooting

### Common Issues
1. **Schedules not triggering**: Check Console.app for launchd errors
2. **Intensity not changing**: Verify nightlight binary permissions
3. **Schedules not showing**: Click refresh (enable dev mode from the file menu to see it) or restart app
4. **Can't delete schedule**: Check file permissions in LaunchAgents

### Debug Locations
- Console logs: Xcode console or Console.app
- launchd logs: `/tmp/nightfade-com.nightfade.schedule.*.log`
- Plist files: `~/Library/LaunchAgents/com.nightfade.schedule.*`
