//
//  AppDelegate.m
//  huayoutong
//
//  Created by HeDongMing on 16/2/23.
//  Copyright © 2016年 HeDongMing. All rights reserved.
//

#import "AppDelegate.h"
#import "JPUSHService.h"
#include <sys/xattr.h>
#import "HeTabBarVC.h"
#import "HeInstructionView.h"
#import "HeLoginVC.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import "WXApi.h"
#import "WeiboSDK.h"
#import "BrowserView.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import "REFrostedViewController.h"
#import "HeSlideMenuVC.h"
#import "DEMONavigationController.h"
#import "DEMOMenuViewController.h"
#import "DEMOHomeViewController.h"
#import <UMMobClick/MobClick.h>
#import <SMS_SDK/SMSSDK.h>
#import "WXApi.h"

@interface AppDelegate ()<WXApiDelegate,EMChatManagerDelegate,EMClientDelegate>
@property(strong,nonatomic)HeSlideMenuVC *menuController;

@end

BMKMapManager* _mapManager;

@implementation AppDelegate
@synthesize queue;
@synthesize menuController;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark :- Easemob Delegate
- (void)didAutoLoginWithError:(EMError *)aError {
    NSLog(@"easemob auto login with error %@",aError);
}

- (void)didConnectionStateChanged:(EMConnectionState)aConnectionState {
//    NSLog(@"easemob connect state changed to ")
    switch (aConnectionState) {
        case EMConnectionConnected:
            NSLog(@"easemob connect success");
            break;
        case EMConnectionDisconnected:
            NSLog(@"easemob disconnect");
            break;
            
        default:
            break;
    }
}


#pragma mark :- WXApi Delegate

- (void)onReq:(BaseReq *)req {
    
}

