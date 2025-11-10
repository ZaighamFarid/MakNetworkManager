//
//  MakNetworkManagerExampleApp.swift
//  MakNetworkManagerExample
//
//  Example app demonstrating MakNetworkManager SDK usage
//

import SwiftUI

@main
struct MakNetworkManagerExampleApp: App {
    @StateObject private var networkManager = ExampleNetworkManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkManager)
        }
    }
}
