//
//  StampSelect.swift
//  Stampa
//
//  Created by a on 2/16/25.
//
import SwiftUI


struct StampSelectView: View {
  @ObservedObject var session = SessionStore.shared
  
  var body: some View {
    NavigationView {
      VStack {
        Text("うんこします")
          .frame(height: 64)
          .padding()
        HStack {
          NavigationLink {
            InviteView()
          } label: {
            Text("集める")
              .frame(maxWidth: .infinity, maxHeight: 82)
              .foregroundStyle(.white)
              .background(.red)
              .cornerRadius(10)
              .bold()
              .contentShape(Rectangle())
          }
          NavigationLink {
            JoinView()
          } label: {
            Text("参加する")
              .frame(maxWidth: .infinity, maxHeight: 82)
              .foregroundStyle(.white)
              .background(.orange)
              .cornerRadius(10)
              .bold()
              .contentShape(Rectangle())
          }
        }
        .padding()
        Spacer()
      }
      .onAppear {
        // Firebase の認証済みユーザーがいる場合、その UID を使って Multipeer のセットアップを実施
        if let user = session.currentUser {
          MultipeerManager.shared.setup(userId: user.uid)
          print("Multipeer setup called with user id: \(user.uid)")
        } else {
          print("ユーザーがログインしていないため、Multipeerのセットアップをスキップします。")
        }
      }
    }
  }
}
