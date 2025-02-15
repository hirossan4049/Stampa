//
//  StampaApp.swift
//  Stampa
//
//  Created by a on 2/15/25.
//

import SwiftUI

@main
struct StampaApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(SessionStore.shared)
    }
  }
}
