//
//  RestaurantService.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import Foundation
import CoreLocation
import GooglePlaces
import GoogleMaps
import UIKit

// here when I can fetch the data from API
class RestaurantService {
    private let placesClient = GMSPlacesClient.shared()
    private let apiKey = Config.googleMapsAPIKey
    
    func searchRestaurants(near location: CLLocation, radius: Double) async throws -> [Restaurant] {
        return try await withCheckedThrowingContinuation { continuation in
            print("DEBUG: Searching restaurants near location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("DEBUG: Search radius: \(radius) meters")
            
            let token = GMSAutocompleteSessionToken()
            let filter = GMSAutocompleteFilter()
            filter.types = ["restaurant", "food"]
            
            // create a location restriction within the radius
            let locationBounds = GMSCoordinateBounds(
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude - (radius/111000),
                    longitude: location.coordinate.longitude - (radius/111000)
                ),
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude + (radius/111000),
                    longitude: location.coordinate.longitude + (radius/111000)
                )
            )
            
            // set up location bias
            filter.locationBias = GMSPlaceRectangularLocationOption(
                locationBounds.northEast,
                locationBounds.southWest
            )
            
            // define search queries for better coverage
            let searchQueries = [
                "restaurant",
                "مطعم",
                "restaurant traditionnel",
                "restaurant marocain",
                "café restaurant",
                "restaurant grill",
                "restaurant poisson",
                "restaurant pizza",
                "restaurant fast food",
                "snack",
                "bistro",
                "restaurant halal"
            ]
            
            var allPredictions: [GMSAutocompletePrediction] = []
            let searchQueue = DispatchQueue(label: "com.ajitakl.search", qos: .userInitiated, attributes: .concurrent)
            let searchGroup = DispatchGroup()
            let predictionsQueue = DispatchQueue(label: "com.ajitakl.predictions", qos: .userInitiated)
            
            print("DEBUG: Starting multiple searches for nearby restaurants")
            
            // perform multiple searches
            for query in searchQueries {
                searchGroup.enter()
                print("DEBUG: Searching for '\(query)' nearby")
            
            placesClient.findAutocompletePredictions(
                fromQuery: query,
                filter: filter,
                sessionToken: token
            ) { predictions, error in
                    defer { searchGroup.leave() }
                    
                if let error = error {
                        print("DEBUG: Error searching for '\(query)': \(error.localizedDescription)")
                    return
                }
                
                    if let predictions = predictions {
                        print("DEBUG: Found \(predictions.count) predictions for '\(query)'")
                        predictionsQueue.async {
                            for prediction in predictions {
                                if !allPredictions.contains(where: { $0.placeID == prediction.placeID }) {
                                    allPredictions.append(prediction)
                                }
                            }
                        }
                    }
                }
            }
            
            // after all searches are complete
            searchGroup.notify(queue: searchQueue) {
                print("DEBUG: Total unique places found: \(allPredictions.count)")
                
                let detailsGroup = DispatchGroup()
                let restaurantsQueue = DispatchQueue(label: "com.ajitakl.restaurants", qos: .userInitiated)
                var restaurants: [Restaurant] = []
                var errors: [Error] = []
                
                // process each prediction
                for prediction in allPredictions {
                    detailsGroup.enter()
                    print("DEBUG: Fetching details for place: \(prediction.placeID)")
                    
                    let request = GMSFetchPlaceRequest(
                        placeID: prediction.placeID,
                        placeProperties: ["name", "formatted_address", "geometry/location", "type", "formatted_phone_number", "rating", "price_level", "photos", "opening_hours"],
                        sessionToken: token
                    )
                    
                    self.placesClient.fetchPlace(with: request) { place, error in
                        if let error = error {
                            print("DEBUG: Error fetching place details: \(error.localizedDescription)")
                            restaurantsQueue.async {
                            errors.append(error)
                            }
                            detailsGroup.leave()
                            return
                        }
                        
                        guard let place = place else {
                            print("DEBUG: No place details found")
                            detailsGroup.leave()
                            return
                        }
                        
                        // calculate distance from user location
                        let placeLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                        let distance = location.distance(from: placeLocation)
                        
                        // only include restaurants within the specified radius
                        guard distance <= radius else {
                            print("DEBUG: Skipping \(place.name ?? "Unknown") - distance \(Int(distance))m exceeds radius \(Int(radius))m")
                            detailsGroup.leave()
                            return
                        }
                        
                        print("DEBUG: Successfully fetched details for \(place.name ?? "Unknown") at distance \(Int(distance))m")
                        
                        // handle photo URL
                        if let photoMetadata = place.photos?.first {
                            let photoGroup = DispatchGroup()
                            photoGroup.enter()
                            print("DEBUG: Loading photo for \(place.name ?? "Unknown")")
                            
                            let fetchPhotoRequest = GMSFetchPhotoRequest(
                                photoMetadata: photoMetadata,
                                maxSize: CGSize(width: 800, height: 800)
                            )
                            
                            let restaurant = Restaurant(
                                id: place.placeID ?? UUID().uuidString,
                                name: place.name ?? "Unknown Restaurant",
                                description: place.types?.joined(separator: ", "),
                                cuisine: place.types?.first ?? "Restaurant",
                                rating: Double(place.rating),
                                priceLevel: place.priceLevel,
                                phoneNumber: place.phoneNumber,
                                address: place.formattedAddress,
                                coordinate: place.coordinate,
                                imageURL: nil,
                                types: place.types ?? []
                            )
                            
                            self.placesClient.fetchPhoto(with: fetchPhotoRequest) { photo, error in
                                defer {
                                    photoGroup.leave()
                                    detailsGroup.leave()
                                }
                                
                                let finalRestaurant: Restaurant
                                
                                if let error = error {
                                    print("DEBUG: Error loading photo: \(error.localizedDescription)")
                                    let defaultImageURL = URL(string: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23FF4E01'/%3E%3C/svg%3E")
                                    finalRestaurant = Restaurant(
                                        id: restaurant.id,
                                        name: restaurant.name,
                                        description: restaurant.description,
                                        cuisine: restaurant.cuisine,
                                        rating: restaurant.rating,
                                        priceLevel: restaurant.priceLevel,
                                        phoneNumber: restaurant.phoneNumber,
                                        address: restaurant.address,
                                        coordinate: restaurant.coordinate,
                                        imageURL: defaultImageURL,
                                        types: restaurant.types
                                    )
                                } else if let photo = photo {
                                    print("DEBUG: Successfully loaded photo for \(restaurant.name)")
                                    let imageURL = self.handleRestaurantPhoto(photo, forRestaurant: restaurant.id)
                                    finalRestaurant = Restaurant(
                                        id: restaurant.id,
                                        name: restaurant.name,
                                        description: restaurant.description,
                                        cuisine: restaurant.cuisine,
                                        rating: restaurant.rating,
                                        priceLevel: restaurant.priceLevel,
                                        phoneNumber: restaurant.phoneNumber,
                                        address: restaurant.address,
                                        coordinate: restaurant.coordinate,
                                        imageURL: imageURL,
                                        types: restaurant.types
                                    )
                                } else {
                                    print("DEBUG: No photo loaded for \(restaurant.name)")
                                    let defaultImageURL = URL(string: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23FF4E01'/%3E%3C/svg%3E")
                                    finalRestaurant = Restaurant(
                                        id: restaurant.id,
                                        name: restaurant.name,
                                        description: restaurant.description,
                                        cuisine: restaurant.cuisine,
                                        rating: restaurant.rating,
                                        priceLevel: restaurant.priceLevel,
                                        phoneNumber: restaurant.phoneNumber,
                                        address: restaurant.address,
                                        coordinate: restaurant.coordinate,
                                        imageURL: defaultImageURL,
                                        types: restaurant.types
                                    )
                                }
                                
                                restaurantsQueue.async {
                                    restaurants.append(finalRestaurant)
                                }
                            }
                        } else {
                            let defaultImageURL = URL(string: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23FF4E01'/%3E%3C/svg%3E")
                            let restaurant = Restaurant(
                                id: place.placeID ?? UUID().uuidString,
                                name: place.name ?? "Unknown Restaurant",
                                description: place.types?.joined(separator: ", "),
                                cuisine: place.types?.first ?? "Restaurant",
                                rating: Double(place.rating),
                                priceLevel: place.priceLevel,
                                phoneNumber: place.phoneNumber,
                                address: place.formattedAddress,
                                coordinate: place.coordinate,
                                imageURL: defaultImageURL,
                                types: place.types ?? []
                            )
                            restaurantsQueue.async {
                                restaurants.append(restaurant)
                            }
                            detailsGroup.leave()
                        }
                    }
                }
                
                detailsGroup.notify(queue: .main) {
                    print("DEBUG: Completed fetching all restaurant details. Found \(restaurants.count) restaurants within \(Int(radius))m")
                    if !errors.isEmpty {
                        print("DEBUG: Encountered \(errors.count) errors while fetching details")
                    }
                    
                    // sort restaurants by distance
                    let sortedRestaurants = restaurants.sorted { r1, r2 in
                        let d1 = location.distance(from: CLLocation(latitude: r1.coordinate.latitude, longitude: r1.coordinate.longitude))
                        let d2 = location.distance(from: CLLocation(latitude: r2.coordinate.latitude, longitude: r2.coordinate.longitude))
                        return d1 < d2
                    }
                    
                    continuation.resume(returning: sortedRestaurants)
                }
            }
        }
    }
    
    func searchAllRestaurants(searchText: String) async throws -> [Restaurant] {
        return try await withCheckedThrowingContinuation { continuation in
            print("DEBUG: Starting country-wide search in Morocco")
            
            let token = GMSAutocompleteSessionToken()
            let filter = GMSAutocompleteFilter()
            filter.types = ["restaurant", "food"]
            filter.countries = ["MA"]
            
            // define multiple search queries to get more varied results
            let searchQueries = [
                "restaurant",
                "مطعم",
                "restaurant traditionnel",
                "restaurant marocain",
                "café restaurant",
                "restaurant grill",
                "restaurant poisson",
                "restaurant pizza",
                "restaurant fast food"
            ]
            
            var allPredictions: [GMSAutocompletePrediction] = []
            let searchQueue = DispatchQueue(label: "com.ajitakl.search", qos: .userInitiated, attributes: .concurrent)
            let searchGroup = DispatchGroup()
            let predictionsQueue = DispatchQueue(label: "com.ajitakl.predictions", qos: .userInitiated)
            
            // perform multiple searches
            for query in searchQueries {
                searchGroup.enter()
                print("DEBUG: Searching for '\(query)' in Morocco")
                
                placesClient.findAutocompletePredictions(
                    fromQuery: query,
                    filter: filter,
                    sessionToken: token
                ) { predictions, error in
                    defer { searchGroup.leave() }
                    
                    if let error = error {
                        print("DEBUG: Error searching for '\(query)': \(error.localizedDescription)")
                        return
                    }
                    
                    if let predictions = predictions {
                        print("DEBUG: Found \(predictions.count) predictions for '\(query)'")
                        // add only unique predictions using a serial queue to avoid race conditions
                        predictionsQueue.async {
                            for prediction in predictions {
                                if !allPredictions.contains(where: { $0.placeID == prediction.placeID }) {
                                    allPredictions.append(prediction)
                                }
                            }
                        }
                    }
                }
            }
            
            // after all searches are complete
            searchGroup.notify(queue: searchQueue) {
                print("DEBUG: Total unique places found: \(allPredictions.count)")
                
                let detailsGroup = DispatchGroup()
                let restaurantsQueue = DispatchQueue(label: "com.ajitakl.restaurants", qos: .userInitiated)
                var restaurants: [Restaurant] = []
                var errors: [Error] = []
                
                // Process each prediction
                for prediction in allPredictions {
                    detailsGroup.enter()
                    print("DEBUG: Fetching details for place: \(prediction.placeID)")
                    
                    let request = GMSFetchPlaceRequest(
                        placeID: prediction.placeID,
                        placeProperties: ["name", "formatted_address", "geometry/location", "type", "formatted_phone_number", "rating", "price_level", "photos", "opening_hours"],
                        sessionToken: token
                    )
                    
                    self.placesClient.fetchPlace(with: request) { place, error in
                        if let error = error {
                            print("DEBUG: Error fetching place details: \(error.localizedDescription)")
                            restaurantsQueue.async {
                                errors.append(error)
                            }
                            detailsGroup.leave()
                            return
                        }
                        
                        guard let place = place else {
                            print("DEBUG: No place details found")
                            detailsGroup.leave()
                            return
                        }
                        
                        print("DEBUG: Successfully fetched details for \(place.name ?? "Unknown")")
                        
                        // handle photo URL
                        if let photoMetadata = place.photos?.first {
                            let photoGroup = DispatchGroup()
                            photoGroup.enter()
                            print("DEBUG: Loading photo for \(place.name ?? "Unknown")")
                            
                            // create a fetch photo request with the photo metadata
                            let fetchPhotoRequest = GMSFetchPhotoRequest(
                                photoMetadata: photoMetadata,
                                maxSize: CGSize(width: 800, height: 800)
                            )
                            
                            // create restaurant without photo URL first
                            let restaurant = Restaurant(
                                id: place.placeID ?? UUID().uuidString,
                                name: place.name ?? "Unknown Restaurant",
                                description: place.types?.joined(separator: ", "),
                                cuisine: place.types?.first ?? "Restaurant",
                                rating: Double(place.rating),
                                priceLevel: place.priceLevel,
                                phoneNumber: place.phoneNumber,
                                address: place.formattedAddress,
                                coordinate: place.coordinate,
                                imageURL: nil,
                                types: place.types ?? []
                            )
                            
                            // fetch the photo
                            self.placesClient.fetchPhoto(with: fetchPhotoRequest) { photo, error in
                                defer {
                                    photoGroup.leave()
                                    detailsGroup.leave()
                                }
                                
                                let finalRestaurant: Restaurant
                                
                                if let error = error {
                                    print("DEBUG: Error loading photo: \(error.localizedDescription)")
                                    let defaultImageURL = URL(string: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23FF4E01'/%3E%3C/svg%3E")
                                    finalRestaurant = Restaurant(
                                        id: restaurant.id,
                                        name: restaurant.name,
                                        description: restaurant.description,
                                        cuisine: restaurant.cuisine,
                                        rating: restaurant.rating,
                                        priceLevel: restaurant.priceLevel,
                                        phoneNumber: restaurant.phoneNumber,
                                        address: restaurant.address,
                                        coordinate: restaurant.coordinate,
                                        imageURL: defaultImageURL,
                                        types: restaurant.types
                                    )
                                } else if let photo = photo {
                                    print("DEBUG: Successfully loaded photo for \(restaurant.name)")
                                    let imageURL = self.handleRestaurantPhoto(photo, forRestaurant: restaurant.id)
                                    finalRestaurant = Restaurant(
                                        id: restaurant.id,
                                        name: restaurant.name,
                                        description: restaurant.description,
                                        cuisine: restaurant.cuisine,
                                        rating: restaurant.rating,
                                        priceLevel: restaurant.priceLevel,
                                        phoneNumber: restaurant.phoneNumber,
                                        address: restaurant.address,
                                        coordinate: restaurant.coordinate,
                                        imageURL: imageURL,
                                        types: restaurant.types
                                    )
                                } else {
                                    print("DEBUG: No photo loaded for \(restaurant.name)")
                                    let defaultImageURL = URL(string: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23FF4E01'/%3E%3C/svg%3E")
                                    finalRestaurant = Restaurant(
                                        id: restaurant.id,
                                        name: restaurant.name,
                                        description: restaurant.description,
                                        cuisine: restaurant.cuisine,
                                        rating: restaurant.rating,
                                        priceLevel: restaurant.priceLevel,
                                        phoneNumber: restaurant.phoneNumber,
                                        address: restaurant.address,
                                        coordinate: restaurant.coordinate,
                                        imageURL: defaultImageURL,
                                        types: restaurant.types
                                    )
                                }
                                
                                restaurantsQueue.async {
                                    restaurants.append(finalRestaurant)
                                }
                            }
                        } else {
                            // no photo available, add restaurant with default image
                            let defaultImageURL = URL(string: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23FF4E01'/%3E%3C/svg%3E")
                            let restaurant = Restaurant(
                                id: place.placeID ?? UUID().uuidString,
                                name: place.name ?? "Unknown Restaurant",
                                description: place.types?.joined(separator: ", "),
                                cuisine: place.types?.first ?? "Restaurant",
                                rating: Double(place.rating),
                                priceLevel: place.priceLevel,
                                phoneNumber: place.phoneNumber,
                                address: place.formattedAddress,
                                coordinate: place.coordinate,
                                imageURL: defaultImageURL,
                                types: place.types ?? []
                            )
                            restaurantsQueue.async {
                                restaurants.append(restaurant)
                            }
                            detailsGroup.leave()
                        }
                    }
                }
                
                detailsGroup.notify(queue: .main) {
                    print("DEBUG: Completed fetching all restaurant details. Found \(restaurants.count) restaurants in Morocco")
                    if !errors.isEmpty {
                        print("DEBUG: Encountered \(errors.count) errors while fetching details")
                    }
                    
                    // sort restaurants by rating (highest first)
                    let sortedRestaurants = restaurants.sorted { (r1, r2) -> Bool in
                        let rating1 = r1.rating ?? 0
                        let rating2 = r2.rating ?? 0
                        return rating1 > rating2
                    }
                    
                    continuation.resume(returning: sortedRestaurants)
                }
            }
        }
    }
    
    func calculateDistance(from userLocation: CLLocation?, to restaurantLocation: CLLocation) -> Double? {
        guard let userLocation = userLocation else { return nil }
        return userLocation.distance(from: restaurantLocation)
    }
    
    // helper method to save image to temporary file
    private func handleRestaurantPhoto(_ photo: UIImage, forRestaurant restaurantId: String) -> URL? {
        // Store in cache
        ImageCache.shared.set(photo, forKey: restaurantId)
        
        // Create a custom URL scheme to reference the cached image
        return URL(string: "ajitakl://image/\(restaurantId)")
    }
}

extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

// MARK: - String Extension for Photo URL Extraction
extension String {
    func extractGooglePhotoURL() -> String? {
        guard let range = self.range(of: "https://lh3.googleusercontent.com/") else { return nil }
        let start = range.lowerBound
        let end = self.range(of: "=s100", options: .backwards)?.upperBound ?? self.endIndex
        return String(self[start..<end])
    }
}
