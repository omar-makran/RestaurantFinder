//
//  LocationManager.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import Foundation
import CoreLocation
import Combine
import UIKit

protocol LocationManagerDelegate: AnyObject {
    func locationManager(_ manager: LocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
}

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    weak var delegate: LocationManagerDelegate?
    
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var isLocationPermissionGranted = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // reduced accuracy for better battery life
        locationManager.distanceFilter = 100 // only update when user moves 100 meters
        
        // check initial status
        authorizationStatus = locationManager.authorizationStatus
        
        // if we already have permission, start updating location immediately
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
        
        // setup notification observers for app lifecycle
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidBecomeActive() {
        // when app becomes active, check authorization and restart location updates if needed
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
    
    @objc private func handleAppWillResignActive() {
        // clean up when app goes to background
        locationManager.stopUpdatingLocation()
        userLocation = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func requestLocationPermission() {
        // clear any existing location data
        userLocation = nil
        // this will trigger the system location permission alert
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        
        // stop any existing updates
        locationManager.stopUpdatingLocation()
        
        // configure for best accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // start updates
        locationManager.startUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let oldStatus = self.authorizationStatus
            self.authorizationStatus = manager.authorizationStatus

            print("DEBUG: Location authorization changed from \(oldStatus) to \(self.authorizationStatus)")

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("DEBUG: Location permission granted - starting location updates")
                self.userLocation = nil
                self.isLocationPermissionGranted = true
                self.startUpdatingLocation()
            case .denied, .restricted:
                print("DEBUG: Location access denied or restricted - will use country-wide search")
                self.userLocation = nil
                self.isLocationPermissionGranted = false
                self.locationManager.stopUpdatingLocation()
            case .notDetermined:
                print("DEBUG: Location authorization in not determined state")
                self.isLocationPermissionGranted = false
            @unknown default:
                print("DEBUG: Location authorization in other state: \(self.authorizationStatus)")
                self.isLocationPermissionGranted = false
            }
            
            // notify delegate of authorization change
            self.delegate?.locationManager(self, didChangeAuthorizationStatus: manager.authorizationStatus)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy <= 100 else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("DEBUG: Received location update - lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude), accuracy: \(location.horizontalAccuracy)m")
            
            // only update if location has changed significantly (more than 100 meters)
            if let currentLocation = self.userLocation {
                let distance = location.distance(from: currentLocation)
                if distance < 100 {
                    print("DEBUG: Skipping location update - distance \(Int(distance))m is less than threshold")
                    return
                }
            }
            
            // only update if the location is fresh (less than 30 seconds old)
            let locationAge = -location.timestamp.timeIntervalSinceNow
            if locationAge > 30 {
                print("DEBUG: Skipping stale location update - age: \(Int(locationAge))s")
                return
            }
            
            print("DEBUG: Updating user location")
            self.userLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            print("Location manager failed with error: \(error.localizedDescription)")
            
            if let error = error as? CLError {
                switch error.code {
                case .denied:
                    self?.userLocation = nil
                case .locationUnknown:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.startUpdatingLocation()
                    }
                default:
                    self?.startUpdatingLocation()
                }
            }
        }
    }
}
