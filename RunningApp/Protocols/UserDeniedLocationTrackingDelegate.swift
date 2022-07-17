//
//  UserDeniedLocationTrackingDelegate.swift
//  RunningApp
//
//  Created by Julian Worden on 7/17/22.
//

import Foundation

protocol UserDeniedLocationTrackingDelegate {
    func presentLocationTrackingFailedError(withError error: Error)
}
