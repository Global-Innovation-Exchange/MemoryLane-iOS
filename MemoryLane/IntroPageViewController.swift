//
//  IntroViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/25/20.
//

import UIKit

class IntroPageViewController: UIPageViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handleButtonPressed), name: Notification.Name("Button Pressed"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("Button Pressed"), object: nil)
    }

    @objc func handleButtonPressed (_ notification: NSNotification) {
        guard let currentIndex = dataSource?.presentationIndex?(for: self) else {return}
        switch notification.object as! Int {
        case 0:
            if currentIndex == 0 {
                self.goToNextPage()
            }
            self.showToast("Like Button Pressed")
        case 1:
            if currentIndex == 1 {
                self.goToNextPage()
            }
            self.showToast("Repeat Button Pressed")
        case 2:
            if currentIndex == 2 {
                self.goToNextPage()
            }
            self.showToast("Next Button Pressed")
        case 3:
            if currentIndex == 3 {
                self.switchScreen()
            }
            self.showToast("Play/Pause Button Pressed")
        default:
            print("Button Press Error")
        }
    }
    
    private func switchScreen() {
        let delayTime = DispatchTime.now() + 0.0
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc = mainStoryboard.instantiateViewController(withIdentifier: "ThemeSelection") as? ThemeSelectionViewController {
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        })
    }
}

extension UIPageViewController {

    func goToNextPage() {
       guard let currentViewController = self.viewControllers?.first else { return }
       guard let nextViewController = dataSource?.pageViewController( self, viewControllerAfter: currentViewController ) else { return }
       setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
    }

    func goToPreviousPage() {
       guard let currentViewController = self.viewControllers?.first else { return }
       guard let previousViewController = dataSource?.pageViewController( self, viewControllerBefore: currentViewController ) else { return }
       setViewControllers([previousViewController], direction: .reverse, animated: true, completion: nil)
    }

}
