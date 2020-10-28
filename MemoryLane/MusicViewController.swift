//
//  MusicViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/28/20.
//

import UIKit
import Lottie

class MusicViewController: UIViewController {

    @IBOutlet weak var animationView: AnimationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animationView.animation = Animation.named("CassetteAnimation")
        animationView.loopMode = .loop
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animationView.play()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
