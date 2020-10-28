//
//  IntroViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/27/20.
//

import UIKit

class IntroViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    
    let dataSource = [
        ["display": "Always press the \"Like\" when you enjoy the content, this can also help us understand your taste. \n\nPress the \"Like\" button to proceed", "centerX": CGFloat(298), "centerY": CGFloat(687.5)],
        ["display": "To play the content again, you can press the \"Repeat\" button.  \n\nPress \"Repeat\" button to proceed", "centerX": CGFloat(328), "centerY": CGFloat(697.5)],
        ["display": "The \"Next\" button can help you skip to the next song/video. \n\nPress \"Next\" button to proceed", "centerX": CGFloat(358), "centerY": CGFloat(707.5)],
        ["display": "Use the \"Play/Pause\" button to control the media playing. \n\nPress \"Play/Pause\" button to proceed", "centerX": CGFloat(388), "centerY": CGFloat(717.5)]
    ]
    
    var currentViewControllerIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePageViewController()
    }
    
    
    
    func configurePageViewController () {
        guard let pageViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: IntroPageViewController.self)) as? IntroPageViewController else {
            return
        }
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(pageViewController.view)
        
        let views: [String: Any] = ["pageView": pageViewController.view!]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        
        guard let startingViewController = detailViewControllerAt(index: currentViewControllerIndex) else {
            return
        }
        
        pageViewController.setViewControllers([startingViewController], direction: .forward, animated: true)
    }
    
    func detailViewControllerAt(index: Int) -> DataViewController? {
        if index >= dataSource.count || dataSource.count == 0 {
            return nil
        }
        
        guard let dataViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: DataViewController.self)) as? DataViewController else {
            return nil
        }
        
        dataViewController.index = index
        dataViewController.displayText = dataSource[index]["display"] as? String
        dataViewController.centerX = dataSource[index]["centerX"] as? CGFloat
        dataViewController.centerY = dataSource[index]["centerY"] as? CGFloat
        
        return dataViewController
    }
}

extension IntroViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentViewControllerIndex
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return dataSource.count
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let dataViewController = viewController as? DataViewController
        
        guard var currentIndex = dataViewController?.index else {
            return nil
        }
        
        currentViewControllerIndex = currentIndex
        
        if currentIndex == 0 {
            return nil
        }
        
        currentIndex -= 1
        
        return detailViewControllerAt(index: currentIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let dataViewController = viewController as? DataViewController
        
        guard var currentIndex = dataViewController?.index else {
            return nil
        }
        
        if currentIndex == dataSource.count {
            return nil
        }
        
        currentIndex += 1
        
        currentViewControllerIndex = currentIndex
        
        return detailViewControllerAt(index: currentIndex)
    }
}
