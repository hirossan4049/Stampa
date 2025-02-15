import SwiftUI

struct StampSelectView: View {
  @ObservedObject var session = SessionStore.shared
  @State private var showInviteSheet = false
  @State private var showJoinSheet = false
  
  var body: some View {
    NavigationStack {
      VStack {
        Text("うんこします")
          .frame(maxWidth: .infinity, maxHeight: 32, alignment: .leading)
          .padding()
        HStack {
          Button("集める") {
            showInviteSheet = true
          }
          .frame(maxWidth: .infinity, maxHeight: 82)
          .foregroundColor(.white)
          .background(Color.red)
          .cornerRadius(10)
          .bold()
          
          Button("参加する") {
            showJoinSheet = true
          }
          .frame(maxWidth: .infinity, maxHeight: 82)
          .foregroundColor(.white)
          .background(Color.orange)
          .cornerRadius(10)
          .bold()
        }
        .padding()
        Spacer()
      }
    }
    .presentationDetents([.height(200)])
    .sheet(isPresented: $showInviteSheet) {
      InviteView()
        .presentationDetents([.large])
    }
    .sheet(isPresented: $showJoinSheet) {
      JoinView()
        .presentationDetents([.large])
    }
  }
}

#Preview {
  StampSelectView()
}