- (void)onResp:(BaseResp *)resp {
    if ([resp isMemberOfClass: SendAuthResp.self]) {
        SendAuthResp *req = (SendAuthResp *)resp;
        if (req.code) {
            NSLog(@"weixin login callback with response code %@",req.code);
//            [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationWXLoginCallBack object:nil userInfo:@{@"CodeURL":req.code}];
        } else {
            printf("\nno response code ");
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
     EMOptions *options = [EMOptions optionsWithAppkey:EASEMOBKEY];
   EMError *initError = [[EMClient sharedClient]initializeSDKWithOptions:options];
    if (initError) {
        NSLog(@"init easemob with error %@",initError);
    }
    [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
    
    [self initialization];
    [self initShareSDK];
    [self umengTrack];
    [self launchBaiduMap];
    [self initAPServiceWithOptions:launchOptions];
    BOOL showGuide = [self isShowIntroduce];
    showGuide = NO;
    if (showGuide) {
        /****  进入使用介绍界面  ****/
        HeInstructionView *howEnjoyLifeView = [[HeInstructionView alloc] init];
        self.window.rootViewController = howEnjoyLifeView;
        [self.window makeKeyAndVisible];
        return YES;
    }
    
    //清除缓存
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(clearImg:) object:nil];
    
    [operation setQueuePriority:NSOperationQueuePriorityNormal];
    [operation setCompletionBlock:^{
        //不上传到iCloud
        [Tool canceliClouldBackup];
    }];
    queue = [[NSOperationQueue alloc]init];
    [queue addOperation:operation];
    [queue setMaxConcurrentOperationCount:1];
    
//    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage new]];
//    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage new]];
    
    
    //配置根控制器
    [self loginStateChange:nil];
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *hostName = url.host;
    if ([hostName hasPrefix:@"wx"]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSString *hostName = url.host;
    if ([hostName hasPrefix:hostName]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    return YES;
}

- (void)launchBaiduMap
{
    // 要使用百度地图，请先启动BaiduMapManager
    _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:BAIDUMAPKEY generalDelegate:self];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
    else{
        NSLog(@"manager start success!");
    }
}

- (void)onGetNetworkState:(int)iError
{
    if (0 == iError) {
        NSLog(@"联网成功");
    }
    else{
        NSLog(@"onGetNetworkState %d",iError);
    }
    
}

- (void)onGetPermissionState:(int)iError
{
    if (0 == iError) {
        NSLog(@"授权成功");
    }
    else {
        NSLog(@"onGetPermissionState %d",iError);
    }
}

- (void)setUpRootVC
{
//    NSString *userToken = [[NSUserDefaults standardUserDefaults] objectForKey:USERTOKENKEY];
//    BOOL haveLogin = (userToken == nil) ? NO : YES;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
//    if (haveLogin) {//登陆成功加载主窗口控制器
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        
//        [UINavigationBar appearance].tintColor = [UIColor blackColor];
//        [[UINavigationBar appearance] setTitleTextAttributes:
//         [NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName, [UIFont systemFontOfSize:20.0], NSFontAttributeName, nil]];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        
        HeTabBarVC *tabBarController = [[HeTabBarVC alloc] init];
        self.viewController = tabBarController;
//    }
//    else{
//        HeLoginVC *loginVC = [[HeLoginVC alloc] init];
//        CustomNavigationController *loginNav = [[CustomNavigationController alloc] initWithRootViewController:loginVC];
//        self.viewController = loginNav;
//    }
    self.window.rootViewController = self.viewController;
}

- (void)initialization
{
    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:USERHAVELOGINKEY];
    //注册登录状态监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginStateChange:)
                                                 name:KNOTIFICATION_LOGINCHANGE
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(phoneCall:) name:LinkNOTIFICATION object:nil];
    //    [[IQKeyboardManager sharedManager] setEnable:YES];
    
    
    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    if (ISIOS7) {
        [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
        UIImage *navBackgroundImage = [UIImage imageNamed:@"NavBarIOS7_white"];
        [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
        NSDictionary *attributeDict = @{NSForegroundColorAttributeName:[UIColor blackColor],NSFontAttributeName:[UIFont systemFontOfSize:20.0]};
        [[UINavigationBar appearance] setTitleTextAttributes:attributeDict];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }
    else{
        [[UINavigationBar appearance] setTintColor:APPDEFAULTORANGE];
        
        NSDictionary *attributeDict = @{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:20.0]};
        [[UINavigationBar appearance] setTitleTextAttributes:attributeDict];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
     [SMSSDK registerApp:SHARESDKSMSKEY withSecret:SHARESDKSMSAPPSECRET];
}

#pragma mark - login changed

- (void)loginStateChange:(NSNotification *)notification
{
    
    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    [[UINavigationBar appearance] setBackgroundImage:[Tool buttonImageFromColor:[UIColor whiteColor] withImageSize:CGSizeZero] forBarMetrics:UIBarMetricsDefault];
    
    NSString *userToken = [[NSUserDefaults standardUserDefaults] objectForKey:USERIDKEY];
    BOOL haveLogin = (userToken == nil) ? NO : YES;
    
//    kWeakSelf;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onLoginSuccess:) name:LOGINKEY object:nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName, [UIFont systemFontOfSize:20.0], NSFontAttributeName, nil]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    if (haveLogin) {//登陆成功加载主窗口控制器
        //        UIImage *navBackgroundImage = [UIImage imageNamed:@"NavBarIOS7_white"];
        //        [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
        HeTabBarVC *tabBarVC = [[HeTabBarVC alloc] init];
        self.viewController = tabBarVC;
        
    }
    else{
        HeLoginVC *loginVC = [[HeLoginVC alloc] init];
        
        CustomNavigationController *loginNav = [[CustomNavigationController alloc] initWithRootViewController:loginVC];
        self.viewController = loginNav;
        
    }
    self.window.rootViewController = self.viewController;
}

- (void)initShareSDK
{
    [ShareSDK registerApp:SHARESDKKEY
          activePlatforms:@[
                            @(SSDKPlatformTypeQQ),
                            @(SSDKPlatformSubTypeWechatTimeline),
                            @(SSDKPlatformSubTypeWechatSession)
                            ]
                 onImport:^(SSDKPlatformType platformType) {
                     switch (platformType)
                     {
                         case SSDKPlatformTypeWechat:
                             [ShareSDKConnector connectWeChat:[WXApi class] delegate:self];
                             break;
                         case SSDKPlatformTypeQQ:
                             [ShareSDKConnector connectQQ:[QQApiInterface class]
                                        tencentOAuthClass:[TencentOAuth class]];
                             break;
                            case SSDKPlatformTypeSinaWeibo:
                             [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                             break;
                         default:
                             break;
                     }
                 }
          onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo) {
              
              switch (platformType)
              {
                      
                  case SSDKPlatformTypeWechat:
                      [appInfo SSDKSetupWeChatByAppId:WECHATKEY
                                            appSecret:WECHATAPPSECRET];
                      break;
                  case SSDKPlatformTypeQQ:
                      [appInfo SSDKSetupQQByAppId:QQKEY
                                           appKey:QQAPPSECRET
                                         authType:SSDKAuthTypeBoth];
                      break;
                      
                    case SSDKPlatformTypeSinaWeibo:
                  {
                      [appInfo SSDKSetupSinaWeiboByAppKey:SINAWEIBOKEY appSecret:SINAWEIBOAPPSECRET redirectUri:SINAWEIBOREDURECTURI authType:SSDKAuthTypeBoth];
                  }
                      break;
                  default:
                      break;
              }
          }];
}

#pragma mark :- 通知
- (void)onLoginSuccess:(NSNotification *)note {
    HeTabBarVC *tabBarVC = [[HeTabBarVC alloc] init];
    
//    CustomNavigationController *loginNav = [[CustomNavigationController alloc] initWithRootViewController:loginVC];
//    self.viewController = nil;
//    self.window.rootViewController = nil;
    self.viewController = tabBarVC;
    self.window.rootViewController = tabBarVC;
}

//打电话的全局方法
- (void)phoneCall:(NSNotification *)notification
{
    //    MLLinkType
    //    MLLinkTypeURL           = 1,          // 链接
    //    MLLinkTypePhoneNumber   = 2,          // 电话
    //    MLLinkTypeEmail         = 3,          // 邮箱
    
    NSDictionary *userInfo = notification.userInfo;
    NSInteger linkType = [[userInfo objectForKey:LINKTypeKey] integerValue];
    NSString *linkValue = [userInfo objectForKey:LINKVALUEKey];
    switch (linkType) {
        case MLLinkTypeURL:
        {
            if ([linkValue rangeOfString:@"http"].length == 0) {
                linkValue = [NSString stringWithFormat:@"http://%@",linkValue];
            }
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",linkValue]]];
            break;
        }
        case MLLinkTypePhoneNumber:{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",linkValue]]];
            break;
        }
        default:
            break;
    }
    if (linkType == MLLinkTypePhoneNumber) {
        
    }
}

- (void)clearImg:(id)sender
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *folderPath = [NSHomeDirectory() stringByAppendingString:@"/tmp"];
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    
    NSString *libraryfolderPath = [NSHomeDirectory() stringByAppendingString:@"/Library"];
    //    libraryfolderPath = [[NSString alloc] initWithFormat:@"libraryfolderPath = %@",libraryfolderPath];
    
    NSString* LibraryfileName = [libraryfolderPath stringByAppendingPathComponent:@"EaseMobLog"];
    childFilesEnumerator = [[manager subpathsAtPath:LibraryfileName] objectEnumerator];
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [LibraryfileName stringByAppendingPathComponent:fileName];
        
        BOOL result = [manager removeItemAtPath:fileAbsolutePath error:nil];
        if (result) {
            NSLog(@"remove EaseMobLog succeed");
        }
        else{
            NSLog(@"remove EaseMobLog faild");
        }
        
    }
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = [path objectAtIndex:0];
    childFilesEnumerator = [[manager subpathsAtPath:cachesPath] objectEnumerator];
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [cachesPath stringByAppendingPathComponent:fileName];
        NSRange range = [fileAbsolutePath rangeOfString:@"umeng"];
        
        if (range.length == 0) {
            BOOL result = [manager removeItemAtPath:fileAbsolutePath error:nil];
            if (result) {
                NSLog(@"remove caches succeed");
            }
            else{
                NSLog(@"remove caches faild");
            }
        }
        
    }
}

