//
//  CALayer+isLight.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/19/20.
//

import UIKit

public extension CALayer {
    /// Get the specific color of given point
    ///
    /// - parameter at: point location
    ///
    /// - returns: Color
    func isLight(at position: CGPoint) -> Bool {
        // pixel of the given point
        var pixel = [UInt8](repeatElement(0, count: 4))
        // set the colorspace to RGB
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // set bitmap to RGBA
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return false
        }
        // translate the context point to each position
        context.translateBy(x: -position.x, y: -position.y)
//        context.rotate(by: CGFloat(.pi / 2.0))
        render(in: context)
        let color = UIColor(red: CGFloat(pixel[0]) / 255.0,
                            green: CGFloat(pixel[1]) / 255.0,
                            blue: CGFloat(pixel[2]) / 255.0,
                            alpha: CGFloat(pixel[3]) / 255.0)
        return color.isLight()
    }
}
