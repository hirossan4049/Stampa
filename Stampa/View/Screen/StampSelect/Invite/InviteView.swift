//
//  InviteView.swift
//  Stampa
//
//  Created by a on 2/16/25.
//
import SwiftUI
import MultipeerConnectivity

struct InviteView: View {
  @StateObject private var usersVM = UsersListViewModel()
  @ObservedObject var mpManager = MultipeerManager.shared
  
  func RightItem(peer: MCPeerID) -> some View {
    ZStack {
      if mpManager.connectedPeers.contains(peer) {
        Text("参加中")
          .font(.caption)
          .foregroundColor(.green)
      } else {
        Button("接続") {
          mpManager.invite(peer: peer)
        }
        .buttonStyle(BorderlessButtonStyle())
      }
    }
  }
  
  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(usersVM.users) { profile in
            HStack {
              PeerRowView(profile: profile)
              Spacer()
              
//               MCPeerID の displayName をユーザーの uid として利用している前提
              if let peer = mpManager.discoveredPeers.first(where: { $0.displayName == profile.id }) {
                RightItem(peer: peer)
              } else {
                Text("未発見")
                  .font(.caption)
                  .foregroundColor(.gray)
              }
            }
            .padding(.vertical, 4)
          }
        }
        
        NavigationLink {
          EventCaptureView()
        } label: {
          Text("次へ")
            .frame(maxWidth: .infinity, maxHeight: 42)
            .foregroundStyle(.white)
            .background(.red)
            .cornerRadius(10)
            .bold()
            .contentShape(Rectangle())
        }
      }
    }
  }
}

#Preview{
  InviteView()
}
