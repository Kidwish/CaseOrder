//
//  ContentView.swift
//  CaseOrder
//
//  Created by KidwishZhu on 2024/10/7.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var dishes: [String] = UserDefaults.standard.stringArray(forKey: "dishes") ?? []
    @State private var newDishName = ""
    @State private var selectedDishes: [String] = []
    @State private var loadedDishesCount = 20 // 初始加载数量
    @State private var isLoadingMore = false
    @State private var searchQuery = ""
    @State private var sortAscending = true // 排序状态

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .onChange(of: selectedDate) { _ in
                        loadSelectedDishesForDate()
                    }

                TextField("搜索菜品", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    sortAscending.toggle()
                }) {
                    Text(sortAscending ? "按字母降序排序" : "按字母升序排序")
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }

                List {
                    Section(header: Text("菜品列表").font(.headline)) {
                        ForEach(filteredDishes.sorted(by: { sortAscending ? $0 < $1 : $0 > $1 }).prefix(loadedDishesCount), id: \.self) { dish in
                            HStack {
                                Text(dish)
                                    .font(.body)
                                Spacer()
                                if selectedDishes.contains(dish) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSelection(dish: dish)
                            }
                        }
                        .onDelete(perform: deleteDish)

                        if isLoadingMore {
                            ProgressView()
                                .onAppear(perform: loadMoreDishes)
                        } else {
                            if filteredDishes.count > loadedDishesCount {
                                Button("加载更多") {
                                    loadMoreDishes()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                    }

                    Section(header: Text("所点菜品").font(.headline)) {
                        ForEach(selectedDishes, id: \.self) { dish in
                            Text(dish)
                        }
                        Text("已选择菜品数量: \(selectedDishes.count)") // 显示数量
                    }
                }
                .listStyle(InsetGroupedListStyle())

                HStack {
                    TextField("我们会做新的菜了！", text: $newDishName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: addDish) {
                        Text("添加")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                .padding()

                Button(action: shareSelectedDishes) {
                    Text("点好菜了！")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.bottom)
            }
            .navigationTitle("点菜")
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.green.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
            .onAppear(perform: loadDishes)
            .onAppear(perform: loadSelectedDishesForDate)
            .onAppear(perform: checkForSharedContent)
        }
    }

    var filteredDishes: [String] {
        return dishes.filter { searchQuery.isEmpty || $0.contains(searchQuery) }
    }

    func addDish() {
        if !newDishName.isEmpty {
            if !dishes.contains(newDishName) {
                dishes.append(newDishName)
                saveDishes()
            }
            newDishName = ""
        }
    }

    func saveDishes() {
        UserDefaults.standard.set(dishes, forKey: "dishes")
    }

    func loadDishes() {
        dishes = UserDefaults.standard.stringArray(forKey: "dishes") ?? []
    }

    func loadSelectedDishesForDate() {
        let dateKey = formattedDate(for: selectedDate)
        selectedDishes = UserDefaults.standard.stringArray(forKey: dateKey) ?? []
    }

    func toggleSelection(dish: String) {
        if let index = selectedDishes.firstIndex(of: dish) {
            selectedDishes.remove(at: index)
        } else {
            selectedDishes.append(dish)
        }
        saveSelectedDishesForDate()
    }

    func saveSelectedDishesForDate() {
        let dateKey = formattedDate(for: selectedDate)
        UserDefaults.standard.set(selectedDishes, forKey: dateKey)
        var dates = UserDefaults.standard.stringArray(forKey: "dates") ?? []
        if !dates.contains(dateKey) {
            dates.append(dateKey)
            UserDefaults.standard.set(dates, forKey: "dates")
        }
    }

    func formattedDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func shareSelectedDishes() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: selectedDate)

        let selectedDishesString = selectedDishes.joined(separator: "\n")
        let message = "在 \(dateString) 的点菜：\n\(selectedDishesString)"

        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        presentActivityVC(activityVC)
    }

    private func presentActivityVC(_ activityVC: UIActivityViewController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let rootViewController = windowScene.windows.first?.rootViewController
            rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }

    func receiveSharedDishes(_ sharedDishes: [String]) {
        for dish in sharedDishes {
            if !dishes.contains(dish) {
                dishes.append(dish)
            }
        }
        saveDishes()
    }

    func checkForSharedContent() {
        if let clipboardString = UIPasteboard.general.string {
            let components = clipboardString.components(separatedBy: "\n").filter { !$0.isEmpty }
            if components.count > 1 {
                let dateString = components[0].replacingOccurrences(of: "在 ", with: "").replacingOccurrences(of: " 的点菜：", with: "")
                let sharedDishesArray = Array(components.dropFirst())
                
                if let date = parseDate(from: dateString) {
                    receiveSharedDishes(sharedDishesArray)
                    saveSharedDishes(sharedDishesArray, for: date)
                }
            }
        }
    }

    func parseDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.date(from: dateString)
    }

    func saveSharedDishes(_ dishes: [String], for date: Date) {
        let dateKey = formattedDate(for: date)
        var existingDishes = UserDefaults.standard.stringArray(forKey: dateKey) ?? []
        for dish in dishes {
            if !existingDishes.contains(dish) {
                existingDishes.append(dish)
            }
        }
        UserDefaults.standard.set(existingDishes, forKey: dateKey)
        loadSelectedDishesForDate()
        addReceivedDishes(dishes)
    }

    func addReceivedDishes(_ receivedDishes: [String]) {
        for dish in receivedDishes {
            if !dishes.contains(dish) {
                dishes.append(dish)
            }
        }
        saveDishes()
    }

    func loadMoreDishes() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let additionalDishes = min(10, filteredDishes.count - loadedDishesCount)
            loadedDishesCount += additionalDishes
            
            isLoadingMore = false
        }
    }

    func deleteDish(at offsets: IndexSet) {
        // 先将当前过滤和排序后的菜品转换为一个数组
        let sortedFilteredDishes = filteredDishes.sorted(by: { sortAscending ? $0 < $1 : $0 > $1 })
        
        // 将要删除的菜品从 sortedFilteredDishes 中找到实际在 dishes 中的索引
        let dishesToDelete = offsets.map { sortedFilteredDishes[$0] }
        
        // 从 dishes 中删除
        dishes.removeAll { dishesToDelete.contains($0) }

        // 更新所选菜品列表
        selectedDishes.removeAll { dishesToDelete.contains($0) }
        
        // 获取所有已保存的日期
        let savedDates = UserDefaults.standard.stringArray(forKey: "dates") ?? []

        // 更新每个日期的所点菜品
        for date in savedDates {
            var selectedDishesForDate = UserDefaults.standard.stringArray(forKey: date) ?? []
            selectedDishesForDate.removeAll { dishesToDelete.contains($0) }
            UserDefaults.standard.set(selectedDishesForDate, forKey: date)
        }

        // 保存当前所选菜品
        saveSelectedDishesForDate()

        // 确保持久化保存菜品
        saveDishes()
    }

    func updateDishesForAllDates(_ dishesToDelete: [String]) {
        let savedDates = UserDefaults.standard.stringArray(forKey: "dates") ?? []
        for date in savedDates {
            var selectedDishesForDate = UserDefaults.standard.stringArray(forKey: date) ?? []
            selectedDishesForDate.removeAll { dishesToDelete.contains($0) }
            UserDefaults.standard.set(selectedDishesForDate, forKey: date)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let components = content.components(separatedBy: "\n").filter { !$0.isEmpty }
            if components.count > 1 {
                let dateString = components[0].replacingOccurrences(of: "在 ", with: "").replacingOccurrences(of: " 的点菜：", with: "")
                let sharedDishesArray = Array(components.dropFirst())

                DispatchQueue.main.async { [weak self] in
                    if let windowScene = application.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController as? UIHostingController<ContentView> {
                        rootViewController.rootView.receiveSharedDishes(sharedDishesArray)

                        if let sharedDate = rootViewController.rootView.parseDate(from: dateString) {
                            rootViewController.rootView.saveSharedDishes(sharedDishesArray, for: sharedDate)
                        }
                    }
                }
            }
        } catch {
            print("读取分享内容时出错：\(error)")
        }
        return true
    }
}

