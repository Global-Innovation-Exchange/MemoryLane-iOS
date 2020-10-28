//
//  ThemeSelectionViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/27/20.
//

import UIKit
import Vision

class ThemeSelectionViewController: UIViewController {

    private var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Theme Selection")
        NotificationCenter.default.addObserver(self, selector: #selector(handleButtonPressed), name: Notification.Name("Button Pressed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleObjectDetected), name: Notification.Name("New Object Detected"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("Object Detection Start"), object: nil)
    }


    @objc func handleButtonPressed (_ notification: NSNotification) {
        switch notification.object as! Int {
        case 0:
            self.showToast("Like Button Pressed")
        case 1:
            self.showToast("Repeat Button Pressed")
        case 2:
            self.showToast("Next Button Pressed")
        case 3:
            self.showToast("Play/Pause Button Pressed")
        default:
            print("Button Press Error")
        }
    }
    
    @objc func handleObjectDetected (_ notification: NSNotification) {
        switch notification.object as! String {
        case "tv":
            print("Playing Video")
        case "cassette":
            print("Playing Music")
            switchScreen()
        default:
            print("Unidentified Object")
        }
    }
    
    private func switchScreen() {
        let delayTime = DispatchTime.now() + 0.0
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc = mainStoryboard.instantiateViewController(withIdentifier: "MusicViewController") as? MusicViewController {
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        })
    }
}
