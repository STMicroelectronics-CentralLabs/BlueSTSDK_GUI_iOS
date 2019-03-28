//
//  UIColor+Hex.swift
//  trilobyte-lib-ios
//
//  Created by Stefano Zanetti on 17/01/2019.
//  Copyright © 2019 Codermine. All rights reserved.
//

import UIKit

public extension UIColor {
    
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        
        var color: UInt32 = 0
        
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let red = Int(color >> 16) & mask
        let green = Int(color >> 8) & mask
        let blue = Int(color) & mask
        let rgbRed = CGFloat(red) / 255.0
        let rgbGreen = CGFloat(green) / 255.0
        let rgbBlue = CGFloat(blue) / 255.0
        
        self.init(red: rgbRed, green: rgbGreen, blue: rgbBlue, alpha: alpha)
    }
    
    func toHexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)( blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}
