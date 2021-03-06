//
//  HeLogTableVC.m
//  huayoutong
//
//  Created by Tony on 16/3/3.
//  Copyright © 2016年 HeDongMing. All rights reserved.
//  日志首页

#import "HeLogTableVC.h"
#import "DFTextImageLineItem.h"
#import "DFLineLikeItem.h"
#import "DFLineCommentItem.h"
#import "DFActivityLineItem.h"
#import "DFLineJoinItem.h"
#import "ActivityLogModel.h"
#include <string.h>
#import "HeSysbsModel.h"
#import "DFBaseLineCell.h"
#import "DFUserActivityLineItem.h"
#import "ReleaseMoodViewController.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKExtension/SSEShareHelper.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>
#import <ShareSDKUI/SSUIShareActionSheetStyle.h>
#import <ShareSDKUI/SSUIShareActionSheetCustomItem.h>
#import <ShareSDK/ShareSDK+Base.h>
#import "ApiUtils.h"
#import "ApiUtils.h"
#import "MJRefresh.h"

//#import "HeConvertToCommonEmoticonsHelper.h"
#import "UIButton+Bootstrap.h"

#define DELETEALERT 500
#define CONTENTCOMMENTSEP @"***contentcomment***"
#define ENCODEWEBVIEWTAG 100
#define DECODEWEBVIEWTAG 200

@interface HeLogTableVC ()
{
    NSInteger pageNo; //页码（十条数据一页）
}
@property(strong,nonatomic)NSMutableArray *dataSource;
@property(strong,nonatomic)NSMutableDictionary *dataDict;
@property(strong,nonatomic)NSMutableArray *distributeImageArray;
//解码的webview
@property(strong,nonatomic)UIWebView *decodewebview;
//编码的webview
@property(strong,nonatomic)UIWebView *encodewebview;
//转义字符
@property(strong,nonatomic)NSDictionary *escDict;
//占位图片
@property(strong,nonatomic)UIImageView *logPlaceholderImage;

/**
 *  当前正在显示的是第几页的内容
 */
@property(nonatomic,assign)NSUInteger currentIndex;

@property(strong,nonatomic)UIView *sectionHeaderView;
@property (weak, nonatomic) IBOutlet UIButton *releaseBtn;
/**
 *  是否处于 "无更多数据"状态
 */
@property(nonatomic,assign)BOOL noMoreData;
@end

@implementation HeLogTableVC
@synthesize dataSource;
@synthesize dataDict;
@synthesize decodewebview;
@synthesize encodewebview;
@synthesize escDict;
@synthesize logPlaceholderImage;
@synthesize sectionHeaderView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
//        label.backgroundColor = [UIColor clearColor];
//        label.font = APPDEFAULTTITLETEXTFONT;
//        label.textColor = APPDEFAULTTITLECOLOR;
//        label.textAlignment = NSTextAlignmentCenter;
//        self.navigationItem.titleView = label;
//        label.text = @"宝 贝 日 记";
//        
//        [label sizeToFit];
//        self.title = @"日记";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initializaiton];
    [self initView];
    //加载日记数据
    [self initData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)initializaiton
{
    [super initializaiton];
    
    NSString *filename = [[NSBundle mainBundle] pathForResource:@"escDict" ofType:@"plist"];
    escDict = [[NSDictionary alloc] initWithContentsOfFile:filename];
    
    pageNo = 1;
    updateOption = 1;
    dataDict = [[NSMutableDictionary alloc] initWithCapacity:0];
    dataSource = [[NSMutableArray alloc] initWithCapacity:0];
    _distributeImageArray = [[NSMutableArray alloc] initWithCapacity:0];
    self.myTableDelegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(distributeLogSuccess:) name:@"distributeLogSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadImageSuccess:) name:UPLOADIMAGESUCCEED_NOTIFICATION object:nil];
}

- (void)initView
{
    [super initView];
    
    //设置头部
    [self setHeader];
    self.tableView.backgroundView = nil;
//    self.tableView.refreshControl = nil;
//    [self.tableView.refreshControl addTarget:self action:@selector(onRefreshHeader:) forControlEvents:UIControlEventValueChanged];
    self.tableView.backgroundColor = [UIColor whiteColor];
    [Tool setExtraCellLineHidden:self.tableView];
    [self.view bringSubviewToFront:self.releaseBtn];
    self.releaseBtn.layer.shadowOffset = CGSizeMake(2, 2);
    self.releaseBtn.layer.shadowColor = [UIColor colorWithWhite:0.4 alpha:1].CGColor;
    self.releaseBtn.layer.shadowOpacity = 1.0;
//    self.releaseBtn.layer.shadowRadius = 30.0;
}

- (UIButton *)buttonWithTitle:(NSString *)buttonTitle frame:(CGRect)buttonFrame
{
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setTitle:buttonTitle forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:143.0 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(filterButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[Tool buttonImageFromColor:[UIColor whiteColor] withImageSize:button.frame.size] forState:UIControlStateSelected];
    [button setBackgroundImage:[Tool buttonImageFromColor:sectionHeaderView.backgroundColor withImageSize:button.frame.size] forState:UIControlStateNormal];
    
    return button;
}


