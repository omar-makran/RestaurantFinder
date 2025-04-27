//
//  AjiTaklApp.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import SwiftUI
import GooglePlaces
import GoogleMaps

@main
struct AjiTaklApp: App {
    // state to track the current app stage
    @State private var appState: AppState = .splash
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        // initialize Google SDKs with your API key from Config
        GMSPlacesClient.provideAPIKey(Config.googleMapsAPIKey)
        GMSServices.provideAPIKey(Config.googleMapsAPIKey)
        print("DEBUG: Successfully initialized Google SDKs with API key")
    }
    
    // app states
    enum AppState {
        case splash
        case onboarding
        case main
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // show different views based on app state
                if appState == .splash {
                    SplashView()
                        .onAppear {
                            // automatically transition to onboarding after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    appState = hasCompletedOnboarding ? .main : .onboarding
                                }
                            }
                        }
                } else if appState == .onboarding {
                    OnboardingView(onComplete: {
                        hasCompletedOnboarding = true
                        withAnimation {
                            appState = .main
                        }
                    })
                } else {
                    // main app flow
                    RestaurantListView()
                }
            }
        }
    }
} 
