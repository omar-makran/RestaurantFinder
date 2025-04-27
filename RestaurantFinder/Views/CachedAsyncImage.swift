//
//  CachedAsyncImage.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 27/04/2025.
//

import SwiftUI
import UIKit

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    var body: some View {
        if let url = url, let cachedImage = ImageCache.shared.get(forKey: url.lastPathComponent) {
            // Show cached image directly
            content(Image(uiImage: cachedImage))
        } else if let url = url, let scheme = url.scheme, (scheme == "http" || scheme == "https") {
            // Only use AsyncImage for real URLs
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder()
                case .success(let image):
                    content(image)
                        .onAppear {
                            if let uiImage = image.asUIImage() {
                                ImageCache.shared.set(uiImage, forKey: url.lastPathComponent)
                            }
                        }
                case .failure:
                    placeholder()
                @unknown default:
                    placeholder()
                }
            }
        } else {
            // for unsupported or custom URLs, show placeholder
            placeholder()
        }
    }
}

// helper extension to convert SwiftUI Image to UIImage
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self.resizable())
        let view = controller.view
        
        let targetSize = CGSize(width: 100, height: 100) // or your preferred size
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
} 
