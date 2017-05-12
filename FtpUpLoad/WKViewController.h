//
//  WKViewController.h
//  FtpUpLoad
//
//  Created by dev on 2017/5/12.
//  Copyright © 2017年 Jeaner. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    kSendBufferSize = 32768
};

@interface WKViewController : UIViewController <UITextFieldDelegate,NSStreamDelegate>{
    uint8_t _buffer[kSendBufferSize];
}


@property (retain, nonatomic) IBOutlet UITextField *fileInput;
@property (retain, nonatomic) IBOutlet UITextField *serverInput;
@property (retain, nonatomic) IBOutlet UITextField *accountInput;
@property (retain, nonatomic) IBOutlet UITextField *passwordInput;
@property (retain, nonatomic) IBOutlet UILabel *status;
- (IBAction)sendAction:(id)sender;//点击上传

- (IBAction)textFieldDoneEditing:(id)sender;//Did End On Exit 事件
@end
