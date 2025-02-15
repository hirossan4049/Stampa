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
  @ObservedObject var session = SessionStore.shared
  
  var body: some View {
    Group {
      if session.currentUser == nil {
        // ログインしていない場合は認証画面（電話認証）を表示
        PhoneAuthView()
      } else if !session.isProfileSet {
        // ログイン済みだがプロフィール設定が未完了の場合
        ProfileSettingsView()
      } else {
        // それ以外（ログイン済みでプロフィール設定済み）の場合はホーム画面を表示
        HomeScreenView()
      }
    }
  }
}


#Preview {
  ContentView()
}
