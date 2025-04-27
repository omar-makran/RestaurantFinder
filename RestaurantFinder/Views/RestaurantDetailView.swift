//
//  RestaurantDetailView.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 25/04/2025.
//

import SwiftUI
import MapKit
import GooglePlaces

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    let distance: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private let primaryColor = Color(red: 0.98, green: 0.306, blue: 0.004)
    private let secondaryColor = Color(red: 1, green: 0.678, blue: 0)
    
    var body: some View {
        VStack(spacing: 0) {
            // header
            ZStack {
                Text(restaurant.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            
            ScrollView {
                VStack(spacing: 20) {
                    // quick Info Card
                    HStack(spacing: 20) {
                        // rating
                        if let rating = restaurant.rating {
                            VStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(secondaryColor)
                                    .font(.title2)
                                Text(String(format: "%.1f", rating))
                                    .fontWeight(.semibold)
                                    .foregroundColor(secondaryColor)
                                Text("Rating")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // distance
                        if let distance = distance {
                            VStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(primaryColor)
                                    .font(.title2)
                                Text(distance)
                                    .fontWeight(.semibold)
                                    .foregroundColor(primaryColor)
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // price Level
                        VStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text(restaurant.formattedPriceLevel)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text("Price")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10)
                    )
                    .padding(.horizontal)
                    
                    // map
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: restaurant.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) {
                        Marker(restaurant.name, coordinate: restaurant.coordinate)
                            .tint(primaryColor)
                    }
                    .mapStyle(.standard)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                    .padding(.horizontal)
                    
                    // Contact Info
                    VStack(alignment: .leading, spacing: 15) {
                        if let address = restaurant.address {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(primaryColor)
                                    .frame(width: 20)
                                Text(address)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let phoneNumber = restaurant.phoneNumber {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(secondaryColor)
                                    .frame(width: 20)
                                Text(phoneNumber)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let description = restaurant.description {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                Text(description)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
    }
}

struct RestaurantDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let restaurant = Restaurant(
            id: "test",
            name: "Test Restaurant",
            description: "A test restaurant description",
            cuisine: "Test Cuisine",
            rating: 4.5,
            priceLevel: .medium,
            phoneNumber: "+1234567890",
            address: "123 Test Street",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            imageURL: URL(string: "https://example.com/test.jpg"),
            types: ["restaurant", "food"]
        )
        
        RestaurantDetailView(restaurant: restaurant, distance: "1.2 km")
    }
} 
