import SwiftUI
import CoreLocation

struct EventDetailView: View {
  let event: Event
  @EnvironmentObject var usersVM: UsersListViewModel
  @State private var address: String? = nil
  
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // 画像表示
        if let url = event.photoURL {
          AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
              ProgressView().frame(maxWidth: .infinity)
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
            case .failure:
              Text("Error loading image").frame(maxWidth: .infinity)
            @unknown default:
              EmptyView()
            }
          }
        }
        Text("\(event.comment)")
          .font(.headline)
          .padding()
        
        Group {
          if let address = address {
            Text(address)
              .font(.subheadline)
          } else {
            Text("\(event.latitude, specifier: "%.4f"), \(event.longitude, specifier: "%.4f")")
              .font(.subheadline)
          }
        }.padding()
        
      }
      Text("\(Date(timeIntervalSince1970: event.timestamp / 1000), formatter: dateFormatter)")
        .font(.caption)
        .padding()
      
      // 参加者のアイコンを水平スクロールで表示
      if !event.participants.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(event.participants, id: \.self) { participantID in
              if let profile = usersVM.userProfile(for: participantID), let url = profile.photoURL {
                AsyncImage(url: url) { phase in
                  switch phase {
                  case .empty:
                    ProgressView()
                  case .success(let image):
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                  case .failure:
                    Color.red
                  @unknown default:
                    EmptyView()
                  }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
              } else {
                Circle()
                  .fill(Color.gray)
                  .frame(width: 60, height: 60)
                  .overlay(
                    Text(String(participantID.prefix(1)))
                      .foregroundColor(.white)
                  )
              }
            }
          }
          .padding(.vertical, 4)
        }
      }
      
      NavigationLink(destination: StampScreen()) {
        HStack {
          Spacer()
          Text("次へ")
            .font(.headline)
            .bold()
            .foregroundColor(.white)
          Spacer()
        }
        .frame(height: 64)
        .background(Color.red)
        .cornerRadius(10)
        .padding()
      }
      
    }
    .onAppear() {
      let location = CLLocation(latitude: event.latitude, longitude: event.longitude)
      reverseGeocode(location: location) { fetchedAddress in
        DispatchQueue.main.async {
          self.address = fetchedAddress
        }
      }
    }
  }
}


private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()
