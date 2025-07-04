import Foundation
import Combine

class ScheduleManager: ObservableObject {
    @Published var schedules: [Schedule] = []
    
    init() {
        loadSchedules()
    }
    
    func loadSchedules() {
        // Only load from launchd plists - single source of truth
        schedules.removeAll()
        scanForExistingPlists()
    }
    
    func addSchedule(_ schedule: Schedule) {
        createLaunchdPlist(for: schedule)
        // Reload from system to get the actual state
        loadSchedules()
    }
    
    func removeSchedule(_ schedule: Schedule) {
        removeLaunchdPlist(for: schedule)
        // Reload from system to get the actual state
        loadSchedules()
    }
    
    func addRememberToSleepPreset() {
        let presetSchedules = [
            Schedule(hour: 19, minute: 0, intensity: 1),   // 7 PM - 1%
            Schedule(hour: 20, minute: 0, intensity: 10),  // 8 PM - 10%  
            Schedule(hour: 21, minute: 0, intensity: 25),  // 9 PM - 25%
            Schedule(hour: 22, minute: 0, intensity: 35),  // 10 PM - 35%
            Schedule(hour: 23, minute: 0, intensity: 50),  // 11 PM - 50%
            Schedule(hour: 0, minute: 0, intensity: 100)   // 12 AM - 100%
        ]
        
        for schedule in presetSchedules {
            addSchedule(schedule)
        }
    }
    
    private func sortSchedules() {
        schedules.sort { schedule1, schedule2 in
            // Adjust hours so that 12pm is the cutoff
            // Times from 12pm-11:59pm (12-23) stay as is
            // Times from 12am-11:59am (0-11) are treated as 24-35
            let hour1 = schedule1.hour < 12 ? schedule1.hour + 24 : schedule1.hour
            let hour2 = schedule2.hour < 12 ? schedule2.hour + 24 : schedule2.hour
            
            if hour1 == hour2 {
                return schedule1.minute < schedule2.minute
            }
            return hour1 < hour2
        }
    }
    
    private func scanForExistingPlists() {
        let launchAgentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: launchAgentsPath, includingPropertiesForKeys: nil)
            let nightFadePlists = files.filter { $0.lastPathComponent.hasPrefix("com.nightfade.schedule.") }
            
            for plistURL in nightFadePlists {
                if let plistData = try? Data(contentsOf: plistURL),
                   let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                    
                    // Parse the schedule from plist
                    if let startCalendarInterval = plist["StartCalendarInterval"] as? [String: Any],
                       let hour = startCalendarInterval["Hour"] as? Int,
                       let minute = startCalendarInterval["Minute"] as? Int {
                        
                        // Extract intensity from the shell script in ProgramArguments
                        var intensity = 50 // default
                        if let programArguments = plist["ProgramArguments"] as? [String],
                           programArguments.count >= 3,
                           let shellScript = programArguments.last {
                            // Parse intensity from the shell script
                            // Look for pattern: "nightlight" temp <number>
                            if let range = shellScript.range(of: "temp ") {
                                let afterTemp = shellScript[range.upperBound...]
                                // Extract the number (might be at end of string or before newline)
                                let scanner = Scanner(string: String(afterTemp))
                                if let parsedInt = scanner.scanInt() {
                                    intensity = parsedInt
                                }
                            }
                        }
                        
                        let schedule = Schedule(hour: hour, minute: minute, intensity: intensity)
                        schedules.append(schedule)
                    }
                }
            }
            
            sortSchedules()
        } catch {
            print("Error scanning for existing plists: \(error)")
        }
    }
    
    private func createLaunchdPlist(for schedule: Schedule) {
        let launchAgentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        
        // Create LaunchAgents directory if it doesn't exist
        try? FileManager.default.createDirectory(at: launchAgentsPath, withIntermediateDirectories: true)
        
        let plistURL = launchAgentsPath.appendingPathComponent("\(schedule.plistIdentifier).plist")
        
        // Get the nightlight binary path
        let nightlightPath = getNightlightPath()
        
        // Create a shell script that runs multiple commands
        let shellScript = """
            #!/bin/bash
            # Play sound
            afplay /System/Library/Sounds/Submarine.aiff &
            
            # Show notification
            osascript -e 'display notification "Night Shift warming up to \(schedule.intensity)%" with title "Night Fade" sound name "Submarine"'
            
            # Set nightlight intensity
            "\(nightlightPath)" temp \(schedule.intensity)
            """
        
        let plistContent: [String: Any] = [
            "Label": schedule.plistIdentifier,
            "ProgramArguments": ["/bin/bash", "-c", shellScript],
            "StartCalendarInterval": [
                "Hour": schedule.hour,
                "Minute": schedule.minute
            ],
            "RunAtLoad": false,
            "StandardOutPath": "/tmp/nightfade-\(schedule.plistIdentifier).log",
            "StandardErrorPath": "/tmp/nightfade-\(schedule.plistIdentifier).error.log"
        ]
        
        do {
            let plistData = try PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0)
            try plistData.write(to: plistURL)
            
            print("Created plist at: \(plistURL.path)")
            
            // Load the plist with launchctl
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["load", "-w", plistURL.path]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.launch()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("launchctl output: \(output)")
            }
            
            if task.terminationStatus != 0 {
                print("launchctl failed with status: \(task.terminationStatus)")
            } else {
                print("Successfully loaded plist")
            }
            
        } catch {
            print("Error creating plist: \(error)")
        }
    }
    
    private func removeLaunchdPlist(for schedule: Schedule) {
        let launchAgentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        let plistURL = launchAgentsPath.appendingPathComponent("\(schedule.plistIdentifier).plist")
        
        // Unload the plist first
        let unloadTask = Process()
        unloadTask.launchPath = "/bin/launchctl"
        unloadTask.arguments = ["unload", plistURL.path]
        unloadTask.launch()
        unloadTask.waitUntilExit()
        
        // Remove the plist file
        try? FileManager.default.removeItem(at: plistURL)
    }
    
    private func getNightlightPath() -> String {
        // First try to find the bundled binary
        if let bundlePath = Bundle.main.path(forResource: "nightlight", ofType: nil) {
            return bundlePath
        }
        
        // Fallback to system installations
        let possiblePaths = [
            "/opt/homebrew/bin/nightlight",
            "/usr/local/bin/nightlight"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Last resort - assume it's in PATH
        return "nightlight"
    }
}