#pragma mark - isShowInstroduce 进入App的介绍页面

-(BOOL)isShowIntroduce
{
    NSDictionary* dic =[[NSBundle mainBundle] infoDictionary];
    /****  读取当前应用的版本号  ****/
    NSString *versionInfo = [dic objectForKey:@"CFBundleShortVersionString"];
    NSString *libraryfolderPath = [NSHomeDirectory() stringByAppendingString:@"/Library"];
    NSString *myPath = [libraryfolderPath stringByAppendingPathComponent:ALBUMNAME];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:myPath]) {
        [fm createDirectoryAtPath:myPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *documentString = [myPath stringByAppendingPathComponent:@"UserData"];
    
    if(![fm fileExistsAtPath:documentString])
    {
        [fm createDirectoryAtPath:documentString withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    NSString *filename = [documentString stringByAppendingPathComponent:@"launch.plist"];
    
    NSDictionary *launchDic = [[NSDictionary alloc] initWithContentsOfFile:filename];
    
    if (launchDic == nil) {
        NSString *versionInfo = [dic objectForKey:@"CFBundleShortVersionString"];
        launchDic = [[NSDictionary alloc] initWithObjectsAndKeys:versionInfo,@"lastVersion" ,nil];
        [launchDic writeToFile:filename atomically:YES];
        
        return YES;
    }
    else{
        NSString *lastVersion = [launchDic objectForKey:@"lastVersion"];
        BOOL showInstruction = [[dic objectForKey:@"ShowInstruction"] boolValue];
        if ((![lastVersion isEqualToString:versionInfo]) && showInstruction) {
            
            NSString *versionInfo = [dic objectForKey:@"CFBundleShortVersionString"];
            launchDic = [[NSDictionary alloc] initWithObjectsAndKeys:versionInfo,@"lastVersion" ,nil];
            [launchDic writeToFile:filename atomically:YES];
            return YES;
        }
    }
    return NO;
}

//初始化极光推送
- (void)initAPServiceWithOptions:(NSDictionary *)launchOptions
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    } else {
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                          UIRemoteNotificationTypeSound |
                                                          UIRemoteNotificationTypeAlert)
                                              categories:nil];
    }
    
    [JPUSHService setupWithOption:launchOptions appKey:appKey
                          channel:channel apsForProduction:isProduction];
}

