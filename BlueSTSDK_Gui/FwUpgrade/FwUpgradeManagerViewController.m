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

#import "FwUpgradeManagerViewController.h"
#import "BlueSTSDKFwUpgradeConsole.h"
#import "UIViewController+BlueSTSDK.h"
#import "MBProgressHUD.h"

#import <BlueSTSDK/BlueSTSDKFwVersion.h>
#import <BlueSTSDK/BlueSTSDK_LocalizeUtil.h>

#define READ_VERSION (BLUESTSDK_LOCALIZE(@"Reading firmware version",nil))
#define UPLOADING_MSG (BLUESTSDK_LOCALIZE(@"Flashing the new firmware",nil))
#define FORMATTING_MSG (BLUESTSDK_LOCALIZE(@"Formatting...",nil))
#define FW_UPGRADE_NOT_AVAILABLE_ERR (BLUESTSDK_LOCALIZE(@"Firmware upgrade not available",nil))
#define FW_UPGRADE_NOT_SUPPORTED_ERR (BLUESTSDK_LOCALIZE(@"Firmware upgrade not supported, please upgrade the firmware",nil))
#define UPLOAD_COMPLETE_WITH_TIME_MSG (BLUESTSDK_LOCALIZE(@"Upgrade completed in: %.2fs\nThe board is resetting",nil))
#define CORRUPTED_DATA_ERR  (BLUESTSDK_LOCALIZE(@"Transmitted data are corrupted",nil))
#define TRANSMISION_ERR (BLUESTSDK_LOCALIZE(@"Error sending the data",nil))
#define INVALID_FW_FILE_ERR (BLUESTSDK_LOCALIZE(@"Error while opening the file",nil))
#define UNKNOWN_ERR (BLUESTSDK_LOCALIZE(@"Unknown Error",nil))
#define ERROR_TITLE (BLUESTSDK_LOCALIZE(@"Error",nil))
#define SUCCESS_TITLE (BLUESTSDK_LOCALIZE(@"FW Flash done",nil))

static NSArray<BlueSTSDKFwVersion*> *sMinVersion;



@interface FwUpgradeManagerViewController ()<UIDocumentPickerDelegate,
        UIDocumentMenuDelegate,
        BlueSTSDKFwUpgradeReadVersionDelegate,
        BlueSTSDKFwUpgradeUploadFwDelegate>
@end

@implementation FwUpgradeManagerViewController{


    BlueSTSDKFwUpgradeConsole *mConsole;

    MBProgressHUD *loadVersionHud;
    
    __weak IBOutlet UILabel *mUploadProgresLabel;
    __weak IBOutlet UILabel *mUploadStatusProgres;
    __weak IBOutlet UIProgressView *mUploadProgressView;
    __weak IBOutlet UIView *mUploadView;
    __weak IBOutlet UILabel *mBoardFwName;
    __weak IBOutlet UILabel *mFwVersion;
    __weak IBOutlet UILabel *mFwType;
    __weak IBOutlet UIBarButtonItem *mUploadBarButton;

    NSInteger mFwFileLength;
    NSDate *mStartTimestamp;
}


+(void)initialize {
    if (self == [FwUpgradeManagerViewController class]) {
        sMinVersion = @[
                [BlueSTSDKFwVersion versionWithName:@"BLUEMICROSYSTEM2" mcuType:nil major:2 minor:0 patch:1] /*,
                [BlueSTSDKFwVersion versionWithName:@"MOTENV1" mcuType:nil major:2 minor:0 patch:1],
                [BlueSTSDKFwVersion versionWithName:@"ALLMEMS1" mcuType:nil major:2 minor:0 patch:1]*/
                
        ];
    }
}


-(BOOL)checkOldVersion:(BlueSTSDKFwVersion *)version{
    for(BlueSTSDKFwVersion *i in sMinVersion){
        if([i.name compare:version.name]==NSOrderedSame){
            if([i compareVersion:version]==NSOrderedDescending){
                return TRUE;
            }
        }
    }
    return FALSE;
}

-(void)showHud{
    loadVersionHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    loadVersionHud.mode = MBProgressHUDModeIndeterminate;
    loadVersionHud.removeFromSuperViewOnHide = YES;
    loadVersionHud.label.text = READ_VERSION;

    [loadVersionHud showAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.navigationItem!=nil){
        self.navigationItem.rightBarButtonItem=mUploadBarButton;
    }else{
        @throw [NSException exceptionWithName:@"Invalid View Controller"
                                       reason:@"FwUpgradeManagerViewController need to be inside a Navigation View controller"
                                     userInfo:nil];
    }

    mConsole = [BlueSTSDKFwUpgradeConsole getFwUpgradeConsole:self.node];
    [self showHud];
    [mConsole readFwVersion:self];
}

