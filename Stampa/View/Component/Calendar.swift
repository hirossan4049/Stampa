import SwiftUI

// MARK: - DayDetailView
import SwiftUI

struct DayDetailView: View {
  let day: Date
  let events: [Event]  // この日付に属するイベント一覧
  private let calendar = Calendar.current
  
  // 日付を「2023年7月15日」のようなフルフォーマットに変換
  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    return formatter.string(from: date)
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        ForEach(events) { event in
          EventCardView(event: event)
        }
      }
      .padding()
    }
    .navigationTitle(formattedDate(day))
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct EventCardView: View {
  let event: Event
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let url = event.photoURL {
        AsyncImage(url: url) { phase in
          switch phase {
          case .empty:
            ZStack {
              Color.gray.opacity(0.1)
              ProgressView()
            }
            .frame(height: 200)
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(height: 200)
              .clipped()
          case .failure:
            ZStack {
              Color.gray.opacity(0.1)
              Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
                .font(.largeTitle)
            }
            .frame(height: 200)
          @unknown default:
            EmptyView()
          }
        }
        .cornerRadius(10)
      }
      Text("Comment: \(event.comment)")
        .font(.headline)
        .lineLimit(2)
      HStack {
        Image(systemName: "location.fill")
          .foregroundColor(.secondary)
        Text("\(event.latitude, specifier: "%.4f"), \(event.longitude, specifier: "%.4f")")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      Text("Time: \(Date(timeIntervalSince1970: event.timestamp / 1000), formatter: dateFormatter)")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(UIColor.systemBackground))
    .cornerRadius(10)
    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
  }
}

struct DayDetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DayDetailView(day: Date(), events: [
        Event(
          id: "1",
          photoURL: URL(string: "https://via.placeholder.com/600x400"),
          comment: "This is a test comment for event 1.",
          latitude: 34.4511,
          longitude: 135.4566,
          timestamp: Date().timeIntervalSince1970 * 1000,
          participants: ["user1"]
        ),
        Event(
          id: "2",
          photoURL: URL(string: "https://via.placeholder.com/600x400"),
          comment: "Another event comment.",
          latitude: 34.4512,
          longitude: 135.4567,
          timestamp: Date().timeIntervalSince1970 * 1000 - 3600 * 1000,
          participants: ["user2"]
        )
      ])
    }
  }
}



// MARK: - CalendarView
struct CalendarView: View {
  let events: [Event]
  
  private let calendar = Calendar.current
  private let currentDate = Date()
  
  // 現在の月の DateInterval を取得
  private var monthInterval: DateInterval? {
    calendar.dateInterval(of: .month, for: currentDate)
  }
  
  // 現在の月の各日を生成
  private var daysInMonth: [Date] {
    guard let monthInterval = monthInterval else { return [] }
    let components = DateComponents(hour: 0, minute: 0, second: 0)
    return calendar.generateDates(inside: monthInterval, matching: components)
  }
  
  // イベントを日ごとにグループ化（timestamp はミリ秒なので変換）
  private var groupedEvents: [Date: [Event]] {
    Dictionary(grouping: events) { event in
      let eventDate = Date(timeIntervalSince1970: event.timestamp / 1000)
      return calendar.startOfDay(for: eventDate)
    }
  }
  
  var body: some View {
    VStack {
      if let monthInterval = monthInterval {
        Text(monthInterval.start, style: .date)
          .font(.headline)
      }
      
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
        ForEach(daysInMonth, id: \.self) { day in
          // セル表示用のView
          let dayCell = VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: day))")
              .font(.subheadline)
            if let eventsForDay = groupedEvents[calendar.startOfDay(for: day)],
               !eventsForDay.isEmpty {
              Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
              Text("\(eventsForDay.count)")
                .font(.caption2)
                .foregroundColor(.red)
            } else {
              Spacer().frame(height: 8)
            }
          }
            .padding(4)
          
          // イベントがある日だけ NavigationLink で詳細画面へ遷移
          if let eventsForDay = groupedEvents[calendar.startOfDay(for: day)],
             !eventsForDay.isEmpty {
            NavigationLink(destination: DayDetailView(day: day, events: eventsForDay)) {
              dayCell
            }
            .buttonStyle(PlainButtonStyle())
          } else {
            dayCell
          }
        }
      }
      .padding()
    }
  }
}

extension Calendar {
  /// 指定された DateInterval 内の日付配列を生成するヘルパー関数
  func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
    var dates: [Date] = []
    dates.append(interval.start)
    enumerateDates(startingAfter: interval.start, matching: components, matchingPolicy: .nextTime) { date, _, stop in
      if let date = date, date < interval.end {
        dates.append(date)
      } else {
        stop = true
      }
    }
    return dates
  }
}
