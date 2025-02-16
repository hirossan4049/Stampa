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
  @State private var messageToSend: String = ""
  @State private var isModalPresented = false
  
  var body: some View {
    ZStack{
      NavigationView {
        ScrollView {
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
          MemoryView()
          BadgeView()
        }
        .frame(maxWidth: .infinity)
        .overlay(
          ProfileIcon()
            .padding(.trailing, 20)
            .offset(x: 0, y: 0), alignment: .topTrailing)
      }
      
    }
  }
}

#Preview {
  HomeScreenView()
    .background(.red)
}
