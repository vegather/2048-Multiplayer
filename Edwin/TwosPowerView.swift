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
class TwosPowerView: SKSpriteNode, EvolvableViewType {
    
    typealias C = TileValue
    
    var value: TileValue
    var label: SKLabelNode
    
    required init(size: CGSize) {
        self.value = TileValue.getBaseValue()
        self.label = SKLabelNode(fontNamed: "AvenirNext-Regular")
        
        super.init(texture: nil, color: TwosPowerView.getColorForValue(self.value), size: size)
        
        self.label.text = "\(self.value.scoreValue)"
        self.label.fontSize = self.getFontSizeForString(self.label.text!)
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
            self.label.fontSize = self.getFontSizeForString(self.label.text!)
            self.color = TwosPowerView.getColorForValue(newValue)
        }
    }
    
    func getFontSizeForString(string: String) -> CGFloat {
        let font = UIFont(name: "AvenirNext-Regular", size: 32)!
        let size = (string as NSString).sizeWithAttributes([NSFontAttributeName as String : font as AnyObject])
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
            return UIColor(red: 26.0 / 255.0,  green: 188.0 / 255.0, blue: 156.0 / 255.0, alpha: 1.0) // Turquise
        case .Four:
            return UIColor(red: 22.0 / 255.0,  green: 160.0 / 255.0, blue: 133.0 / 255.0, alpha: 1.0) // Green sea
        case .Eight:
            return UIColor(red: 39.0 / 255.0,  green: 174.0 / 255.0, blue: 96.0  / 255.0, alpha: 1.0) // Nephritis
        case .Sixteen:
            return UIColor(red: 46.0 / 255.0,  green: 204.0 / 255.0, blue: 113.0 / 255.0, alpha: 1.0) // Emerald
        case .ThirtyTwo:
            return UIColor(red: 241.0 / 255.0, green: 196.0 / 255.0, blue: 15.0 / 255.0,  alpha: 1.0) // Sun Flower
        case .SixtyFour:
            return UIColor(red: 243.0 / 255.0, green: 156.0 / 255.0, blue: 18.0 / 255.0,  alpha: 1.0) // Orange
        case .OneHundredAndTwentyEight:
            return UIColor(red: 230.0 / 255.0, green: 126.0 / 255.0, blue: 34.0 / 255.0,  alpha: 1.0) // Carrot
        case .TwoHundredAndFiftySix:
            return UIColor(red: 211.0 / 255.0, green: 84.0 / 255.0,  blue: 0.0 / 255.0,   alpha: 1.0) // Pumpkin
        case .FiveHundredAndTwelve:
            return UIColor(red: 192.0 / 255.0, green: 57.0 / 255.0,  blue: 43.0 / 255.0,  alpha: 1.0) // Pomegranate
        case .OneThousandAndTwentyFour:
            return UIColor(red: 231.0 / 255.0, green: 76.0 / 255.0,  blue: 60.0 / 255.0,  alpha: 1.0) // Alizaring
        case .TwoThousandAndFourtyEight:
            return UIColor(red: 52.0 / 255.0,  green: 152.0 / 255.0, blue: 219.0 / 255.0, alpha: 1.0) // Peter River
        case .FourThousandAndNinetySix:
            return UIColor(red: 41.0 / 255.0,  green: 128.0 / 255.0, blue: 185.0 / 255.0, alpha: 1.0) // Belize Blue
        case .EightThousandOneHundredAndNinetyTwo:
            return UIColor(red: 155.0 / 255.0, green: 89.0 / 255.0,  blue: 182.0 / 255.0, alpha: 1.0) // Amethyst
        case .SixteenThousandThreeHundredAndEightyFour:
            return UIColor(red: 142.0 / 255.0, green: 68.0 / 255.0,  blue: 173.0 / 255.0, alpha: 1.0) // Wisteria
        case .ThirtyTwoThousandSevenHundredAndSixtyEight:
            return UIColor(red: 52.0 / 255.0,  green: 73.0 / 255.0,  blue: 94.0 / 255.0,  alpha: 1.0) // Wet Asphalt
        case .SixtyFiveThousandFiveHundredAndThirtySix:
            return UIColor(red: 44.0 / 255.0,  green: 62.0 / 255.0,  blue: 80.0 / 255.0,  alpha: 1.0) // Midnight Blue
        case .OneHundredAndThirtyOneThousandAndSeventyTwo:
            return UIColor(red: 127.0 / 255.0, green: 140.0 / 255.0, blue: 141.0 / 255.0, alpha: 1.0) // Asbestos
        }
    }
    
    override var description: String {
        get {
            return "TwosPowerView(value: \(self.value.scoreValue) label.text: \(self.label.text) position: \(self.position))"
        }
    }
}
