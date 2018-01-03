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

public class BlueSTSDKFwUpgradeProgressViewController: BlueSTSDKFwUpgradeUploadFwDelegate{
    
    
    private static let UPLOADING_MSG:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeProgressViewController.self);
        return NSLocalizedString("Flashing the new firmware", tableName: nil,
                                        bundle: bundle,
                                        value: "Flashing the new firmware",
                                        comment: "Flashing the new firmware");
    }();
    
    private static let PROGRESS_FORMAT:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeProgressViewController.self);
        return NSLocalizedString("%d/%ld bytes", tableName: nil,
                                 bundle: bundle,
                                 value: "%d/%ld bytes",
                                 comment: "%d/%ld bytes");
    }();

    private static let UPLOAD_COMPLETE_FORMAT:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeProgressViewController.self);
        return NSLocalizedString("Upgrade completed in: %.2fs\nThe board is resetting", tableName: nil,
                                 bundle: bundle,
                                 value: "Upgrade completed in: %.2fs\nThe board is resetting",
                                 comment: "Upgrade completed in: %.2fs\nThe board is resetting");
    }();

    
    private static let CORRUPTED_DATA_ERR:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeProgressViewController.self);
        return NSLocalizedString("Transmitted data are corrupted", tableName: nil,
                                 bundle: bundle,
                                 value: "Transmitted data are corrupted",
                                 comment: "Transmitted data are corrupted");
    }();
    
    
    private static let TRANSMISION_ERR:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeProgressViewController.self);
        return NSLocalizedString("Error sending the data", tableName: nil,
                                 bundle: bundle,
                                 value: "Error sending the data",
                                 comment: "Error sending the data");
    }();
    
    private static let INVALID_FW_FILE_ERR:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeProgressViewController.self);
        return NSLocalizedString("Error while opening the file", tableName: nil,
                                 bundle: bundle,
                                 value: "Error while opening the file",
                                 comment: "Error while opening the file");
    }();
    
    private static let UNKNOWN_ERR:String = {
        let bundle = Bundle(for: BlueSTSDKFwUpgradeProgressViewController.self);
        return NSLocalizedString("Unknown Error", tableName: nil,
                                 bundle: bundle,
                                 value: "Unknown Error",
                                 comment: "Unknown Error");
    }();
    
    
    private unowned let mUploadProgressLabel:UILabel;
    private unowned let mUploadStatusProgress:UILabel;
    private unowned let mUploadProgressView:UIProgressView;
    
    public weak var mFwUploadDelegate:BlueSTSDKFwUpgradeUploadFwDelegate?=nil;
    
    private var mFileLength:UInt=0;
    private var mStartUploadDate:Date = Date();

    init( progressLabel:UILabel!, statusLabel:UILabel! ,progressView:UIProgressView! ){
        mUploadProgressLabel = progressLabel;
        mUploadStatusProgress = statusLabel;
        mUploadProgressView = progressView;
    }

    
    /**
     * function called when the firmware file is correctly upload to the node
     * @param console object used to upload the file
     * @param file file upload to the board
     */
    
    public func fwUpgrade(_ console: BlueSTSDKFwUpgradeConsole, onLoadComplite file: URL){
        mFwUploadDelegate?.fwUpgrade(console, onLoadComplite: file);
        let time = -mStartUploadDate.timeIntervalSinceNow;
        let message = String(format: BlueSTSDKFwUpgradeProgressViewController.UPLOAD_COMPLETE_FORMAT,
                             time);
        DispatchQueue.main.async {
            self.mUploadStatusProgress.text=message;
        }
    }
    

    /**
     * function called when the firmware file had an error during the uploading
     * @param console object used to upload the file
     * @param file file upload to the board
     * @param error error that happen during the upload
     */
    
    public func fwUpgrade(_ console: BlueSTSDKFwUpgradeConsole,
                          onLoadError file: URL,
                          error: BlueSTSDKFwUpgradeUploadFwError){
    
        let errorStr = BlueSTSDKFwUpgradeProgressViewController.getErrorString(error);
        DispatchQueue.main.async {
            self.mUploadStatusProgress.text = errorStr;
        }
    
    }
    
    
    private static func getErrorString(_ error:BlueSTSDKFwUpgradeUploadFwError)->String{
        switch(error){
            case .BLUESTSDK_FWUPGRADE_UPLOAD_CORRUPTED_FILE:
                return CORRUPTED_DATA_ERR;
            case .BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_TRANSMISSION:
                return TRANSMISION_ERR;
            case .BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_INVALID_FW_FILE:
                return INVALID_FW_FILE_ERR;
            case .BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_UNKNOWN:
                return UNKNOWN_ERR;
        }//switch
    }
    
    private func updateProgressView( load:UInt){
        mUploadProgressView.progress = 1.0 - (Float(load))/Float(mFileLength);
        mUploadProgressLabel.text = String(format: BlueSTSDKFwUpgradeProgressViewController.PROGRESS_FORMAT,
                                           UInt(mFileLength-load),Int64(mFileLength));
    }
    
    public func fwUpgrade(_ console: BlueSTSDKFwUpgradeConsole, onLoadProgres file: URL, loadBytes load: UInt){
        mFwUploadDelegate?.fwUpgrade(console, onLoadProgres: file, loadBytes: load);
        if(mFileLength==0){
            mFileLength = load;
            mStartUploadDate = Date();
            DispatchQueue.main.async {
                self.mUploadStatusProgress.text = BlueSTSDKFwUpgradeProgressViewController.UPLOADING_MSG;
            }
        }
        DispatchQueue.main.async {
            self.updateProgressView(load: load);
        }
    }
}
