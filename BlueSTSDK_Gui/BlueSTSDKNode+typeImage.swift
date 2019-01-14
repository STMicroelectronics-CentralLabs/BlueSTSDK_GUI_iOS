//
//  Node+typeImage.swift
//  BlueSTSDK_Gui
//
//  Created by Giovanni Visentini on 25/09/2018.
//  Copyright © 2018 STCentralLab. All rights reserved.
//

import Foundation
import BlueSTSDK
import UIKit

public extension BlueSTSDKNode{
    
    public func getTypeImage()->UIImage?{
        let currentBundle = Bundle(for: BlueSTSDKNodeListViewController.self)
        switch type {
        case .generic:
            return UIImage(named: "board_generic.png", in: currentBundle, compatibleWith: nil)
        case .STEVAL_WESU1:
            return UIImage(named: "logo_steval_wesu1", in: currentBundle, compatibleWith: nil)
        case .sensor_Tile, .sensor_Tile_101:
            return UIImage(named: "logo_sensorTile", in: currentBundle, compatibleWith: nil)
        case .blue_Coin:
            return UIImage(named: "logo_blueCoin", in: currentBundle, compatibleWith: nil)
        case .STEVAL_IDB008VX:
            return UIImage(named: "logo_steval_idb008VX", in: currentBundle, compatibleWith: nil)
        case .STEVAL_BCN002V1:
            return UIImage(named: "logo_steval_bnc002V1", in: currentBundle, compatibleWith: nil)
        case .nucleo:
            return UIImage(named: "logo_nucleo", in: currentBundle, compatibleWith: nil)
        }
    }
    
}
