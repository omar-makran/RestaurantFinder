//
//  RestaurantRow.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import SwiftUI
import MapKit

struct RestaurantRow: View {
    let restaurant: Restaurant
    let distance: String?
    @Environment(\.colorScheme) var colorScheme
    @State private var image: UIImage?
    
    private let primaryColor = Color(red: 0.98, green: 0.306, blue: 0.004)
    private let secondaryColor = Color(red: 1, green: 0.678, blue: 0)
    
    var body: some View {
        HStack(spacing: 16) {
            // restaurant image
            Group {
                if let imageURL = restaurant.imageURL {
                    CachedAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .transition(.opacity.combined(with: .scale))
                    } placeholder: {
                        defaultRestaurantImage
                    }
                } else {
                    defaultRestaurantImage
                }
            }
            .frame(width: 100, height: 100)
            
            // restaurant info
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let description = restaurant.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if let rating = restaurant.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(secondaryColor)
                            Text(String(format: "%.1f", rating))
                                .foregroundColor(secondaryColor)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if let distance = distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(primaryColor)
                            Text(distance)
                                .foregroundColor(primaryColor)
                                .fontWeight(.medium)
                        }
                    }
                }
                .font(.subheadline)
                
                if let address = restaurant.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // arrow indicator with gradient
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
    
    private var defaultRestaurantImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundStyle(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 100, height: 100)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct RestaurantRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let restaurant = Restaurant(
                id: "test-restaurant",
                name: "Test Restaurant",
                description: "A test restaurant description",
                cuisine: "Test Cuisine",
                rating: 4.5,
                priceLevel: .medium,
                phoneNumber: "+1234567890",
                address: "123 Test Street, San Francisco, CA",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                imageURL: URL(string: "https://example.com/test.jpg"),
                types: ["restaurant", "food"]
            )
            
            RestaurantRow(restaurant: restaurant, distance: "1.2 km")
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)
                .padding()
            
            RestaurantRow(restaurant: restaurant, distance: "1.2 km")
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
