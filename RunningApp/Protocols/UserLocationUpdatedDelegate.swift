//
//  UserLocationUpdatedDelegate.swift
//  RunningApp
//
//  Created by Julian Worden on 7/9/22.
//

import CoreLocation
import Foundation

protocol UserLocationUpdatedDelegate {
    func userLocationUpdated(toLocation location: CLLocation)
}
