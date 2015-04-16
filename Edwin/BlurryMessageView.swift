//
//  BlurryMessage.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 15/04/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit

class BlurryMessageView: UIView {

    private var messageLabel: UILabel! = nil
    
    private let LABEL_MARGIN_INSET = 16
    
    var message: String! {
        didSet {
            if let message = message {
                messageLabel.text = message
            }
        }
    }
    
    init(message: String, frame: CGRect) {
        super.init(frame: frame)
        addSubViews()
        self.message = message
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubViews()
    }
    
    private func addSubViews() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.bounds
        blurView.alpha = 0.8
        self.addSubview(blurView)
        
        
        var labelFrame = self.bounds
        labelFrame.origin.y     = CGFloat(LABEL_MARGIN_INSET)
        labelFrame.origin.x     = CGFloat(LABEL_MARGIN_INSET)
        labelFrame.size.width  -= CGFloat(LABEL_MARGIN_INSET * 2)
        labelFrame.size.height -= CGFloat(LABEL_MARGIN_INSET * 2)
        
        messageLabel = UILabel(frame: labelFrame)
        messageLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 30)
        messageLabel.textColor = UIColor.whiteColor()
        messageLabel.textAlignment = NSTextAlignment.Center
        messageLabel.numberOfLines = 0
        self.addSubview(messageLabel)
    }

}
