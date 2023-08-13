//
//  ContentView.swift
//  NoconDiary
//
//  Created by 金子広樹 on 2023/08/12.
//

import SwiftUI
import CoreData

struct CalendarDates: Identifiable {
    var id = UUID()
    var date: Date?
}

struct ContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Entity.date, ascending: true)])
    var data: FetchedResults<Entity>
    
    let setting = Setting()
    @ObservedObject var viewModel = ContentViewModel.shared
    @State private var indicateDate = Date()
    
    var year: Int {
        Calendar.current.year(for: indicateDate) ?? 0
    }           // 年
    var month: Int {
        Calendar.current.month(for: indicateDate) ?? 0
    }           // 月
    var calendarDates: [CalendarDates] {
        createCalendarDates(indicateDate)
    }           // 日付配列
    let weekdays = Calendar.current.shortWeekdaySymbols         // 曜日
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 5), count: 7) // グリッドアイテム
    
    @GestureState private var dragOffset: CGFloat = 0           // ドラッグの度量
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(String(format: "%04d / %2d", year, month))
                    .font(.system(size: 24))
                
                // 曜日
                HStack(spacing: 5) {
                    ForEach(weekdays, id: \.self) { weekday in
                        if weekday == "日" {
                            Text(weekday)
                                .frame(height: 40, alignment: .center)
                                .frame(maxWidth: UIScreen.main.bounds.width)
                                .foregroundColor(.red)
                        } else if weekday == "土" {
                            Text(weekday)
                                .frame(height: 40, alignment: .center)
                                .frame(maxWidth: UIScreen.main.bounds.width)
                                .foregroundColor(.blue)
                        } else {
                            Text(weekday)
                                .frame(height: 40, alignment: .center)
                                .frame(maxWidth: UIScreen.main.bounds.width)
                        }
                    }
                }
                .padding()
                
                // カレンダー
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(createThreeMonthDate(month), id: \.self) { date in
                            LazyVGrid(columns: columns, spacing: 0) {
                                ForEach(createCalendarDates(date)) { calendarDates in
                                    VStack(spacing: 7) {
                                        if let date = calendarDates.date,
                                           let day = Calendar.current.day(for: date) {
                                            // 日曜日は赤、土曜日は青、それ以外は黒に分ける。
                                            if isCheckHoliday(date) {
                                                CalendarDayView(date: date, day: day, color: .red)
                                            } else if isCheckSunday(calendars: createCalendarDates(date), day: day) {
                                                CalendarDayView(date: date, day: day, color: .red)
                                            } else if isCheckSaturday(calendars: createCalendarDates(date), day: day) {
                                                CalendarDayView(date: date, day: day, color: .blue)
                                            } else {
                                                CalendarDayView(date: date, day: day, color: setting.black)
                                            }
                                        } else {
                                            Text("")
                                        }
                                        ZStack {
                                            Spacer()
                                                .frame(height: createCalendarDates(date).count > 35 ? (geometry.size.height / 6) - 20 : (geometry.size.height / 5) - 20)
                                            if let date = calendarDates.date {
//                                                if !(getDataByPriority(date) == nil) {
                                                    VStack {
                                                        NavigationLink {
                                                            DiaryView(date: date)
                                                        } label: {
                                                            if isCheckDiary(date) {
                                                                Image(systemName: "pencil.circle")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(width: 35)
                                                                    .foregroundColor(setting.black)
                                                            } else {
                                                                Image("")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(width: 35)
                                                            }
                                                        }
                                                        Spacer()
                                                    }
//                                                }
                                            }
                                        }
                                    }
//                                    .contentShape(Rectangle())
//                                    .onTapGesture {
//                                        // MARK: - 日記を開く
//                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .offset(x: self.dragOffset)
                    .offset(x: -1 * geometry.size.width)
                    .gesture(
                        DragGesture()
                            .updating(self.$dragOffset, body: { (value, state, _) in
                                // 移動幅（width）のみ更新する
                                state = value.translation.width
                            })
                            .onEnded({ value in
                                let calendar = Calendar(identifier: .gregorian)
                                
                                var newDate = self.indicateDate
                                
                                // ドラッグ幅からページングを判定
                                if abs(value.translation.width) > geometry.size.width * 0.4 {
                                    newDate = (value.translation.width > 0 ? calendar.date(from: DateComponents(year: year, month: month - 1)) : calendar.date(from: DateComponents(year: year, month: month + 1))) ?? Date()
                                }
                                // 最小ページ、最大ページを超えないようチェック
                                //                        if newDate < 0 {
                                //                            newDate = 0
                                //                        } else if newDate > (self.examples.count - 1) {
                                //                            newDate = self.examples.count - 1
                                //                        }
                                self.indicateDate = newDate
                            })
                    )
                }
            }
        }
    }
    
    /// 示すカレンダーの日付が祝日か否かを判定する。
    /// - Parameters:
    ///   - date: 対象日
    /// - Returns: 祝日の場合True、それ以外の場合False。
    private func isCheckHoliday(_ date: Date) -> Bool {
        let horiday = viewModel.convertHolidayToDate(viewModel.horiday)
        if horiday.contains(date) {
            return true
        }
        return false
    }
    
    
    /// 示すカレンダーの日付が日曜日か否かを判定する。
    /// - Parameters:
    ///   - calendars: その月のカレンダー
    ///   - day: カレンダー表示の対象日
    /// - Returns: 日曜日の場合True、それ以外の場合False。
    private func isCheckSunday(calendars: [CalendarDates], day: Int) -> Bool {
        var count: Int = 0
        for calendar in calendars {
            count += 1
            if let date = calendar.date {
                if count % 7 == 1 && Calendar.current.component(.day, from: date) == day {
                    return true
                }
            }
        }
        return false
    }
    
    /// 示すカレンダーの日付が土曜日か否かを判定する。
    /// - Parameters:
    ///   - calendars: その月のカレンダー
    ///   - day: カレンダー表示の対象日
    /// - Returns: 土曜日の場合True、それ以外の場合False。
    private func isCheckSaturday(calendars: [CalendarDates], day: Int) -> Bool {
        var count: Int = 0
        for calendar in calendars {
            count += 1
            if let date = calendar.date {
                if count % 7 == 0 && Calendar.current.component(.day, from: date) == day {
                    return true
                }
            }
        }
        return false
    }
    
    /// 示すカレンダーの日付の日記が存在するか否かを判定する。
    /// - Parameters:
    ///   - date: 検索対象の日付
    /// - Returns: 存在する場合True、それ以外の場合False。
    private func isCheckDiary(_ date: Date) -> Bool {
        for data in data {
            if let dataDate = data.date,
               let dataText = data.text {
                if date == dataDate && !dataText.isEmpty {
                    return true
                }
            }
        }
        return false
    }
    
    /// 先月、今月（表示月）、来月の3ヶ月分のDateを取得。
    /// - Parameters: なし
    /// - Returns: 3ヶ月分の日付配列
    private func createThreeMonthDate(_ month: Int) -> [Date] {
        let calendar = Calendar(identifier: .gregorian)
        
        let oneMonthAgo = calendar.date(from: DateComponents(year: year, month: month - 1))
        let thisMonth = calendar.date(from: DateComponents(year: year, month: month))
        let oneMonthLater = calendar.date(from: DateComponents(year: year, month: month + 1))
        
        guard let oneMonthAgoDate = oneMonthAgo,
              let thisMonthDate = thisMonth,
              let oneMonthLaterDate = oneMonthLater else { return [] }
        
        return [oneMonthAgoDate, thisMonthDate, oneMonthLaterDate]
    }
    
    func getDataByPriority(_ date: Date) -> Entity? {
        let persistenceController = PersistenceController()
        let context = persistenceController.container.viewContext
        
        let request = NSFetchRequest<Entity>(entityName: "Entity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Entity.date, ascending: true)]
        
        let predicate = NSPredicate(format: "date >= %@", date as CVarArg)
        request.predicate = predicate
        do {
            let tasks = try context.fetch(request)
            let task = tasks.first
            return task
        }
        catch {
            fatalError()
        }
    }
}

