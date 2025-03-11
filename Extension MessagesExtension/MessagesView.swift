//
//  MessageView.swift
//  PencilMeIn
//
//  Created by Don Do on 2/20/25.
//

import SwiftUI
import Messages

struct MessagesView: View {
    var controller: MessagesViewController
    @State private var showingSentEvents = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    showingSentEvents = true
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                        Text("My Events")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 55/255, green: 86/255, blue: 209/255))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .padding(.trailing, 15)
                .padding(.top, 10)
            }
            
            ContentView(controller: controller)
                .onOpenURL{ url in
                }
                .preferredColorScheme(.light)
        }
        .fullScreenCover(isPresented: $showingSentEvents) {
            SentEventsView(controller: controller)
        }
    }
    
    func sendMessage() {
        guard let conversation = controller.activeConversation else { return }
        let session = MSSession()
        let message = MSMessage(session: session)
        let layout = MSMessageTemplateLayout()
        layout.caption = "Hello from SwiftUI!"
        message.layout = layout

        conversation.insert(message) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
}
