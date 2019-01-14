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
import UIKit

public class BlueSTSDKFwUpgradeManagerViewController: UIViewController{
    
    
    /// instanziate a View controller to upload a new fw on the board
    ///
    /// - Parameters:
    ///   - node: node where upload the board
    ///   - requireAddress: true if the use has to insert an address where upload the firmware
    ///   - defaultAddress: default address where load the fw
    ///   - fwRemoteUrl: if present the fw will be dowloaded from this url
    /// - Returns: BlueSTSDKFwUpgradeManagerViewController instance
    public static func instaziate(forNode node:BlueSTSDKNode, requireAddress:Bool, defaultAddress:Int?=nil, fwRemoteUrl:URL?=nil)->BlueSTSDKFwUpgradeManagerViewController{
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self)
        let storyBoard = UIStoryboard(name: "FwUpgrade", bundle: bundle)
        
        let fwUpgradeController = storyBoard.instantiateInitialViewController() as! BlueSTSDKFwUpgradeManagerViewController
        
        fwUpgradeController.node=node
        fwUpgradeController.requireAddress=requireAddress
        fwUpgradeController.defaultAddress=defaultAddress
        fwUpgradeController.fwRemoteUrl=fwRemoteUrl
        
        return fwUpgradeController;
    }
    
    
    
    private static let ERROR_TITLE_MSG:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("Error", tableName: nil,
                                 bundle: bundle,
                                 value: "Error",
                                 comment: "Error");
    }();
    
    private static let ERROR_ADDRESS_RANGE_FORMAT:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("The address is not in the range: [0x%x,0x%x]", tableName: nil,
                                 bundle: bundle,
                                 value: "The address is not in the range: [0x%x,0x%x]",
                                 comment: "The address is not in the range: [0x%x,0x%x]");
    }();

    private static let FW_UPGRADE_NOT_AVAILABLE_ERR:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("Firmware upgrade not available", tableName: nil,
                                 bundle: bundle,
                                 value: "Firmware upgrade not available",
                                 comment: "Firmware upgrade not available");
    }();
    
    static let FW_UPGRADE_NOT_SUPPORTED_ERR:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("Firmware upgrade not supported, please upgrade the firmware", tableName: nil,
                                 bundle: bundle,
                                 value: "Firmware upgrade not supported, please upgrade the firmware",
                                 comment: "Firmware upgrade not supported, please upgrade the firmware");
    }();
    
    static let FORMATTING_MSG:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("Formatting...", tableName: nil,
                                 bundle: bundle,
                                 value: "Formatting...",
                                 comment: "Formatting...");
    }();
    
    static let MIN_VERSION = [
      BlueSTSDKFwVersion(name: "BLUEMICROSYSTEM2", mcuType: nil, major: 2, minor: 0, patch: 1)
    ];
    
    
    static let READ_VERSION:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("Reading firmware version", tableName: nil,
                                 bundle: bundle,
                                 value: "Reading firmware version",
                                 comment: "Reading firmware version");
    }();
    
    private static func checkOldVersion(version:BlueSTSDKFwVersion)->Bool{
        
        for v in MIN_VERSION {
            if(v.name == version.name){
                if(v.compare(version) == .orderedDescending){
                    return true;
                }
            }
        }
        return false;
    }
    
    @IBOutlet weak var mBoardFwNameLabel: UILabel!
    @IBOutlet weak var mFwVersionLabel: UILabel!
    @IBOutlet weak var mFwTypeLabel: UILabel!

    @IBOutlet weak var mUploadView: UIView!
    @IBOutlet weak var mUploadProgressView: UIProgressView!
    @IBOutlet weak var mUploadProgressLabel: UILabel!
    @IBOutlet weak var mUploadStatusProgress: UILabel!
   
    @IBOutlet weak var mSelectFileButton: UIBarButtonItem!

    @IBOutlet weak var mAddressView: UIStackView!
    @IBOutlet weak var mAddressText: UITextField!
    
    public var node:BlueSTSDKNode?;
    public var fwRemoteUrl:URL?;
    
    public var requireAddress:Bool=false
    public var defaultAddress:UInt32?=nil
    
    private var mLoadVersionHud:MBProgressHUD?;
    private var mFwUpgradeConsole:BlueSTSDKFwUpgradeConsole?;
    private var mReadVersionConsole:BlueSTSDKFwReadVersionConsole?;
    private var mProgresViewController:BlueSTSDKFwUpgradeProgressViewController!;
    private var mDownloadProgressViewController:BlueSTSDKDownloadFileViewController!;
    
    private func showHud(){
        mLoadVersionHud = MBProgressHUD.showAdded(to: self.view, animated: true);
        mLoadVersionHud?.mode = .indeterminate;
        mLoadVersionHud?.removeFromSuperViewOnHide=true;
        mLoadVersionHud?.label.text = BlueSTSDKFwUpgradeManagerViewController.READ_VERSION;
    }

    private func setRightBarButton(){
        //we set also in the parent in the case the vc is used inside another view controller
        // like the DemoViewController
        parent?.navigationItem.rightBarButtonItem = mSelectFileButton
        navigationItem.rightBarButtonItem = mSelectFileButton
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setRightBarButton()
        mProgresViewController =
            BlueSTSDKFwUpgradeProgressViewController(progressLabel: mUploadProgressLabel,
                                                     statusLabel: mUploadStatusProgress,
                                                     progressView: mUploadProgressView)
        mProgresViewController.mFwUploadDelegate=self;
        mDownloadProgressViewController =
            BlueSTSDKDownloadFileViewController(progressLabel: mUploadProgressLabel,
                                                 statusLabel: mUploadStatusProgress,
                                                 progressView: mUploadProgressView)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        showHud();
        mReadVersionConsole = BlueSTSDKFwConsoleUtil.getFwReadVersionConsoleForNode(node: self.node)
        mFwUpgradeConsole = BlueSTSDKFwConsoleUtil.getFwUploadConsoleForNode(node: self.node)
        _ = mReadVersionConsole?.readFwVersion{ [weak self] version in
            self?.onFwVersionRead(version)
        }
        
        mAddressView.isHidden = !requireAddress;
        if let address = defaultAddress{
            mAddressText.text = String(format:"%X",address)
        }
        
    }
    
    @IBAction func onSelectFileButtonPress(_ sender: UIBarButtonItem) {
        guard  hasValidFlashAddress() else {
            let msg = String(format: BlueSTSDKFwUpgradeManagerViewController.ERROR_ADDRESS_RANGE_FORMAT,
                             mFwUpgradeConsole?.validAddressRange.lowerBound ?? UInt32.min,
                             mFwUpgradeConsole?.validAddressRange.upperBound ?? UInt32.max)
            showAllert(title: BlueSTSDKFwUpgradeManagerViewController.ERROR_TITLE_MSG,
                       message: msg)
            return;
        }
        if let userAddress = UInt32(mAddressText.text ?? "", radix: 16){
            defaultAddress = userAddress
        }
        let docPicker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
        docPicker.delegate = self
        docPicker.popoverPresentationController?.barButtonItem=sender
        present(docPicker, animated: true, completion: nil)
    }
    
    private func hasValidFlashAddress()->Bool{
        //if address is not required return true
        guard requireAddress == true else {
            return true;
        }
        
        if let text = mAddressText.text,
            let address = UInt32(text, radix: 16){
            return mFwUpgradeConsole?.validAddressRange.contains(address) ?? false
        }else{
            return false
        }
    }
    
    fileprivate func startFwUpgrade(firmware: URL){
        //onSelectFileButtonPress has check that is a valid address
        DispatchQueue.main.async{
            self.mUploadView.isHidden=false
            self.mUploadStatusProgress.text = BlueSTSDKFwUpgradeManagerViewController.FORMATTING_MSG
            
        }
        let address = defaultAddress != nil ? UInt32(defaultAddress!) : nil
        
        _ = self.mFwUpgradeConsole?.loadFwFile(type:.applicationFirmware,
                                               file:firmware,
                                               delegate: self.mProgresViewController,
                                               address: address)
    }
    
    private func onFwVersionRead(_ version: BlueSTSDKFwVersion?){
        DispatchQueue.main.async {
            self.mLoadVersionHud?.hide(animated: true);
            self.mLoadVersionHud=nil
            
            guard version != nil else{
                self.showAllert(title: BlueSTSDKFwUpgradeManagerViewController.ERROR_TITLE_MSG,
                                message: BlueSTSDKFwUpgradeManagerViewController.FW_UPGRADE_NOT_AVAILABLE_ERR,
                                  closeController: true)
                return
            }
            
            self.mBoardFwNameLabel.text = version?.name;
            self.mFwTypeLabel.text = version?.mcuType;
            self.mFwVersionLabel.text = version?.getNumberStr();
            if(BlueSTSDKFwUpgradeManagerViewController.checkOldVersion(version: version!)){
                self.showAllert(title: BlueSTSDKFwUpgradeManagerViewController.ERROR_TITLE_MSG,
                                message: BlueSTSDKFwUpgradeManagerViewController.FW_UPGRADE_NOT_SUPPORTED_ERR,
                                closeController: true)
            }else{
                self.mSelectFileButton.isEnabled=true
            }
            
            if let url = self.fwRemoteUrl{
                self.mUploadView.isHidden=false;
                self.mDownloadProgressViewController.downloadFile(url: url, onComplete: {
                    self.startFwUpgrade(firmware:  $0)
                })
            }
        }       
    }

}
 
 extension BlueSTSDKFwUpgradeManagerViewController :UIDocumentPickerDelegate{
    public func documentPicker(_ pickController:UIDocumentPickerViewController, didPickDocumentsAt urls:[URL]){
        if let selectedFile = urls.first{
            startFwUpgrade(firmware: selectedFile)
        }
    }
    
    public func documentPicker(_ pickController:UIDocumentPickerViewController, didPickDocumentAt url:URL){
        startFwUpgrade(firmware: url)
    }
    
 }
 
 
 extension BlueSTSDKFwUpgradeManagerViewController : BlueSTSDKFwUpgradeConsoleCallback{
    
    private static let UPLOAD_COMPLETE_TITLE:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("Upgrade completed", tableName: nil,
                                 bundle: bundle,
                                 value: "Upgrade completed",
                                 comment: "Upgrade completed");
    }();
    
    private static let UPLOAD_COMPLETE_CONTENT:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("The board is resetting", tableName: nil,
                                 bundle: bundle,
                                 value: "The board is resetting",
                                 comment: "The board is resetting");
    }();
    
    public func onLoadComplite(file: URL) {
        self.showAllert(title: BlueSTSDKFwUpgradeManagerViewController.UPLOAD_COMPLETE_TITLE,
                        message: BlueSTSDKFwUpgradeManagerViewController.UPLOAD_COMPLETE_CONTENT,
                        closeController: true)
    }
    
    public func onLoadError(file: URL, error: BlueSTSDKFwUpgradeError) {
        
    }
    
    public func onLoadProgres(file: URL, remainingBytes: UInt) {
        
    }
    
    
 
 }
