import SwiftUI
import FirebaseDatabase
import FirebaseAuth

// MARK: - StampCellView
struct StampCellView: View {
  let userID: String?
  let count: Int?
  let profile: UserProfile?
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      if let profile = profile, let url = profile.photoURL {
        AsyncImage(url: url) { phase in
          if let image = phase.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else if phase.error != nil {
            Color.red
          } else {
            ProgressView()
          }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        
        // バッジとして「X回目」を表示
        Text("\(count ?? 0)")
          .font(.caption2)
          .padding(6)
          .background(Color.blue)
          .foregroundColor(.white)
          .clipShape(Circle())
          .offset(x: 5, y: -5)
      } else {
        Circle()
          .fill(Color.gray.opacity(0.1))
          .frame(width: 64, height: 64)
          .overlay(
            Text(String(userID?.prefix(1) ?? ""))
              .foregroundColor(.white)
          )
      }
    }
  }
}

// MARK: - StampScreen
struct StampScreen: View {
  @Environment(\.dismiss) private var dismiss
  @State private var events: [Event] = []
  @StateObject private var usersVM = UsersListViewModel()
  
  private var latestStamps: [(id: String, count: Int)]? {
    let sortedEvents = events.sorted { $0.timestamp > $1.timestamp }
    var rtv: [(id: String, count: Int)] = []
    if sortedEvents.count == 0 {return nil}
    for i in 0...(sortedEvents.count < 10 ? sortedEvents.count : 9-sortedEvents.count%10) {
      let event = sortedEvents[i]
      guard let participantID = event.participants.first else { continue }
      
      let count = sortedEvents.filter{$0.timestamp >= event.timestamp}.reduce(0) { partialResult, event in
        event.participants.contains(participantID) ? partialResult + 1 : partialResult
      }
      rtv.append((id: participantID, count: count))
    }
    return rtv
  }
  
  private var count: (Int) {
    return Int(events.count/10)+1
  }
  
  var body: some View {
    NavigationStack {
      Spacer()
      VStack {
        VStack{
          Text("No.\(count)")
            .frame(maxWidth: .infinity, alignment: .trailing)

        LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 12) {
          if let stamps = latestStamps {
            ForEach(0..<(stamps.count ?? 0)) { i in
              StampCellView(
                userID: stamps[i].id,
                count: stamps[i].count,
                profile: usersVM.userProfile(for: stamps[i].id)
              )
            }
            ForEach(0..<(10-stamps.count)) { i in
              /// TODO
              StampCellView(userID: nil, count: nil, profile: nil)
            }
          } else {
            ForEach(0..<10) { i in
              /// TODO
              StampCellView(userID: nil, count: nil, profile: nil)
            }
          }
        }}
        .padding(.init(top: 26, leading: 24, bottom: 32, trailing: 24))
        .background(.gray.opacity(0.1))
        .cornerRadius(6)
        .padding()
        
        Spacer()
        Button {
          dismiss()
        } label: {
          Text("閉じる")
            .frame(maxWidth: .infinity, maxHeight: 64)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(10)
            .bold()
            .padding()
        }
      }
      .task {
        await fetchEvents()
        usersVM.fetchUsers()
      }
    }
  }
  
  // Firebase Realtime Database から一度だけイベントデータを取得する
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
        self.events = fetchedEvents
      }
    } catch {
      print("Error fetching events: \(error.localizedDescription)")
    }
  }
}

struct StampScreen_Previews: PreviewProvider {
  static var previews: some View {
    StampScreen()
  }
}
