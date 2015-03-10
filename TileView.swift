//
//  TileView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 28/02/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import Foundation



class TileView: UIView {
    
    private let EVOLVE_ANIMATION_DURATION = 0.3
    private let EVOLVE_ANIMATION_SCALE_AMOUNT: CGFloat = 1.2
    
    var value: TileValue {
        didSet {
            self.backgroundColor = self.getColorForValue(self.value)
            self.valueLabel.text = "\(value.rawValue)"
            self.animateGettingBiggerAndSmaller()
        }
    }
    
    var valueLabel: UILabel
    
    init(frame: CGRect, value: TileValue) {
        self.value = value // Will not invoke property observer
        
        self.valueLabel = UILabel(frame: frame)
        self.valueLabel.text = "\(value.rawValue)"
        self.valueLabel.adjustsFontSizeToFitWidth = true
        self.valueLabel.font = UIFont(name: "HelveticaNeue-Light", size: 50)
        self.valueLabel.textColor = UIColor.whiteColor()
        self.valueLabel.sizeToFit()
        
        super.init(frame: frame)
        
        self.addSubview(self.valueLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    private func getColorForValue(value: TileValue) -> UIColor {
        switch (value) {
        case .Two:
            return UIColor.blueColor()
        case .Four:
            return UIColor.brownColor()
        case .Eight:
            return UIColor.redColor()
        case .Sixteen:
            return UIColor.grayColor()
        case .ThirtyTwo:
            return UIColor.greenColor()
        case .SixtyFour:
            return UIColor.purpleColor()
        case .OneHundredAndTwentyEight:
            return UIColor.orangeColor()
        case .TwoHundredAndFiftySix:
            return UIColor.darkGrayColor()
        case .FiveHundredAndTwelve:
            return UIColor.lightGrayColor()
        case .OneThousandAndTwentyFour:
            return UIColor.cyanColor()
        case .TwoThousandAndFourtyEight:
            return UIColor.magentaColor()
        case .FourThousandAndNinetySix:
            return UIColor.blueColor()
        case .EightThousandOneHundredAndNinetyTwo:
            return UIColor.brownColor()
        case .SixteenThousandThreeHundredAndEightyFour:
            return UIColor.redColor()
        case .ThirtyTwoThousandSevenHundredAndSixtyEight:
            return UIColor.grayColor()
        case .SixtyFiveThousandFiveHundredAndThirtySix:
            return UIColor.greenColor()
        case .OneHundredAndThirtyOneThousandAndSeventyTwo:
            return UIColor.purpleColor()
        default:
            return UIColor.whiteColor()
        }
    }

    func animateGettingBiggerAndSmaller() {
        UIView.animateWithDuration(self.EVOLVE_ANIMATION_DURATION / 2.0,
            delay: 0,
            options: .CurveEaseInOut,
            animations: {
                self.transform = CGAffineTransformScale(self.transform,
                    self.EVOLVE_ANIMATION_SCALE_AMOUNT,
                    self.EVOLVE_ANIMATION_SCALE_AMOUNT)
            },
            completion: { finished in
                UIView.animateWithDuration(self.EVOLVE_ANIMATION_DURATION / 2.0,
                    delay: 0,
                    options: .CurveEaseInOut,
                    animations: {
                        self.transform = CGAffineTransformIdentity
                    },
                    completion: nil
                )
            }
        )
    }

}
