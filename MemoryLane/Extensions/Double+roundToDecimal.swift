//
//  Double+roundToDecimal.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/19/20.
//

import Foundation

extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}
