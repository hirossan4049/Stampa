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
  private var handle: DatabaseHandle?
  
  // 基準タイムスタンプ（Join画面表示時の時刻を基準にする）
  private var startTimestamp: TimeInterval = Date().timeIntervalSince1970 * 1000
  
  init() {
    // 初期化時は空リストにしておく
    self.events = []
  }
  
  deinit {
    if let handle = handle {
      ref?.removeObserver(withHandle: handle)
    }
  }
  
  func fetchEvents() {
    guard let currentUser = Auth.auth().currentUser else { return }
    ref = Database.database().reference()
      .child("users")
      .child(currentUser.uid)
      .child("events")
    
    // Remove previous observer if any.
    if let handle = handle {
      ref?.removeObserver(withHandle: handle)
    }
    
    // クエリ：timestampがstartTimestamp以上のイベントのみ取得する
    let query = ref!.queryOrdered(byChild: "timestamp").queryStarting(atValue: startTimestamp)
    
    // Observe childAdded for new events.
    handle = query.observe(.childAdded, with: { [weak self] snapshot in
      guard let self = self,
            let dict = snapshot.value as? [String: Any],
            let comment = dict["comment"] as? String,
            let latitude = dict["latitude"] as? Double,
            let longitude = dict["longitude"] as? Double,
            let timestampAny = dict["timestamp"] else {
        return
      }
      
      // timestamp may be returned as a Double or dictionary (if ServerValue.timestamp() is used),
      // so convert it to Double. Here we assume it's returned as Double.
      guard let timestamp = timestampAny as? Double else {
        return
      }
      
      let photoURL: URL?
      if let urlString = dict["photoURL"] as? String {
        photoURL = URL(string: urlString)
      } else {
        photoURL = nil
      }
      
      let participants = dict["participants"] as? [String] ?? []
      let newEvent = Event(id: snapshot.key,
                           photoURL: photoURL,
                           comment: comment,
                           latitude: latitude,
                           longitude: longitude,
                           timestamp: timestamp,
                           participants: participants)
      
      DispatchQueue.main.async {
        self.events.append(newEvent)
        // Optionally, sort the events (latest first)
        self.events.sort(by: { $0.timestamp > $1.timestamp })
      }
    })
  }
  
  /// Call this when the JoinView appears to reset the event list and start timestamp.
  func resetAndStart() {
    // Clear previous events.
    DispatchQueue.main.async {
      self.events.removeAll()
    }
    // Set the startTimestamp to current time.
    startTimestamp = Date().timeIntervalSince1970 * 1000
    // Re-fetch events using the new startTimestamp.
    fetchEvents()
  }
}