- (IBAction)onUploadFileClick:(UIBarButtonItem *)sender {

    
    //[mConsole loadFwFile:nil delegate:self];

    UIDocumentMenuViewController *docMenu= [[UIDocumentMenuViewController alloc]
            initWithDocumentTypes:@[@"public.data" ] inMode:UIDocumentPickerModeImport];
    docMenu.delegate=self;
    docMenu.popoverPresentationController.barButtonItem=sender;
    [self presentViewController:docMenu animated:YES completion:nil];
 
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    mFwFileLength=0;
    mUploadView.hidden=false;
    mUploadStatusProgres.text=FORMATTING_MSG;
    [mConsole loadFwFile:url delegate:self];
}


- (void)fwUpgrade:(BlueSTSDKFwUpgradeConsole *)console didVersionRead:(BlueSTSDKFwVersion *)version {
    dispatch_async(dispatch_get_main_queue(),^{
        [loadVersionHud hideAnimated:true];
        loadVersionHud=nil;

        if(version==nil){
            [self showErrorMsg:FW_UPGRADE_NOT_AVAILABLE_ERR title:ERROR_TITLE closeController:true];
            return;
        }

        //else
        mBoardFwName.text = version.name;
        mFwType.text = version.mcuType;
        mFwVersion.text = [NSString stringWithFormat:@"%ld.%ld.%ld",
                           (long)version.major,
                           (long)version.minor,
                           (long)version.patch];
        if ([self checkOldVersion:version]) {
            [self showErrorMsg:FW_UPGRADE_NOT_SUPPORTED_ERR title:ERROR_TITLE closeController:true];
        }else {
            mUploadBarButton.enabled = true;
        }
    });


}

- (void)fwUpgrade:(BlueSTSDKFwUpgradeConsole *)console onLoadComplite:(NSURL *)file {
    NSTimeInterval time = -[mStartTimestamp timeIntervalSinceNow];
    NSString * msg = [NSString stringWithFormat:UPLOAD_COMPLETE_WITH_TIME_MSG,time];
    dispatch_async(dispatch_get_main_queue(),^{
        [self showErrorMsg:msg title:SUCCESS_TITLE closeController:false];
        mUploadStatusProgres.text= msg;
    });
}

-(NSString*) getErrorMsg:(BlueSTSDKFwUpgradeUploadFwError)error{
    switch (error) {
        case BLUESTSDK_FWUPGRADE_UPLOAD_CORRUPTED_FILE:
            return CORRUPTED_DATA_ERR;
        case BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_TRANSMISSION:
            return TRANSMISION_ERR;
        case BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_INVALID_FW_FILE:
            return INVALID_FW_FILE_ERR;
        case BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_UNKNOWN:
            return UNKNOWN_ERR;
        default:
            return nil;
    }//switch
}

- (void)fwUpgrade:(BlueSTSDKFwUpgradeConsole *)console onLoadError:(NSURL *)file
            error:(BlueSTSDKFwUpgradeUploadFwError)error {
    NSString *errorMsg= [self getErrorMsg:error];
    dispatch_async(dispatch_get_main_queue(),^{
        [self showErrorMsg:errorMsg title:ERROR_TITLE closeController:false];
        mUploadStatusProgres.text = errorMsg;
    });
}



- (void)fwUpgrade:(BlueSTSDKFwUpgradeConsole *)console onLoadProgres:(NSURL *)file
        loadBytes:(NSUInteger)load {
    if(mFwFileLength==0){
        mFwFileLength=load;
        mStartTimestamp = [NSDate date];
        dispatch_async(dispatch_get_main_queue(),^{
            mUploadStatusProgres.text=UPLOADING_MSG;
        });
    }
    dispatch_async(dispatch_get_main_queue(),^{
        [self updateProgressView:load];
    });

}

- (void)updateProgressView:(NSUInteger)load {
    mUploadProgressView.progress=1.0f-load/(float)mFwFileLength;
    mUploadProgresLabel.text= [NSString stringWithFormat:BLUESTSDK_LOCALIZE(@"%d/%ld bytes",nil),
                               (int)(mFwFileLength-load),(long)mFwFileLength];
}

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu
        didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate=self;
    [self presentViewController:documentPicker animated:YES completion:nil];
}


@end
