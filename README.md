# 🍽️ AjiTakl Restaurant Finder

[![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios)
[![Xcode](https://img.shields.io/badge/Xcode-13.0+-blue.svg)](https://developer.apple.com/xcode)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A beautiful SwiftUI app for discovering and exploring restaurants in Morocco. Find the perfect dining spot near you or across the country with ease.

## ✨ Features

- 🔍 **Smart Search**: Find restaurants by name, cuisine, or location
- 📍 **Location-Based**: Discover restaurants near your current location
- 🌍 **Country-Wide**: Search across all of Morocco
- 🌙 **Dark Mode**: Beautiful UI that adapts to your preferences
- ⭐ **Detailed Info**: View ratings, price levels, and contact information
- 🗺️ **Interactive Maps**: See restaurant locations on a map

## 🚀 Getting Started

### Prerequisites

- iOS 15.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later
- A Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/thee-falcon/AjiTaklFinder.git
   ```

2. **Open the project**
   ```bash
   cd AjiTaklFinder
   open RestaurantFinder.xcworkspace
   ```

3. **Configure API Key**
   - Create a new file `Config.swift` in `RestaurantFinder/Config/`
   - Add your Google Maps API key:
   ```swift
   import Foundation

   enum Config {
       static let googleMapsAPIKey = "YOUR_API_KEY_HERE"
   }
   ```

4. **Build and Run**
   - Select your target device
   - Press ⌘R or click the Run button

## 🔒 Security

The app requires a Google Maps API key to function. For security:

- 🔑 Never commit your API key to version control
- 🛡️ Keep your API key secure and private
- ⚙️ Set up proper API key restrictions in Google Cloud Console:
  - Restrict to iOS apps only
  - Limit to your bundle identifier
  - Enable only required APIs (Places API and Maps SDK)


## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Omar Makran** - [@thee-falcon](https://github.com/thee-falcon)

## 🙏 Acknowledgments

- Google Maps Platform
- SwiftUI
- The iOS development community 
