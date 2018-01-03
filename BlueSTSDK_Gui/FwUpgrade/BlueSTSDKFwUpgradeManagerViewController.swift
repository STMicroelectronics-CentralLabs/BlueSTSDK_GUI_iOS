/*
 * Copyright (c) 2017  STMicroelectronics – All rights reserved
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
import UIKit

public class BlueSTSDKFwUpgradeManagerViewController: UIViewController,
    UIDocumentPickerDelegate,
    UIDocumentMenuDelegate,
    BlueSTSDKFwUpgradeReadVersionDelegate{
    
    private static let ERROR_TITLE_MSG:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeManagerViewController.self);
        return NSLocalizedString("Error", tableName: nil,
                                 bundle: bundle,
                                 value: "Error",
                                 comment: "Error");
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

    @objc public var node:BlueSTSDKNode?;
    @objc public var fwRemoteUrl:URL?;
    private var mLoadVersionHud:MBProgressHUD!;
    private var mConsole:BlueSTSDKFwUpgradeConsole?;
    private var mProgresViewController:BlueSTSDKFwUpgradeProgressViewController!;
    private var mDownloadProgressViewController:BlueSTSDKDownloadFileViewController!;
    
    private func showHud(){
        mLoadVersionHud = MBProgressHUD.showAdded(to: self.view, animated: true);
        mLoadVersionHud.mode = .indeterminate;
        mLoadVersionHud.removeFromSuperViewOnHide=true;
        mLoadVersionHud.label.text = BlueSTSDKFwUpgradeManagerViewController.READ_VERSION;
    }
    
    public override func viewDidLoad() {
        self.navigationItem.rightBarButtonItem = mSelectFileButton;
        mProgresViewController =
            BlueSTSDKFwUpgradeProgressViewController(progressLabel: mUploadProgressLabel,
                                                     statusLabel: mUploadStatusProgress,
                                                     progressView: mUploadProgressView);
        mDownloadProgressViewController =
            BlueSTSDKDownloadFileViewController(progressLabel: mUploadProgressLabel,
                                                 statusLabel: mUploadStatusProgress,
                                                 progressView: mUploadProgressView);
        showHud();
        mConsole = BlueSTSDKFwUpgradeConsole .getFwUpgradeConsole(self.node);
        mConsole?.readFwVersion(self);
    }
    
    @IBAction func onSelectFileButtonPress(_ sender: UIBarButtonItem) {
        let docMenu = UIDocumentMenuViewController(documentTypes: ["public.data"], in: .import);

        docMenu.delegate=self;
        docMenu.popoverPresentationController?.barButtonItem=sender;
        present(docMenu, animated: true, completion: nil);
    }
    
    
    private func startFwUpgrade(firmware: URL){
        mUploadView.isHidden=false;
        mUploadStatusProgress.text = BlueSTSDKFwUpgradeManagerViewController.FORMATTING_MSG;
        mConsole?.loadFwFile(firmware, delegate: mProgresViewController);
    }
    
    public func documentPicker(_ pickController:UIDocumentPickerViewController, didPickDocumentAt: URL){
        startFwUpgrade(firmware: didPickDocumentAt)
    }
 
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController,
                      didPickDocumentPicker documentPicker: UIDocumentPickerViewController){
        documentPicker.delegate=self;
        present(documentPicker, animated: true, completion: nil)
    }
    
    
    public func fwUpgrade(_ console: BlueSTSDKFwUpgradeConsole, didVersionRead version: BlueSTSDKFwVersion?){
        DispatchQueue.main.async {
            self.mLoadVersionHud.hide(animated: true);
            self.mLoadVersionHud=nil;
            
            guard version != nil else{
                self.showErrorMsg(BlueSTSDKFwUpgradeManagerViewController.FW_UPGRADE_NOT_AVAILABLE_ERR,
                                  title: BlueSTSDKFwUpgradeManagerViewController.ERROR_TITLE_MSG,
                                  closeController: true)
                return;
            }
            
            self.mBoardFwNameLabel.text = version?.name;
            self.mFwTypeLabel.text = version?.mcuType;
            self.mFwVersionLabel.text = version?.getNumberStr();
            if(BlueSTSDKFwUpgradeManagerViewController.checkOldVersion(version: version!)){
                self.showErrorMsg(BlueSTSDKFwUpgradeManagerViewController.FW_UPGRADE_NOT_SUPPORTED_ERR,
                                  title: BlueSTSDKFwUpgradeManagerViewController.ERROR_TITLE_MSG,
                                  closeController: true)
            }else{
                self.mSelectFileButton.isEnabled=true;
            }
            
            if let url = self.fwRemoteUrl{
                self.mUploadView.isHidden=false;
                self.mDownloadProgressViewController.downloadFile(url: url, onComplete: {
                    self.startFwUpgrade(firmware:  $0);
                })
            }
        }       
    }

}
