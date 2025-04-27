//
//  RestaurantListViewModel.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import Foundation
import CoreLocation
import Combine

class RestaurantListViewModel: ObservableObject, LocationManagerDelegate {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var filteredRestaurants: [Restaurant] = []
    @Published var searchText: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let restaurantService: RestaurantService
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(restaurantService: RestaurantService = RestaurantService(), locationManager: LocationManager) {
        self.restaurantService = restaurantService
        self.locationManager = locationManager
        self.locationManager.delegate = self
        setupSubscriptions()
    }
    
    // MARK: - LocationManagerDelegate
    func locationManager(_ manager: LocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch status {
            case .denied, .restricted:
                print("DEBUG: Location denied/restricted in ViewModel - loading all restaurants")
                self.searchAllRestaurants()
            case .authorizedWhenInUse, .authorizedAlways:
                print("DEBUG: Location authorized in ViewModel - starting location updates")
                // start location updates and wait for location update
                manager.startUpdatingLocation()
            case .notDetermined:
                print("DEBUG: Location authorization not determined in ViewModel")
                break
            @unknown default:
                print("DEBUG: Unknown location authorization status in ViewModel")
                break
            }
        }
    }
    
    private func setupSubscriptions() {
        // subscribe to search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterRestaurants()
            }
            .store(in: &cancellables)
        
        // subscribe to location updates
        locationManager.$userLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                if let location = location {
                    print("DEBUG: Received location update in ViewModel - searching nearby restaurants")
                    self.searchNearbyRestaurants(location: location, radius: 3000)
                }
            }
            .store(in: &cancellables)
            
        // subscribe to authorization status changes
        locationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("DEBUG: Authorization status changed to authorized - waiting for location update")
                    // Don't search yet, wait for location update
                    break
                case .denied, .restricted:
                    print("DEBUG: Authorization status changed to denied/restricted - searching all restaurants")
                    self.searchAllRestaurants()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func loadRestaurants() {
        guard !isLoading else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.error = nil
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let userLocation = locationManager.userLocation {
                searchNearbyRestaurants(location: userLocation, radius: 3000)
            } else {
                print("DEBUG: Location permission granted but no location yet, waiting for update")
            }
        case .denied, .restricted:
            print("DEBUG: Location permission denied, showing all restaurants in Morocco")
            searchAllRestaurants()
        case .notDetermined:
            print("DEBUG: Location permission not determined, requesting permission")
            locationManager.requestLocationPermission()
        @unknown default:
            print("DEBUG: Unknown authorization status, showing all restaurants in Morocco")
            searchAllRestaurants()
        }
    }
    
    private func searchNearbyRestaurants(location: CLLocation, radius: Double) {
        print("DEBUG: Initiating nearby restaurant search at \(location.coordinate.latitude),\(location.coordinate.longitude) with radius \(radius)m")
        
        Task {
            do {
                let results = try await restaurantService.searchRestaurants(
                    near: location,
                    radius: radius
                )
                
                await MainActor.run {
                    self.restaurants = results
                    self.filteredRestaurants = results
                    self.isLoading = false
                    
                    print("DEBUG: View model updated with \(results.count) restaurants within \(Int(radius))m")
                    if self.restaurants.isEmpty {
                        print("DEBUG: No restaurants found in the area")
                    } else {
                        // log distances for verification
                        for restaurant in results {
                            let distance = location.distance(from: CLLocation(
                                latitude: restaurant.coordinate.latitude,
                                longitude: restaurant.coordinate.longitude
                            ))
                            print("DEBUG: Restaurant \(restaurant.name) is at \(Int(distance))m")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    print("DEBUG: Error searching for restaurants: \(error.localizedDescription)")
                    self.error = error
                    self.isLoading = false
                    self.restaurants = []
                    self.filteredRestaurants = []
                }
            }
        }
    }
    
    private func searchAllRestaurants() {
        Task {
            do {
                print("DEBUG: Starting country-wide search for restaurants in Morocco")
                let results = try await restaurantService.searchAllRestaurants(searchText: searchText)
                
                await MainActor.run {
                    self.restaurants = results
                    self.filteredRestaurants = results
                    self.isLoading = false
                    
                    print("DEBUG: View model updated with \(results.count) restaurants for country-wide search")
                    if self.restaurants.isEmpty {
                        print("DEBUG: No restaurants found in the country")
                    } else {
                        print("DEBUG: Successfully loaded \(results.count) restaurants in Morocco")
                    }
                }
            } catch {
                await MainActor.run {
                    print("DEBUG: Error searching for restaurants: \(error.localizedDescription)")
                    self.error = error
                    self.isLoading = false
                    self.restaurants = []
                    self.filteredRestaurants = []
                }
            }
        }
    }
    
    func updateSearchText(_ text: String) {
        DispatchQueue.main.async {
            self.searchText = text
        }
    }
    
    private func filterRestaurants() {
        DispatchQueue.main.async {
            if self.searchText.isEmpty {
                self.filteredRestaurants = self.restaurants
            } else {
                self.filteredRestaurants = self.restaurants.filter { restaurant in
                    let nameMatch = restaurant.name.localizedCaseInsensitiveContains(self.searchText)
                    let cuisineMatch = restaurant.cuisine.localizedCaseInsensitiveContains(self.searchText)
                    let addressMatch = restaurant.address?.localizedCaseInsensitiveContains(self.searchText) ?? false
                    return nameMatch || cuisineMatch || addressMatch
                }
            }
        }
    }
    
    func formattedDistance(to restaurant: Restaurant) -> String? {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways,
              let userLocation = locationManager.userLocation else {
            return nil
        }
        
        let distance = userLocation.distance(from: CLLocation(latitude: restaurant.coordinate.latitude, longitude: restaurant.coordinate.longitude))
        
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
}
