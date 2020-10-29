//
//  ThemeSelectionViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/27/20.
//

import UIKit
import Vision
import Lottie

class ThemeSelectionViewController: UIViewController {

    @IBOutlet weak var animationView: AnimationView!
    var videoList = [String]()
    var musicList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Post notification to start the object detection process
        animationView.animation = Animation.named("ArrowAnimation")
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        
        let user = UserDataManager(userId: "baseline75")
        user.fetchProfile(profileCompletionHandler: { profile, error in
          if let profile = profile {
            // Only start object detection when fetchProfile is completed
            NotificationCenter.default.post(name: Notification.Name("Object Detection Start"), object: nil)
            DispatchQueue.main.async() {
                self.videoList = profile.video
                self.musicList = profile.music
            }
          }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleObjectDetected), name: Notification.Name("New Object Detected"), object: nil)
        animationView.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("New Object Detected"), object: nil)
    }
    
    @objc func handleObjectDetected (_ notification: NSNotification) {
        switch notification.object as! String {
        case "tv":
//            print("Playing Video")
            switchScreen(animationName: "TVAnimation", mediaType: "video", mediaList: self.videoList)
        case "cassette":
//            print("Playing Music")
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
