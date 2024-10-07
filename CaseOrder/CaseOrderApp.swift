//
//  CaseOrderApp.swift
//  CaseOrder
//
//  Created by KidwishZhu on 2024/10/7.
//

import UIKit
import SwiftUI

@main
struct MyApp: App {
    // AppDelegate 实例
    let appDelegate = AppDelegate()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate) // 如果需要传递环境对象
        }
    }
}
