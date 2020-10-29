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
    
    var videoList = [String]()
    var musicList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let user = UserDataManager(userId: "baseline75")
        print(self.videoList)
        // Post notification to start the object detection process
        NotificationCenter.default.post(name: Notification.Name("Object Detection Start"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add observer to listen to object detection notification

        NotificationCenter.default.addObserver(self, selector: #selector(handleObjectDetected), name: Notification.Name("New Object Detected"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("New Object Detected"), object: nil)
    }
    
    @objc func handleObjectDetected (_ notification: NSNotification) {
        switch notification.object as! String {
        case "tv":
            print("Playing Video")
            switchScreen(animationName: "TVAnimation", mediaType: "video", mediaList: self.videoList)
        case "cassette":
            print("Playing Music")
            switchScreen(animationName: "CassetteAnimation", mediaType: "music", mediaList: self.musicList)
        default:
            print("Unidentified Object")
            print(notification.object as! String)
        }
    }
    
    private func switchScreen(animationName: String, mediaType: String, mediaList: [String]) {
        let delayTime = DispatchTime.now() + 0.0
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc = mainStoryboard.instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController {
                vc.modalPresentationStyle = .fullScreen
                vc.animationName = animationName
                vc.mediaType = mediaType
                vc.mediaList = mediaList
                self.present(vc, animated: true, completion: nil)
            }
        })
    }
}
