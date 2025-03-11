//
//  CreateEvent.swift
//  PencilMeIn
//
//  Created by Don Do on 3/3/25.
//

import SwiftUI
import Messages

struct CreateEvent: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    var controller: MessagesViewController?
    
    @State private var eventName = ""
    let startTimes = 0..<24
    let endTimes = 1..<25
    @State private var start: Int = 9
    @State private var end: Int = 22
    
    @State private var localTime: String = TimeZone.current.abbreviation() ?? "UTC"
    
    // Static property for timezones to avoid recreating the array for each instance
    private static let cachedTimeZones: [String] = Array(TimeZone.abbreviationDictionary.keys).sorted()
    var allTimeZones: [String] { Self.cachedTimeZones }
    
    @State private var scheduleType: String = "Specific Dates"
    @State private var selectedDates: Set<Date> = []
    
    // Animation states
    @State private var showHeatmapView = false
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var showingSendMessageConfirmation = false
    
    // Static date formatter to avoid repeated instantiation
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        GeometryReader { geometry in
            if(verticalSizeClass == .regular) {
                ScrollView {
                    VStack {
                        
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width:geometry.size.width * 0.5, height: geometry.size.height * 0.1)
                            .padding()
                        /*
                         Text("pencil me in")
                         .font(Font.custom("Outfit-Bold", size: geometry.size.width * 0.15))
                         .foregroundColor(Color(red: 55/255, green: 86/255, blue: 209/255))
                         .dynamicTypeSize(.medium ... .medium)
                         
                         
                         Text("simplify scheduling, maximize time")
                         .font(Font.custom("Outfit-Regular", size: geometry.size.width * 0.05))
                         */
                        
                        ZStack{
                            HStack{
                                
                                
                                TextField("Pencil in an event name..."
                                          , text: $eventName
                                )
                                .onSubmit {
                                    
                                }
                                .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.04))
                                
                                
                                Menu {
                                    ForEach(allTimeZones, id: \.self) { timeZone in
                                        Button(timeZone, action: {
                                            localTime = timeZone
                                        })
                                    }
                                } label: {
                                    makeTimeZoneView(geometry: geometry)
                                }
                                
                            }
                            .frame(width: geometry.size.width * 0.85)
                            .padding(.vertical, geometry.size.height * 0.01)
                            .padding(.horizontal, geometry.size.width * 0.02)
                            .background(Color.primary.colorInvert())
                        }
                        .compositingGroup()
                        .shadow(color: .primary.opacity(0.3), radius: geometry.size.width * 0.01, x: 0, y:0)
                        .padding(.bottom, geometry.size.height * 0.02)
                        
                        
                        Text("Pencil in a time frame...")
                            .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.04))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, geometry.size.width * 0.03)
                            .padding(.trailing, geometry.size.width * 0.03)
                        ZStack {
                            Menu {
                                ForEach(startTimes, id: \.self) { time in
                                    Button(action: {
                                        start = time
                                    }, label: {
                                        Text(formatTime(hour: time))
                                    })
                                }
                            } label: {
                                Text(formatTime(hour: start))
                                .foregroundColor(.primary)
                                .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.04))
                                .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.04)
                            }
                            .background(Color.primary.colorInvert())
                            //.padding(.horizontal, 130)
                            //.padding(.vertical, 7)
                            //.border(.black.opacity(0.3), width: 2)
                        }
                        .compositingGroup()
                        .shadow(color: .primary.opacity(0.3), radius: geometry.size.width * 0.01, x: 0, y:0)
                        
                        Text("to")
                            .padding(.vertical, 0)
                            .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.04))
                        
                        ZStack {
                            Menu {
                                ForEach(endTimes, id: \.self) { time in
                                    Button(action: {
                                        end = time
                                    }, label: {
                                        Text(formatTime(hour: time % 24))
                                    })
                                }
                            } label: {
                                Text(formatTime(hour: end % 24))
                                .foregroundColor(.primary)
                                .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.04))
                                .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.04)
                            }
                            //.border(.black.opacity(0.3), width: 2)
                            //.padding(.bottom, 20/heightFactor)
                            .background(Color.primary.colorInvert())
                            
                        }
                        .compositingGroup()
                        .shadow(color: .primary.opacity(0.3), radius: geometry.size.width * 0.01, x: 0, y:0)
                        .padding(.bottom, geometry.size.height*0.015)
                        
                        
                        HStack {
                            /*
                             Text("Pencil in Dates...")
                             .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.04))
                             .frame(maxWidth: .infinity, alignment: .leading)
                             */
                            Spacer()
                            Menu {
                                Button {
                                    scheduleType = "Specific Dates"
                                } label: {
                                    Text("Specific Dates")
                                }
                                Button {
                                    scheduleType = "Days of the Week"
                                } label: {
                                    Text("Days of the Week")
                                }
                            } label: {
                                makeMenuImageView(geometry: geometry)
                                
                                Text(scheduleType)
                                    .font(Font.custom("Inter-Bold", size: geometry.size.width * 0.04))
                                    .fixedSize()
                                    .underline()
                                    .foregroundColor(.primary)
                            }
                            .padding(.leading, geometry.size.width * 0.01)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, geometry.size.height * 0.01)
                        .padding(.leading, geometry.size.width * 0.03)
                        .padding(.trailing, geometry.size.width * 0.03)
                        
                        ZStack {
                            if scheduleType == "Specific Dates" {
                                CalendarView(selectedDates: $selectedDates)
                                    .background(Color.primary.colorInvert())
                                    .frame(width: geometry.size.width * 0.85, height: geometry.size.width * 0.9)
                            } else if scheduleType == "Days of the Week" {
                                WeeklyView()
                                //.background(Color.primary.colorInvert())
                            }
                        }
                        .padding(.bottom, geometry.size.height * 0.03)
                        .compositingGroup()
                        .shadow(color: .primary.opacity(0.3), radius: geometry.size.width * 0.01, x: 0, y:0)
                        
                        
                        Button {
                            // Validate input - make sure there are dates selected
                            if selectedDates.isEmpty {
                                // Show alert or feedback that dates need to be selected
                                return
                            }
                            
                            // Use the selected dates from the calendar and create the event
                            let event = createEvent()
                            
                            // If in Messages context, send the event as a message
                            if let messagesController = controller, let conversation = messagesController.activeConversation {
                                // Send the event as a message
                                sendEventAsMessage(event: event, controller: messagesController, conversation: conversation)
                                showingSendMessageConfirmation = true
                                
                                // Wait a bit then dismiss the confirmation
                                DispatchQueue.main.asyncAfter(deadline: .now()) {
                                    showingSendMessageConfirmation = false
                                    // Dismiss the view and return to keyboard
                                    messagesController.dismiss()
                                }
                            }
                        } label: {
                            Text("Create Event")
                                .font(Font.custom("Inter-Bold", size: geometry.size.width * 0.04))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 99/255, green: 126/255, blue: 232/255))
                                .cornerRadius(10)
                        }
                        .padding(.bottom, geometry.size.height * 0.01)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.05)
                        
                        // Show a confirmation message when the message is sent
                        if showingSendMessageConfirmation {
                            Text("Event shared in Messages")
                                .font(Font.custom("Inter-Regular", size: geometry.size.width * 0.035))
                                .foregroundColor(.green)
                                .padding(.vertical, 8)
                                .transition(.opacity)
                        }
                    }.padding()
                        .dynamicTypeSize(.large ... .large)
                        .offset(y: offset)
                        .opacity(opacity)
                }
                .ignoresSafeArea(.keyboard)
            }
            
            // Show the HeatmapView with a fade-in animation when showHeatmapView is true
            if showHeatmapView {
                HeatmapView(event: createEvent(), controller: controller)
                    .opacity(showHeatmapView ? 1 : 0)
                    .offset(y: showHeatmapView ? 0 : UIScreen.main.bounds.height)
                    .animation(.easeInOut(duration: 0.5), value: showHeatmapView)
            }
        }
    }
    
    // Helper method to create timeZone menu image and text
    private func makeTimeZoneView(geometry: GeometryProxy) -> some View {
        HStack {
            makeMenuImageView(geometry: geometry)
            Text(localTime)
                .font(Font.custom("Inter-Bold", size: geometry.size.width * 0.04))
                .underline()
                .fixedSize()
                .foregroundColor(.primary)
        }
    }
    
    // Helper method to create menu image that adapts to color scheme
    private func makeMenuImageView(geometry: GeometryProxy) -> some View {
        Image("Image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width * 0.02, height: geometry.size.width * 0.02)
            .padding(.trailing, geometry.size.width * 0.01)
            .colorInvert(colorScheme == .dark)
    }
    
    // Helper method to format time consistently
    private func formatTime(hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return Self.timeFormatter.string(from: date)
    }
    
    // Helper method to create event once instead of duplicating code
    private func createEvent() -> Event {
        let event = Event(name: eventName.isEmpty ? "Untitled Event" : eventName,
                        dates: Array(selectedDates),
                        startTime: start,
                        endTime: end,
                        timeZone: TimeZone(abbreviation: localTime) ?? TimeZone.current)
        
        // Save the event when it's created for later editing
        EventStorage.saveEvent(event)
        
        return event
    }
}


