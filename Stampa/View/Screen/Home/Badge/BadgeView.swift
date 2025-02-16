//
//  BadgeScreen.swift
//  Stampa
//
//  Created by a on 2/16/25.
//

import SwiftUI
import FirebaseDatabase
import FirebaseAuth

// MARK: - BadgeScreen
struct BadgeView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var events: [Event] = []
  @StateObject private var usersVM = UsersListViewModel()
  
  // とりあえず毎回計算
  private var oneCard: (Bool) {
    return events.count > 0
  }
  
  private var twoCard: (Bool) {
    return events.count / 10 > 2
  }
  
  private var threeCard: (Bool) {
    return events.count / 10 > 3
  }
  
  private var fourCard: (Bool) {
    return events.count / 10 > 4
  }
  
  private var fiveCard: (Bool) {
    return events.count / 10 > 5
  }
  
  private var count: (Int) {
    return Int(events.count/10)+1
  }
  
  var body: some View {
    VStack {
      Text("バッジ")
        .frame(maxWidth: .infinity, alignment: .leading)
        .fontWeight(.bold)
        .font(.title2)
        .padding()
      ScrollView(.horizontal) {
        HStack {
          if oneCard {
            Image("one_card")
              .resizable()
              .scaledToFit()
              .frame(width: 100)
          }
          
          if twoCard {
            Image("two_card")
              .resizable()
              .scaledToFit()
              .frame(width: 100)
          }
          
          if threeCard {
            Image("three_card")
              .resizable()
              .scaledToFit()
              .frame(width: 100)
          }
          
          if fourCard {
            Image("four_card")
              .resizable()
              .scaledToFit()
              .frame(width: 100)
          }
          
          if fiveCard {
            Image("five_card")
              .resizable()
              .scaledToFit()
              .frame(width: 100)
          }
          ZStack{}.frame(width: 80, height: 80).background(.gray.opacity(0.1)).cornerRadius(40)
          ZStack{}.frame(width: 80, height: 80).background(.gray.opacity(0.1)).cornerRadius(40)
          ZStack{}.frame(width: 80, height: 80).background(.gray.opacity(0.1)).cornerRadius(40)
          ZStack{}.frame(width: 80, height: 80).background(.gray.opacity(0.1)).cornerRadius(40)
          ZStack{}.frame(width: 80, height: 80).background(.gray.opacity(0.1)).cornerRadius(40)
          ZStack{}.frame(width: 80, height: 80).background(.gray.opacity(0.1)).cornerRadius(40)
          ZStack{}.frame(width: 80, height: 80).background(.gray.opacity(0.1)).cornerRadius(40)
        }
        .padding(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
        .task {
          await fetchEvents()
          usersVM.fetchUsers()
        }
      }
    }
  }
  
  // Firebase Realtime Database から一度だけイベントデータを取得する
  func fetchEvents() async {
    guard let currentUser = Auth.auth().currentUser else { return }
    let ref = Database.database().reference()
      .child("users")
      .child(currentUser.uid)
      .child("events")
    do {
      let snapshot = try await ref.getData()
      var fetchedEvents: [Event] = []
      for child in snapshot.children {
        if let snap = child as? DataSnapshot,
           let dict = snap.value as? [String: Any],
           let comment = dict["comment"] as? String,
           let latitude = dict["latitude"] as? Double,
           let longitude = dict["longitude"] as? Double,
           let timestampAny = dict["timestamp"],
           let timestamp = timestampAny as? Double {
          
          let photoURL: URL?
          if let urlString = dict["photoURL"] as? String {
            photoURL = URL(string: urlString)
          } else {
            photoURL = nil
          }
          
          let participants = dict["participants"] as? [String] ?? []
          let event = Event(
            id: snap.key,
            photoURL: photoURL,
            comment: comment,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            participants: participants
          )
          fetchedEvents.append(event)
        }
      }
      await MainActor.run {
        self.events = fetchedEvents
      }
    } catch {
      print("Error fetching events: \(error.localizedDescription)")
    }
  }
}

#Preview {
  BadgeView()
}
