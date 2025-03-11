//
//  EventStorage.swift
//  Extension MessagesExtension
//
//  Created in 2025.
//

import Foundation

class EventStorage {
    private static let sentEventsKey = "com.pencilmein.sentEvents"
    
    // Save an event to local storage
    static func saveEvent(_ event: Event) {
        do {
            // Get current list of saved events
            var savedEvents = getSavedEvents()
            
            // Check if this event already exists (by ID) and update it
            if let index = savedEvents.firstIndex(where: { $0.id == event.id }) {
                savedEvents[index] = event
            } else {
                // Otherwise add it as a new event
                savedEvents.append(event)
            }
            
            // Convert to data and save
            let data = try JSONEncoder().encode(savedEvents)
            UserDefaults.standard.set(data, forKey: sentEventsKey)
        } catch {
            print("Error saving event: \(error)")
        }
    }
    
    // Get all saved events
    static func getSavedEvents() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: sentEventsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Event].self, from: data)
        } catch {
            print("Error loading events: \(error)")
            return []
        }
    }
    
    // Delete an event by ID
    static func deleteEvent(id: String) {
        var savedEvents = getSavedEvents()
        savedEvents.removeAll { $0.id == id }
        
        do {
            let data = try JSONEncoder().encode(savedEvents)
            UserDefaults.standard.set(data, forKey: sentEventsKey)
        } catch {
            print("Error deleting event: \(error)")
        }
    }
    
    // Get a specific event by ID
    static func getEvent(id: String) -> Event? {
        return getSavedEvents().first { $0.id == id }
    }
}
