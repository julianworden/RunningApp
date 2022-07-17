//
//  MapViewModel+UserLocationUpdatedDelegate.swift
//  RunningApp
//
//  Created by Julian Worden on 7/16/22.
//

import CoreLocation
import Foundation

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
