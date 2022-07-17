//
//  MapViewModel.swift
//  RunningApp
//
//  Created by Julian Worden on 7/12/22.
//

import Foundation
import MapKit

class MapViewModel: NSObject {
    var userLocationsArray = [CLLocation]()
    var userCoordinatesArray = [CLLocationCoordinate2D]() {
        didSet {
            drawPolyline()
        }
    }
    var startingLocation: CLLocation?
    var endingLocation: CLLocation?
    var totalDistanceTraveled: String {
        guard let endingLocation = endingLocation else { return ""  }
        return endingLocation.distance(from: startingLocation!).formatted()
    }

    @objc func setStartingLocation() {
        startingLocation = userLocationsArray[0]
    }

    @objc func setEndingLocation() {
        guard startingLocation != nil else { return }
        endingLocation = userLocationsArray[0]
//        totalDistanceTraveledLabel.text = "Congratulations! You ran \(totalDistanceTraveled)m"
    }
}

// swiftlint:disable force_cast
extension MapViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeRenderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        routeRenderer.lineWidth = 5
        routeRenderer.strokeColor = .systemBlue
        return routeRenderer
    }

    func checkLocationAuthorizationStatus() {
        switch LocationService.instance.locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            LocationService.instance.userLocationUpdatedDelegate = self
//            centerMapOnUserCoordinates(withCoordinates: LocationService.instance.currentUserCoordinates!)
        default:
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
        }
    }

    func centerMapOnUserCoordinates(withCoordinates coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 500, longitudinalMeters: 500)
//        mapView.setRegion(region, animated: true)
    }

    func drawPolyline() {
        let polyLine = MKPolyline(coordinates: userCoordinatesArray, count: userCoordinatesArray.count)
//        mapView.addOverlay(polyLine)
    }
}

extension MapViewModel: UserLocationUpdatedDelegate {
    func userLocationUpdated(toLocation location: CLLocation) {
        centerMapOnUserCoordinates(withCoordinates: location.coordinate)
        userCoordinatesArray.insert(location.coordinate, at: 0)
        userLocationsArray.insert(location, at: 0)
    }
}
