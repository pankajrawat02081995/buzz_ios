//
//  LocationService.swift
//  Zupet
//
//  Created by Pankaj Rawat on 01/09/25.
//

import Foundation
import CoreLocation

// MARK: - Location Model
struct UserLocation: Codable {
    let latitude: Double?
    let longitude: Double?
    let city: String?
    let state: String?
    let country: String?
    let postalCode: String?
    let fullAddress: String?
}

// MARK: - Location Manager
final class LocationService: NSObject {
    
    static let shared = LocationService() // Singleton
    
    private let locationManager = CLLocationManager()
    private var completion: ((Result<UserLocation, Error>) -> Void)?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    /// Get current location with details
    func getUserLocation(completion: @escaping (Result<UserLocation, Error>) -> Void) {
        self.completion = completion
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            completion(.failure(LocationError.permissionDenied))
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        } else if manager.authorizationStatus == .denied {
            completion?(.failure(LocationError.permissionDenied))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation() // stop to save battery
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                self.completion?(.failure(error))
                self.completion = nil
                return
            }
            
            if let placemark = placemarks?.first {
                let model = UserLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    city: placemark.locality,
                    state: placemark.administrativeArea,
                    country: placemark.country,
                    postalCode: placemark.postalCode,
                    fullAddress: [placemark.name,
                                  placemark.locality,
                                  placemark.administrativeArea,
                                  placemark.postalCode,
                                  placemark.country]
                                  .compactMap { $0 }
                                  .joined(separator: ", ")
                )
                self.completion?(.success(model))
                self.completion = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
}

// MARK: - Errors
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Location permission denied"
        case .unknown: return "Unknown location error"
        }
    }
}
