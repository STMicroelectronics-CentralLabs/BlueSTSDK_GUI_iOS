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

#import <Foundation/Foundation.h>

#import <BlueSTSDK/BlueSTSDKNode.h>
#import <BlueSTSDK/BlueSTSDKDebug.h>
#import <BlueSTSDK/BlueSTSDKFwVersion.h>

@protocol BlueSTSDKFwUpgradeReadVersionDelegate;
@protocol BlueSTSDKFwUpgradeUploadFwDelegate;

/**
 * Generic class used to hide the node protocol*/
@interface BlueSTSDKFwUpgradeConsole : NSObject

/* object where send/receve the commands */
@property (retain) BlueSTSDKDebug * _Nonnull console;
/* object where notify the current firmware version */
@property (retain) id<BlueSTSDKFwUpgradeReadVersionDelegate> _Nullable delegateReadVersion;
/* object where notify the current upload status */
@property (retain) id<BlueSTSDKFwUpgradeUploadFwDelegate> _Nonnull delegateLoadFw;


/**
 * create an instance that works with the specific node type
 * @param node node where upload the fiwmare
 */
+(nullable instancetype) getFwUpgradeConsole:(BlueSTSDKNode * _Nullable)node;

 /**
  * @return true if the node is already doing a command
  * if the the console has a delegate != nil
  */
-(BOOL)isWaitingAnswer;

/**
 * add the delegate to listener to the console output. When a delegate != nil is
 * set the UpdateConsole became busy. when implement the protocol remeber to call
 * setConsoleDelegate:nil before exec the next command.
 */
-(void)setConsoleDelegate:(nullable id<BlueSTSDKDebugOutputDelegate>)delegate;

/**
 * read the current firmware version
 * @param delegate object where notify the read fw version
 * @return true if the command is correctly send
 */
-(BOOL)readFwVersion:(nonnull id<BlueSTSDKFwUpgradeReadVersionDelegate>) delegate;

/**
 * upload the file to the board
 * @param file file to upload to the board
 * @param delegate object where notify the upload progress
 * @return true if the command is correctly send
 */
-(BOOL) loadFwFile:(NSURL * _Nonnull)file delegate:(nonnull id<BlueSTSDKFwUpgradeUploadFwDelegate>) delegate;
@end

/**
 * Delegate used to comunicate the firmware version 
 */
@protocol BlueSTSDKFwUpgradeReadVersionDelegate
/**
 * function called when the firmware version is read
 * @param console object used for read the versione
 * @param version version read
 */
@required
- (void) fwUpgrade:(BlueSTSDKFwUpgradeConsole * _Nonnull)console didVersionRead:(BlueSTSDKFwVersion* _Nullable)version;
@end

typedef NS_ENUM(uint8_t, BlueSTSDKFwUpgradeUploadFwError) {
    // the crc of the receved file doen't match the original one
    BLUESTSDK_FWUPGRADE_UPLOAD_CORRUPTED_FILE,
    // some package it get lost during the trasmission
    BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_TRANSMISSION,
    // the file is not valid and can not be upload
    BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_INVALID_FW_FILE,
    // unknown error
    BLUESTSDK_FWUPGRADE_UPLOAD_ERROR_UNKNOWN=0xFF
};


@protocol BlueSTSDKFwUpgradeUploadFwDelegate
/**
 * function called when the firmware file is correctly upload to the node 
 * @param console object used to upload the file
 * @param file file upload to the board
 */
@required
- (void) fwUpgrade:(BlueSTSDKFwUpgradeConsole * _Nonnull)console onLoadComplite:(NSURL* _Nonnull)file;

/**
 * function called when the firmware file had an error during the uploading
 * @param console object used to upload the file
 * @param file file upload to the board
 * @param error error that happen during the upload
 */
@required
- (void) fwUpgrade:(BlueSTSDKFwUpgradeConsole * _Nonnull)console onLoadError:(NSURL* _Nonnull)file error:(BlueSTSDKFwUpgradeUploadFwError)error;

/**
 * function called during the file upload
 * @param console object used to upload the file
 * @param file file upload to the board
 * @param load number of bytes loaded into the board
 */
@required
- (void) fwUpgrade:(BlueSTSDKFwUpgradeConsole * _Nonnull)console onLoadProgres:(NSURL* _Nonnull)file loadBytes:(NSUInteger)load;

@end

