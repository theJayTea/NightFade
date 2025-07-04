import SwiftUI

struct ContentView: View {
    @StateObject private var scheduleManager = ScheduleManager()
    @State private var showingAddSchedule = false
    @Binding var debugModeEnabled: Bool
    
    var body: some View {
        ZStack {
            // Glassmorphic background
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 12) {
                            // App icon
                            if let appIcon = NSImage(named: "AppIcon") {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Night Fade")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("macOS Night Shift Intensity Scheduler")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        if debugModeEnabled {
                            Button(action: {
                                scheduleManager.loadSchedules()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Refresh schedules")
                        }
                    }
                }
                
                // Explanatory blurb
                VStack(spacing: 16) {
                    Text("Night Fade can gradually increase the Night Shift warmth intensity slider at scheduled times, so you can make your screen gradually warmer as you go further into the night.")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("**Note:**\n• Night Shift on/off timing is controlled in System Settings as usual.\n• Schedules persist even when the app is closed, using macOS's built-in system scheduler.")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
                .opacity(1.0)
                
                // Schedules List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Current Schedules")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddSchedule = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.0))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if scheduleManager.schedules.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "moon.stars")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No schedules yet")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    VStack(spacing: 8) {
                                        Text("Add your first schedule to get started")
                                            .font(.subheadline)
                                            .foregroundColor(.primary.opacity(0.7))
                                        
                                        Text("**OR**")
                                            .font(.subheadline)
                                            .foregroundColor(.primary.opacity(0.7))
                                        
                                        HStack(spacing: 4) {
                                            Text("Try my")
                                                .font(.subheadline)
                                                .foregroundColor(.primary.opacity(0.7))
                                            
                                            Button(action: {
                                                scheduleManager.addRememberToSleepPreset()
                                            }) {
                                                Text("\"Remember to Sleep\" preset")
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.0))
                                                    .underline()
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Text(":)")
                                                .font(.subheadline)
                                                .foregroundColor(.primary.opacity(0.7))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(16)
                            } else {
                                ForEach(scheduleManager.schedules) { schedule in
                                    ScheduleRowView(schedule: schedule) {
                                        scheduleManager.removeSchedule(schedule)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                
                // Footer
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("💛 Crafted with care by")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Link("Jesai", destination: URL(string: "https://github.com/theJayTea?tab=repositories")!)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.0))
                            .underline()
                    }
                    Spacer()
                }
                .opacity(1.0)
                .padding(.bottom, 8)
                
                // Debug section
                if debugModeEnabled {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Debug Tools")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        DebugSection()
                    }
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(30)
        }
        .frame(minWidth: 480, maxWidth: 480, minHeight: 725, maxHeight: .infinity)
        .sheet(isPresented: $showingAddSchedule) {
            AddScheduleView { schedule in
                scheduleManager.addSchedule(schedule)
            }
        }
        .onAppear {
            scheduleManager.loadSchedules()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Reload schedules when app becomes active
            scheduleManager.loadSchedules()
        }
    }
}

struct ScheduleRowView: View {
    let schedule: Schedule
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.timeString)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("\(schedule.intensity)% warmth")
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.7))
            }
            
            Spacer()
            
            // Warmth indicator
            Circle()
                .fill(schedule.warmthColor.opacity(0.5))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.5), lineWidth: 1.5)
                )
            
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color.black.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AddScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHour = 21
    @State private var selectedMinute = 0
    @State private var intensity = 50.0
    
    let onSave: (Schedule) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Add New Schedule")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose a time, and choose the intensity you want Night Shift to set to at that time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(spacing: 24) {
                    // Time picker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Time")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TimePickerView(hour: $selectedHour, minute: $selectedMinute)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Intensity slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                            .font(.headline)
                        
                        HStack {
                            Text("1%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $intensity, in: 1...100)
                                .accentColor(.orange)
                            
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("\(Int(intensity))% warmth")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(Schedule.warmthColor(for: Int(intensity)).opacity(0.5))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.5), lineWidth: 1.5)
                                )
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        let schedule = Schedule(
                            hour: selectedHour,
                            minute: selectedMinute,
                            intensity: Int(intensity)
                        )
                        onSave(schedule)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
        }
        .padding(30)
        .frame(width: 400, height: 500)
        .background(VisualEffectView(material: .popover, blendingMode: .withinWindow))
    }
}

struct DebugSection: View {
    @State private var debugIntensity = 50.0
    @State private var isRunning = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Test Intensity:")
                Slider(value: $debugIntensity, in: 1...100)
                    .frame(width: 150)
                Text("\(Int(debugIntensity))%")
                    .frame(width: 40)
            }
            
            HStack(spacing: 16) {
                Button("Apply Now") {
                    applyIntensity()
                }
                .disabled(isRunning)
                
            }
            
            if isRunning {
                Text("Running...")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    private func applyIntensity() {
        isRunning = true
        
        let nightlightPath = getNightlightPath()
        let task = Process()
        task.launchPath = nightlightPath
        task.arguments = ["temp", "\(Int(debugIntensity))"]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Error running nightlight: \(error)")
        }
        
        isRunning = false
    }
    
    
    private func getNightlightPath() -> String {
        if let bundlePath = Bundle.main.path(forResource: "nightlight", ofType: nil) {
            return bundlePath
        }
        return "/opt/homebrew/bin/nightlight"
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct AboutView: View {
    var body: some View {
        ZStack {
            // Glassmorphic background
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App icon and title
                VStack(spacing: 16) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Night Fade")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("macOS Night Shift Intensity Scheduler")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // App description
                VStack(spacing: 12) {
                    Text("Studies show that blue light affects melatonin production, which may degrade your sleep quality.")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                    
                    Text("And for me, more importantly, I find I've gotten used to the warm tint as my own mental cue that it's time to sleep!")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                    
                    Text("I made this app so that I could make the screen 100% warm past midnight, so that I feel compelled to sleep and not stay up :)")
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                }
                
                // Version info
                VStack(spacing: 8) {
                    Text("Version 1.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 Jesai Tarun")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Footer with GitHub link
                HStack(spacing: 4) {
                    Text("💛 Crafted with care by")
                        .font(.footnote)
                        .foregroundColor(.primary)
                    
                    Link("Jesai", destination: URL(string: "https://github.com/theJayTea?tab=repositories")!)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.0))
                        .underline()
                }
                .padding(.top, 8)
            }
            .padding(32)
        }
        .frame(width: 500, height: 450)
    }
}

#Preview {
    ContentView(debugModeEnabled: .constant(false))
}

#Preview("About View") {
    AboutView()
}