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
  @State private var address: String? = nil  // 逆ジオコーディング結果
  
  @StateObject private var locationManager = LocationManager()
  @ObservedObject var mpManager = MultipeerManager.shared
  
  // State for automatic navigation to EventDetailView
  @State private var navigateToDetail = false
  @State private var createdEvent: Event? = nil
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Hidden NavigationLink for navigation to EventDetailView.
          NavigationLink(destination: Group {
            if let event = createdEvent {
              EventDetailView(event: event)
            } else {
              EmptyView()
            }
          }, isActive: $navigateToDetail) {
            EmptyView()
          }
          .hidden()
          
          // Captured image or "Take Photo" button
          Group {
            if let image = capturedImage {
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .cornerRadius(12)
                .shadow(radius: 5)
            } else {
              Button {
                showingImagePicker = true
              } label: {
                Label("写真を撮る", systemImage: "camera.fill")
                  .font(.headline)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(Color.blue.opacity(0.8))
                  .foregroundColor(.white)
                  .cornerRadius(12)
              }
              .padding(.horizontal)
            }
          }
          
          // Comment TextField
          TextField("コメントを入力", text: $comment)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
          
          // Location information: 住所があれば表示し、なければ緯度・経度を表示
          Group {
            if let addr = address {
              Text("住所: \(addr)")
                .font(.caption)
                .foregroundColor(.secondary)
            } else if let location = locationManager.lastLocation {
              Text("位置: \(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                .font(.caption)
                .foregroundColor(.secondary)
            } else {
              Text("位置情報を取得中…")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          
          // Participants information
          if !mpManager.connectedPeers.isEmpty {
            Text("参加者: \(mpManager.connectedPeers.map { $0.displayName }.joined(separator: ", "))")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
          // Error message
          if !errorMessage.isEmpty {
            Text(errorMessage)
              .font(.body)
              .foregroundColor(.red)
              .padding(.horizontal)
          }
          
          // Submit button
          Button {
            submitEvent()
          } label: {
            Text("送信")
              .font(.headline)
              .bold()
              .frame(maxWidth: .infinity, minHeight: 64)
              .background(isSubmitting ? Color.gray : Color.red)
              .foregroundColor(.white)
              .cornerRadius(12)
              .padding(.horizontal)
          }
          .disabled(isSubmitting || capturedImage == nil)
          
          Spacer()
        }
        .padding(.vertical)
      }
      .navigationTitle("イベント記録")
      .sheet(isPresented: $showingImagePicker) {
        ImagePicker(image: $capturedImage, sourceType: .camera)
      }
      .onAppear {
        locationManager.requestLocation()
        showingImagePicker = true
      }
      .onChange(of: locationManager.lastLocation) { newLocation in
        if let loc = newLocation {
          reverseGeocode(location: loc) { fetchedAddress in
            DispatchQueue.main.async {
              self.address = fetchedAddress
            }
          }
        }
      }
    }
  }
  
  func submitEvent() {
    guard let image = capturedImage,
          let currentLocation = locationManager.lastLocation,
          let currentUser = Auth.auth().currentUser else {
      errorMessage = "必要な情報が不足しています"
      return
    }
    
    isSubmitting = true
    errorMessage = ""
    
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
          "participants": participants,
          "isEvent": true
        ]
        
        eventRef.setValue(eventData) { error, _ in
          isSubmitting = false
          if let error = error {
            errorMessage = "データ保存エラー: \(error.localizedDescription)"
          } else {
            print("イベントデータが正常に保存されました")
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
            capturedImage = nil
            comment = ""
            MultipeerManager.shared.sendEventData(eventData)
            navigateToDetail = true
          }
        }
      }
    }
  }
}
