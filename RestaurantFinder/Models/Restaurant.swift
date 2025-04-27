//
//  Restaurant.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import Foundation
import CoreLocation
import MapKit
import GooglePlaces

struct Restaurant: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let cuisine: String
    let rating: Double?
    let priceLevel: GMSPlacesPriceLevel?
    let phoneNumber: String?
    let address: String?
    let coordinate: CLLocationCoordinate2D
    let imageURL: URL?
    let types: [String]
    
    var formattedPriceLevel: String {
        guard let priceLevel = priceLevel else { return "N/A" }
        switch priceLevel {
        case .free:
            return "Free"
        case .cheap:
            return "$"
        case .medium:
            return "$$"
        case .high:
            return "$$$"
        case .expensive:
            return "$$$$"
        case .unknown:
            return "N/A"
        @unknown default:
            return "N/A"
        }
    }
    
    var formattedRating: String {
        guard let rating = rating else { return "N/A" }
        return String(format: "%.1f", rating)
    }
    
    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}