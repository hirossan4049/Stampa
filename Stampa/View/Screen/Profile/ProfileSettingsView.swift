//
//  ProfileSettingsView.swift
//  Stampa
//
//  Created by a on 2/15/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage

struct ProfileSettingsView: View {
  @State private var displayName: String = ""
  @State private var profileImage: Image? = nil
  @State private var selectedUIImage: UIImage? = nil
  @State private var showingImagePicker: Bool = false
  @State private var isSaving: Bool = false
  @State private var errorMessage: String = ""
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        if let profileImage = profileImage {
          profileImage
            .resizable()
            .scaledToFill()
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .shadow(radius: 4)
        } else {
          Circle()
            .fill(Color.gray)
            .frame(width: 120, height: 120)
            .overlay(
              Text("No Image")
                .foregroundColor(.white)
            )
        }
        
        Button(action: {
          showingImagePicker = true
        }) {
          Text("Change Photo")
            .font(.headline)
        }
        .padding(.top, 5)
        
        TextField("Display Name", text: $displayName)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        
        if isSaving {
          ProgressView()
        }
        
        if !errorMessage.isEmpty {
          Text(errorMessage)
            .foregroundColor(.red)
            .padding(.horizontal)
        }
        
        Button(action: {
          saveProfile()
        }) {
          Text("Save")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
        }
        
        Spacer()
      }
      .navigationTitle("Profile Settings")
      .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
        ImagePicker(image: $selectedUIImage)
      }
    }
  }
  
  /// 選択した画像を SwiftUI の Image に変換
  func loadImage() {
    if let uiImage = selectedUIImage {
      profileImage = Image(uiImage: uiImage)
    }
  }
  
  /// プロフィール情報の保存処理
  /// - ユーザーが選択した画像があれば Firebase Storage にアップロードし、取得した URL を使って FirebaseAuth の displayName および photoURL を更新
  /// - 画像がなければ displayName のみ更新
  func saveProfile() {
    guard let user = Auth.auth().currentUser else {
      errorMessage = "ユーザーがログインしていません。"
      return
    }
    
    isSaving = true
    errorMessage = ""
    
    func updateProfile(with photoURL: URL?) {
      let changeRequest = user.createProfileChangeRequest()
      changeRequest.displayName = displayName
      if let photoURL = photoURL {
        changeRequest.photoURL = photoURL
      }
      changeRequest.commitChanges { error in
        isSaving = false
        if let error = error {
          errorMessage = "プロフィール更新エラー: \(error.localizedDescription)"
          print(errorMessage)
        } else {
          print("プロフィール更新成功!")
        }
      }
    }
    
    if let uiImage = selectedUIImage,
       let imageData = uiImage.jpegData(compressionQuality: 0.8) {
      
      let storageRef = Storage.storage().reference().child("profileImages/\(user.uid)/profile.jpg")
      storageRef.putData(imageData, metadata: nil) { metadata, error in
        if let error = error {
          isSaving = false
          errorMessage = "画像アップロードエラー: \(error.localizedDescription)"
          print(errorMessage)
          return
        }
        storageRef.downloadURL { url, error in
          if let error = error {
            isSaving = false
            errorMessage = "ダウンロードURL取得エラー: \(error.localizedDescription)"
            print(errorMessage)
            return
          }
          updateProfile(with: url)
        }
      }
    } else {
      updateProfile(with: nil)
    }
  }
}

#Preview {
  ProfileSettingsView()
}
