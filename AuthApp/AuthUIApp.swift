//
//  AuthenticationSwiftUIApp.swift
//  AuthenticationSwiftUI
//
//  Created by Muhammad Mamun on 19/11/23.
//

import SwiftUI

@main
struct AutheUIApp: App {

    init() {
        // UI tests pass "--uitesting" (always start logged out) and optionally
        // "--logged-in" (skip the login screen).
        let args = CommandLine.arguments
        if args.contains("--uitesting") {
            UserDefaults.standard.set(args.contains("--logged-in"), forKey: "isLoggedIn")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
