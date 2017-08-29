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

#import "BlueSTSDKDemoViewController.h"
#import "DebugConsole/BlueSTSDKDebugConsoleViewController.h"
#import "UIViewController+BlueSTSDK.h"
#import "FwUpgrade/FwUpgradeManagerViewController.h"
#import <BlueSTSDK/BlueSTSDK_LocalizeUtil.h>

#import <MessageUI/MessageUI.h>

#define START_LOG_NAME BLUESTSDK_LOCALIZE(@"Start Logging",nil)
#define STOP_LOG_NAME BLUESTSDK_LOCALIZE(@"Stop Logging",nil)
#define SHOW_DEBUG_NAME BLUESTSDK_LOCALIZE(@"Show Debug Console",nil)
#define SHOW_LICENSE_MANAGER_NAME BLUESTSDK_LOCALIZE(@"License Manager",nil)
#define SHOW_FWUPGRADE_MANAGER_NAME BLUESTSDK_LOCALIZE(@"Firmware Upgrade",nil)
#define CANCEL_NAME BLUESTSDK_LOCALIZE(@"Cancel",nil)
#define MAIL_TITLE BLUESTSDK_LOCALIZE(@"Logger data",nil)

@interface BlueSTSDKDemoViewController() <MFMailComposeViewControllerDelegate, BlueSTSDKNodeStateDelegate>

@end

@implementation BlueSTSDKDemoViewController{
    bool mIsLogging;
    BlueSTSDKFeatureLogCSV *mLogger;
    NSMutableArray<UIAlertAction*> *mActions;
    UIAlertAction *mActionDebug;
    UIAlertAction *mActionFwUpgradeManager;
    UIAlertAction *mActionStartLog;
    UIAlertAction *mActionStopLog;
}

- (void) displayContentController: (UIViewController*) content {
    [self addChildViewController:content];
    content.view.frame = self.demoView.bounds;
    [self.view addSubview:content.view];
    [content didMoveToParentViewController:self];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    mActions = [NSMutableArray array];
    
    mActionStartLog = [UIAlertAction actionWithTitle:START_LOG_NAME
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
                                                 [self changeLoggingStatus]; }];
    
    mActionStopLog = [UIAlertAction actionWithTitle:STOP_LOG_NAME
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self changeLoggingStatus];}];
    
    mActionDebug = [UIAlertAction   actionWithTitle:SHOW_DEBUG_NAME
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self moveToDebugConsoleViewController];
                                            }];


    mActionFwUpgradeManager = [UIAlertAction   actionWithTitle:SHOW_FWUPGRADE_MANAGER_NAME
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [self moveToFwUpgradeManagerViewController];
                                                     }];
    
    
    [self addMenuAction:mActionStartLog];
    [self addMenuAction:mActionDebug];
    [self addMenuAction:mActionFwUpgradeManager];
    
    UIBarButtonItem *extraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                 target:self
                                                                                 action:@selector(showPopupMenu:)];
    
    self.navigationItem.rightBarButtonItems =@[extraButton];
    
    //this must be called after initialized the menu since it create the other
    //control view that can add menu items
    [self displayContentController:self.demoViewController];
}


-(UIAlertController*) createMenuController{
    
   UIAlertController* alertController = [UIAlertController
                        alertControllerWithTitle:nil message:nil
                        preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (UIAlertAction *a in mActions){
        [alertController addAction:[a copy]];
    }
    
    //on the iphone add the cancel button
    if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ){
        [alertController addAction:
         [UIAlertAction actionWithTitle:CANCEL_NAME
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
    }
    
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    return alertController;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    mLogger = [[BlueSTSDKFeatureLogCSV alloc] initWithTimestamp:[NSDate date]
                                                          nodes:@[self.node]];
    //add the debug console if present
    if(self.node.debugConsole==nil) {
        [self removeMenuAction:mActionDebug];
        [self removeMenuAction:mActionFwUpgradeManager];
    }else if(self.node.type == BlueSTSDKNodeTypeSTEVAL_WESU1){
        [self removeMenuAction:mActionFwUpgradeManager];
    }
        
    [self.node addNodeStatusDelegate:self];
}

-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.node removeNodeStatusDelegate:self];
}

