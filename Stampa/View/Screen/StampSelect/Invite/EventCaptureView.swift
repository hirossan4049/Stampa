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
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // 撮影した画像を表示（なければ「写真を撮る」ボタンを表示）
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
        
        // 位置情報の表示（取得中なら ProgressView を表示）
        if let location = locationManager.lastLocation {
          Text("位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            .font(.caption)
        } else {
          Text("位置情報を取得中...")
            .font(.caption)
        }
        
        // 参加者一覧の簡易表示
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
        locationManager.requestLocation() // 位置情報の取得を開始
      }
    }
  }
  
  /// イベント（写真、コメント、位置、参加者情報）を Firebase に送信する
  func submitEvent() {
    guard let image = capturedImage,
          let currentLocation = locationManager.lastLocation,
          let currentUser = Auth.auth().currentUser else {
      errorMessage = "必要な情報が不足しています"
      return
    }
    
    isSubmitting = true
    errorMessage = ""
    
    // 1. 画像を Firebase Storage にアップロード
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
        
        // 2. イベントデータの作成（"isEvent": true を追加）
        var eventData: [String: Any] = [
          "photoURL": downloadURL.absoluteString,
          "comment": comment,
          "latitude": currentLocation.coordinate.latitude,
          "longitude": currentLocation.coordinate.longitude,
          "timestamp": ServerValue.timestamp(),
          "participants": mpManager.connectedPeers.map { $0.displayName },
          "isEvent": true
        ]
        
        // 3. Realtime Database にイベントデータを書き込み (/users/<uid>/events/<autoId>)
        let eventRef = Database.database().reference()
          .child("users")
          .child(currentUser.uid)
          .child("events")
          .childByAutoId()
        eventRef.setValue(eventData) { error, _ in
          isSubmitting = false
          if let error = error {
            errorMessage = "データ保存エラー: \(error.localizedDescription)"
          } else {
            print("イベントデータが正常に保存されました")
            // 保存成功後、画面をリセット
            capturedImage = nil
            comment = ""
            // 4. MP 経由でイベントデータを送信（参加者側にも記録してもらう）
            MultipeerManager.shared.sendEventData(eventData)
          }
        }
      }
    }
  }
}
