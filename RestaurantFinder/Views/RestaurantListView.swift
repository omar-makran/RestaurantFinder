//
//  RestaurantListView.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import SwiftUI
import CoreLocation

struct RestaurantListView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel: RestaurantListViewModel
    @State private var selectedRestaurant: Restaurant?
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let locationManager = LocationManager()
        _viewModel = StateObject(wrappedValue: RestaurantListViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        NavigationView {
            RestaurantListContentView(
                viewModel: viewModel,
                searchText: $searchText,
                selectedRestaurant: $selectedRestaurant,
                colorScheme: colorScheme
            )
        }
        .onChange(of: searchText) { oldValue, newValue in
            viewModel.updateSearchText(newValue)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // when app becomes active, reload restaurants if we have location permission
                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                   locationManager.authorizationStatus == .authorizedAlways {
                    viewModel.loadRestaurants()
                }
            }
        }
        .onAppear {
            // request location permission when the view appears
            locationManager.requestLocationPermission()
        }
        .onChange(of: locationManager.authorizationStatus) { oldValue, newValue in
            // reset and reload when authorization changes
            if newValue == .authorizedWhenInUse || newValue == .authorizedAlways {
                print("DEBUG: Location authorization changed to authorized - starting location updates")
                locationManager.startUpdatingLocation()
            } else if newValue == .denied || newValue == .restricted {
                print("DEBUG: Location authorization changed to denied/restricted - searching all restaurants")
                viewModel.loadRestaurants()
            }
        }
        .onChange(of: locationManager.userLocation) { oldValue, newValue in
            // reload restaurants when location updates
            if newValue != nil {
                print("DEBUG: Location updated - searching nearby restaurants")
                viewModel.loadRestaurants()
            }
        }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(
                restaurant: restaurant,
                distance: viewModel.formattedDistance(to: restaurant)
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Material.regular)
            .presentationCornerRadius(25)
        }
    }
}

// helper to get reference to SearchBarView
extension View {
    func saveSearchBar(action: @escaping (SearchBarView?) -> Void) -> some View {
        action(self as? SearchBarView)
        return self
    }
}

struct RestaurantRowView: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // restaurant Image
            if let imageURL = restaurant.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .foregroundColor(.gray)
            }
            
            // restaurant Info
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let address = restaurant.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(restaurant.formattedRating)
                    }
                    
                    Spacer()
                    
                    // price Level
                    Text(restaurant.formattedPriceLevel)
                        .foregroundColor(.green)
                }
                .font(.subheadline)
                
                // cuisine Types
                if !restaurant.types.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(restaurant.types, id: \.self) { type in
                                Text(type)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    RestaurantListView()
}
