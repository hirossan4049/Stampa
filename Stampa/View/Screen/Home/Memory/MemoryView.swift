import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct MemoryView: View {
  @State private var events: [Event] = []
  
  var body: some View {
    VStack {
      Text("メモリー")
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.title2)
        .fontWeight(.bold)
        .padding()
      
      CalendarView(events: events)
    }
    .task {
      await fetchEvents()
    }
  }
  
  func fetchEvents() async {
    guard let currentUser = Auth.auth().currentUser else { return }
    let ref = Database.database().reference()
      .child("users")
      .child(currentUser.uid)
      .child("events")
    do {
      let snapshot = try await ref.getData()
      var fetchedEvents: [Event] = []
      for child in snapshot.children {
        if let snap = child as? DataSnapshot,
           let dict = snap.value as? [String: Any],
           let comment = dict["comment"] as? String,
           let latitude = dict["latitude"] as? Double,
           let longitude = dict["longitude"] as? Double,
           let timestampAny = dict["timestamp"],
           let timestamp = timestampAny as? Double {
          
          let photoURL: URL?
          if let urlString = dict["photoURL"] as? String {
            photoURL = URL(string: urlString)
          } else {
            photoURL = nil
          }
          
          let participants = dict["participants"] as? [String] ?? []
          let event = Event(
            id: snap.key,
            photoURL: photoURL,
            comment: comment,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            participants: participants
          )
          fetchedEvents.append(event)
        }
      }
      await MainActor.run {
        self.events = fetchedEvents.sorted { $0.timestamp > $1.timestamp }
      }
    } catch {
      print("Error fetching events: \(error.localizedDescription)")
    }
  }
}

struct MemoryView_Previews: PreviewProvider {
  static var previews: some View {
    MemoryView()
  }
}
