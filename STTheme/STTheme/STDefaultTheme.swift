/*
 * Copyright (c) 2019  STMicroelectronics – All rights reserved
 * The STMicroelectronics corporate logo is a trademark of STMicroelectronics
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, this list of conditions
 *   and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright notice, this list of
 *   conditions and the following disclaimer in the documentation and/or other materials provided
 *   with the distribution.
 *
 * - Neither the name nor trademarks of STMicroelectronics International N.V. nor any other
 *   STMicroelectronics company nor the names of its contributors may be used to endorse or
 *   promote products derived from this software without specific prior written permission.
 *
 * - All of the icons, pictures, logos and other images that are provided with the source code
 *   in a directory whose title begins with st_images may only be used for internal purposes and
 *   shall not be redistributed to any third party or modified in any way.
 *
 * - Any redistributions in binary form shall not include the capability to display any of the
 *   icons, pictures, logos and other images that are provided with the source code in a directory
 *   whose title begins with st_images.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 */

import UIKit

struct STDefaultTheme: Theme {
    var color: Colors = STDefaultColors()
    var font: Font = STDefaultFont()
}

private func assetColor(named: String) -> UIColor{
    return UIColor(named: named, in: Bundle(for: ThemeService.self),compatibleWith:nil)!
}

struct STDefaultColors: Colors {
    let primary = assetColor(named: "primary")
    let secondary = assetColor(named: "accent")
    var background:UIColor {
        if #available(iOS 13, *){
            return UIColor.systemBackground
        }
        return assetColor(named: "background")
    }
    
    let text = assetColor(named: "text")
    
    let textDark = assetColor(named: "textDark")
    
    let error = assetColor(named: "error")
    
    var cardPrimary:UIColor {
        if #available(iOS 13, *){
            return UIColor{ uiTrait in
                if(uiTrait.userInterfaceStyle == .dark){
                    return UIColor.secondarySystemGroupedBackground
                }else{
                    return .white
                }
            }//ui color
        }//ios 13
        return .white
    }
    var cardSecondary:UIColor {
        if #available(iOS 13, *){
           return UIColor{ uiTrait in
               if(uiTrait.userInterfaceStyle == .dark){
                   return UIColor.tertiarySystemGroupedBackground
               }else{
                   return assetColor(named: "card_secondary")
               }
           }//ui color
       }//ios 13
       return assetColor(named: "card_secondary")
    }

    let navigationBar = assetColor(named: "primary")
    let navigationBarText = assetColor(named: "primary_dark")
}

struct STDefaultFont: Font {
    var regular: UIFont = UIFont.systemFont(ofSize: 15.0)
    var bold: UIFont = UIFont.boldSystemFont(ofSize: 15.0)
}
