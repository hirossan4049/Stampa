//
//  ContentView.swift
//  Stampa
//
//  Created by a on 2/15/25.
//

import SwiftUI
import MultipeerConnectivity
import FirebaseAuth


struct ContentView: View {
  @State private var user: User? = nil
  @State private var isProfileSet: Bool = false
  @State private var isLoading: Bool = true
  
  var body: some View {
    Group {
      if isLoading {
        // ローディング中はプログレスビューを表示
        ProgressView("Loading...")
      } else if user == nil {
        PhoneAuthView()
      } else if !isProfileSet {
        ProfileSettingsView()
      } else {
        HomeScreenView()
      }
    }
    .onAppear(perform: setupAuthListener)
  }
  
  /// FirebaseAuth の状態を監視して、ユーザー情報とプロフィール設定状態を更新する
  func setupAuthListener() {
    Auth.auth().addStateDidChangeListener { auth, currentUser in
      self.user = currentUser
      if let user = currentUser {
        // ここでは displayName が設定されているかどうかでプロフィール設定済みか判定
        self.isProfileSet = !(user.displayName?.isEmpty ?? true)
      } else {
        self.isProfileSet = false
      }
      self.isLoading = false
    }
  }
}



#Preview {
  ContentView()
}
