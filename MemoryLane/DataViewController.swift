//
//  DataViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/27/20.
//

import UIKit
import Lottie


class DataViewController: UIViewController {

    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var animationImageView: UIImageView!
    @IBOutlet weak var animationView: AnimationView!
    
    var displayText: String?
    var animationName: String?
    var centerX: CGFloat?
    var centerY: CGFloat?
    var index: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLabel.text = displayText
        animationView.center.x = centerX ?? 300.5
        animationView.center.y = centerY ?? 670.5
        animationView.animation = Animation.named(animationName ?? "ArrowAnimation")
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animationView.play()
    }

//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        animationView.stop()
//    }

    /*
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
