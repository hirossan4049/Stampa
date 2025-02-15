//
//  EventDetailView.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import SwiftUI

struct EventDetailView: View {
  let event: Event
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if let url = event.photoURL {
          AsyncImage(url: url) { phase in
            if let image = phase.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            } else if phase.error != nil {
              Text("Error loading image")
            } else {
              ProgressView()
            }
          }
          .frame(maxWidth: .infinity)
        }
        Text("Comment: \(event.comment)")
          .font(.headline)
        Text("Location: \(event.latitude), \(event.longitude)")
          .font(.subheadline)
        Text("Participants: \(event.participants.joined(separator: ", "))")
          .font(.caption)
        Text("Timestamp: \(Date(timeIntervalSince1970: event.timestamp / 1000), formatter: dateFormatter)")
          .font(.caption)
      }
      .padding()
    }
    .navigationTitle("Event Detail")
  }
}

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()
