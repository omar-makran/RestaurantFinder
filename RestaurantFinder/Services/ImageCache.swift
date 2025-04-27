//
//  ImageCache.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 27/04/2025.
//

import Foundation
import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let memoryLimit = 50 * 1024 * 1024 // 50MB limit
    
    private init() {
        cache.totalCostLimit = memoryLimit
    }
    
    func set(_ image: UIImage, forKey key: String) {
        let cost = image.jpegData(compressionQuality: 0.8)?.count ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
} 
