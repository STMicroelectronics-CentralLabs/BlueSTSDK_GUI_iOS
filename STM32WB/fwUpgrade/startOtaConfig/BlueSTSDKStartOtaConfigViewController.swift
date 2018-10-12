/*
 * Copyright (c) 2018  STMicroelectronics – All rights reserved
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

import Foundation
import BlueSTSDK


/// ViewController that will reboot the board in ota mode
class BlueSTSDKStartOtaConfigViewController:UIViewController, BlueSTSDKDemoViewProtocol{
    
    private static let SEARCH_OTA_NODE_SEGUE = "searchOtaNodeSegue";
    
    private static let INVALID_ARGS_TITLE:String = {
        let bundle = Bundle(for: BlueSTSDKStartOtaConfigViewController.self);
        return NSLocalizedString("Invalid Argument", tableName: nil,
                                 bundle: bundle,
                                 value: "Invalid Argument",
                                 comment: "Invalid Argument");
    }();

    private static let INVALID_ARGS_MSG:String = {
        let bundle = Bundle(for: BlueSTSDKStartOtaConfigViewController.self);
        return NSLocalizedString("The valid range is %d %d", tableName: nil,
                                 bundle: bundle,
                                 value: "The valid range is %d %d",
                                 comment: "The valid range is %d %d");
    }();

    
    var node: BlueSTSDKNode!
    var menuDelegate: BlueSTSDKViewControllerMenuDelegate?
    
    var boardIsRebooting = false;
    
    private struct MemoryLayout{
        let startSector:UInt8
        let numSecotor:UInt8
    }
    
    private static let VALID_MEMORY_SECOTR_RANGE = UInt8(0x07)..<UInt8(0x7F)
    private static let APPLICATION_MEMORY = MemoryLayout(startSector: 7, numSecotor: 0x7F-7-1)
    private static let RADIO_MEMORY = MemoryLayout(startSector: 8, numSecotor: 0x7F-8-1)
    
    @IBOutlet weak var mFirstSectorText: UITextField!
    @IBOutlet weak var mNumSectorText: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onApplicationMemorySelected()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if(boardIsRebooting){
            node.disconnect()
        }
    }
    
    @IBAction func onMemoryTypeSelected(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            return onApplicationMemorySelected()
        case 1:
            return onCustomMemorySelected()
//        case 1:
//            return onRadioMemorySelected()
        default:
            return
        }
    }
    
    private func setFixMemoryLayout(layout:MemoryLayout){
        mFirstSectorText.text = String(format:"%d",layout.startSector)
        mFirstSectorText.isEnabled=false;
        mNumSectorText.text = String(format:"%d",layout.numSecotor)
        mNumSectorText.isEnabled=false;
    }
    
    private func onApplicationMemorySelected(){
        setFixMemoryLayout(layout: BlueSTSDKStartOtaConfigViewController.APPLICATION_MEMORY)
    }
    
    private func onCustomMemorySelected(){
        mFirstSectorText.isEnabled=true
        mNumSectorText.isEnabled=true
    }
    
    private func onRadioMemorySelected(){
        setFixMemoryLayout(layout: BlueSTSDKStartOtaConfigViewController.RADIO_MEMORY)
    }
    
    private func getFistSector()->UInt8?{
        guard let value = UInt8(mFirstSectorText.text ?? "") else {
            return nil
        }
        if( BlueSTSDKStartOtaConfigViewController.VALID_MEMORY_SECOTR_RANGE.contains(value)){
            return value
        }
        return nil
    }
    
    private func getNumSector(firstSector:UInt8)->UInt8?{
        guard let value = UInt8(mNumSectorText.text ?? "") else {
            return nil
        }
        let (endLocation, overflow) = firstSector.addingReportingOverflow(value)
        if( !overflow && BlueSTSDKStartOtaConfigViewController.VALID_MEMORY_SECOTR_RANGE.contains(endLocation)){
            return value
        }
        
        return nil
    }
    
    @IBAction func onRebootPressed(_ sender: UIButton) {
        let feature = self.node.getFeatureOfType(BlueSTSDKSTM32WBRebootOtaModeFeature.self) as? BlueSTSDKSTM32WBRebootOtaModeFeature;
        
        if let firstSector = getFistSector(),
            let nSector = getNumSector(firstSector: firstSector){
            feature?.rebootToFlash(sectorOffset: firstSector,
                                   numSector: nSector)
            boardIsRebooting=true;//avoid to disconnect here to give the time to send the message
            
            //create the vc that will search the ota node
            let searchVc = BlueSTSDKSeachOtaNodeViewController.instanziate(
                nodeAddress: BlueSTSDKSTM32WBOTAUtils.getOtaAddressForNode(self.node),
                addressWhereFlash: Int(firstSector)*0x1000)
            //replace the current vc with the one for search the node
            replaceViewController(searchVc,animated: false)
        }else{
            showInvalidRangeError()
        }
    }
    
    private func showInvalidRangeError(){
        let message = String(format: BlueSTSDKStartOtaConfigViewController.INVALID_ARGS_MSG,
                             BlueSTSDKStartOtaConfigViewController.VALID_MEMORY_SECOTR_RANGE.startIndex,
                             BlueSTSDKStartOtaConfigViewController.VALID_MEMORY_SECOTR_RANGE.endIndex)
        showAllert(title: BlueSTSDKStartOtaConfigViewController.INVALID_ARGS_TITLE,
                   message: message)
    }
    
}