//初始化友盟的SDK
- (void)umengTrack
{
    [MobClick setLogEnabled:NO];  // 打开友盟sdk调试，注意Release发布时需要注释掉此行,减少io消耗
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [MobClick setAppVersion:version];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [MobClick setLogEnabled:YES];
        UMConfigInstance.appKey = UMANALYSISKEY;
        UMConfigInstance.secret = @"secretstringaldfkals";
        //    UMConfigInstance.eSType = E_UM_GAME;
        [MobClick startWithConfigure:UMConfigInstance];
        
        //        [MobClick startWithAppkey:UMANALYSISKEY reportPolicy:(ReportPolicy) SEND_INTERVAL channelId:nil];
    }
    else{
        [MobClick setLogEnabled:YES];
        UMConfigInstance.appKey = UMANALYSISKEY_HD;
        UMConfigInstance.secret = @"secretstringaldfkals";
        //    UMConfigInstance.eSType = E_UM_GAME;
        [MobClick startWithConfigure:UMConfigInstance];
        
        //        [MobClick startWithAppkey:UMANALYSISKEY_HD reportPolicy:(ReportPolicy) SEND_INTERVAL channelId:nil];
    }
    
    [MobClick setCrashReportEnabled:YES]; // 如果不需要捕捉异常，注释掉此行
    [MobClick setBackgroundTaskEnabled:YES];
    [MobClick setLogSendInterval:90];//每隔两小时上传一次
    //    [MobClick ];  //在线参数配置
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineConfigCallBack:) name:UMOnlineConfigDidFinishedNotification object:nil];
}

- (void)onlineConfigCallBack:(NSNotification *)note {
    
    NSLog(@"online config has fininshed and note = %@", note.userInfo);
}

- (void)networkDidSetup:(NSNotification *)notification {
    
    NSLog(@"已连接");
}

- (void)networkDidClose:(NSNotification *)notification {
    
    NSLog(@"未连接。。。");
}

- (void)networkDidRegister:(NSNotification *)notification {
    
    NSLog(@"已注册");
}

- (void)networkDidLogin:(NSNotification *)notification {
    
    NSLog(@"已登录");
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[EMClient sharedClient]applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [application setApplicationIconBadgeNumber:0];
    [application cancelAllLocalNotifications];
    [[EMClient sharedClient]applicationWillEnterForeground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
}

// Called when your app has been activated by the user selecting an action from
// a local notification.
// A nil action identifier indicates the default action.
// You should call the completion handler as soon as you've finished handling
// the action.
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    
}

// Called when your app has been activated by the user selecting an action from
// a remote notification.
// A nil action identifier indicates the default action.
// You should call the completion handler as soon as you've finished handling
// the action.
- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)())completionHandler {
}
#endif

//收到推送通知的处理
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [JPUSHService handleRemoteNotification:userInfo];
    NSLog(@"收到通知:%@", [self logDic:userInfo]);
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application
didReceiveLocalNotification:(UILocalNotification *)notification {
    [JPUSHService showLocalNotificationAtFront:notification identifierKey:nil];
}

// log NSSet with UTF8
// if not ,log will be \Uxxx
- (NSString *)logDic:(NSDictionary *)dic {
    if (![dic count]) {
        return nil;
    }
    NSString *tempStr1 =
    [[dic description] stringByReplacingOccurrencesOfString:@"\\u"
                                                 withString:@"\\U"];
    NSString *tempStr2 =
    [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 =
    [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString *str =
    [NSPropertyListSerialization propertyListFromData:tempData
                                     mutabilityOption:NSPropertyListImmutable
                                               format:NULL
                                     errorDescription:NULL];
    return str;
}

@end
