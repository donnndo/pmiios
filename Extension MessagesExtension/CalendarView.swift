//
//  Calendar.swift
//  test
//
//  Created by Don Do on 3/6/25.
//

import SwiftUI

struct CalendarView: View {
    @State var selectedMonth = Date().month
    @State var selectedYear = Date().year
    @Binding var selectedDates: Set<Date>
    @State private var initialSelectedDates: Set<Date> = []
    @State private var affectedDates = Set<Date>()
    
    @State private var dragStart: CGPoint = .zero
    @State private var dragCurrent: CGPoint = .zero
    @State private var dateFrames: [Date: CGRect] = [:]
    @State private var isSelecting: Bool = false
    
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        GeometryReader { geometry in
            let totalHorizontalPadding: CGFloat = 32 // 16 padding on each side
            let availableWidth = geometry.size.width - totalHorizontalPadding
            let cellSize = max(availableWidth / 8.5, 10) // Minimum cell size of 10
            let gridSpacing = cellSize * 0.25
            let columns = Array(repeating: GridItem(.fixed(cellSize)), count: 7)
            let days: [Date] = Date.datesInCalendarMonth(year: selectedYear, month: selectedMonth)
            
            VStack {
                // Month navigation
                HStack {
                    Button {
                        selectedMonth -= 1
                        if selectedMonth < 1 {
                            selectedYear -= 1
                            selectedMonth = 12
                        }
                    } label: {
                        ZStack {
                            Color.clear // For tap area expansion
                            Image("left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: cellSize * 0.25, height: cellSize * 0.35)
                        }
                        .padding(.horizontal, cellSize * 0.1)
                    }
                    .frame(width: cellSize * 0.5, height: cellSize * 0.5)
                    .contentShape(Rectangle())
                    Spacer()
                    Text("\(Date.monthString(month: selectedMonth)) \(String(selectedYear))")
                        .font(Font.custom("Inter-Bold", size: cellSize * 0.4))
                    Spacer()
                    Button {
                        selectedMonth += 1
                        if selectedMonth > 12 {
                            selectedYear += 1
                            selectedMonth = 1
                        }
                    } label: {
                        ZStack {
                            Color.clear // For tap area expansion
                            Image("right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: cellSize * 0.25, height: cellSize * 0.35)
                        }
                        .padding(.horizontal, cellSize * 0.1)
                    }
                    .frame(width: cellSize * 0.5, height: cellSize * 0.5)
                    .contentShape(Rectangle())
                }
                .padding()
                
                // Days of week
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(Font.custom("Inter-Bold", size: cellSize * 0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, cellSize * 0.25)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(days, id: \.self) { day in
                        Text("\(day.day)")
                            .font(Font.custom("Inter-Bold", size: cellSize * 0.375))
                            .foregroundColor(day.month == selectedMonth ? .primary : .gray)
                            .frame(width: cellSize, height: cellSize)
                            .background(background(for: day))
                            .cornerRadius(cellSize * 0.25)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(
                                            key: DateFramePreferenceKey.self,
                                            value: [day: geo.frame(in: .named("CalendarSpace"))]
                                        )
                                }
                            )
                    }
                }
                .onPreferenceChange(DateFramePreferenceKey.self) { self.dateFrames = $0 }
                .coordinateSpace(name: "CalendarSpace")
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("CalendarSpace"))
                        .onChanged { value in
                            handleDragChange(value: value)
                        }
                        .onEnded { _ in
                            dragStart = .zero
                            dragCurrent = .zero
                            affectedDates.removeAll()
                        }
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func background(for date: Date) -> some View {
        Group {
            if date.month == selectedMonth {
                if selectedDates.contains(date) {
                    Color(red: 99/255, green: 126/255, blue: 232/255)
                } else {
                    Color.clear
                }
            } else {
                Color.clear
            }
        }
    }
    
    private func toggleDate(_ date: Date) {
        guard date.month == selectedMonth else { return }
        selectedDates.toggle(date)
    }
    
    private func handleDragChange(value: DragGesture.Value) {
        if dragStart == .zero {
            dragStart = value.startLocation
            initialSelectedDates = selectedDates
            if let initialDate = dateAtLocation(value.startLocation) {
                isSelecting = !initialSelectedDates.contains(initialDate)
            }
        }
        dragCurrent = value.location
        updateSelection()
    }
    
    private func updateSelection() {
        guard dragStart != .zero else { return }
        
        let dragRect = dragRectangle
        let newAffectedDates = Set(dateFrames.filter {
            dragRect.intersects($0.value) && $0.key.month == selectedMonth
        }.map(\.key))
        
        // Get added/removed dates
        let addedDates = newAffectedDates.subtracting(affectedDates)
        let removedDates = affectedDates.subtracting(newAffectedDates)
        
        var newSelection = selectedDates
        
        // Apply action to newly added dates
        for date in addedDates {
            if isSelecting {
                newSelection.insert(date)
            } else {
                newSelection.remove(date)
            }
        }
        
        // Revert removed dates to initial state
        for date in removedDates {
            if initialSelectedDates.contains(date) {
                newSelection.insert(date)
            } else {
                newSelection.remove(date)
            }
        }
        
        selectedDates = newSelection
        affectedDates = newAffectedDates // Update tracked affected dates
    }
    
    private func dateAtLocation(_ location: CGPoint) -> Date? {
        dateFrames.first { (date, frame) in
            frame.contains(location) && date.month == selectedMonth
        }?.key
    }
    
    private var dragRectangle: CGRect {
        CGRect(
            x: min(dragStart.x, dragCurrent.x),
            y: min(dragStart.y, dragCurrent.y),
            width: abs(dragCurrent.x - dragStart.x),
            height: abs(dragCurrent.y - dragStart.y)
        )
    }
    
    func returnSelectedDates() -> [Date]{
        return Array(selectedDates)
    }
}

#Preview {
    CalendarView(selectedDates: .constant(Set<Date>()))
}



struct DateFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Date: CGRect] = [:]
    
    static func reduce(value: inout [Date: CGRect], nextValue: () -> [Date: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}

extension Date {
    
    static func datesInCalendarMonth(year: Int, month: Int) -> [Date] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        let calendar = Calendar.current
        
        guard let startOfMonth = calendar.date(from: components),
              //let monthRange = calendar.range(of: .day, in: .month, for: startOfMonth),
              let weekIntervalStart = calendar.dateInterval(of: .weekOfMonth, for: startOfMonth)?.start
        else {
            return []
        }
        
        var dates: [Date] = []
        var currentDate = weekIntervalStart
        while dates.count < 42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    static func monthString(month: Int) -> String {
        switch month {
        case 1: return "January"
        case 2: return "February"
        case 3: return "March"
        case 4: return "April"
        case 5: return "May"
        case 6: return "June"
        case 7: return "July"
        case 8: return "August"
        case 9: return "September"
        case 10: return "October"
        case 11: return "November"
        case 12: return "December"
        default: return "ERROR"
        }
    }
    
    
}