- (void)onRefreshHeader:(UIRefreshControl *)refreshCtrl {
    CGFloat longitude = [[NSUserDefaults standardUserDefaults]doubleForKey:kDefaultsUserLocationlongitude];
    CGFloat latitude = [[NSUserDefaults standardUserDefaults] doubleForKey:kDefaultsUserLocationLatitude];
    [ApiUtils queryAllDynamicAtLongitude:longitude
                                latitude:latitude
                              startIndex:0
                       onCompleteHandler:^(NSArray<DynamicListModel *> *dynamicList) {
                           [refreshCtrl endRefreshing];
                           [self removeItmeWithItemId:nil];
                           for (DynamicListModel *model in dynamicList) {
                               DFTextImageLineItem *item = [[DFTextImageLineItem alloc]init];
                               //                               item.location = model.
                               item.userAvatar = [NSString stringWithFormat:@"%@%@",[ApiUtils baseUrl],model.userHeader];
                               item.userNick = model.userNick;
                               item.title = model.dynamicContent;
                               item.ts = model.dynamicCreatetime;
                               item.itemId = model.dynamicId;
                               NSArray *imageList = [model.dynamicWallurl componentsSeparatedByString:@","];
                               NSMutableArray *imageLinkArray = [NSMutableArray arrayWithCapacity:imageList.count];
                               for (NSString *imageName in imageList) {
                                   if ([imageName hasPrefix:@"HTTP"] || [imageName hasPrefix:@"http"]) {
                                       [imageLinkArray addObject:imageName];
                                   } else {
                                       NSString *newimageName = [NSString stringWithFormat:@"%@%@",[ApiUtils baseUrl],imageName];
                                       [imageLinkArray addObject:newimageName];
                                   }
                               }
                               item.srcImages = imageLinkArray;
                               item.thumbImages = imageLinkArray;
                               item.width = SCREENWIDTH;
                               item.height = 300;
                               
                               [self addItem:item];
                               
                           }
                       } errorHandler:^(NSString *responseErrorInfo) {
                           [refreshCtrl endRefreshing];
                           [self showHint:responseErrorInfo];
                       }];
}

- (void)onHeaderRefresh:(MJRefreshNormalHeader *)header {
 
}

- (void)filterButtonClick:(UIButton *)button
{
    
}



- (void)loadLog
{
    //加载日记与活动
    NSLog(@"...");
}

-(void) initData
{
}

- (void)updateActivityLogList
{
    //加载日记与活动
    
}

- (void)distributeButtonClick:(id)sender
{
    NSLog(@"distribute");
}

-(void) setHeader
{
    self.tableView.tableHeaderView = nil;
}

- (void)distributeLogSuccess:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSArray *imageArray = [userInfo objectForKey:@"image"];
    [_distributeImageArray insertObject:imageArray atIndex:0];
    
    
    //加载日记与活动
    updateOption = 1;
    pageNo = 1;
//    [self removeItmeWithItemId:nil];
    NSString *t_token = [[NSUserDefaults standardUserDefaults] objectForKey:USERTOKENKEY];
    if (!t_token) {
        t_token = @"";
    }
    NSString *pageNoString = [NSString stringWithFormat:@"%ld",pageNo];
    NSDictionary *loadParams = @{@"pageNo":pageNoString,@"t_token":t_token};
    [self loadActivityDiaryWithParams:loadParams show:NO];
}

- (void)uploadImageSuccess:(NSNotification *)notification
{

}

