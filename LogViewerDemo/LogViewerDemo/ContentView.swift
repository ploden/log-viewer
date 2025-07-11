//
//  ContentView.swift
//  LogViewerDemo
//
//  Created by Philip Loden on 7/9/25.
//

import SwiftUI
import OSLog

struct ContentView: View {
    private let logger = Logger(subsystem: "com.logviewer.app", category: "UI")

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            HStack {
                Button(action: {
                    logger.info("User clicked play button")
                }) {
                    Image(systemName: "play.fill")
                }

                Button(action: {
                    logger.notice("User clicked trash can button")
                }) {
                    Image(systemName: "trash")
                }
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
