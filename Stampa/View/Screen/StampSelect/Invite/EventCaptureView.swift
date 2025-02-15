import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import CoreLocation

struct EventCaptureView: View {
  @State private var comment: String = ""
  @State private var capturedImage: UIImage?
  @State private var showingImagePicker = false
  @State private var isSubmitting = false
  @State private var errorMessage: String = ""
  
  @StateObject private var locationManager = LocationManager()
  @ObservedObject var mpManager = MultipeerManager.shared
  
  // State for automatic navigation to EventDetailView
  @State private var navigateToDetail = false
  @State private var createdEvent: Event? = nil
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // Hidden NavigationLink that activates when an event is created.
        NavigationLink(
          destination: Group {
            if let event = createdEvent {
              EventDetailView(event: event)
            } else {
              EmptyView()
            }
          },
          isActive: $navigateToDetail,
          label: { EmptyView() }
        )
        .hidden()
        
        // Display captured image or "Take Photo" button.
        if let image = capturedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: 300)
        } else {
          Button("写真を撮る") {
            showingImagePicker = true
          }
          .font(.headline)
        }
        
        TextField("コメントを入力", text: $comment)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        
        // Display location info.
        if let location = locationManager.lastLocation {
          Text("位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            .font(.caption)
        } else {
          Text("位置情報を取得中...")
            .font(.caption)
        }
        
        // Display participants info.
        if !mpManager.connectedPeers.isEmpty {
          Text("参加者: \(mpManager.connectedPeers.map { $0.displayName }.joined(separator: ", "))")
            .font(.caption)
        }
        
        if isSubmitting {
          ProgressView("送信中...")
        }
        
        if !errorMessage.isEmpty {
          Text(errorMessage)
            .foregroundColor(.red)
            .padding(.horizontal)
        }
        
        Button("送信") {
          submitEvent()
        }
        .disabled(isSubmitting || capturedImage == nil)
        .padding()
        
        Spacer()
      }
      .navigationTitle("イベント記録")
      .sheet(isPresented: $showingImagePicker) {
        ImagePicker(image: $capturedImage, sourceType: .camera)
      }
      .onAppear {
        locationManager.requestLocation() // Start getting location.
      }
    }
  }
  
  /// Submits the event by uploading the image, saving event data to Realtime Database,
  /// sending the data via MP, and then navigating to EventDetailView.
  func submitEvent() {
    guard let image = capturedImage,
          let currentLocation = locationManager.lastLocation,
          let currentUser = Auth.auth().currentUser else {
      errorMessage = "必要な情報が不足しています"
      return
    }
    
    isSubmitting = true
    errorMessage = ""
    
    // 1. Upload image to Firebase Storage.
    let storageRef = Storage.storage().reference().child("eventPhotos/\(currentUser.uid)/\(UUID().uuidString).jpg")
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      errorMessage = "画像変換に失敗しました"
      isSubmitting = false
      return
    }
    
    storageRef.putData(imageData, metadata: nil) { metadata, error in
      if let error = error {
        errorMessage = "画像アップロードエラー: \(error.localizedDescription)"
        isSubmitting = false
        return
      }
      storageRef.downloadURL { url, error in
        if let error = error {
          errorMessage = "ダウンロードURL取得エラー: \(error.localizedDescription)"
          isSubmitting = false
          return
        }
        guard let downloadURL = url else {
          errorMessage = "ダウンロードURLが取得できませんでした"
          isSubmitting = false
          return
        }
        
        // 2. Create event data dictionary.
        let participants = mpManager.connectedPeers.map { $0.displayName }
        let timestamp = Date().timeIntervalSince1970 * 1000 // milliseconds
        
        let eventRef = Database.database().reference()
          .child("users")
          .child(currentUser.uid)
          .child("events")
          .childByAutoId()
        let eventID = eventRef.key ?? UUID().uuidString
        
        let eventData: [String: Any] = [
          "eventID": eventID,
          "photoURL": downloadURL.absoluteString,
          "comment": comment,
          "latitude": currentLocation.coordinate.latitude,
          "longitude": currentLocation.coordinate.longitude,
          "timestamp": ServerValue.timestamp(),
          "participants": mpManager.connectedPeers.map { $0.displayName },
          "isEvent": true
        ]
        
        eventRef.setValue(eventData) { error, _ in
          isSubmitting = false
          if let error = error {
            errorMessage = "データ保存エラー: \(error.localizedDescription)"
          } else {
            print("イベントデータが正常に保存されました")
            // Create an Event model for navigation.
            let eventId = eventRef.key ?? UUID().uuidString
            if let photoURL = URL(string: downloadURL.absoluteString) {
              let newEvent = Event(
                id: eventId,
                photoURL: photoURL,
                comment: comment,
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude,
                timestamp: timestamp,
                participants: participants
              )
              createdEvent = newEvent
            }
            // Reset fields.
            capturedImage = nil
            comment = ""
            // 4. Send event data via Multipeer.
            MultipeerManager.shared.sendEventData(eventData)
            // 5. Navigate to EventDetailView.
            navigateToDetail = true
          }
        }
      }
    }
  }
}
