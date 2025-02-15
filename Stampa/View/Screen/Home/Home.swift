//
//  Home.swift
//  Stampa
//
//  Created by a on 2/15/25.
//
import SwiftUI


struct HomeScreenView: View {
  @StateObject var mpManager = MultipeerManager()
  @State private var messageToSend: String = ""
  @State private var isModalPresented = false
  
  var body: some View {
    NavigationView {
      VStack {
        // 接続中のピアをリスト表示
        List(mpManager.connectedPeers, id: \.self) { peer in
          Text(peer.displayName)
        }
        .listStyle(PlainListStyle())
        
        // メッセージ入力フィールド
        TextField("メッセージを入力", text: $messageToSend)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding()
        
        // 送信ボタン
        Button("送信") {
          mpManager.send(message: messageToSend)
          messageToSend = ""
        }
        .padding()
        
        Button("モーダルを表示") {
          isModalPresented = true
        }
        .sheet(isPresented: $isModalPresented) {
          //          NavigationModalView()
          MasterSelectView()
        }
      }
      .navigationTitle("Multipeer Chat")
    }
  }
}

struct MasterSelectView: View {
  var body: some View {
    
    NavigationView{
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
          Button {
            
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
    }
  }
}


struct InviteView: View {
  var body: some View {
    NavigationView{
      HStack {
        Text("name")
        Text("name")
        Text("name")
        Text("name")
        Text("name")
        Text("name")
      }
    }
  }
}

struct JoinView: View {
  var body: some View {
    NavigationView{
      HStack {
        Text("")
      }
    }
  }
}