#Preview {
    return CreateEvent(controller: nil)
}

// Helper function to send the event as a message
func sendEventAsMessage(event: Event, controller: MessagesViewController, conversation: MSConversation) {
    // Create a new MSSession
    let session = MSSession()
    
    // Create a new MSMessage with the session
    let message = MSMessage(session: session)
    
    // Create a message layout
    let layout = MSMessageTemplateLayout()
    
    // Set the layout properties
    layout.image = createEventImage(for: event)
    layout.caption = "\(event.name)"
    layout.subcaption = "Pencil in your availability"
    
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
    
    // Set the URL to the message
    message.url = components.url
    
    // Insert the message into the conversation
    conversation.insert(message) { error in
        if let error = error {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
}

// Static formatter to avoid recreating DateFormatter objects
private let hourFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.locale = Locale.autoupdatingCurrent
    return formatter
}()

func formatHour(hour: Int) -> String {
    let calendar = Calendar.current
    var dateComponents = DateComponents()
    dateComponents.hour = hour
    dateComponents.minute = 0
    
    if let date = calendar.date(from: dateComponents) {
        return hourFormatter.string(from: date)
    } else {
        return "Invalid time"
    }
}

// Helper function to create an image for the event
func createEventImage(for event: Event) -> UIImage {
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
        
        // Sort the dates to ensure we get the actual first and last date
        let sortedDates = event.dates.sorted()
        
        if let firstDate = sortedDates.first, let lastDate = sortedDates.last {
            let firstDateString = dateFormatter.string(from: firstDate)
            let lastDateString = firstDate == lastDate ? "" : " to " + dateFormatter.string(from: lastDate)
            let startTime = formatHour(hour: event.startTime)
            let endTime = formatHour(hour: event.endTime)
            let timeString = "\(startTime) - \(endTime)"
            let dateTimeString = NSAttributedString(string: "\(firstDateString)\(lastDateString)\n\(timeString)", attributes: infoAttributes)
            dateTimeString.draw(at: CGPoint(x: 20, y: 60))
        }
        
        // Draw instruction
        let instructionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        let instructionString = NSAttributedString(string: "Tap to share your availability", attributes: instructionAttributes)
        instructionString.draw(at: CGPoint(x: 20, y: 160))
    }
}

// Extension to simplify colorInvert based on condition
extension View {
    @ViewBuilder
    func colorInvert(_ shouldInvert: Bool) -> some View {
        if shouldInvert {
            self.colorInvert()
        } else {
            self
        }
    }
}
