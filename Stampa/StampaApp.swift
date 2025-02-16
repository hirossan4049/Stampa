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
  @StateObject var usersVM = UsersListViewModel()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(SessionStore.shared)
        .environmentObject(usersVM)
    }
  }
}
