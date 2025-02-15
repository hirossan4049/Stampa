//
//  UserListViewModel.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import Foundation
import FirebaseDatabase

struct UserProfile: Identifiable {
  let id: String // uid
  let displayName: String
  let photoURL: URL?
}

final class UsersListViewModel: ObservableObject {
  @Published var users: [UserProfile] = []
  
  init() {
    fetchUsers()
  }
  
  func fetchUsers() {
    let ref = Database.database().reference().child("users")
    ref.observeSingleEvent(of: .value) { snapshot in
      var tempUsers: [UserProfile] = []
      for child in snapshot.children {
        if let snap = child as? DataSnapshot,
           let dict = snap.value as? [String: Any],
           let profile = dict["profile"] as? [String: Any],
           let displayName = profile["displayName"] as? String {
          
          let photoURL: URL?
          if let urlString = profile["photoURL"] as? String {
            photoURL = URL(string: urlString)
          } else {
            photoURL = nil
          }
          let userProfile = UserProfile(id: snap.key, displayName: displayName, photoURL: photoURL)
          tempUsers.append(userProfile)
        }
      }
      DispatchQueue.main.async {
        self.users = tempUsers
      }
    }
  }
}
