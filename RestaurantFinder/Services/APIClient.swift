//
//  APIClient.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 25/04/2025.
//

import Foundation

class APIClient {
    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        // in a real app, this would make actual API calls
        // for now, we'll just throw an error to indicate it's not implemented
        throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "API client not implemented"])
    }
} 
