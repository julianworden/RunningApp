//
//  LocationService.swift
//  RunningApp
//
//  Created by Julian Worden on 7/9/22.
//

import CoreLocation
import Foundation

class LocationService: NSObject, CLLocationManagerDelegate {
    static let instance = LocationService()
    let locationManager = CLLocationManager()
    var currentUserCoordinates: CLLocationCoordinate2D?
    var userLocationUpdatedDelegate: UserLocationUpdatedDelegate?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = 1
        locationManager.startUpdatingLocation()
        currentUserCoordinates = locationManager.location?.coordinate
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocationUpdatedDelegate?.userLocationUpdated(toLocation: locations.first!)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
