//
//  ContentView.swift
//  test
//
//  Created by Don Do on 3/6/25.
//

import SwiftUI
import Messages

struct ContentView: View {
    @State var controller: MessagesViewController
    @State private var selectedDates = Set<Date>()
    var body: some View {
        VStack {
            CreateEvent(controller: controller)
                .preferredColorScheme(.light)
        }
        .padding()
    }
}
