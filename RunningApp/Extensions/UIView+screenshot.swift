//
//  UIView+screenshot.swift
//  RunningApp
//
//  Created by Julian Worden on 7/16/22.
//

import Foundation
import UIKit

extension UIView {
    func screenshot() -> UIImage? {
        let scale = UIScreen.main.scale
        let bounds = self.bounds

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, scale)

        guard UIGraphicsGetCurrentContext() != nil else {
            return UIImage()
        }

        self.drawHierarchy(in: bounds, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }
}
