//
//  EventViewModel.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import FirebaseAuth
import FirebaseDatabase
import Combine

struct Event: Identifiable, Equatable {
  let id: String
  let photoURL: URL?
  let comment: String
  let latitude: Double
  let longitude: Double
  let timestamp: TimeInterval
  let participants: [String]
}

final class EventListViewModel: ObservableObject {
  @Published var events: [Event] = []
  private var ref: DatabaseReference?
  
  init() {
    fetchEvents()
  }
  
  func fetchEvents() {
    guard let currentUser = Auth.auth().currentUser else { return }
    ref = Database.database().reference().child("users").child(currentUser.uid).child("events")
    
    // Observe value changes for all events
    ref?.observe(.value, with: { snapshot in
      var newEvents: [Event] = []
      for child in snapshot.children {
        if let snap = child as? DataSnapshot,
           let dict = snap.value as? [String: Any],
           let comment = dict["comment"] as? String,
           let latitude = dict["latitude"] as? Double,
           let longitude = dict["longitude"] as? Double,
           let timestamp = dict["timestamp"] as? TimeInterval {
          
          let photoURL: URL?
          if let urlString = dict["photoURL"] as? String {
            photoURL = URL(string: urlString)
          } else {
            photoURL = nil
          }
          
          let participants = dict["participants"] as? [String] ?? []
          let event = Event(id: snap.key,
                            photoURL: photoURL,
                            comment: comment,
                            latitude: latitude,
                            longitude: longitude,
                            timestamp: timestamp,
                            participants: participants)
          newEvents.append(event)
        }
      }
      // Sort events by timestamp (latest first)
      DispatchQueue.main.async {
        self.events = newEvents.sorted(by: { $0.timestamp > $1.timestamp })
      }
    })
  }
}
