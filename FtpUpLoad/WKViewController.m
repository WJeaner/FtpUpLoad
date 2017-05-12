//
//  WKViewController.m
//  FtpUpLoad
//
//  
//
//

#import "WKViewController.h"

@interface WKViewController ()
//内部变量
@property (nonatomic, readonly) BOOL              isSending;
@property (nonatomic, retain)   NSOutputStream *  networkStream;
@property (nonatomic, retain)   NSInputStream *   fileStream;
@property (nonatomic, readonly) uint8_t *         buffer;
@property (nonatomic, assign)   size_t            bufferOffset;
@property (nonatomic, assign)   size_t            bufferLimit;

@end

//存取方法
@implementation WKViewController
@synthesize fileInput = _fileInput;
@synthesize serverInput = _serverInput;
@synthesize status = _status;
@synthesize accountInput = _accountInput;
@synthesize passwordInput = _passwordInput;


- (uint8_t *)buffer
{
    return self->_buffer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _passwordInput.delegate = self;
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_fileInput release];
    [_serverInput release];
    [_status release];
    [_accountInput release];
    [_passwordInput release];
    [super dealloc];
}


#pragma mark 上传事件
- (IBAction)sendAction:(id)sender {

    NSURL *url;//ftp服务器地址
    NSString *filePath;//图片地址
    NSString *account;//账号
    NSString *password;//密码
    CFWriteStreamRef ftpStream;
    
    //获得输入
    url = [NSURL URLWithString:@"ftp://ftp.lovejiajiao.com:60001/images/"];//[NSURL URLWithString:_serverInput.text];
    filePath = @"/Users/jeaner/Desktop/test11.jpg";//_fileInput.text;
//    filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"png"];
    account = @"imftp";//_accountInput.text;
    password = @"im.ftp.2014";//_passwordInput.text;
    
    //添加后缀（文件名称）
    url = [NSMakeCollectable(CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef) url, (CFStringRef) [filePath lastPathComponent], false)) autorelease];
    
    //读取文件，转化为输入流
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    [self.fileStream open];
    
    //为url开启CFFTPStream输出流
    ftpStream = CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef) url);
    self.networkStream = (NSOutputStream *) ftpStream;
    
    //设置ftp账号密码
    [self.networkStream setProperty:account forKey:(id)kCFStreamPropertyFTPUserName];
    [self.networkStream setProperty:password forKey:(id)kCFStreamPropertyFTPPassword];

    //设置networkStream流的代理，任何关于networkStream的事件发生都会调用代理方法
    self.networkStream.delegate = self;

    //设置runloop 
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.networkStream open];
    
    //完成释放链接
    CFRelease(ftpStream);///Users/dev/Desktop/2359.jpg
}


#pragma mark 回调方法
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    //aStream 即为设置为代理的networkStream
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"NSStreamEventOpenCompleted");
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
            assert(NO);     // 在上传的时候不会调用
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"NSStreamEventHasSpaceAvailable");
            NSLog(@"bufferOffset is %zd",self.bufferOffset);
            NSLog(@"bufferLimit is %zu",self.bufferLimit);
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];
                
                if (bytesRead == -1) {
                    //读取文件错误
                    [self _stopSendWithStatus:@"读取文件错误"];
                } else if (bytesRead == 0) {
                    
                    NSLog(@"UpLoad Success");
                    
                    //文件读取完成 上传完成
                    [self _stopSendWithStatus:nil];
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }
                        
            if (self.bufferOffset != self.bufferLimit) {
                //写入数据
                NSInteger bytesWritten;//bytesWritten为成功写入的数据
                bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self _stopSendWithStatus:@"网络写入错误"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self _stopSendWithStatus:@"Stream打开错误"];
            assert(NO);  
        } break;
        case NSStreamEventEndEncountered: {
            // 忽略
        } break;
        default: {
            assert(NO);
        } break;
    }
}

//结果处理
- (void)_stopSendWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self _sendDidStopWithStatus:statusString];
}

- (void)_sendDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        statusString = @"上传成功";
    }
    _status.text = statusString;
}


//输入Done事件
-(IBAction)textFieldDoneEditing:(id)sender{
    [sender resignFirstResponder];
}


#pragma mark UITextField代理方法
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    [UIView beginAnimations:@"ResignForKeyBoard" context:nil];
    [UIView setAnimationDuration:0.30f];
     
    CGRect rect = CGRectMake(0.0f, -10.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.view.frame = rect;
    
    [UIView commitAnimations];
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    [UIView beginAnimations:@"ResignForKeyBoard" context:nil];
    [UIView setAnimationDuration:0.30f];
    
    CGRect rect = CGRectMake(0.0f, 20.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.view.frame = rect;
    
    [UIView commitAnimations];
    return YES;
}
@end
