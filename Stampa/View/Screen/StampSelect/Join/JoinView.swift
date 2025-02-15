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
  @StateObject private var eventVM = EventListViewModel()
  @State private var autoNavigate: Bool = false
  
  var body: some View {
    NavigationView {
      VStack {
        NavigationLink(
          destination: Group {
            if let event = eventVM.events.first {
              EventDetailView(event: event)
            } else {
              EmptyView()
            }
          },
          isActive: $autoNavigate,
          label: { EmptyView() }
        )
        .hidden()
        
        Text("参加中のピア:")
          .font(.headline)
          .padding()
        
        List {
          ForEach(mpManager.connectedPeers, id: \.self) { peer in
            // Use Firebase user list to match peer.displayName (assumed to be uid)
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
      .onChange(of: eventVM.events) { newEvents in
        // Automatically navigate when an event is available.
        if !newEvents.isEmpty {
          autoNavigate = true
        }
      }
    }
  }
}


#Preview {
  JoinView()
}
