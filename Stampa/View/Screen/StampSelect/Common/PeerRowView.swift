//
//  PeerRowView.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import SwiftUI

struct PeerRowView: View {
  let profile: UserProfile
  
  var body: some View {
    HStack {
      if let url = profile.photoURL {
        AsyncImage(url: url) { phase in
          if let image = phase.image {
            image.resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 40, height: 40)
              .clipShape(Circle())
          } else if phase.error != nil {
            placeholderIcon
          } else {
            ProgressView()
              .frame(width: 40, height: 40)
          }
        }
      } else {
        placeholderIcon
      }
      
      Text(profile.displayName)
        .font(.headline)
      
      Spacer()
    }
  }
  
  private var placeholderIcon: some View {
    Circle()
      .fill(Color.gray)
      .frame(width: 40, height: 40)
      .overlay(
        Text(String(profile.displayName.prefix(1)))
          .foregroundColor(.white)
      )
  }
}
