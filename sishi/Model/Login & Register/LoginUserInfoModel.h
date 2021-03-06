//
//  LoginUserInfoModel.h
//
//  Created by likeSo  on 2016/12/22
//  Copyright (c) 2016 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



/**
 用户登录时返回的用户信息内容
 */
@interface LoginUserInfoModel : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *userAge;
@property (nonatomic, strong) NSString *userSex;
@property (nonatomic, strong) NSString *userCarlable;
@property (nonatomic, strong) NSString *userAlipay;
@property (nonatomic, strong) NSString *userPwd;
@property (nonatomic, strong) NSString *usercarPass;
@property (nonatomic, strong) NSString *userNick;
@property (nonatomic, strong) NSString *userDrivinglicense;
@property (nonatomic, strong) NSString *userTrueName;
@property (nonatomic, strong) NSString *userCredit;
@property (nonatomic, strong) NSString *userDriverphoet;
@property (nonatomic, assign) double userPositionX;
@property (nonatomic, strong) NSString *userPrivatephoto;
@property (nonatomic, strong) NSString *userDaty;
@property (nonatomic, strong) NSString *userPass;
@property (nonatomic, strong) NSString *userPhone;
@property (nonatomic, strong) NSString *userAddress;
@property (nonatomic, strong) NSString *userCity;
@property (nonatomic, strong) NSString *userSign;
@property (nonatomic, strong) NSString *userPayPwd;
@property (nonatomic, strong) NSString *userCarphoto;
@property (nonatomic, strong) NSString *userCard;
@property (nonatomic, strong) NSString *userState;
@property (nonatomic, assign) double userPositionY;
@property (nonatomic, strong) NSString *userCarinfo;
@property (nonatomic, assign) double userCreatetime;
@property (nonatomic, strong) NSString *userHeader;
@property (nonatomic, strong) NSString *userYear;
@property (nonatomic, strong) NSString *userBalance;
@property (nonatomic, strong) NSString *userProvince;
@property (nonatomic, strong) NSString *userJudge;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userMouth;
@property (nonatomic, strong) NSString *userId;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
