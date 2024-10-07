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

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        loadSelectedDishesForDate()
                    }

                List {
                    Section(header: Text("菜品列表")) {
                        ForEach(dishes, id: \.self) { dish in
                            HStack {
                                Text(dish)
                                Spacer()
                                if selectedDishes.contains(dish) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .onTapGesture {
                                toggleSelection(dish: dish)
                            }
                        }
                        .onDelete(perform: deleteDish) // 添加删除功能
                    }

                    Section(header: Text("所点菜品")) {
                        ForEach(selectedDishes, id: \.self) { dish in
                            Text(dish)
                        }
                    }
                }

                HStack {
                    TextField("添加新菜品", text: $newDishName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: addDish) {
                        Text("添加")
                    }
                    .padding()
                }

                Button(action: shareSelectedDishes) {
                    Text("分享所选菜品")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("点菜")
            .onAppear(perform: loadDishes)
            .onAppear(perform: loadSelectedDishesForDate)
            .onAppear(perform: checkForSharedContent)
        }
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
        // 确保保存日期
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
        loadSelectedDishesForDate() // 刷新当前选中日期的菜品
        addReceivedDishes(dishes) // 将新菜品添加到主列表
    }

    func addReceivedDishes(_ receivedDishes: [String]) {
        for dish in receivedDishes {
            if !dishes.contains(dish) {
                dishes.append(dish)
            }
        }
        saveDishes()
    }

    // 添加删除菜品的方法
    func deleteDish(at offsets: IndexSet) {
        let dishesToDelete = offsets.map { dishes[$0] }
        dishes.remove(atOffsets: offsets)

        // 获取所有已保存的日期
        let savedDates = UserDefaults.standard.stringArray(forKey: "dates") ?? []
        
        // 更新每个日期的所点菜品
        for date in savedDates {
            var selectedDishesForDate = UserDefaults.standard.stringArray(forKey: date) ?? []
            selectedDishesForDate.removeAll { dishesToDelete.contains($0) }
            UserDefaults.standard.set(selectedDishesForDate, forKey: date)
        }

        // 更新当前所选日期的存储
        selectedDishes.removeAll { dishesToDelete.contains($0) }
        saveDishes()
        
        // 强制更新当前日期的所选菜品
        loadSelectedDishesForDate()
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
