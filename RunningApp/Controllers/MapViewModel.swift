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
    @Published var totalDistanceTravelled = "0.0"

    var selectedLengthUnit = UnitLength.miles
    var stopDrawingPolyline = true
    var centeredOnPolyline = false

    var startingLocation: CLLocation? {
        didSet {
            getTotalDistanceTravelled()
        }
    }
    var endingLocation: CLLocation?

    var userCoordinatesArray = [CLLocationCoordinate2D]() {
        didSet {
            if !stopDrawingPolyline && startingLocation != nil {
                drawPolyline()
            }
        }
    }
    var userLocationsArray = [CLLocation]()

    func startRun() {
        startingLocation = userLocationsArray[0]
        userCoordinatesArray.removeAll()
        userLocationsArray.removeAll()
        LocationService.instance.locationManager.startUpdatingLocation()
        stopDrawingPolyline = false
        centeredOnPolyline = false
    }

    func endRun() {
        guard startingLocation != nil else { return }
        totalDistanceTravelled = "0.0"
        startingLocation = nil
        endingLocation = nil
        endingLocation = userLocationsArray[0]
        stopDrawingPolyline = true
        centeredOnPolyline = true
//        userCoordinatesArray.removeAll()
    }

    func getTotalDistanceTravelled() {
        guard let currentUserLocation = LocationService.instance.locationManager.location,
              let startingLocation = startingLocation else { return }

        let distanceInMeters = Measurement(value: currentUserLocation.distance(from: startingLocation),
                                           unit: UnitLength.meters)
        let formatter = MeasurementFormatter()

        switch selectedLengthUnit {
        case .miles:
            let distanceInMiles = distanceInMeters.converted(to: UnitLength.miles)
            totalDistanceTravelled = formatter.string(from: distanceInMiles)
        case .kilometers:
            let distanceInKilometers = distanceInMeters.converted(to: UnitLength.kilometers)
            totalDistanceTravelled = formatter.string(from: distanceInKilometers)
        default:
            return
        }
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
        if !centeredOnPolyline {
            centerMapOnUserCoordinates(withCoordinates: location.coordinate)
        }

        if !stopDrawingPolyline {
            userCoordinatesArray.insert(location.coordinate, at: 0)
        }
        userLocationsArray.insert(location, at: 0)
        getTotalDistanceTravelled()
    }
}
