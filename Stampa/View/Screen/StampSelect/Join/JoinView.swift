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
        // Hidden NavigationLink that auto-navigates when an event is available.
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
        
        Text("参加中の友達:")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)
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
      Text("のスマホをみてね〜")
      .onAppear {
        eventVM.resetAndStart()
      }
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
