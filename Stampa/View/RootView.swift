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
        PhoneAuthView()
      } else if !session.isProfileSet {
        ProfileSettingsView()
      } else {
        HomeScreenView()
      }
    }
  }
}

#Preview {
  ContentView()
}
