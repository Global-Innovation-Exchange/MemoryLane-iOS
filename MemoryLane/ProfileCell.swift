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
    func switchScreen()
}

class ProfileCell: FoldingCell {

    @IBOutlet var closeNumberLabel: UILabel!
    @IBOutlet var openNumberLabel: UILabel!
    @IBOutlet weak var closeNameLabel: UILabel!
    @IBOutlet weak var openNameLabel: UILabel!
    @IBOutlet weak var detailNameLabel: UILabel!
    
    weak var delegate: ProfileCellDelegate?
    var userId: String = "test" {
        didSet {
            closeNameLabel.text = userId
            openNameLabel.text = userId
            detailNameLabel.text = userId
        }
    }
    
    var number: Int = 0 {
        didSet {
            closeNumberLabel.text = String(number)
            openNumberLabel.text = String(number)
        }
    }

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
        delegate?.switchScreen()
    }
}
