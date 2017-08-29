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

#import "BlueSTSDKDebugConsoleViewController.h"
#import <BlueSTSDK/BlueSTSDK_LocalizeUtil.h>

#define PAUSE_DETECTION_TIME_MS 100 //ms
#define SENDING_TIME_OUT_MS 100 //s
#define MAX_MESSAGE_LENGTH_BYTE 20

static NSDictionary *genericAttribute;
static NSDictionary *errorAttribute;
static NSDictionary *outAttribute;
static NSDictionary *inAttribute;

typedef NS_ENUM(NSInteger, Type_e){
    TypeError,
    TypeOut,
    TypeIn,
    TypeGeneric,
};

@implementation BlueSTSDKDebugConsoleViewController{
    NSMutableAttributedString *mDisplayString;
    NSDateFormatter *mDateFormatter;
    NSString *mMessageToSend;
    NSUInteger mLastByteSend;

    NSDate *mLastMessageReceived;
    NSDate *mLastMessageSending;

    NSString *mToSendMessage;
    NSInteger mNextPartToSend;

    __weak IBOutlet UIBarButtonItem *mMenuButton;
    
    BOOL mWaitEcho;
    BOOL mKeyboardIsShown;
}



+(void)initialize{
    if(self == [BlueSTSDKDebugConsoleViewController class]){
        genericAttribute = @{
                        NSForegroundColorAttributeName: [UIColor blackColor]
                        };
        errorAttribute = @{
                           NSForegroundColorAttributeName: [UIColor redColor]
                           };
        outAttribute = @{
                           NSForegroundColorAttributeName: [UIColor blueColor]
                        };
        inAttribute = @{
                           NSForegroundColorAttributeName: [UIColor greenColor]
                        };
    }//if
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.navigationItem!=nil){
        self.navigationItem.rightBarButtonItem=mMenuButton;
    }else{
        @throw [NSException exceptionWithName:@"Invalid View Controller"
                                       reason:@"BlueSTSDKDebugConsoleViewController need to be inside a Navigation View controller"
                                     userInfo:nil];
    }

    
    mDisplayString = [[NSMutableAttributedString alloc] init];
   
    _userText.delegate=self;

    mDateFormatter = [[NSDateFormatter alloc] init];
    mDateFormatter.timeStyle = NSDateFormatterMediumStyle;
    mDateFormatter.dateStyle = NSDateFormatterMediumStyle;

    mLastMessageReceived = [NSDate dateWithTimeIntervalSince1970:0];
    mLastMessageSending = [NSDate dateWithTimeIntervalSince1970:0];
    mToSendMessage = nil;
    mNextPartToSend = -1;
    mWaitEcho = YES;

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [super viewDidAppear:animated];
    [_debugInterface addDebugOutputDelegate:self];
    [_userText becomeFirstResponder];
    [self appendMessage:BLUESTSDK_LOCALIZE(@"Send 'help' for help",nil) type:TypeGeneric eol:YES timestamp:NO];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_debugInterface removeDebugOutputDelegate:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    BOOL ret = [self sendMessage:textField.text eol:YES];
    if (ret) textField.text = @"";
    return ret;
}


-(void)setMessageToSend:(NSString *)msg{
    mMessageToSend= [msg stringByAppendingString:@"\n"];
    mLastByteSend=0;
}

-(BOOL)sendMessage:(NSString *)text eol:(BOOL)eol{
    BOOL ret = NO;
    NSTimeInterval elapsedMillisec = -1000 * [mLastMessageSending timeIntervalSinceNow];

    //not message already sending or time out
    if (!mToSendMessage || (NSInteger)elapsedMillisec > SENDING_TIME_OUT_MS) {
        ret = YES;
        [self resetMessageToSend];
        if (text && text.length > 0) {
            mToSendMessage = (eol ? [NSString stringWithFormat:@"%@\n", text] : text);
            mNextPartToSend = 0;
            ret = [self writeNextMessage];
            mLastMessageSending = [NSDate date];
        }
    }

    return ret;
}

-(void)resetMessageToSend {
    mToSendMessage = nil;
    mNextPartToSend = -1;
}

-(NSString *)previousPartSent {
    NSString *ret = @"";
    NSInteger prevPart = mNextPartToSend - 1;
    NSInteger startIndex = prevPart * MAX_MESSAGE_LENGTH_BYTE;
    if (prevPart >= 0 && mToSendMessage && startIndex < mToSendMessage.length) {
        NSInteger lenToSend = mToSendMessage.length - startIndex;
        NSInteger len = MIN(MAX_MESSAGE_LENGTH_BYTE, lenToSend);

        ret = [mToSendMessage substringWithRange:NSMakeRange(startIndex, len)];
    }
    return ret;
}
-(BOOL)writeNextMessage {
    NSInteger startIndex = mNextPartToSend * MAX_MESSAGE_LENGTH_BYTE;

    if(mToSendMessage && startIndex < mToSendMessage.length) {
        NSInteger lenToSend = mToSendMessage.length - startIndex;
        NSInteger len = MIN(MAX_MESSAGE_LENGTH_BYTE, lenToSend);
        mNextPartToSend++;

        NSString *partToSendMessage = [mToSendMessage substringWithRange:NSMakeRange(startIndex, len)];
        return [_debugInterface writeMessage:partToSendMessage] == partToSendMessage.length;
    }
    return NO;
}

