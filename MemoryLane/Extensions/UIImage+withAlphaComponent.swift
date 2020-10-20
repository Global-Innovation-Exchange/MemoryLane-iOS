//
//  UIImage+withAlphaComponent.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/19/20.
//

import UIKit

extension UIImage {
  func withAlphaComponent(_ alpha: CGFloat) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }

    draw(at: .zero, blendMode: .normal, alpha: alpha)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
