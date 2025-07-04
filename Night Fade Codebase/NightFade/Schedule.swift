import SwiftUI
import Foundation

struct Schedule: Identifiable, Codable {
    let id: UUID
    let hour: Int
    let minute: Int
    let intensity: Int
    
    init(hour: Int, minute: Int, intensity: Int) {
        self.id = UUID()
        self.hour = hour
        self.minute = minute
        self.intensity = intensity
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return formatter.string(from: date)
    }
    
    var warmthColor: Color {
        Self.warmthColor(for: intensity)
    }
    
    static func warmthColor(for intensity: Int) -> Color {
        // Create a more realistic warm color (from cool white to warm orange)
        // At 0%: cool white/blue tint
        // At 100%: warm orange (like actual Night Shift)
        
        if intensity == 0 {
            return Color(red: 0.95, green: 0.95, blue: 1.0) // Cool white with slight blue
        } else if intensity <= 50 {
            // Transition from cool white to neutral
            let factor = Double(intensity) / 50.0
            let red = 0.95 + (1.0 - 0.95) * factor
            let green = 0.95 + (0.92 - 0.95) * factor
            let blue = 1.0 + (0.85 - 1.0) * factor
            return Color(red: red, green: green, blue: blue)
        } else {
            // Transition from neutral to warm orange
            let factor = Double(intensity - 50) / 50.0
            let red = 1.0
            let green = 0.92 + (0.75 - 0.92) * factor
            let blue = 0.85 + (0.55 - 0.85) * factor
            return Color(red: red, green: green, blue: blue)
        }
    }
    
    var plistIdentifier: String {
        "com.nightfade.schedule.\(hour).\(minute)"
    }
}