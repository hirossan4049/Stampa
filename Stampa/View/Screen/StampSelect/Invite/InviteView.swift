import SwiftUI
import MultipeerConnectivity

struct InviteView: View {
  @StateObject private var usersVM = UsersListViewModel()
  @ObservedObject var mpManager = MultipeerManager.shared
  @ObservedObject var session = SessionStore.shared

  // 右側の項目：接続済みなら「参加中」、未接続なら「接続」ボタンを表示
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
    NavigationStack {
      VStack {
        // discoveredPeers に該当するユーザーのみフィルタリングして List 表示
        let filteredUsers = usersVM.users.filter { profile in
          mpManager.discoveredPeers.contains(where: { $0.displayName == profile.id })
        }
        
        if !filteredUsers.isEmpty {
          List {
            ForEach(filteredUsers) { profile in
              HStack {
                PeerRowView(profile: profile)
                Spacer()
                if let peer = mpManager.discoveredPeers.first(where: { $0.displayName == profile.id }) {
                  RightItem(peer: peer)
                }
              }
              .padding(.vertical, 4)
            }
          }
        } else {
          Text("表示するユーザーがありません")
            .foregroundColor(.gray)
        }
        
        NavigationLink {
          EventCaptureView()
            .presentationDetents([.large])
        } label: {
          Text("次へ")
            .frame(maxWidth: .infinity, maxHeight: 64)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(10)
            .bold()
            .padding()
        }
      }
      .onAppear() {
        if let userId = session.currentUser?.uid {
          print(userId)
          mpManager.setup(userId: userId)
        }
      }
      .navigationTitle("参加画面")
    }
  }
}

#Preview {
  InviteView()
}
