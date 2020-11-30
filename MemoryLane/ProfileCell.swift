//
//  DemoCell.swift
//  FoldingCell
//
//  Created by Alex K. on 25/12/15.
//  Copyright © 2015 Alex K. All rights reserved.
//

import FoldingCell
import UIKit

protocol ProfileCellDelegate: class {
    func switchScreen(profileId: String)
}

class ProfileCell: FoldingCell {

    @IBOutlet var closeNumberLabel: UILabel!
    @IBOutlet var openNumberLabel: UILabel!
    @IBOutlet weak var closeNameLabel: UILabel!
    @IBOutlet weak var openNameLabel: UILabel!
    @IBOutlet weak var detailNameLabel: UILabel!
    @IBOutlet weak var occupationNameLabel: UILabel!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var closeSubInfoLabel: UILabel!
    @IBOutlet weak var openSubInfoLabel: UILabel!
    @IBOutlet weak var musicPreferenceLabel: UILabel!
    
    weak var delegate: ProfileCellDelegate?
    var userName: String = "test" {
        didSet {
            closeNameLabel.text = userName
            openNameLabel.text = userName
            detailNameLabel.text = userName
        }
    }
    
    var number: Int = 0 {
        didSet {
            closeNumberLabel.text = String(number)
            openNumberLabel.text = String(number)
        }
    }
    
    var occupation: String = "Teacher" {
        didSet {
            occupationNameLabel.text = occupation
        }
    }
    
    var location: String = "Bellevue, WA" {
        didSet {
            locationNameLabel.text = location
        }
    }
    
    var subInfo: String = "Male, 90 years old" {
        didSet {
            closeSubInfoLabel.text = subInfo
            openSubInfoLabel.text = subInfo
        }
    }
    
    var preferedGenre: [String] = [] {
        didSet {
            if preferedGenre.count < 1 {
                musicPreferenceLabel.text = "No preference"
            } else {
                musicPreferenceLabel.text = preferedGenre.joined(separator: " ")
            }
        }
    }
    
    var profileId: String = "test"
    
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        super.awakeFromNib()
    }

    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.26, 0.2, 0.2]
        return durations[itemIndex]
    }
}

// MARK: - Actions ⚡️

extension ProfileCell {
    
    @IBAction func buttonHandler(_: AnyObject) {
        delegate?.switchScreen(profileId: profileId)
    }
}
