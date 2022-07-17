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
    @Published var totalDistanceTravelled = ""

    let locationService = LocationService.instance

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
        mapViewPolyline = MKPolyline()
        userCoordinatesArray.removeAll()
        userLocationsArray.removeAll()
        totalDistanceTravelled = "0.0"
        stopDrawingPolyline = false
        centeredOnPolyline = false
        startingLocation = locationService.currentUserLocation
    }

    func endRun() {
        stopDrawingPolyline = true
        centeredOnPolyline = true
        startingLocation = nil
        endingLocation = locationService.currentUserLocation
    }

    // Updates totalDistanceTravelled value while run is ongoing,
    // stops updating when the run is ended and the startingLocation is
    // set to nil
    func getTotalDistanceTravelled() {
        guard let currentUserLocation = locationService.currentUserLocation,
              let startingLocation = startingLocation else { return }

        let distanceInMeters = Measurement(value: currentUserLocation.distance(from: startingLocation),
                                           unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 2

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