/// カレンダー表示用の日付配列を取得
/// - Parameters:
///   - date: カレンダー表示の対象日
/// - Returns: 日付配列
func createCalendarDates(_ date: Date) -> [CalendarDates] {
    var days = [CalendarDates]()
    
    // 今月の開始日
    let startOfMonth = Calendar.current.startOfMonth(for: date)
    // 今月の日数
    let daysInMonth = Calendar.current.daysInMonth(for: date)
    
    guard let daysInMonth = daysInMonth, let startOfMonth = startOfMonth else { return [] }
    
    // 今月の全ての日付
    for day in 0..<daysInMonth {
        // 今月の開始日から1日ずつ加算
        days.append(CalendarDates(date: Calendar.current.date(byAdding: .day, value: day, to: startOfMonth)))
    }
    
    guard let firstDay = days.first, let lastDay = days.last,
          let firstDate = firstDay.date, let lastDate = lastDay.date,
          let firstDateWeekday = Calendar.current.weekday(for: firstDate),
          let lastDateWeekday = Calendar.current.weekday(for: lastDate) else { return [] }
    
    // 初週のオフセット日数
    let firstWeekEmptyDays = firstDateWeekday - 1
    // 最終週のオフセット日数
    let lastWeekEmptyDays = 7 - lastDateWeekday
    
    // 初週のオフセットを追加
    for _ in 0..<firstWeekEmptyDays {
        days.insert(CalendarDates(date: nil), at: 0)
    }
    
    // 最終週のオフセットを追加
    for _ in 0..<lastWeekEmptyDays {
        days.append(CalendarDates(date: nil))
    }
    
    return days
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
