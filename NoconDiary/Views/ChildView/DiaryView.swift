//
//  DiaryView.swift
//  NoconDiary
//
//  Created by 金子広樹 on 2023/08/13.
//

import SwiftUI

struct DiaryView: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Entity.date, ascending: true)])
    var data: FetchedResults<Entity>
    @Environment(\.dismiss) var dismiss
    
    let date: Date
    
    let setting = Setting()
    @FocusState private var focus: Bool
    @State var editedText: String = ""                  // 編集用テキスト
    @State private var isShowDeleteAlert: Bool = false  // 削除アラート表示有無
    @State private var dateText = ""                    // 日付表示テキスト
    private let dateFormatter = DateFormatter()
    
    // スワイプで戻る動作に使用する変数
    @GestureState private var dragOffset: CGSize = .zero
    private let edgeWidth: CGFloat = 50
    private let baseDragWidth: CGFloat = 30
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(editedText.count) / \(setting.maxTextCount)")
                    .bold()
                    .font(.system(size: 20))
                TextEditor(text: $editedText)
                    .padding()
                    .focused($focus, equals: true)
                    .onChange(of: editedText) { text in
                        // 最大文字数に達したら、それ以上書き込めないようにする。
                        if text.count > setting.maxTextCount {
                            editedText.removeLast(editedText.count - setting.maxTextCount)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            HStack {
                                Button {
                                    isShowDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25)
                                        .foregroundColor(setting.black)
                                }
                                Spacer()
                            }
                        }
                        ToolbarItem(placement: .keyboard) {
                            HStack {
                                // 何故か空白のボタンを入れないとチェックマークが表示されなくなるので仕方なく入れている。
                                Button { } label: { }
                                Spacer()
                                // 完了ボタン
                                Button {
                                    focus = false
                                } label: {
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25)
                                        .foregroundColor(setting.black)
                                }
                            }
                        }
                    }
                    .navigationTitle(dateText)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            searchDiary()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            dateFormatter.locale = Locale(identifier: "ja_jp")
            dateText = "\(dateFormatter.string(from: date))"
            if editedText.isEmpty {
                focus = true
            }
        }
        .onDisappear {
            for data in data {
                if let dataDate = data.date {
                    if date ==  dataDate {
                        update(data)
                    }
                }
            }
            create()
        }
        // 戻るボタンの独自実装
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .bold()
                        .foregroundColor(setting.black)
                }
            }
        }
        .highPriorityGesture(
            // スワイプで戻る動作
            DragGesture().updating($dragOffset) { value, _, _ in
                if value.startLocation.x < edgeWidth && value.translation.width > baseDragWidth {
                    dismiss()
                }
            }
        )
        .alert("", isPresented: $isShowDeleteAlert) {
            Button("削除", role: .destructive) {
                editedText = ""
                for data in data {
                    if let dataDate = data.date {
                        if date ==  dataDate {
                            delete(data: data)
                        }
                    }
                }
            }
            Button("キャンセル", role: .cancel) {
                isShowDeleteAlert = false
            }
        } message: {
            Text("全て削除しますか？")
        }
    }
    
    /// DBに保存しているテキストを検索する
    /// - Parameters: なし
    /// - Returns: なし
    private func searchDiary() {
        for data in data {
            if let dataDate = data.date {
                if date ==  dataDate {
                    editedText = data.text ?? ""
                }
            }
        }
    }
    
    /// Modelに新規データを保存する。
    /// - Parameters: なし
    /// - Returns: なし
    private func create() {
        let newEntity = Entity(context: viewContext)
        newEntity.text = editedText
        newEntity.date = date
        do {
            try viewContext.save()
        } catch {
            fatalError("セーブに失敗")
        }
    }
    
    /// textを更新する。
    /// - Parameters: なし
    /// - Returns: なし
    private func update(_ data: FetchedResults<Entity>.Element) {
        data.text = editedText
        do {
            try viewContext.save()
        } catch {
            fatalError("セーブに失敗")
        }
    }
    
    /// textデータを削除する。
    /// - Parameters:
    ///   - data: 削除するデータ
    /// - Returns: なし
    private func delete(data: FetchedResults<Entity>.Element) {
        viewContext.delete(data)
        do {
            try viewContext.save()
        } catch {
            fatalError("セーブに失敗")
        }
    }
}

struct DiaryView_Previews: PreviewProvider {
    static var previews: some View {
        DiaryView(date: Date())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