- (void)loadActivityDiaryWithParams:(NSDictionary *)loadParams show:(BOOL)show
{
//    logPlaceholderImage.hidden = YES;
//    NSString *loadActivityDiaryPath = [NSString stringWithFormat:@"%@%@",BASEURL,GETACTIVITYDIARY];
//    if (show) {
//        [Waiting show];
//    }
//    [AFHttpTool requestWihtMethod:RequestMethodTypePost url:loadActivityDiaryPath params:loadParams success:^(AFHTTPRequestOperation* operation,id response){
//        if (show) {
//            [Waiting dismiss];
//        }
//        NSString *respondString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
//        NSDictionary *respondDict = [respondString objectFromJSONString];
//        
//        NSInteger totalCount = [[respondDict objectForKey:@"totalCount"] integerValue];
//        NSInteger totalPages = [[respondDict objectForKey:@"totalPages"] integerValue];
//        if (updateOption == 1 && totalCount == 1) {
//            [self.view addSubview:logPlaceholderImage];
//            logPlaceholderImage.hidden = NO;
//            return;
//        }
//        else{
//            [self.view addSubview:logPlaceholderImage];
//            logPlaceholderImage.hidden = YES;
//        }
//        if (totalCount != 0) {
//            if (updateOption == 1) {
//                [dataSource removeAllObjects];
//                id results = [respondDict objectForKey:@"result"];
//                if ([results isKindOfClass:[NSArray class]]) {
//                    NSMutableArray *contentArray = [[NSMutableArray alloc] initWithCapacity:0];
//                    NSMutableArray *commentArray = [[NSMutableArray alloc] initWithCapacity:0];
//                    for (id resultObj in results) {
//                        ActivityLogModel *activityLogModel = [[ActivityLogModel alloc] initModelWithDict:resultObj];
//                        [dataSource addObject:activityLogModel];
//                        [dataDict setObject:activityLogModel forKey:activityLogModel.activityid];
//                        [contentArray addObject:activityLogModel.content];
//                        [commentArray addObject:activityLogModel.commentStringList];
////                        if ([emojiArray count] < 36) {
////                            NSString *content = [resultObj objectForKey:@"content"];
////                            [emojiArray addObject:content];
////                        }
//                    }
//                    [self translateUnicdoeToChineseWithContentArray:contentArray commentArray:commentArray];
//                    
//                }
//                [self endRefresh];
//            }
//            else{
//                id results = [respondDict objectForKey:@"result"];
//                if ([results isKindOfClass:[NSArray class]]) {
//                    if ([results count] > 0) {
//                        NSMutableArray *contentArray = [[NSMutableArray alloc] initWithCapacity:0];
//                        NSMutableArray *commentArray = [[NSMutableArray alloc] initWithCapacity:0];
//                        for (id resultObj in results) {
//                            ActivityLogModel *activityLogModel = [[ActivityLogModel alloc] initModelWithDict:resultObj];
//                            [dataSource addObject:activityLogModel];
//                            [dataDict setObject:activityLogModel forKey:activityLogModel.activityid];
//                            
//                            [contentArray addObject:activityLogModel.content];
//                            [commentArray addObject:activityLogModel.commentStringList];
////                            if ([emojiArray count] < 36) {
////                                NSString *content = [resultObj objectForKey:@"content"];
////                                [emojiArray addObject:content];
////                            }
////                            else{
////                                NSMutableString *mutable_emojiContent = [[NSMutableString alloc] initWithCapacity:0];
////                                for (NSString *str in emojiArray) {
////                                    NSString *emojiStr = [str stringByReplacingOccurrencesOfString:@"&#" withString:@""];
////                                    [mutable_emojiContent insertString:emojiStr atIndex:0];
////                                }
////                                NSArray *array = [mutable_emojiContent componentsSeparatedByString:@";"];
////                                NSArray *array1 = [[NSArray alloc] initWithArray:array];
////                                NSMutableArray *array2 = [[NSMutableArray alloc] initWithCapacity:2];
////                                for (NSString *str in array1) {
////                                    if (![str hasSuffix:@";"]) {
////                                        NSString *substr = [NSString stringWithFormat:@"&#%@;",str];
////                                        [unicodeArray addObject:substr];
////                                        
////                                    }
////                                }
////                                [self performSelector:@selector(startTranslate) withObject:nil afterDelay:5];
////                                
////                            }
//                            
//                        }
//                        [self translateUnicdoeToChineseWithContentArray:contentArray commentArray:commentArray];
//                    }
//                    else{
////                        [self showHint:@"更多已加载完毕"];
//                        pageNo--;
//                    }
//                }
//                [self endLoadMore];
//            }
//        }
//        else{
//            
//            NSString *message = [response objectForKey:@"message"];
//            if ([message isMemberOfClass:[NSNull class]] || message == nil) {
//                message = ERRORREQUESTTIP;
//            }
//            [self showHint:message];
//        }
//    } failure:^(NSError *error){
//        if (updateOption == 1) {
//            [self endRefresh];
//        }
//        else{
//            [self endLoadMore];
//        }
//        if (show) {
//            [Waiting dismiss];
//        }
//        [self showHint:ERRORREQUESTTIP];
//    }];
    
//    [Waiting dismiss];
//    [self endLoadMore];
//    NSString *longitude = [NSString stringWithFormat:@""];
//    NSString *latitude = [NSString stringWithFormat:@""];
//    [ApiUtils queryMoodListWithStartIndex:self.currentIndex
//                                longitude:longitude
//                                 latitude:latitude
//                           onResponseInfo:^(NSArray *responseList) {
//                               
//    } onResponseError:^(NSString *responseErrorInfo) {
//        
//    }];
    
    if (_noMoreData) {
        [self endLoadMore];
        return;
    }
    CGFloat longitude = [[NSUserDefaults standardUserDefaults]doubleForKey:kDefaultsUserLocationlongitude];
    CGFloat latitude = [[NSUserDefaults standardUserDefaults] doubleForKey:kDefaultsUserLocationLatitude];
    [ApiUtils queryAllDynamicAtLongitude:longitude
                                latitude:latitude
                              startIndex:self.currentIndex
                       onCompleteHandler:^(NSArray<DynamicListModel *> *dynamicList) {
                           self.noMoreData = dynamicList.count < 5;
                           [self endLoadMore];
                           self.currentIndex += 1;
                           for (DynamicListModel *model in dynamicList) {
                               DFTextImageLineItem *item = [[DFTextImageLineItem alloc]init];
                               item.userAvatar = [NSString stringWithFormat:@"%@%@",[ApiUtils baseUrl],model.userHeader];
                               item.userNick = model.userNick;
                               item.text = model.dynamicContent;
                               item.userId = model.userId;
                               item.ts = model.dynamicCreatetime;
                               item.itemId = model.dynamicId;
                               NSArray *imageList = [model.dynamicWallurl componentsSeparatedByString:@","];
                               NSMutableArray *imageLinkArray = [NSMutableArray arrayWithCapacity:imageList.count];
                               for (NSString *imageName in imageList) {
                                   if ([imageName hasPrefix:@"HTTP"] || [imageName hasPrefix:@"http"]) {
                                       [imageLinkArray addObject:imageName];
                                   } else {
                                       NSString *newimageName = [NSString stringWithFormat:@"%@%@",[ApiUtils baseUrl],imageName];
                                       [imageLinkArray addObject:newimageName];
                                   }
                               }
//                               if (imageLinkArray.count == 1) {
//                                   [imageLinkArray addObject:@""];
//                               }
                               item.srcImages = imageLinkArray;
                               item.thumbImages = imageLinkArray;
                               item.width = SCREENWIDTH;
                               item.height = 300;
                               [self addItem:item];
                               
                           }
                       } errorHandler:^(NSString *responseErrorInfo) {
                           [self endLoadMore];
                           [self showHint:responseErrorInfo];
                       }];
}


