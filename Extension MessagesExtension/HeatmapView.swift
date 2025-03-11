//
//  HeatmapView.swift
//  test
//
//  Created on 3/8/25.
//

import SwiftUI
import Messages

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: [DateInterval: CGRect] = [:]
    
    static func reduce(value: inout [DateInterval: CGRect], nextValue: () -> [DateInterval: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct QuarterHourSection: View {
    var date: Date
    var hour: Int
    var minute: Int
    var event: Event
    var groupedSlots: [Date: [DateInterval]]
    var onTap: (DateInterval) -> Void
    var isEditMode: Bool
    var userAvailability: Set<DateInterval>
    var onToggleAvailability: (DateInterval) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        
        let quarterDate = calendar.date(from: components) ?? Date()
        let endDate = calendar.date(byAdding: .minute, value: 15, to: quarterDate) ?? Date()
        let timeInterval = DateInterval(start: quarterDate, end: endDate)
        
        let matchingSlots = (groupedSlots[calendar.startOfDay(for: date)] ?? []).filter { slot in
            let slotComponents = calendar.dateComponents([.hour, .minute], from: slot.start)
            return slotComponents.hour == hour && slotComponents.minute == minute
        }
        
        let hasData = !matchingSlots.isEmpty
        // Use the matched slot from groupedSlots if available, otherwise use our computed timeInterval
        let timeSlot = matchingSlots.first ?? timeInterval
        let fillColor = getHeatColor(for: timeSlot, event: event, isEditMode: isEditMode, userAvailability: userAvailability)
        
        // Get the current device identifier
        //let currentDevice = UIDevice.current.identifierForVendor?.uuidString ?? "Anonymous"
        
        // Check if the current user has selected this time slot
        let hasUserSelected = userAvailability.contains(timeSlot)
        
        return GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(fillColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(2)
                
                // Show a checkmark if this user has selected this time slot
                if hasUserSelected && isEditMode {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10))
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
                
                // Get the count of users for this time slot for the small badge
                if let users = event.avail[timeSlot], !users.isEmpty && !isEditMode {
                    Text("\(users.count)")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Circle().fill(Color.blue))
                        .opacity(0.8)
                }
            }
            .onTapGesture {
                if isEditMode {
                    onToggleAvailability(timeSlot)
                } else if hasData {
                    // Ensure we're passing the actual time slot from groupedSlots
                    // that was used to determine hasData
                    onTap(matchingSlots.first ?? timeSlot)
                }
            }
            .preference(key: FramePreferenceKey.self, value: [timeSlot: geometry.frame(in: .named("heatmapContainer"))])
        }
    }
    
    private func getHeatColor(for timeSlot: DateInterval, event: Event, isEditMode: Bool, userAvailability: Set<DateInterval>) -> Color {
        if isEditMode {
            if colorScheme == .dark {
                return userAvailability.contains(timeSlot) ? Color(white: 0.4) : Color(white: 0.2)
            } else {
                return userAvailability.contains(timeSlot) ? Color.blue.opacity(0.3) : Color(white: 0.95)
            }
        } else {
            guard let availableUsers = event.avail[timeSlot], !availableUsers.isEmpty else {
                return colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95)
            }
            let userCount = availableUsers.count
            let maxUsers = max(event.users.count, 1)
            let intensity = Double(userCount) / Double(maxUsers)
            
            if colorScheme == .dark {
                let red = min(1.0, (119/255 - (44/255 * intensity)))
                let green = min(1.0, (146/255 - (40/255 * intensity)))
                let blue = min(1.0, 252/255)
                return Color(red: red, green: green, blue: blue)
            } else {
                return Color(red: 99/255 - (44/255 * intensity), green: 126/255 - (40/255 * intensity), blue: 232/255)
            }
        }
    }
}

struct HeatmapView: View {
    @State var event: Event
    var controller: MessagesViewController?
    @State private var selectedTimeSlot: DateInterval?
    @State private var showingAvailableUsers: Bool = false
    @State private var isEditMode: Bool = false
    @State private var userAvailability: Set<DateInterval> = []
    @Environment(\.colorScheme) var colorScheme
    @State private var showingConfirmation: Bool = false
    @State private var userName: String = ""
    @State private var showNameError: Bool = false
    
