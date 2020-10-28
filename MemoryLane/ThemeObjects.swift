//
//  ThemeObjects.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/28/20.
//

import UIKit


class ThemeObjects: NSObject {
    
    private var detectedObject: String {
        didSet {
            if detectedObject != oldValue  {
                Helper.playSound(filename: "ObjectDetectedSound")
                NotificationCenter.default.post(name: Notification.Name("New Object Detected"), object: detectedObject)
            }
        }
    }
    
    override init() {
        self.detectedObject = ""
    }
    
    func detect(objectName: String) {
        self.detectedObject = objectName
    }
}
