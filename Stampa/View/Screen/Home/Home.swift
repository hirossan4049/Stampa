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
          StampSelectView()
        }
        
        Spacer()
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
