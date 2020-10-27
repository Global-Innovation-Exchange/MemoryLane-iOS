//
//  IntroViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/25/20.
//

import UIKit

class IntroViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.buttonDetection()
    }

    
    func buttonDetection() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleButtonPressed), name: Notification.Name("Button Pressed"), object: nil)
    }
    
    @objc func handleButtonPressed (_ notification: NSNotification) {
        print(notification.object as! Int)
        switch notification.object as! Int {
        case 0:
            print("Like Button")
        case 1:
            print("Repeat Button")
        case 2:
            print("Next")
        case 3:
            print("Play/Pause")
        default:
            print("No")
        }
    }
}


