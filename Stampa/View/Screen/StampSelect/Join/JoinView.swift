import SwiftUI
import MultipeerConnectivity

struct JoinView: View {
  @StateObject private var usersVM = UsersListViewModel()
  @ObservedObject var mpManager = MultipeerManager.shared
  @StateObject private var eventVM = EventListViewModel()
  @State private var autoNavigate: Bool = false
  @ObservedObject var session = SessionStore.shared
  
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
      .onAppear {
        if let userId = session.currentUser?.uid {
          print("USERID!!!")
          print(userId)
          mpManager.setup(userId: userId)
        }
        eventVM.resetAndStart()
      }
      Text("のスマホをみてね〜")
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
