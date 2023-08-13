//
//  ContentViewModel.swift
//  NoconDiary
//
//  Created by 金子広樹 on 2023/08/12.
//

import SwiftUI

final class ContentViewModel: ObservableObject {
    static var shared: ContentViewModel = ContentViewModel()
    
    struct Horiday {
        let year: Int
        let month: Int
        let day: Int
    }
    
    let horiday: [Horiday] = [.init(year: 2023, month: 1, day: 1),
                              .init(year: 2023, month: 1, day: 2),
                              .init(year: 2023, month: 1, day: 9),
                              .init(year: 2023, month: 2, day: 11),
                              .init(year: 2023, month: 2, day: 23),
                              .init(year: 2023, month: 3, day: 21),
                              .init(year: 2023, month: 4, day: 29),
                              .init(year: 2023, month: 5, day: 3),
                              .init(year: 2023, month: 5, day: 4),
                              .init(year: 2023, month: 5, day: 5),
                              .init(year: 2023, month: 2, day: 23),
                              .init(year: 2023, month: 7, day: 17),
                              .init(year: 2023, month: 8, day: 11),
                              .init(year: 2023, month: 9, day: 18),
                              .init(year: 2023, month: 9, day: 23),
                              .init(year: 2023, month: 10, day: 9),
                              .init(year: 2023, month: 11, day: 3),
                              .init(year: 2023, month: 11, day: 23),
                              .init(year: 2024, month: 1, day: 1),
                              .init(year: 2024, month: 1, day: 8),
                              .init(year: 2024, month: 2, day: 11),
                              .init(year: 2024, month: 2, day: 12),
                              .init(year: 2024, month: 2, day: 23),
                              .init(year: 2024, month: 3, day: 20),
                              .init(year: 2024, month: 4, day: 29),
                              .init(year: 2024, month: 5, day: 3),
                              .init(year: 2024, month: 5, day: 4),
                              .init(year: 2024, month: 5, day: 5),
                              .init(year: 2024, month: 5, day: 6),
                              .init(year: 2024, month: 7, day: 15),
                              .init(year: 2024, month: 8, day: 11),
                              .init(year: 2024, month: 8, day: 12),
                              .init(year: 2024, month: 9, day: 16),
                              .init(year: 2024, month: 9, day: 22),
                              .init(year: 2024, month: 9, day: 23),
                              .init(year: 2024, month: 10, day: 14),
                              .init(year: 2024, month: 11, day: 3),
                              .init(year: 2024, month: 11, day: 23)]
    
    /// HoridayからDateに変換する
    /// - Parameters:
    ///   - horiday: その年の祝日
    /// - Returns: Date型に変換した祝日の配列
    func convertHolidayToDate(_ horiday: [Horiday]) -> [Date] {
        var date: [Date] = []
        for horiday in horiday {
            let calendar = Calendar(identifier: .gregorian)
            let newDate = calendar.date(from: DateComponents(year: horiday.year, month: horiday.month, day: horiday.day, hour: 0, minute: 0, second: 0)) ?? Date()
            date.append(newDate)
        }
        return date
    }
}