-(void)appendMessage:(NSString *)text type:(Type_e)type eol:(BOOL)eol timestamp:(BOOL)timestamp {

    //prepare the text
    NSMutableString *raw = [NSMutableString stringWithString:@""];
    NSTimeInterval elapsedMillisec = -1000 * [mLastMessageReceived timeIntervalSinceNow];
    if (timestamp && (NSInteger)elapsedMillisec > PAUSE_DETECTION_TIME_MS) {
        [raw appendFormat:@"%@: ", [mDateFormatter stringFromDate:[NSDate date]]];
    }
    [raw appendString:text];
    if (eol) {
        [raw appendString:@"\n"];
    }

    //if available apply the attribe
    NSDictionary *attr = [self attributeType:type];
    NSAttributedString *temp = [[NSAttributedString alloc] initWithString:raw attributes:(attr ? attr : genericAttribute)];
    // be secure that the object doesn't change while displaying
    @synchronized (mDisplayString) {
        [mDisplayString appendAttributedString:temp];
    }
    
    [self updateDisplayString];

    mLastMessageReceived = [NSDate date]; //update in any case
}

-(void)scrollToTheEnd{
    NSRange range = self.console.selectedRange;
    BOOL editable = self.console.editable;
    
    if (self.console.scrollEnabled) {
        if(self.console.text.length > 0 ) {
            NSRange bottom = NSMakeRange(self.console.text.length-1, 1);
            [self.console scrollRangeToVisible:bottom];
            //needed for a smoth scrolling
            [self.console setScrollEnabled:NO];
            [self.console setScrollEnabled:YES];
        }
    }
    self.console.selectedRange = range;
    self.console.editable = editable;

}

-(void)updateDisplayString {
    dispatch_async(dispatch_get_main_queue(),^{
        // be secure that the object doesn't change while displaying
        @synchronized (mDisplayString) {
            self.console.attributedText = mDisplayString;
        }
        [self scrollToTheEnd];
    });
}

-(void) debug:(BlueSTSDKDebug*)debug didStdOutReceived:(NSString*) msg{
    [self appendMessage:msg type:TypeOut eol:NO timestamp:YES];
    if (mWaitEcho && [msg isEqualToString:[self previousPartSent]]) {
        if (![self writeNextMessage]) {
            [self resetMessageToSend];
        }
    }
}

-(void) debug:(BlueSTSDKDebug*)debug didStdErrReceived:(NSString*) msg{
    [self appendMessage:msg type:TypeError eol:NO timestamp:YES];
}

-(void) debug:(BlueSTSDKDebug*)debug didStdInSend:(NSString*) msg error:(NSError*)error{
    if (mWaitEcho) {
        if (mNextPartToSend == 1 && mToSendMessage) {
            [self appendMessage:mToSendMessage type:TypeIn eol:NO timestamp:YES];
        }
    }
    else {
        [self appendMessage:msg type:TypeIn eol:NO timestamp:YES];
    }
}

-(NSDictionary *)attributeType:(Type_e)type {
    NSDictionary * ret = nil;
    switch(type) {
        case TypeError:
            ret = errorAttribute;
            break;
        case TypeOut:
            ret = outAttribute;
            break;
        case TypeIn:
            ret = inAttribute;
            break;
        case TypeGeneric:
            ret = genericAttribute;
            break;
    }
    return ret;
}


- (IBAction)displayMenu:(UIBarButtonItem *)sender {
    UIAlertAction *alertAction;

    // create action sheet
    UIAlertController *alertController = [UIAlertController
            alertControllerWithTitle:nil message:nil
                      preferredStyle:UIAlertControllerStyleActionSheet];


    //hide keyboard
    alertAction = [UIAlertAction actionWithTitle:BLUESTSDK_LOCALIZE(@"Send help",nil)
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action) {
                                             [self sendMessage:@"help" eol:YES];
                                         }];
    [alertController addAction:alertAction];

    //hide keyboard
    alertAction = [UIAlertAction actionWithTitle:BLUESTSDK_LOCALIZE(@"Hide keyboard",nil)
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action) {
                                             [self.view endEditing:NO];
                                         }];
    [alertController addAction:alertAction];

    //clear
    alertAction = [UIAlertAction actionWithTitle:BLUESTSDK_LOCALIZE(@"Clear",nil)
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action) {
                                             mDisplayString = [[NSMutableAttributedString alloc] init];
                                             [self updateDisplayString];
                                         }];
    [alertController addAction:alertAction];

    //on the iphone add the cancel button
    if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ){
        [alertController addAction:
                [UIAlertAction actionWithTitle:BLUESTSDK_LOCALIZE(@"Cancel",nil)
                                         style:UIAlertActionStyleCancel
                                       handler:nil]];
    }
    if (sender) {
        [alertController setModalPresentationStyle:UIModalPresentationPopover];

        UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
        popPresenter.barButtonItem=sender;
        popPresenter.sourceView=self.view;
    }
    [self presentViewController:alertController animated:YES completion:nil];
}



-(void)keyboardWillShow: (NSNotification *)n {
    if (mKeyboardIsShown) {
        return;
    }
    NSDictionary* userInfo = [n userInfo];

    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // resize the noteView
    CGRect viewFrame = self.view.frame;
    
    viewFrame.size.height -= (keyboardSize.height);
    
    [self.view setFrame:viewFrame];
    
    mKeyboardIsShown = YES;
}

- (void)keyboardWillHide:(NSNotification *)n
{
    NSDictionary* userInfo = [n userInfo];
    
    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // resize the scrollview
    CGRect viewFrame = self.view.frame;

    viewFrame.size.height += (keyboardSize.height);
    
    [self.view setFrame:viewFrame];
    
    mKeyboardIsShown = NO;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:self.view.window];
}

@end

