//
//  PhoneAuth.swift
//  Stampa
//
//  Created by a on 2/15/25.
//

import SwiftUI
import FirebaseAuth

struct PhoneAuthView: View {
  @State private var phoneNumber: String = ""
  @State private var verificationCode: String = ""
  @State private var verificationID: String?
  @State private var showVerificationField = false
  @State private var errorMessage: String = ""
  
  var body: some View {
    VStack(spacing: 20) {
      if !showVerificationField {
        TextField("電話番号（例: +819012345678）", text: $phoneNumber)
          .keyboardType(.phonePad)
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(8)
          .padding(.horizontal)
        
        Button(action: {
          sendVerificationCode()
        }) {
          Text("認証コードを送信")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
        }
      } else {
        TextField("認証コードを入力", text: $verificationCode)
          .keyboardType(.numberPad)
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(8)
          .padding(.horizontal)
        
        Button(action: {
          verifyCode()
        }) {
          Text("認証")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
        }
      }
      
      if !errorMessage.isEmpty {
        Text(errorMessage)
          .foregroundColor(.red)
          .padding()
      }
      
      Spacer()
    }
    .padding(.top)
  }
  
  /// 電話番号に認証コードを送信
  private func sendVerificationCode() {
    // 入力チェックなど必要に応じて追加してください
    PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
      if let error = error {
        self.errorMessage = "認証コード送信エラー: \(error.localizedDescription)"
        return
      }
      // 成功した場合、認証ID を保持し、認証コード入力画面へ遷移
      self.verificationID = verificationID
      self.showVerificationField = true
      self.errorMessage = ""
    }
  }
  
  /// 入力された認証コードでサインイン
  private func verifyCode() {
    guard let verificationID = verificationID else {
      self.errorMessage = "認証IDが取得できていません。"
      return
    }
    let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
    Auth.auth().signIn(with: credential) { authResult, error in
      if let error = error {
        self.errorMessage = "サインインエラー: \(error.localizedDescription)"
        return
      }
      // サインイン成功時の処理
      print("サインイン成功: \(authResult?.user.uid ?? "")")
      self.errorMessage = ""
      // 次の画面に遷移するなど、適切な処理を実施
    }
  }
}


#Preview {
  PhoneAuthView()
}
