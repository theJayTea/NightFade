import SwiftUI

struct TimePickerView: View {
    @Binding var hour: Int
    @Binding var minute: Int
    @State private var isAM = true
    @State private var displayHour = 12
    @State private var hourText = "12"
    @State private var minuteText = "00"
    @FocusState private var focusedField: Field?
    
    enum Field {
        case hour, minute
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                // Hour
                VStack(spacing: 12) {
                    Button(action: { incrementHour() }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    TextField("", text: $hourText)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($focusedField, equals: .hour)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(focusedField == .hour ? Color.accentColor.opacity(0.1) : Color.clear)
                                .padding(-8)
                        )
                        .onChange(of: hourText) { newValue in
                            handleHourInput(newValue)
                        }
                        .onSubmit {
                            focusedField = .minute
                        }
                    
                    Button(action: { decrementHour() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text(":")
                    .font(.system(size: 36, weight: .light))
                    .padding(.horizontal, 8)
                
                // Minute
                VStack(spacing: 12) {
                    Button(action: { incrementMinute() }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    TextField("", text: $minuteText)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($focusedField, equals: .minute)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(focusedField == .minute ? Color.accentColor.opacity(0.1) : Color.clear)
                                .padding(-8)
                        )
                        .onChange(of: minuteText) { newValue in
                            handleMinuteInput(newValue)
                        }
                        .onSubmit {
                            formatMinuteText()
                        }
                    
                    Button(action: { decrementMinute() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // AM/PM Toggle
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isAM ? Color.orange : Color.clear)
                        .frame(width: 60, height: 36)
                    
                    Text("AM")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isAM ? .white : .secondary)
                }
                .frame(width: 60, height: 36)
                .onTapGesture {
                    setAM()
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(!isAM ? Color.orange : Color.clear)
                        .frame(width: 60, height: 36)
                    
                    Text("PM")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(!isAM ? .white : .secondary)
                }
                .frame(width: 60, height: 36)
                .onTapGesture {
                    setPM()
                }
            }
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
        }
        .onAppear {
            updateDisplayTime()
            focusedField = .hour
        }
        .onChange(of: focusedField) { newValue in
            if newValue != .minute {
                formatMinuteText()
            }
        }
    }
    
    private func updateDisplayTime() {
        if hour == 0 {
            displayHour = 12
            isAM = true
        } else if hour < 12 {
            displayHour = hour
            isAM = true
        } else if hour == 12 {
            displayHour = 12
            isAM = false
        } else {
            displayHour = hour - 12
            isAM = false
        }
        hourText = String(displayHour)
        // Only format minute text if not currently focused
        if focusedField != .minute {
            minuteText = String(format: "%02d", minute)
        }
    }
    
    private func updateHour() {
        if isAM {
            hour = displayHour == 12 ? 0 : displayHour
        } else {
            hour = displayHour == 12 ? 12 : displayHour + 12
        }
    }
    
    private func incrementHour() {
        displayHour = displayHour == 12 ? 1 : displayHour + 1
        hourText = String(displayHour)
        updateHour()
    }
    
    private func decrementHour() {
        displayHour = displayHour == 1 ? 12 : displayHour - 1
        hourText = String(displayHour)
        updateHour()
    }
    
    private func incrementMinute() {
        minute = (minute + 1) % 60
        minuteText = String(format: "%02d", minute)
    }
    
    private func decrementMinute() {
        minute = minute == 0 ? 59 : minute - 1
        minuteText = String(format: "%02d", minute)
    }
    
    private func setAM() {
        isAM = true
        updateHour()
    }
    
    private func setPM() {
        isAM = false
        updateHour()
    }
    
    private func handleHourInput(_ input: String) {
        // Remove non-numeric characters
        let filtered = input.filter { $0.isNumber }
        
        // Limit to 2 digits
        let limited = String(filtered.prefix(2))
        
        if limited != input {
            hourText = limited
        }
        
        if let newHour = Int(limited), newHour >= 1 && newHour <= 12 {
            displayHour = newHour
            updateHour()
        }
    }
    
    private func handleMinuteInput(_ input: String) {
        // Remove non-numeric characters
        let filtered = input.filter { $0.isNumber }
        
        // Limit to 2 digits
        let limited = String(filtered.prefix(2))
        
        if limited != input {
            minuteText = limited
            return
        }
        
        minuteText = limited
        
        if let newMinute = Int(limited) {
            if newMinute >= 0 && newMinute <= 59 {
                minute = newMinute
            } else if limited.count == 2 {
                // If they typed an invalid 2-digit number, reset
                minuteText = String(format: "%02d", minute)
            }
        } else if limited.isEmpty {
            minute = 0
        }
    }
    
    private func formatMinuteText() {
        if let currentMinute = Int(minuteText), currentMinute >= 0 && currentMinute <= 59 {
            minute = currentMinute
            minuteText = String(format: "%02d", minute)
        } else {
            minuteText = String(format: "%02d", minute)
        }
    }
}