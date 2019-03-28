//
//  UIResponder+Helper.swift
//  trilobyte-lib-ios
//
//  Created by Stefano Zanetti on 17/01/2019.
//  Copyright © 2019 Codermine. All rights reserved.
//

import UIKit

public extension UIResponder {
    var currentTheme: Theme {
        return ThemeService.shared.currentTheme
    }
}
