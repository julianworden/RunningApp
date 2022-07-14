//
//  MapViewModel.swift
//  RunningApp
//
//  Created by Julian Worden on 7/13/22.
//

import Combine
import Foundation
import MapKit

final class MapViewModel: NSObject {
    @Published var mapViewShowsUserLocation = false
    @Published var mapViewRegion: MKCoordinateRegion?
    @Published var mapViewPolyline = MKPolyline()

    var startingLocation: CLLocation?
    var endingLocation: CLLocation?
    var totalDistanceTraveled: String {
        guard let endingLocation = endingLocation else { return ""  }
        return endingLocation.distance(from: startingLocation!).formatted()
    }

    var userCoordinatesArray = [CLLocationCoordinate2D]() {
        didSet {
            drawPolyline()
        }
    }
    var userLocationsArray = [CLLocation]()
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
            mapViewShowsUserLocation = true
            centerMapOnUserCoordinates(withCoordinates: LocationService.instance.currentUserCoordinates!)
        default:
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
        }
    }

    func centerMapOnUserCoordinates(withCoordinates coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 500, longitudinalMeters: 500)
        mapViewRegion = region
    }

    func drawPolyline() {
        let polyLine = MKPolyline(coordinates: userCoordinatesArray, count: userCoordinatesArray.count)
        mapViewPolyline = polyLine
    }
}

extension MapViewModel: UserLocationUpdatedDelegate {
    func userLocationUpdated(toLocation location: CLLocation) {
        centerMapOnUserCoordinates(withCoordinates: location.coordinate)
        userCoordinatesArray.insert(location.coordinate, at: 0)
        userLocationsArray.insert(location, at: 0)
    }
}
