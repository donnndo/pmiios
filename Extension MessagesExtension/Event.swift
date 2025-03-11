//
//  Event.swift
//  PencilMeIn
//
//  Created by Don Do on 3/4/25.
//

import SwiftUI

class Event: Codable {
    var id: String
    var name: String
    var timeZone: TimeZone
    var startTime: Int
    var endTime: Int
    var dates: [Date]
    var avail: [DateInterval:[String]] = [:]
    var users: [String] = []
    
    
    init(name: String, dates: [Date], startTime: Int, endTime: Int, timeZone: TimeZone) {
        self.id = UUID().uuidString
        self.name = name
        self.timeZone = timeZone
        self.startTime = startTime
        self.endTime = endTime
        self.dates = dates
        var currentTime: Double
        
        for date in self.dates {
            currentTime = Double(startTime)
            while(currentTime < Double(endTime)) {
                if(currentTime > 24) {
                    let hour = Int(currentTime)%24
                    let minute = Int((currentTime.truncatingRemainder(dividingBy: 24) - Double(hour))*60)
                    //let minute = Int((currentTime - Double(hour))*60)
                    let dateComponents = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date.addingTimeInterval(86400))
                    let interval = DateInterval(start: dateComponents!, end: dateComponents!.addingTimeInterval(900))
                    self.avail[interval] = []
                    currentTime += 0.25
                } else {
                    let hour = Int(currentTime)
                    let minute = Int((currentTime - Double(hour))*60)
                    let dateComponents = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date)
                    let interval = DateInterval(start: dateComponents!, end: dateComponents!.addingTimeInterval(900))
                    self.avail[interval] = []
                    currentTime += 0.25
                }
            }
        }
        return
    }
    /*
     init(name: String, days: [Int], startTime: Int, endTime: Int, timeZone: TimeZone){
     self.name = name
     self.dates = []
     return
     }*/
    
    func addUser(_ user: String) {
        if !self.users.contains(user) {
            self.users.append(user)
        }
    }
    
    // Update user availability for specific time slots
    func updateUserAvailability(user: String, timeSlots: [DateInterval], isAvailable: Bool) {
        // Make sure user exists in the users array
        if !users.contains(user) {
            addUser(user)
        }
        
        // Update each time slot with the user's availability
        for timeSlot in timeSlots {
            if let existingUsers = avail[timeSlot] {
                // If the user should be available and isn't already in the list
                if isAvailable && !existingUsers.contains(user) {
                    avail[timeSlot] = existingUsers + [user]
                }
                // If the user should not be available and is in the list
                else if !isAvailable && existingUsers.contains(user) {
                    avail[timeSlot] = existingUsers.filter { $0 != user }
                }
            } else if isAvailable {
                // Create a new entry if the time slot doesn't exist yet
                avail[timeSlot] = [user]
            }
        }
    }
    
    // Get the best time slots based on availability
    func getBestTimeSlots(limit: Int = 3) -> [DateInterval] {
        let sortedSlots = avail.sorted { (slot1, slot2) -> Bool in
            return (slot1.value.count > slot2.value.count) ||
                   (slot1.value.count == slot2.value.count && slot1.key.start < slot2.key.start)
        }
        
        return sortedSlots.prefix(limit).map { $0.key }
    }
    
    // Check if a specific user is available for a time slot
    func isUserAvailable(user: String, for timeSlot: DateInterval) -> Bool {
        if let users = avail[timeSlot] {
            // Check both the exact user ID and legacy "You" user
            return users.contains(user) || (user == UIDevice.current.identifierForVendor?.uuidString && users.contains("You"))
        }
        return false
    }
    
    // Get all time slots where a specific user is available
    func getUserAvailability(user: String) -> [DateInterval] {
        var result: [DateInterval] = []
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "Anonymous"
        
        for (timeSlot, users) in avail {
            for availUser in users {
                // Check all possible formats for the user identifier
                if availUser == user || // Exact match
                   (user == deviceId && availUser == "You") || // Legacy "You" identifier
                   availUser.contains(user) || // User ID is part of the string
                   (user == deviceId && availUser.contains(deviceId)) { // Current device ID is part of the string
                    result.append(timeSlot)
                    break
                }
            }
        }
        
        // Sort by start time
        return result.sorted { $0.start < $1.start }
    }
    
    // Replace legacy "You" username with the device identifier
    func normalizeUsernames() {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "Anonymous"
        
        for (timeSlot, users) in avail {
            if let index = users.firstIndex(of: "You") {
                var updatedUsers = users
                updatedUsers[index] = deviceID
                avail[timeSlot] = updatedUsers
            }
        }
        
        if let index = users.firstIndex(of: "You") {
            users[index] = deviceID
        }
    }
    
    // Codable conformance for TimeZone
    enum CodingKeys: String, CodingKey {
        case id, name, startTime, endTime, dates, avail, users, timeZoneIdentifier
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(dates, forKey: .dates)
        
        // Convert DateInterval keys to a string-based dictionary for coding
        var encodableAvail: [String: [String]] = [:]
        for (interval, users) in avail {
            let key = "\(interval.start.timeIntervalSince1970)_\(interval.end.timeIntervalSince1970)"
            encodableAvail[key] = users
        }
        try container.encode(encodableAvail, forKey: .avail)
        
        try container.encode(users, forKey: .users)
        try container.encode(timeZone.identifier, forKey: .timeZoneIdentifier)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        startTime = try container.decode(Int.self, forKey: .startTime)
        endTime = try container.decode(Int.self, forKey: .endTime)
        dates = try container.decode([Date].self, forKey: .dates)
        
        // Convert the string-based dictionary back to DateInterval keys
        let encodedAvail = try container.decode([String: [String]].self, forKey: .avail)
        avail = [:]
        for (encodedKey, availUsers) in encodedAvail {
            let components = encodedKey.split(separator: "_")
            if components.count == 2,
               let startTime = Double(components[0]),
               let endTime = Double(components[1]) {
                let start = Date(timeIntervalSince1970: startTime)
                let end = Date(timeIntervalSince1970: endTime)
                avail[DateInterval(start: start, end: end)] = availUsers
            }
        }
        
        users = try container.decode([String].self, forKey: .users)
        let timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
    }
}