    @State private var cellFrames: [DateInterval: CGRect] = [:]
    //@State private var dragStart: CGPoint?
    //@State private var dragCurrent: CGPoint?
    @State private var processedSlots: Set<DateInterval> = []
    
    @State private var dragMode: DragMode?
    enum DragMode {
        case adding
        case removing
    }
    
    @State private var dragStart: CGPoint = .zero
    @State private var dragCurrent: CGPoint = .zero
    @State private var initialUserAvailability: Set<DateInterval> = []
    @State private var affectedSlots: Set<DateInterval> = []
    @State private var isAdding: Bool = false
    
    @State private var showUserDetails: Bool = false
    @State private var selectedUsers: [String] = []
    
    var body: some View {
        GeometryReader { geometry in
            let totalHorizontalPadding: CGFloat = 32
            //let availableWidth = geometry.size.width - totalHorizontalPadding
            //let cellWidth = availableWidth / 7
            let cellHeight: CGFloat = 20
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(isEditMode ? "Your Availability" : "Group Availability")
                        .font(Font.custom("Outfit-Bold", size: geometry.size.width * 0.08))
                        .foregroundColor(Color(red: 55/255, green: 86/255, blue: 209/255))
                    
                    Spacer()
                    
                    Toggle("", isOn: $isEditMode)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 55/255, green: 86/255, blue: 209/255)))
                        .onChange(of: isEditMode) { newValue in
                            if newValue {
                                // Re-initialize user availability when entering edit mode
                                initializeUserAvailability()
                            }
                        }
                }
                .padding(.bottom, 5)
                
                Text(event.name)
                    .font(Font.custom("Inter-Bold", size: geometry.size.width * 0.05))
                    .padding(.bottom, 10)
                
                HStack(spacing: 10) {
                    Text("Availability:")
                        .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.035))
                    
                    ForEach(0..<5) { i in
                        let intensity = Double(i) / 4.0
                        Rectangle()
                            .fill(colorScheme == .dark ? 
                                 Color(red: min(1.0, (119/255 - (44/255 * intensity))), green: min(1.0, (146/255 - (40/255 * intensity))), blue: min(1.0, 252/255)) : 
                                 Color(red: 99/255 - (44/255 * intensity), green: 126/255 - (40/255 * intensity), blue: 232/255))
                            .frame(width: 20, height: 20)
                            .cornerRadius(4)
                    }
                }
                .padding(.bottom, 15)
                
                let groupedSlots = groupedTimeSlots()
                let sortedDates = groupedSlots.keys.sorted()
                let sortedHours = uniqueHours()
                
                // Simpler layout approach
                VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: true) {
                            // Fixed date header row
                            HStack(spacing: 0) {
                                // Empty corner cell
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white)
                                    .border(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                
                                
                                // Fixed date headers
                                HStack(spacing: 0) {
                                    ForEach(sortedDates, id: \.self) { date in
                                        VStack {
                                            Text(formatDate(date))
                                                .font(.system(size: 12, weight: .bold))
                                            Text(getDayOfWeek(from: date))
                                                .font(.system(size: 10))
                                        }
                                        .frame(width: 60, height: 50)
                                        .background(colorScheme == .dark ? Color(white: 0.2) : Color.white)
                                        .border(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.3))
                                    }
                                }
                            }
                            
                            // Scrollable content area with fixed time column
                            ScrollView(.vertical, showsIndicators: true) {
                                HStack(spacing: 0) {
                                    // Fixed time column
                                    VStack(spacing: 0) {
                                        ForEach(sortedHours, id: \.self) { hour in
                                            let hourDate = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
                                            Text({
                                                let formatter = DateFormatter()
                                                formatter.dateFormat = "h a"
                                                return formatter.string(from: hourDate)
                                            }())
                                            .font(.system(size: 12))
                                            .frame(width: 50, height: cellHeight * 4)
                                            .background(colorScheme == .dark ? Color(white: 0.2) : Color.white)
                                            .border(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.3))
                                            .zIndex(3)
                                        }
                                    }
                                    
                                    // Time slots grid
                                    HStack(spacing: 0) {
                                        ForEach(sortedDates, id: \.self) { date in
                                            VStack(spacing: 0) {
                                                ForEach(sortedHours, id: \.self) { hour in
                                                    VStack(spacing: 0) {
                                                    QuarterHourSection(
                                                        date: date,
                                                        hour: hour,
                                                        minute: 0,
                                                        event: event,
                                                        groupedSlots: groupedSlots,
                                                        onTap: { timeSlot in
                                                            selectedTimeSlot = timeSlot
                                                            showingAvailableUsers = true
                                                        },
                                                        isEditMode: isEditMode,
                                                        userAvailability: userAvailability,
                                                        onToggleAvailability: { timeSlot in
                                                            toggleAvailability(timeSlot)
                                                        }
                                                    )
                                                        
                                                    QuarterHourSection(
                                                        date: date,
                                                        hour: hour,
                                                        minute: 15,
                                                        event: event,
                                                        groupedSlots: groupedSlots,
                                                        onTap: { timeSlot in
                                                            selectedTimeSlot = timeSlot
                                                            showingAvailableUsers = true
                                                        },
                                                        isEditMode: isEditMode,
                                                        userAvailability: userAvailability,
                                                        onToggleAvailability: { timeSlot in
                                                            toggleAvailability(timeSlot)
                                                        }
                                                    )
                                                        
                                                    QuarterHourSection(
                                                        date: date,
                                                        hour: hour,
                                                        minute: 30,
                                                        event: event,
                                                        groupedSlots: groupedSlots,
                                                        onTap: { timeSlot in
                                                            selectedTimeSlot = timeSlot
                                                            showingAvailableUsers = true
                                                        },
                                                        isEditMode: isEditMode,
                                                        userAvailability: userAvailability,
                                                        onToggleAvailability: { timeSlot in
                                                            toggleAvailability(timeSlot)
                                                        }
                                                    )
                                                        
                                                    QuarterHourSection(
                                                        date: date,
                                                        hour: hour,
                                                        minute: 45,
                                                        event: event,
                                                        groupedSlots: groupedSlots,
                                                        onTap: { timeSlot in
                                                            selectedTimeSlot = timeSlot
                                                            showingAvailableUsers = true
                                                        },
                                                        isEditMode: isEditMode,
                                                        userAvailability: userAvailability,
                                                        onToggleAvailability: { timeSlot in
                                                            toggleAvailability(timeSlot)
                                                        }
                                                    )
                                                    }
                                                    .frame(width: 60, height: cellHeight * 4)
                                                    .zIndex(1)
                                                }
                                            }
                                            .border(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.3))
                                        }
                                    }
                                    .coordinateSpace(name: "heatmapContainer")
                                    .gesture(isEditMode ? DragGesture(minimumDistance: 0, coordinateSpace: .named("heatmapContainer"))
                                        .onChanged { value in
                                            handleDragChange(value: value)
                                        }
                                        .onEnded { _ in
                                            dragStart = .zero
                                            dragCurrent = .zero
                                            affectedSlots.removeAll()
                                        } : nil
                                    )
                                    .onPreferenceChange(FramePreferenceKey.self) { frames in
                                        cellFrames = frames
                                    }
                                }
                            }
                        }
                }
            }
            .padding()
            .overlay(alignment: .bottom) {
                if isEditMode {
                    VStack {
                        Divider()
                        
                        if showNameError {
                            Text("Please enter your name")
                                .foregroundColor(.red)
                                .font(Font.custom("Inter-Regular", size: 14))
                                .padding(.top, 4)
                        }
                        
                        TextField("Enter your name", text: $userName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .autocapitalization(.words)
                        
                        Button("Pencil In My Availability") {
                            if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                showNameError = true
                            } else {
                                showNameError = false
                                saveAvailability()
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        if showingConfirmation {
                            Text("Availability shared with group")
                                .font(Font.custom("Inter-Regular", size: 14))
                                .foregroundColor(.green)
                                .padding(.top, 8)
                                .transition(.opacity)
                        }
                    }
                    .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                }
            }
            .sheet(isPresented: $showingAvailableUsers) {
                
                VStack(spacing: 15) {
                    Text("Available Users")
                        .font(.headline)
                        .padding()
                    
                    if let selectedSlot = selectedTimeSlot, let users = event.avail[selectedSlot] {
                        let formattedTime = "\(formatTime(selectedSlot.start)) - \(formatTime(selectedSlot.end))"
                        Text(formattedTime)
                            .font(.subheadline)
                            .padding(.bottom, 5)
                        
                        List {
                            ForEach(users, id: \.self) { user in
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.blue)
                                    
                                    // Display the user's name
                                    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Anonymous"
                                    if user.contains(deviceId) {
                                        Text("You (\(user.components(separatedBy: "_\(deviceId)").first ?? "Anonymous"))")
                                            .foregroundColor(.primary)
                                    } else if user == "Anonymous" || user == "You" {
                                        Text("Anonymous")
                                            .foregroundColor(.primary)
                                    } else {
                                        // Extract the name part from the identifier
                                        let displayName = user.components(separatedBy: "_").first ?? user
                                        Text(displayName)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("No users available at this time")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Close") {
                        showingAvailableUsers = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            initializeUserAvailability()
        }
    }
    
    private func toggleAvailability(_ timeSlot: DateInterval) {
        if userAvailability.contains(timeSlot) {
            userAvailability.remove(timeSlot)
        } else {
            userAvailability.insert(timeSlot)
        }
    }
    
    private func handleDragChange(value: DragGesture.Value) {
        if dragStart == .zero {
            dragStart = value.startLocation
            initialUserAvailability = userAvailability
            if let initialSlot = slotAtLocation(value.startLocation) {
                isAdding = !initialUserAvailability.contains(initialSlot)
            }
        }
        dragCurrent = value.location
        updateSelection()
    }
    private func updateSelection() {
        guard dragStart != .zero else { return }
        
        let dragRect = CGRect(
            x: min(dragStart.x, dragCurrent.x),
            y: min(dragStart.y, dragCurrent.y),
            width: abs(dragCurrent.x - dragStart.x),
            height: abs(dragCurrent.y - dragStart.y)
        )
        
        let newAffectedSlots = Set(cellFrames.filter {
            dragRect.intersects($0.value)
        }.map(\.key))
        
        // Get added/removed slots
        let addedSlots = newAffectedSlots.subtracting(affectedSlots)
        let removedSlots = affectedSlots.subtracting(newAffectedSlots)
        
        var newSelection = userAvailability
        
        // Apply action to newly added slots
        for slot in addedSlots {
            if isAdding {
                newSelection.insert(slot)
            } else {
                newSelection.remove(slot)
            }
        }
        
        // Revert removed slots to initial state
        for slot in removedSlots {
            if initialUserAvailability.contains(slot) {
                newSelection.insert(slot)
            } else {
                newSelection.remove(slot)
            }
        }
        
        userAvailability = newSelection
        affectedSlots = newAffectedSlots
    }
    
    private func slotAtLocation(_ location: CGPoint) -> DateInterval? {
        cellFrames.first { $0.value.contains(location) }?.key
    }
    
    private func saveAvailability() {
        // Use the entered name instead of device ID
        let currentUser = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save the username to UserDefaults for future use
        UserDefaults.standard.set(currentUser, forKey: "PMI_LastUsedName")
        
        let availCopy = event.avail
        
        // Remove previous entries from this device
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Anonymous"
        for (timeSlot, users) in availCopy {
            var updatedUsers = users
            if let index = updatedUsers.firstIndex(where: { $0 == deviceId || $0 == "You" || $0.contains(deviceId) }) {
                updatedUsers.remove(at: index)
                event.avail[timeSlot] = updatedUsers
            }
        }
        
        // Add new entries with the user's name
        for timeSlot in userAvailability {
            if event.avail[timeSlot] != nil {
                var updatedUsers = event.avail[timeSlot] ?? []
                // Add name with device ID to maintain uniqueness
                let userIdentifier = "\(currentUser)_\(deviceId)"
                if !updatedUsers.contains(userIdentifier) {
                    updatedUsers.append(userIdentifier)
                    event.avail[timeSlot] = updatedUsers
                }
            } else {
                // Create new entry for this time slot
                event.avail[timeSlot] = ["\(currentUser)_\(deviceId)"]
            }
        }
        
        // Send updated event as a message if we have a controller and conversation
        if let messagesController = controller, let conversation = messagesController.activeConversation {
            sendUpdatedEventAsMessage(event: event, controller: messagesController, conversation: conversation)
            showingConfirmation = true
            
            // Hide the confirmation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                showingConfirmation = false
                // Dismiss the view and return to keyboard
                messagesController.dismiss()
            }
        }
        
        isEditMode = false
    }
    
    private func initializeUserAvailability() {
        // Get identifiers for the current device
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Anonymous"
        
        // Clear the set first
        userAvailability.removeAll()
        
        // First normalize any legacy "You" usernames
        event.normalizeUsernames()
        
        // Check if we have this event saved locally with our previous selections
        if let savedEvent = EventStorage.getEvent(id: event.id) {
            // First try to get availability from our saved version of this event
            for (timeSlot, users) in savedEvent.avail {
                for user in users {
                    // Check if this is the current device (comparing both device ID and any names that contain the device ID)
                    if user == deviceId || user.contains(deviceId) || user == "You" {
                        userAvailability.insert(timeSlot)
                        
                        // If we find a username with our device ID, extract and use it
                        if user.contains(deviceId) && user != deviceId {
                            let extractedName = user.components(separatedBy: "_\(deviceId)").first ?? ""
                            if !extractedName.isEmpty && userName.isEmpty {
                                userName = extractedName
                            }
                        }
                        break
                    }
                }
            }
        }
        
        // If nothing was loaded from saved events, try loading from the current event
        if userAvailability.isEmpty {
            // Use the helper method to get all time slots for this user
            let userTimeSlots = event.getUserAvailability(user: deviceId)
            userAvailability = Set(userTimeSlots)
            
            // Try to extract the username from the event if we haven't found it yet
            if userName.isEmpty {
                for (_, users) in event.avail {
                    for user in users {
                        if user.contains(deviceId) && user != deviceId {
                            let extractedName = user.components(separatedBy: "_\(deviceId)").first ?? ""
                            if !extractedName.isEmpty {
                                userName = extractedName
                                break
                            }
                        }
                    }
                    if !userName.isEmpty {
                        break
                    }
                }
            }
        }
        
        // If we still don't have a name, try to get it from UserDefaults
        if userName.isEmpty {
            userName = UserDefaults.standard.string(forKey: "PMI_LastUsedName") ?? ""
        }
        
        // Add any missing time slots to the event data model to ensure the grid is complete
        ensureTimeSlots()
    }
    
    // Make sure all time slots exist in the event's availability dictionary
    private func ensureTimeSlots() {
        let calendar = Calendar.current
        
        for date in event.dates {
            var currentTime = Double(event.startTime)
            while currentTime < Double(event.endTime) {
                let hour = Int(currentTime)
                let minute = Int((currentTime - Double(hour)) * 60)
                
                if let timeDate = calendar.date(bySettingHour: hour % 24, minute: minute, second: 0, of: date) {
                    let endDate = timeDate.addingTimeInterval(900) // 15 minutes = 900 seconds
                    let timeSlot = DateInterval(start: timeDate, end: endDate)
                    
                    // Create the time slot if it doesn't exist
                    if event.avail[timeSlot] == nil {
                        event.avail[timeSlot] = []
                    }
                }
                
                // Move to next 15-minute slot
                currentTime += 0.25
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    // Format date for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures English month abbreviation
        formatter.dateFormat = "MMM d" // Format like "Mar 12"
        return formatter.string(from: date)
    }
    func getDayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensure English abbreviations
        formatter.dateFormat = "EEE" // "EEE" = 3-letter weekday abbreviation
        return formatter.string(from: date)
    }
    
    // Group the time slots by date
    func groupedTimeSlots() -> [Date: [DateInterval]] {
        var grouped: [Date: [DateInterval]] = [:]
        
        for timeSlot in event.avail.keys {
            let startDate = Calendar.current.startOfDay(for: timeSlot.start)
            if grouped[startDate] == nil {
                grouped[startDate] = []
            }
            grouped[startDate]?.append(timeSlot)
        }
        
        // Sort the time slots for each date
        for (date, slots) in grouped {
            grouped[date] = slots.sorted { $0.start < $1.start }
        }
        
        return grouped
    }
    
    // Get all unique hours across all days
    func uniqueHours() -> [Int] {
        let groupedSlots = groupedTimeSlots()
        var allHours: Set<Int> = []
        
        for (_, slots) in groupedSlots {
            for slot in slots {
                let hour = Calendar.current.component(.hour, from: slot.start)
                allHours.insert(hour)
            }
        }
        
        return allHours.sorted()
    }
    
    // Get all unique time slots across all days
    func uniqueTimeSlots() -> [DateComponents] {
        let groupedSlots = groupedTimeSlots()
        var allTimeSlots: Set<DateComponents> = []
        
        for (_, slots) in groupedSlots {
            for slot in slots {
                let components = Calendar.current.dateComponents([.hour, .minute], from: slot.start)
                allTimeSlots.insert(components)
            }
        }
        
        return allTimeSlots.sorted {
            let hour1 = $0.hour ?? 0
            let hour2 = $1.hour ?? 0
            if hour1 != hour2 {
                return hour1 < hour2
            }
            return ($0.minute ?? 0) < ($1.minute ?? 0)
        }
    }
    
}

// Function to send the updated event as a message
func sendUpdatedEventAsMessage(event: Event, controller: MessagesViewController, conversation: MSConversation) {
    // Create a new MSSession
    let session = MSSession()
    
    // Create a new MSMessage with the session
    let message = MSMessage(session: session)
    
    // Create a message layout
    let layout = MSMessageTemplateLayout()
    
    // Set the layout properties
    layout.image = createUpdatedEventImage(for: event)
    layout.caption = "Updated: \(event.name)"
    layout.subcaption = "Availability updated"
    
    // Set the layout for the message
    message.layout = layout
    
    // Add the event data to the message URL components
    var components = URLComponents()
    components.queryItems = [
        URLQueryItem(name: "name", value: event.name),
        URLQueryItem(name: "startTime", value: String(event.startTime)),
        URLQueryItem(name: "endTime", value: String(event.endTime)),
        URLQueryItem(name: "timeZone", value: event.timeZone.identifier)
    ]
    
    // Add dates
    for (index, date) in event.dates.enumerated() {
        let dateString = "\(Int(date.timeIntervalSince1970))"
        components.queryItems?.append(URLQueryItem(name: "date\(index)", value: dateString))
    }
    
    // Add availability data
    var availIndex = 0
    for (timeSlot, users) in event.avail {
        if !users.isEmpty {
            let startTimeString = "\(Int(timeSlot.start.timeIntervalSince1970))"
            let endTimeString = "\(Int(timeSlot.end.timeIntervalSince1970))"
            
            components.queryItems?.append(URLQueryItem(name: "slot\(availIndex)_start", value: startTimeString))
            components.queryItems?.append(URLQueryItem(name: "slot\(availIndex)_end", value: endTimeString))
            
            // Add users for this time slot
            for (userIndex, user) in users.enumerated() {
                components.queryItems?.append(URLQueryItem(name: "slot\(availIndex)_user\(userIndex)", value: user))
            }
            
            availIndex += 1
        }
    }
    
    // Set the URL to the message
    message.url = components.url
    
    // Insert the message into the conversation
    conversation.insert(message) { error in
        if let error = error {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
}

// Helper function to create an image for the updated event
func createUpdatedEventImage(for event: Event) -> UIImage {
    // Create an image context
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200))
    
    return renderer.image { context in
        // Fill background
        UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0).setFill()
        context.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
        
        // Draw event name
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor(red: 55/255, green: 86/255, blue: 209/255, alpha: 1.0)
        ]
        
        let titleString = NSAttributedString(string: event.name, attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: 20, y: 20))
        
        // Draw calendar icon and info
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if let firstDate = event.dates.first, let lastDate = event.dates.last {
            let firstDateString = dateFormatter.string(from: firstDate)
            let lastDateString = firstDate == lastDate ? "" : " to " + dateFormatter.string(from: lastDate)
            let startTime = formatHour(hour: event.startTime)
            let endTime = formatHour(hour: event.endTime)
            let timeString = "\(startTime) - \(endTime)"
            let dateTimeString = NSAttributedString(string: "\(firstDateString)\(lastDateString)\n\(timeString)", attributes: infoAttributes)
            dateTimeString.draw(at: CGPoint(x: 20, y: 60))
        }
        
        // Draw availability info
        let availabilityAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let numResponses = event.users.count
        let availabilityString = NSAttributedString(string: "\(numResponses) people responded", attributes: availabilityAttributes)
        availabilityString.draw(at: CGPoint(x: 20, y: 120))
        
        // Draw instruction
        let instructionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let instructionString = NSAttributedString(string: "Tap to view & edit availability", attributes: instructionAttributes)
        instructionString.draw(at: CGPoint(x: 20, y: 160))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 55/255, green: 86/255, blue: 209/255))
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(Font.custom("Inter-Bold", size: 16))
            .padding(.horizontal)
            .padding(.bottom, 10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
