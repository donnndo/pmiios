//
//  SentEventsView.swift
//  Extension MessagesExtension
//
//  Created in 2025.
//

import SwiftUI

struct SentEventsView: View {
    @State private var events: [Event] = []
    var controller: MessagesViewController?
    @State private var showingNoEventsAlert = false
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Format time range
    private func formatTimeRange(start: Int, end: Int) -> String {
        let startHour = start % 24
        let endHour = end % 24
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        // Create date objects for the start and end times
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        var components = DateComponents()
        components.hour = startHour
        components.minute = 0
        let startDate = calendar.date(from: components) ?? Date()
        
        components.hour = endHour
        let endDate = calendar.date(from: components) ?? Date()
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var body: some View {
        VStack {
            Text("Your Events")
                .font(Font.custom("Outfit-Bold", size: 28))
                .foregroundColor(Color(red: 55/255, green: 86/255, blue: 209/255))
                .padding(.top)
            
            if events.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No events found")
                        .font(Font.custom("Inter-Regular", size: 18))
                        .foregroundColor(.gray)
                    
                    Text("Events you send will appear here so you can edit your availability later")
                        .font(Font.custom("Inter-Regular", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        controller?.dismiss()
                    }) {
                        Text("Create New Event")
                            .font(Font.custom("Inter-Bold", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 55/255, green: 86/255, blue: 209/255))
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(events, id: \.id) { event in
                        Button(action: {
                            // Present the heatmap view with this event for editing
                            if let controller = controller {
                                controller.presentSwiftUIView(HeatmapView(event: event, controller: controller))
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(event.name)
                                    .font(Font.custom("Inter-Bold", size: 18))
                                    .foregroundColor(.primary)
                                
                                if !event.dates.isEmpty {
                                    Text("Dates: \(formatDateList(event.dates))")
                                        .font(Font.custom("Inter-Regular", size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Time: \(formatTimeRange(start: event.startTime, end: event.endTime))")
                                    .font(Font.custom("Inter-Regular", size: 14))
                                    .foregroundColor(.secondary)
                                
                                Text("Timezone: \(event.timeZone.abbreviation() ?? event.timeZone.identifier)")
                                    .font(Font.custom("Inter-Regular", size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete { indexSet in
                        // Get the events to delete
                        let eventsToDelete = indexSet.map { events[$0] }
                        
                        // Remove from storage
                        for event in eventsToDelete {
                            EventStorage.deleteEvent(id: event.id)
                        }
                        
                        // Remove from the view
                        events.remove(atOffsets: indexSet)
                    }
                }
                
                Button(action: {
                    controller?.dismiss()
                }) {
                    Text("Create New Event")
                        .font(Font.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 55/255, green: 86/255, blue: 209/255))
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .onAppear {
            // Load saved events when the view appears
            if let controller = controller {
                events = controller.loadSentEvents()
            }
        }
    }
    
    // Helper function to format a list of dates
    private func formatDateList(_ dates: [Date]) -> String {
        // Sort dates
        let sortedDates = dates.sorted()
        
        // If there are more than 2 dates, show first and last with ellipsis
        if sortedDates.count > 2 {
            return "\(formatDate(sortedDates.first!)) ... \(formatDate(sortedDates.last!))"
        } else {
            return sortedDates.map { formatDate($0) }.joined(separator: ", ")
        }
    }
}

#Preview {
    SentEventsView(controller: nil)
}
