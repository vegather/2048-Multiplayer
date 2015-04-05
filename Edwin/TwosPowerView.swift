//
//  TwosPowerView.swift
//  Edwin
//
//  Created by Vegard Solheim Theriault on 12/03/15.
//  Copyright (c) 2015 Wrong Bag. All rights reserved.
//

import UIKit
import SpriteKit

// This should be a SKLabelNode, but those do not have a backgroundColor property.
// Most straightforward solution as therefore to subclass SKSpriteNode,
// and add a SKLabelNode as a child.
class TwosPowerView: SKSpriteNode, EvolvableViewType, Printable {
    
    typealias C = TileValue
    
    var value: TileValue
    var label: SKLabelNode
    
    required init(size: CGSize) {
        self.value = TileValue.getBaseValue()
        self.label = SKLabelNode(fontNamed: "AvenirNext-Regular")
        
        super.init(texture: nil, color: TwosPowerView.getColorForValue(self.value), size: size)
        
        self.label.text = "\(self.value.scoreValue)"
        self.label.fontSize = self.getFontSizeForString(self.label.text)
        self.label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        
        
        self.addChild(self.label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func evolve() {
        if let newValue = self.value.evolve() {
            self.value = newValue
            self.label.text = "\(newValue.scoreValue)"
            self.label.fontSize = self.getFontSizeForString(self.label.text)
            self.color = TwosPowerView.getColorForValue(newValue)
        }
    }
    
    func getFontSizeForString(string: String) -> CGFloat {
        let font = UIFont(name: "AvenirNext-Regular", size: 32)!
        let size = (string as NSString).sizeWithAttributes([NSFontAttributeName as NSObject : font as AnyObject])
        let pointsPerPixel =  font.pointSize / (max(size.width, size.height) * 1.2)
        let desiredPointSize = self.size.height * pointsPerPixel
        
        return desiredPointSize
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Helper Methods
    // -------------------------------
    
    private class func getColorForValue(value: TileValue) -> UIColor {
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
    
    override var description: String {
        get {
            return "TwosPowerView(value: \(self.value.scoreValue) label.text: \(self.label.text) position: \(self.position))"
        }
    }
}
