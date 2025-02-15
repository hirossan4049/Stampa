//
//  SessionSotre.swift
//  Stampa
//
//  Created by a on 2/15/25.
//

import FirebaseAuth
import Combine
import Foundation

final class SessionStore: ObservableObject {
  static let shared = SessionStore()
  
  @Published var currentUser: User?
  @Published var isProfileSet: Bool = false
  
  private var handle: AuthStateDidChangeListenerHandle?
  
  private init() {
    listen()
  }
  
  /// Firebase の認証状態を監視する
  func listen() {
    handle = Auth.auth().addStateDidChangeListener { auth, user in
      DispatchQueue.main.async {
        self.currentUser = user
        if let user = user {
          self.isProfileSet = !(user.displayName?.isEmpty ?? true)
        } else {
          self.isProfileSet = false
        }
      }
    }
  }
  
  deinit {
    if let handle = handle {
      Auth.auth().removeStateDidChangeListener(handle)
    }
  }
}