-(void) sendLogToMail{
    MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
    mail.mailComposeDelegate = self;
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    [mail setSubject:[NSString stringWithFormat:@"[%@] %@",appName, MAIL_TITLE]];
    if ([MFMailComposeViewController canSendMail]) {
        NSArray *files = [BlueSTSDKFeatureLogCSV getAllLogFiles];
        if(files.count==0)
            return;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (NSURL *file in files) {
            NSData *data = [fileManager contentsAtPath:file.path];
            [mail addAttachmentData:data mimeType:@"text/plain" fileName: file.lastPathComponent];
        }//for
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self.navigationController presentViewController:mail animated:YES completion:nil];
        } else {
            [self presentViewController:mail animated:YES completion:nil];
        }//if-else
    }//if
}

-(void) startLogging{
    NSArray *features = [_node getFeatures];
    for(BlueSTSDKFeature *f in features){
        [f addFeatureLoggerDelegate:mLogger];
    
    }
    [self addMenuAction:mActionStopLog atIndex:0];
    [self removeMenuAction:mActionStartLog];
}

-(void) stopLogging{
    NSArray *features = [_node getFeatures];
    for(BlueSTSDKFeature *f in features){
        [f removeFeatureLoggerDelegate:mLogger];
    }
    [mLogger closeFiles];
    [self addMenuAction:mActionStartLog atIndex:0];
    [self removeMenuAction:mActionStopLog];
    [self sendLogToMail];
}

- (void)changeLoggingStatus {
    if(mIsLogging){
        [self stopLogging];
    }else{
        [self startLogging];
    }//if-else
    mIsLogging=!mIsLogging;
    
}


//This is one of the delegate methods that handles success or failure
//and dismisses the mail
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    UIAlertController *alert;
    
    if (result == MFMailComposeResultFailed) {
        alert = [UIAlertController alertControllerWithTitle:BLUESTSDK_LOCALIZE(@"Message Failed!",nil)
                                            message:BLUESTSDK_LOCALIZE(@"Your email was not sent",nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        
    }else if (result == MFMailComposeResultSent) {
        alert = [UIAlertController alertControllerWithTitle:BLUESTSDK_LOCALIZE(@"Message Ok",nil)
                                                    message:BLUESTSDK_LOCALIZE(@"Your message has been sent.",nil)
                                             preferredStyle:UIAlertControllerStyleAlert];
        [BlueSTSDKFeatureLogCSV clearLogFolder];
    }
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:BLUESTSDK_LOCALIZE(@"OK",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    if(alert!=nil){
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)showPopupMenu:(UIBarButtonItem *)sender {
    UIAlertController *alertController = [self createMenuController];
    UIPopoverPresentationController *popPresenter = [alertController
                                                     popoverPresentationController];
    popPresenter.barButtonItem=sender;
    popPresenter.sourceView=self.view;
    [self presentViewController:alertController animated:YES completion:nil];
    
}

-(void)moveToDebugConsoleViewController{
    NSBundle *currentBundle = [NSBundle bundleForClass:self.class];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"DebugConsoleMainView" bundle:currentBundle];

    BlueSTSDKDebugConsoleViewController *debugView = [storyBoard instantiateInitialViewController];

    debugView.debugInterface=self.node.debugConsole;

    [self changeViewController:debugView];
}

- (void)moveToFwUpgradeManagerViewController {
    NSBundle *currentBundle = [NSBundle bundleForClass:self.class];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"FwUpgrade" bundle:currentBundle];

    FwUpgradeManagerViewController *fwUpgradeControlView = [storyBoard instantiateInitialViewController];

    fwUpgradeControlView.node=self.node;

    [self changeViewController:fwUpgradeControlView];
}

#pragma mark - BlueSTSDKNodeStateDelegate
- (void) node:(BlueSTSDKNode *)node didChangeState:(BlueSTSDKNodeState)newState
    prevState:(BlueSTSDKNodeState)prevState{
    
    if(newState == BlueSTSDKNodeStateLost || newState == BlueSTSDKNodeStateUnreachable
       || newState == BlueSTSDKNodeStateDead){
        dispatch_sync(dispatch_get_main_queue(),^{
            if(self.navigationController!=nil)
                [self.navigationController popViewControllerAnimated:YES];
        });
    }//if
    
}

#pragma mark - BlueSTSDKViewControllerMenuDelegate

-(void)addMenuAction:(UIAlertAction*)action{
    [mActions addObject:action];
}

-(void)addMenuAction:(UIAlertAction*)action atIndex:(NSUInteger)index{
    [mActions insertObject:action atIndex:index];
}

-(void)removeMenuAction:(UIAlertAction*)action{
    [mActions removeObject:action];
}

-(NSUInteger)getMenuActionCount{
    return mActions.count;
}

@end

