//
//  WeeklyView.swift
//  test
//
//  Created by Don Do on 3/7/25.
//

import SwiftUI

struct WeeklyView: View {
    @State var selectedDays: [String] = []
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Select Days of Week")
                .font(Font.custom("Inter-Bold", size: 18))
                .padding(.bottom, 5)
            
            ForEach(daysOfWeek, id: \.self) { day in
                Button(action: {
                    if selectedDays.contains(day) {
                        selectedDays.removeAll(where: { $0 == day })
                    } else {
                        selectedDays.append(day)
                    }
                }) {
                    HStack {
                        Text(day)
                            .font(Font.custom("Inter-Regular", size: 16))
                            .foregroundColor(.black)
                        Spacer()
                        if selectedDays.contains(day) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(red: 55/255, green: 86/255, blue: 209/255))
                        }
                    }
                    .padding()
                    .background(selectedDays.contains(day) ?
                                Color(red: 99/255, green: 126/255, blue: 232/255).opacity(0.1) :
                                    Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding()
    }
}
