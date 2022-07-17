//
//  MapViewModel+MKMapViewDelegate.swift
//  RunningApp
//
//  Created by Julian Worden on 7/16/22.
//

import Foundation
import MapKit

// swiftlint:disable force_cast
extension MapViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeRenderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        routeRenderer.lineWidth = 5
        routeRenderer.strokeColor = .systemBlue
        return routeRenderer
    }

    func showUserLocationOnMap() {
        locationService.userLocationUpdatedDelegate = self
        mapViewShowsUserLocation = true
        centerMapOnUserCoordinates(withCoordinates: locationService.currentUserCoordinates!)
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
