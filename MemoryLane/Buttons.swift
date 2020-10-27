//
//  buttons.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/26/20.
//
import UIKit


class Buttons: NSObject {
    
    private var buttonsPressed: [Bool] {
        didSet {
            if buttonsPressed != oldValue  {
                // only record the last pressed button
                let lastPressedButton = zip(buttonsPressed, oldValue).map {$0.0 != $0.1}
                let lastPressedButtonIndex = lastPressedButton.firstIndex{$0}
                NotificationCenter.default.post(name: Notification.Name("Button Pressed"), object: lastPressedButtonIndex)
            }
        }
    }
    
    override init() {
        self.buttonsPressed = [Bool](repeating: false, count: 4)
    }
    
    func press(i: Int) {
        self.buttonsPressed[i] = true
    }

    func release(i: Int) {
        self.buttonsPressed[i] = false
    }
    
    func allPressed() -> Bool {
        return self.buttonsPressed.allSatisfy({$0})
    }
}
