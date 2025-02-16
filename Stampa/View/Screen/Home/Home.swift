import SwiftUI
import FirebaseAuth

struct HomeScreenView: View {
  @ObservedObject var session = SessionStore.shared
  @State private var isModalPresented = false
  
  var body: some View {
    ZStack {
      NavigationView {
        ScrollView {
          // コンテンツ部分
          MemoryView()
          BadgeView()
        }
        .frame(maxWidth: .infinity)
        .overlay(profileIconOverlay, alignment: .topTrailing)
      }
      
      // 画面右下のフローティング＋ボタン
      floatingModalButton
    }
  }
  
  // MARK: - Floating Button
  
  private var floatingModalButton: some View {
    Button(action: {
      isModalPresented = true
    }) {
      Image(systemName: "plus")
        .font(.system(size: 24))
        .foregroundColor(.white)
        .padding()
        .background(Color.orange)
        .clipShape(Circle())
        .shadow(radius: 4)
    }
    .padding(.bottom, 28)
    .padding(.trailing, 28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    .sheet(isPresented: $isModalPresented) {
      StampSelectView()
    }
  }
  
  // MARK: - Profile Icon with Menu
  
  private var profileIconOverlay: some View {
    Menu {
      Button {
        signOutUser()
      } label: {
        Label("ログアウト", systemImage: "arrow.backward.square")
      }
    } label: {
      ProfileIcon()
        .padding(.trailing, 20)
    }
  }
  
  // MARK: - Methods
  
  private func signOutUser() {
    do {
      try Auth.auth().signOut()
    } catch {
      print("ログアウトエラー: \(error.localizedDescription)")
    }
  }
}

#Preview {
  HomeScreenView()
    .background(Color.red)
}
