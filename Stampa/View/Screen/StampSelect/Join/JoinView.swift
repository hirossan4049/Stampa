//
//  JoinView.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import SwiftUI
import MultipeerConnectivity

struct JoinView: View {
  @StateObject private var usersVM = UsersListViewModel()
  @ObservedObject var mpManager = MultipeerManager.shared
  
  var body: some View {
    NavigationView {
      VStack {
        Text("参加中のピア:")
          .font(.headline)
          .padding()
        
        List {
          ForEach(mpManager.connectedPeers, id: \.self) { peer in
            // Firebase のユーザー一覧から、peer.displayName（uid）に合致するプロフィールを取得
            if let profile = usersVM.users.first(where: { $0.id == peer.displayName }) {
              PeerRowView(profile: profile)
            } else {
              HStack {
                Circle()
                  .fill(Color.gray)
                  .frame(width: 40, height: 40)
                  .overlay(
                    Text(String(peer.displayName.prefix(1)))
                      .foregroundColor(.white)
                  )
                Text(peer.displayName)
                  .font(.headline)
                Spacer()
              }
            }
          }
        }
      }
      .navigationTitle("参加画面")
    }
  }
}

#Preview {
  JoinView()
}
