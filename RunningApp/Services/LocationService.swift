//
//  LocationService.swift
//  RunningApp
//
//  Created by Julian Worden on 7/9/22.
//

import CoreLocation
import Foundation

class LocationService: NSObject, CLLocationManagerDelegate {
    enum LocationTrackingError: Error, LocalizedError {
        case trackingPermissionDenied
    }

    static let instance = LocationService()
    let locationManager = CLLocationManager()
    var currentUserCoordinates: CLLocationCoordinate2D?
    var userLocationUpdatedDelegate: UserLocationUpdatedDelegate?
    var userApprovedLocationTrackingDelegate: UserApprovedLocationTrackingDelegate?
    var userDeniedLocationTrackingDelegate: UserDeniedLocationTrackingDelegate?

    var currentUserLocation: CLLocation? {
        locationManager.location
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = 1
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            currentUserCoordinates = locationManager.location?.coordinate
            userApprovedLocationTrackingDelegate?.userApprovedLocationTracking()
        case .denied, .restricted:
            userDeniedLocationTrackingDelegate?.presentLocationTrackingFailedError(withError: LocationTrackingError.trackingPermissionDenied)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocationUpdatedDelegate?.userLocationUpdated(toLocation: locations.first!)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        userDeniedLocationTrackingDelegate?.presentLocationTrackingFailedError(withError: error)
    }
}
