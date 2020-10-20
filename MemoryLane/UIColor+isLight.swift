//
//  UIColor+isLight.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/19/20.
//

import UIKit

public extension UIColor {
    func isLight() -> Bool {
        guard let components = cgColor.components, components.count > 2 else {return false}
        // w3.org/TR/AERT/#color-contrast
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
//        if brightness > 0.6 {
//            print(brightness)
//        }
        return (brightness > BRIGHTNESS_THRESHOLD)
    }
}