- (void)translateUnicdoeToChineseWithContentArray:(NSArray *)contentArray commentArray:(NSArray *)commentArray
{
    NSString *contentString = [contentArray JSONString];
    NSString *commentString = [commentArray JSONString];
    
    NSString *unicodeString = [NSString stringWithFormat:@"%@%@%@",contentString,CONTENTCOMMENTSEP,commentString];
    [self translateUnicdoeToChinese:unicodeString];
}

- (NSString *)replaceESC:(NSString *)inputString
{
    
    NSArray *escArray = [escDict objectForKey:@"esc"];
    NSArray *characterArray = [escDict objectForKey:@"character"];
    
    NSString *outPutString = [[NSString alloc] initWithString:inputString];
    
    for (NSInteger index = 0; index < [escArray count]; index++) {
        NSString *escStr = escArray[index];
        NSString *characterStr = characterArray[index];
        outPutString = [outPutString stringByReplacingOccurrencesOfString:escStr withString:characterStr];
    }
    return outPutString;
}

- (void)translateUnicdoeToChinese:(NSString *)unicodeString
{
    [decodewebview loadHTMLString:unicodeString baseURL:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView.tag == DECODEWEBVIEWTAG) {
        NSString *jsToGetHTMLSource = @"document.body.innerHTML";
        NSString *HTMLSource = [webView stringByEvaluatingJavaScriptFromString:jsToGetHTMLSource];
        HTMLSource = [self replaceESC:HTMLSource];
        if (updateOption == 1) {
            NSArray *array = [HTMLSource componentsSeparatedByString:CONTENTCOMMENTSEP];
            NSString *contentString = array[0];
            NSString *commentString = array[1];
            NSArray *contentArray = [contentString objectFromJSONString];
            NSArray *commentArray = [commentString objectFromJSONString];
            for (NSInteger index = 0; index < [contentArray count]; index++) {
                ActivityLogModel *activityLogModel = dataSource[index];
                NSString *content = contentArray[index];
                NSMutableArray *comment = [NSMutableArray arrayWithArray:commentArray[index]];
                activityLogModel.content = content;
                activityLogModel.commentStringList = comment;
            }
            [self removeItmeWithItemId:nil];
            [self translateToDFLineModel];
        }
        else{
            NSArray *array = [HTMLSource componentsSeparatedByString:CONTENTCOMMENTSEP];
            NSString *contentString = array[0];
            NSString *commentString = array[1];
            NSArray *contentArray = [contentString objectFromJSONString];
            NSArray *commentArray = [commentString objectFromJSONString];
            for (NSInteger index = 0; index < [contentArray count]; index++) {
                NSInteger dataSourceIndex = [dataSource count] - [contentArray count] + index;
                ActivityLogModel *activityLogModel = dataSource[dataSourceIndex];
                NSString *content = contentArray[index];
                NSMutableArray *comment = commentArray[index];
                activityLogModel.content = content;
                activityLogModel.commentStringList = comment;
                
                DFBaseLineItem *item = [self translateModelToDFLineModel:activityLogModel];
                [self addItem:item];
            }
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (webView.tag == ENCODEWEBVIEWTAG) {
        if ([@"ios" isEqualToString:request.URL.scheme]) {
            NSString *url = request.URL.absoluteString;
            NSRange range = [url rangeOfString:@":"];
            NSString *method = [request.URL.absoluteString substringFromIndex:range.location + 1];
            method = [method
                      stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if ([method hasPrefix:@"json_"]){
                if ([method rangeOfString:@"/"].length == 0) {
                    return NO;
                }
                NSInteger location = [method rangeOfString:@"/"].location;
                NSString *funcName = [method substringToIndex:location];
                SEL func = NSSelectorFromString([NSString stringWithFormat:@"%@:",funcName]);
                NSString *jsonString = [method substringFromIndex:location+1];
                if ( [self respondsToSelector:func]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [self performSelector:func withObject:jsonString];
#pragma clang diagnostic pop
                }
            }
            return NO;
        }
    }
    return YES;
}
//将自己的model转换成DFLineModel
- (void)translateToDFLineModel
{
    for (NSInteger index = 0; index < [_distributeImageArray count]; index++) {
        NSArray *imageArray = _distributeImageArray[index];
        ActivityLogModel *model = dataSource[index];
        model.thumbLink = [NSMutableArray arrayWithArray:imageArray];
        model.link = [NSMutableArray arrayWithArray:imageArray];
    }
    for (ActivityLogModel *model in dataSource) {
        ActivityLog_Type type = model.diaryOrActivity;
        if (type == ActivityType) {
            //活动
            DFActivityLineItem *textImageItem = [[DFActivityLineItem alloc] init];
            textImageItem.itemId = model.activityid;
            textImageItem.activityIconText = @"活动";
            textImageItem.activityDate = [NSString stringWithFormat:@"%@%@ - %@",EMPTYSTRING,model.activityStartTime,model.activityEndTime];
            textImageItem.activityAddress = [NSString stringWithFormat:@"%@%@",EMPTYSTRING,model.activityPlace];
            textImageItem.activityContactPhone = [NSString stringWithFormat:@"%@%@",EMPTYSTRING,model.activityPhone];
            textImageItem.itemType = LineItemTypeActivity;
            textImageItem.userId = model.creator.userID;
            textImageItem.userAvatar = model.creator.headurl;
            textImageItem.userNick = model.creator.nickname;
            textImageItem.title = @"";
            textImageItem.text = model.content;
            textImageItem.isLike = model.isLike;
            
            textImageItem.srcImages = model.link;
            
            textImageItem.thumbImages = model.thumbLink;
            
            textImageItem.width = SCREENWIDTH;
            textImageItem.height = 300;
            
            textImageItem.location = model.activityTownName;
            textImageItem.ts = [Tool convertStringToTimesp:model.createTime] * 1000
            ;
            //点赞部分
            textImageItem.likes = [[NSMutableArray alloc] initWithArray:model.islikeList];
            NSLog(@"%@",textImageItem.likesStr);
            //评论部分
            textImageItem.comments = [[NSMutableArray alloc] initWithArray:model.commentList];

            [self addItem:textImageItem];
        }
        else if (type == LogType){
            //日记
            DFTextImageLineItem *textImageItem = [[DFTextImageLineItem alloc] init];
            textImageItem.itemId = model.activityid;
            
            textImageItem.itemType = LineItemTypeTextImage;
            textImageItem.userId = model.creator.userID;
            textImageItem.userAvatar = model.creator.headurl;
            textImageItem.userNick = model.creator.nickname;
            textImageItem.title = @"";
            textImageItem.text = model.content;
            textImageItem.isLike = model.isLike;
            
            textImageItem.srcImages = model.link;
            
            textImageItem.thumbImages = model.thumbLink;
            textImageItem.width = SCREENWIDTH;
            textImageItem.height = 300;
            textImageItem.location = model.activityTownName;
            textImageItem.ts = [Tool convertStringToTimesp:model.createTime] * 1000;
            
            //点赞部分
            textImageItem.likes = [[NSMutableArray alloc] initWithArray:model.islikeList];
            //评论部分
            textImageItem.comments = [[NSMutableArray alloc] initWithArray:model.commentList];
            
            textImageItem.width = SCREENWIDTH;
            textImageItem.height = 300;
            
            [self addItem:textImageItem];
        }
    }
    
    
    if (updateOption == 1) {
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
        
    }
    else if (updateOption == 2){
    }
    
}

- (DFBaseLineItem *)translateModelToDFLineModel:(ActivityLogModel *)model
{
    ActivityLog_Type type = model.diaryOrActivity;
    if (type == ActivityType) {
        //活动
        DFActivityLineItem *textImageItem = [[DFActivityLineItem alloc] init];
        textImageItem.itemId = model.activityid;
        textImageItem.activityIconText = @"活动";
        textImageItem.activityDate = [NSString stringWithFormat:@"%@%@ - %@",EMPTYSTRING,model.activityStartTime,model.activityEndTime];
        textImageItem.activityAddress = [NSString stringWithFormat:@"%@%@",EMPTYSTRING,model.activityPlace];
        textImageItem.activityContactPhone = [NSString stringWithFormat:@"%@%@",EMPTYSTRING,model.activityPhone];
        textImageItem.itemType = LineItemTypeActivity;
        textImageItem.userId = model.creator.userID;
        textImageItem.userAvatar = model.creator.headurl;
        textImageItem.userNick = model.creator.nickname;
        textImageItem.title = @"";
        textImageItem.text = model.content;
        textImageItem.isLike = model.isLike;
        
        textImageItem.srcImages = model.link;
        
        textImageItem.thumbImages = model.thumbLink;
        
        textImageItem.width = SCREENWIDTH;
        textImageItem.height = 300;
        
        textImageItem.location = model.activityTownName;
        textImageItem.ts = [Tool convertStringToTimesp:model.createTime] * 1000
        ;
        //点赞部分
        textImageItem.likes = [[NSMutableArray alloc] initWithArray:model.islikeList];
        NSLog(@"%@",textImageItem.likesStr);
        //评论部分
        textImageItem.comments = [[NSMutableArray alloc] initWithArray:model.commentList];
        
        return textImageItem;
    }
    else if (type == LogType){
        //日记
        DFTextImageLineItem *textImageItem = [[DFTextImageLineItem alloc] init];
        textImageItem.itemId = model.activityid;
        textImageItem.itemType = LineItemTypeTextImage;
        textImageItem.userId = model.creator.userID;
        textImageItem.userAvatar = model.creator.headurl;
        textImageItem.userNick = model.creator.nickname;
        textImageItem.title = @"";
        textImageItem.text = model.content;
        textImageItem.isLike = model.isLike;
        
        textImageItem.srcImages = model.link;
        
        textImageItem.thumbImages = model.thumbLink;
        
        textImageItem.width = SCREENWIDTH;
        textImageItem.height = 300;
        
        textImageItem.location = model.activityTownName;
        textImageItem.ts = [Tool convertStringToTimesp:model.createTime] * 1000;
        
        //点赞部分
        textImageItem.likes = [[NSMutableArray alloc] initWithArray:model.islikeList];
        //评论部分
        textImageItem.comments = [[NSMutableArray alloc] initWithArray:model.commentList];
        
        textImageItem.width = SCREENWIDTH;
        textImageItem.height = 300;
        
        return textImageItem;
    }
    return nil;
}

-(void)onCommentCreate:(NSString *)commentId text:(NSString *)text itemId:(NSString *) itemId
{
    

}
//js回调原生这边的评论方法
- (void)json_commentWithJsonString:(NSString *)commentString
{
    NSDictionary *commentDictParams = [commentString objectFromJSONString];
    if (commentDictParams == nil) {
        commentString = [commentString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        commentDictParams = [commentString objectFromJSONString];
    }
    NSString *commentPath = [NSString stringWithFormat:@"%@%@",BASEURL,DIARY_ACTIVITY_COMMENT];
    [AFHttpTool requestWihtMethod:RequestMethodTypePost url:commentPath params:commentDictParams success:^(AFHTTPRequestOperation* operation,id response){
        [self hideHud];
        NSString *respondString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
        NSDictionary *respondDict = [respondString objectFromJSONString];
        NSInteger statueCode = [[respondDict objectForKey:@"code"] integerValue];
        if (statueCode == REQUESTCODE_SUCCEED) {
            
        }
        else{
            //[self showHint:ERRORREQUESTTIP];
        }
    } failure:^(NSError *error){
        //[self showHint:ERRORREQUESTTIP];
    }];
}

- (void)onDeleteActivityLog:(NSString *)itemId
{
    NSString *diaryActivityId = itemId;
    NSString *t_token = [HeSysbsModel getSysModel].user.usertoken;
    
    NSString *deletePath = [NSString stringWithFormat:@"%@%@",BASEURL,DIARY_ACTIVITY_DELETE];
    NSDictionary *deleteDictParams = @{@"diaryActivityId":diaryActivityId,@"t_token":t_token};
    [AFHttpTool requestWihtMethod:RequestMethodTypePost url:deletePath params:deleteDictParams success:^(AFHTTPRequestOperation* operation,id response){
        [self hideHud];
        NSString *respondString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
        NSDictionary *respondDict = [respondString objectFromJSONString];
        if ([[respondDict objectForKey:@"result"] isEqualToString:@"success"]) {
            [self loadLog];
        }
        else{
            [self showHint:ERRORREQUESTTIP];
        }
    } failure:^(NSError *error){
        [self showHint:ERRORREQUESTTIP];
    }];
}

//分享事件
-(void)onShare:(NSString *)itemId
{
    ActivityLogModel *model = [dataDict objectForKey:itemId];
    if (![model.creator.userID isEqualToString:[HeSysbsModel getSysModel].user.userID]) {
        [self showHint:@"该活动(日记)无分享权限"];
        return;
    }
    NSString *shareId = model.shareId;
    
    NSString *typeStr = @"发表一篇日记";
    if (model.diaryOrActivity == ActivityType) {
        typeStr = @"发布一场活动";
    }
    //分享出去的链接地址
    NSString *shareUrl = [NSString stringWithFormat:@"%@/view/query?t=%@",WEBBASEURL,shareId];    //分享的链接地址
    
    NSString *shareContent = model.content;  //分享的内容
    NSString *shareTitleStr = [NSString stringWithFormat:@"我在华幼通%@，快来看看吧!",typeStr];    //分享的主标题
    NSString *imagePath = @"";  //分享的图片链接地址
    
    NSArray* imageArray = nil;
    if ([imagePath isMemberOfClass:[NSNull class]] || imagePath == nil || [imagePath isEqualToString:@""]) {
        imagePath = [[NSBundle mainBundle] pathForResource:@"huayoutong_logo"  ofType:@"png"];
        imageArray = @[imagePath];
        
    }
    
   
    
    NSArray *sharePlatFormArray = @[@(SSDKPlatformSubTypeWechatSession),@(SSDKPlatformSubTypeWechatTimeline)];
    
    shareUrl = [shareUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //1、创建分享参数（必要）
    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    [shareParams SSDKSetupShareParamsByText:shareContent
                                     images:imageArray
                                        url:[NSURL URLWithString:shareUrl]
                                      title:shareTitleStr
                                       type:SSDKContentTypeWebPage];
    //2、分享
    [ShareSDK showShareActionSheet:nil
                             items:sharePlatFormArray
                       shareParams:shareParams
               onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
                   switch (state) {
                           
                       case SSDKResponseStateBegin:
                       {
                           
                           break;
                       }
                       case SSDKResponseStateSuccess:
                       {
                           break;
                       }
                       case SSDKResponseStateFail:
                       {
                           if (platformType == SSDKPlatformTypeSMS && [error code] == 201)
                           {
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                               message:@"失败原因可能是：1、短信应用没有设置帐号；2、设备不支持短信应用；3、短信应用在iOS 7以上才能发送带附件的短信。"
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil, nil];
                               [alert show];
                               break;
                           }
                           else if(platformType == SSDKPlatformTypeMail && [error code] == 201)
                           {
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                               message:@"失败原因可能是：1、邮件应用没有设置帐号；2、设备不支持邮件应用；"
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil, nil];
                               [alert show];
                               break;
                           }
                           else
                           {
                               break;
                           }
                           break;
                       }
                       case SSDKResponseStateCancel:
                       {
                           break;
                       }
                       default:
                           break;
                   }
                   
                   
               }];
    
}

//点赞事件
-(void)onLike:(NSString *)itemId
{
    if (itemId == nil) {
        itemId = @"";
    }
    //首先进行本地数据的操作
    ActivityLogModel *model = [dataDict objectForKey:itemId];
    if (model.isLike) {
        //原本是点赞，现在取消点赞
        [self addLikeItem:nil itemId:itemId];
    }
    else{
        //添加点赞
        DFLineLikeItem *likeItem = [[DFLineLikeItem alloc] init];
        likeItem.userId = [HeSysbsModel getSysModel].user.userID;
        likeItem.userNick = [HeSysbsModel getSysModel].user.truename;
        likeItem.userPhoto = [HeSysbsModel getSysModel].user.headurl;
        likeItem.itemID = [NSString stringWithFormat:@"like/%@/%@/%@",model.activityid,likeItem.userId,[NSDate date]];
        [model.islikeList insertObject:likeItem atIndex:0];
        [self addLikeItem:likeItem itemId:model.activityid];
    }
    model.isLike = !model.isLike;
    
    NSString *t_token = [HeSysbsModel getSysModel].user.usertoken;
    NSDictionary *likeParams = @{@"diaryActivityId":itemId,@"t_token":t_token};
    NSString *likePath = [NSString stringWithFormat:@"%@%@",BASEURL,DIARY_ACTIVITY_ADDLIKE];
    [AFHttpTool requestWihtMethod:RequestMethodTypePost url:likePath params:likeParams success:^(AFHTTPRequestOperation* operation,id response){
        [self hideHud];
        NSString *respondString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
        NSDictionary *respondDict = [respondString objectFromJSONString];
        if ([[respondDict objectForKey:@"result"] isEqualToString:@"success"]) {
            
        }
        else{
//            [self showHint:ERRORREQUESTTIP];
        }
    } failure:^(NSError *error){
//        [self showHint:ERRORREQUESTTIP];
    }];
}

//点击用户头像或者点击用户，浏览器日记情况
-(void)onClickUser:(NSString *)userId
{
    UITableView *tableView = self.tableView;
    if ([tableView respondsToSelector:@selector(numberOfRowsInSection:)]) {
        NSInteger rows =  [tableView numberOfRowsInSection:0];
        for (int row = 0; row < rows; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            DFBaseLineCell *cell  = (DFBaseLineCell *)[tableView cellForRowAtIndexPath:indexPath];
            //如果当前toobar是显示的，如果点击cell任意位置，都是优先隐藏toolbar
            if ([cell isToolBarShow]) {
                [cell hideLikeCommentToolbar];
                return;
            }
            if ([cell isMenuItemShow]) {
                [cell hideEditMenu];
                return;
            }
        }
    }
    
    //点击左边头像 或者 点击评论和赞的用户昵称
    NSLog(@"onClickUser: %@", userId);
    User *selectUser = nil;
    for (ActivityLogModel *model in dataSource) {
        User *user = model.creator;
        if ([user.userID isEqualToString:userId]) {
            selectUser = [[User alloc] initUserWithUser:user];
        }
    }
    
//    UserTimelineViewController *controller = [[UserTimelineViewController alloc] init];
//    [self.navigationController pushViewController:controller animated:YES];
    
}


-(void)onClickHeaderUserAvatar
{
    [self onClickUser:@"1111"];
}

- (void)deleteActivityDiary:(NSString *)itemId
{
    UITableView *tableView = self.tableView;
    if ([tableView respondsToSelector:@selector(numberOfRowsInSection:)]) {
        NSInteger rows =  [tableView numberOfRowsInSection:0];
        for (int row = 0; row < rows; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            DFBaseLineCell *cell  = (DFBaseLineCell *)[tableView cellForRowAtIndexPath:indexPath];
            //如果当前toobar是显示的，如果点击cell任意位置，都是优先隐藏toolbar
            if ([cell isToolBarShow]) {
                [cell hideLikeCommentToolbar];
                return;
            }
            if ([cell isMenuItemShow]) {
                [cell hideEditMenu];
                return;
            }
        }
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"确定要删除该日记(活动)吗？删除后将不可恢复。" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];
    alert.tag = DELETEALERT;
    alert.accessibilityIdentifier = itemId;
    [alert show];
}

- (void)onDeleteCommentWithCommentID:(NSString *)commentId itemId:(NSString *)itemId
{
    //先进性本地操作
    [self deleteCommentItem:commentId itemId:itemId];
    
    ActivityLogModel *model = [dataDict objectForKey:itemId];
    for (DFLineCommentItem *commentItem in model.commentList) {
        if ([commentItem.commentId isEqualToString:commentId]) {
            [model.commentList removeObject:commentItem];
            break;
        }
    }
    NSString *diaryActivityCommentId = commentId;
    NSString *t_token = [HeSysbsModel getSysModel].user.usertoken;
    
    NSString *commentPath = [NSString stringWithFormat:@"%@%@",BASEURL,DIARY_ACTIVITY_DELETECOMMENT];
    NSDictionary *commentDictParams = @{@"diaryActivityCommentId":diaryActivityCommentId,@"t_token":t_token};
    [AFHttpTool requestWihtMethod:RequestMethodTypePost url:commentPath params:commentDictParams success:^(AFHTTPRequestOperation* operation,id response){
        [self hideHud];
        NSString *respondString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
        NSDictionary *respondDict = [respondString objectFromJSONString];
        NSInteger statueCode = [[respondDict objectForKey:@"code"] integerValue];
        if (statueCode == REQUESTCODE_SUCCEED) {
            
        }
        else{
            //            [self showHint:ERRORREQUESTTIP];
        }
    } failure:^(NSError *error){
        //        [self showHint:ERRORREQUESTTIP];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case DELETEALERT:
        {
            if (buttonIndex == 1) {
                NSString *itemId = alertView.accessibilityIdentifier;
                [self onDeleteActivityLog:itemId];
            }
            break;
        }
        default:
            break;
    }
}

-(void) refresh
{
    CGFloat longitude = [[NSUserDefaults standardUserDefaults]doubleForKey:kDefaultsUserLocationlongitude];
    CGFloat latitude = [[NSUserDefaults standardUserDefaults] doubleForKey:kDefaultsUserLocationLatitude];
    [ApiUtils queryAllDynamicAtLongitude:longitude
                                latitude:latitude
                              startIndex:0
                       onCompleteHandler:^(NSArray<DynamicListModel *> *dynamicList) {
                           self.noMoreData = dynamicList.count < 5;
                           self.currentIndex = 0;
                           [self endRefresh];
                           [self removeItmeWithItemId:nil];
                           for (DynamicListModel *model in dynamicList) {
                               DFTextImageLineItem *item = [[DFTextImageLineItem alloc]init];
                               item.userAvatar = [NSString stringWithFormat:@"%@%@",[ApiUtils baseUrl],model.userHeader];
                               item.userNick = model.userNick;
                               
                               item.text = model.dynamicContent;
                               item.userId = model.userId;
                               item.ts = model.dynamicCreatetime;
                               item.itemId = model.dynamicId;
                               NSArray *imageList = [model.dynamicWallurl componentsSeparatedByString:@","];
                               NSMutableArray *imageLinkArray = [NSMutableArray arrayWithCapacity:imageList.count];
                               for (NSString *imageName in imageList) {
                                   if ([imageName hasPrefix:@"HTTP"] || [imageName hasPrefix:@"http"]) {
                                       [imageLinkArray addObject:imageName];
                                   } else {
                                       NSString *newimageName = [NSString stringWithFormat:@"%@%@",[ApiUtils baseUrl],imageName];
                                       [imageLinkArray addObject:newimageName];
                                   }
                               }
                               item.srcImages = imageLinkArray;
                               item.thumbImages = imageLinkArray;
                               item.width = SCREENWIDTH;
                               item.height = 300;
                               [self addItem:item];
                               
                           }
                       } errorHandler:^(NSString *responseErrorInfo) {
                           [self endRefresh];
                           [self showHint:responseErrorInfo];
                       }];
}

-(void)loadMore
{
    //加载更多
    
    pageNo++;
    updateOption = 2;
    if ([dataSource count] == 0) {
        pageNo = 1;
        updateOption = 1;
    }
    NSString *t_token = [[NSUserDefaults standardUserDefaults] objectForKey:USERTOKENKEY];
    if (!t_token) {
        t_token = @"";
    }
    NSString *pageNoString = [NSString stringWithFormat:@"%ld",pageNo];
    NSDictionary *loadParams = @{@"pageNo":pageNoString,@"t_token":t_token};
    [self loadActivityDiaryWithParams:loadParams show:NO];
    dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^{
//        [self endLoadMore];
    });
}
#pragma mark :- 发表心情
- (IBAction)onRelease:(UIButton *)sender {
    ReleaseMoodViewController *moodVC = [[ReleaseMoodViewController alloc]initWithNibName:@"ReleaseMoodViewController" bundle:[NSBundle mainBundle]];
//    [   [NSBundle mainBundle]loadNibNamed:@"" owner:moodVC options:nil];
    [self.navigationController pushViewController:moodVC animated:YES];
}

#pragma mark - MyTabelViewDelegate
- (void)didSelectTableAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
//    ActivityLogModel *activityLogModel = [self.dataSource objectAtIndex:row];
//    if (activityLogModel.diaryOrActivity == ActivityType) {
//        
//    }
    
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    return sectionHeaderView;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return sectionHeaderView.frame.size.height;
//}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
