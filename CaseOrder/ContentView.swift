//
//  ContentView.swift
//  CaseOrder
//
//  Created by KidwishZhu on 2024/10/7.
//

import UIKit
import SwiftUI

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var dishes: [String] = UserDefaults.standard.stringArray(forKey: "dishes") ?? ["宫保鸡丁", "麻婆豆腐", "红烧肉"]
    @State private var newDishName = ""
    @State var sharedDishes: [String] = [] // 新增状态属性

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .padding()

                List {
                    ForEach(dishes, id: \.self) { dish in
                        Text(dish)
                    }

                    // 展示接收到的菜品
                    ForEach(sharedDishes, id: \.self) { dish in
                        Text("来自分享: \(dish)")
                            .foregroundColor(.gray)
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

                Button(action: shareDishes) {
                    Text("分享所选菜品")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("点菜")
            .onAppear(perform: loadDishes)
        }
    }
    
    func addDish() {
        if !newDishName.isEmpty {
            dishes.append(newDishName)
            newDishName = ""
            saveDishes()
        }
    }

    func saveDishes() {
        UserDefaults.standard.set(dishes, forKey: "dishes")
    }

    func loadDishes() {
        dishes = UserDefaults.standard.stringArray(forKey: "dishes") ?? []
    }
    
    func shareDishes() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: selectedDate)
        
        let dishesString = dishes.joined(separator: "\n")
        let message = "在 \(dateString) 的点菜：\n\(dishesString)"
        
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let rootViewController = windowScene.windows.first?.rootViewController
            rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }
}




