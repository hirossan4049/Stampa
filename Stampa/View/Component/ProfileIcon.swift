//
//  ProfileIcon.swift
//  Stampa
//
//  Created by a on 2/16/25.
//
import SwiftUI

struct ProfileIcon: View {
  @ObservedObject var session = SessionStore.shared

  var body: some View {
    AsyncImage(url: session.currentUser?.photoURL) { img in
      img.image?.resizable()
    }
    .frame(width: 40, height: 40)
    .background(.gray.opacity(0.5))
    .clipShape(Circle())
  }
}
