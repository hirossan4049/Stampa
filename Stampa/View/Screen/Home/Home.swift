//
//  Home.swift
//  Stampa
//
//  Created by a on 2/15/25.
//
import SwiftUI
import FirebaseAuth


struct HomeScreenView: View {
  @ObservedObject var session = SessionStore.shared
  
  //  @StateObject var mpManager = MultipeerManager()
  @State private var messageToSend: String = ""
  @State private var isModalPresented = false
  
  var body: some View {
    NavigationView {
      VStack {
        AsyncImage(url: session.currentUser?.photoURL) { img in
          img.image?.resizable()
        }
        .frame(width: 32, height: 32)
        //        List(mpManager.connectedPeers, id: \.self) { peer in
        //          Text(peer.displayName)
        //        }
        //        .listStyle(PlainListStyle())
        
        TextField("メッセージを入力", text: $messageToSend)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding()
        
        //        Button("送信") {
        //          mpManager.send(message: messageToSend)
        //          messageToSend = ""
        //        }
        //        .padding()
        
        Button("モーダルを表示") {
          isModalPresented = true
        }
        .sheet(isPresented: $isModalPresented) {
          //          NavigationModalView()
          MasterSelectView()
        }
        
        Button("ろぐあうと") {
          do {
            try Auth.auth().signOut()
          }
          catch let error as NSError {
            print(error)
          }
        }
      }
      .navigationTitle("Multipeer Chat")
    }
  }
}

struct MasterSelectView: View {
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
