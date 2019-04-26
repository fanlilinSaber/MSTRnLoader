//
//  PWAPIController.m
//  Unity-iPhone
//
//  Created by Dan Jiang on 2017/5/4.
//
//

#import "PWAPIController.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString+Additions.h"
#import "MSTAPI.h"

#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
#define APILogError(fmt, ...) DDLogError((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define APILogError(...) NSLog(__VA_ARGS__)
#endif

/*&* 请求Token失效通知 */
NSString *const PWRequestDataTokenNoAvailNotification = @"PWRequestDataTokenNoAvailNotification";

typedef NSString * (^AFQueryStringSerializationBlock)(NSString *urlString, id parameters, NSError *__autoreleasing *error);

/*&* HTTPS请求认证 */
static BOOL enabledSecurity = NO;

@interface PWAPIController ()
/*&* core */
@property (strong, nonatomic) AFHTTPSessionManager *manager;
/*&* 请求 baseURL */
@property (copy, nonatomic) NSString *baseURL;
/*&* 请求头 */
@property (copy, nonatomic) NSString *cliInfo;
/*&* 请求格式序列化 二进制格式 */
@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestFormSerializer;
/*&* 请求格式序列化 JSON格式 */
@property (nonatomic, strong) AFJSONRequestSerializer <AFURLRequestSerialization> * requestJsonSerializer;

@end

@implementation PWAPIController

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    
    NSString *resourceServer = [[NSUserDefaults standardUserDefaults] stringForKey:MST_ResourceServerKey];
    NSAssert(resourceServer != nil, @"Resource server is not ready");

    if ([resourceServer hasPrefix:@"https://"]) {
        enabledSecurity = YES;
    }else {
        enabledSecurity = NO;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{        
        sharedInstance = [[self alloc] initWithBaseURL:resourceServer];
    });
    
    return sharedInstance;
}

/*&* 导入https 证书 */
- (AFSecurityPolicy *)customSecurityPolicy
{
    /*&* 导入证书 证书由服务端生成 */
    NSString *strResourcesBundle = [[NSBundle mainBundle] pathForResource:@"Resource" ofType:@"bundle"];
    NSString *cerPath = [[NSBundle bundleWithPath:strResourcesBundle] pathForResource:@"marsdt" ofType:@"cer"];
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    NSSet *certSet = [NSSet setWithObject:cerData];
    /*&* AFSSLPinningModeCertificate 使用证书验证模式 */
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certSet];
    /*&* 如果是需要验证自建证书，需要设置为YES */
    securityPolicy.allowInvalidCertificates = YES;
    /*&* validatesDomainName 是否需要验证域名，默认为YES;*/
    /*&* 假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。*/
    /*&* 置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。*/
    /*&* 如置为NO，建议自己添加对应域名的校验逻辑。*/
    securityPolicy.validatesDomainName = NO;
    return securityPolicy;
}

#pragma mark - init method

- (instancetype)initWithBaseURL:(NSString *)baseURL
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL] sessionConfiguration:configuration];
        self.requestFormSerializer = [AFHTTPRequestSerializer serializer];
        self.requestJsonSerializer = [AFJSONRequestSerializer serializer];
        self.baseURL = baseURL;
        NSMutableString *cliInfo = [NSMutableString new];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [cliInfo appendString:@"phone"];
        } else {
            [cliInfo appendString:@"tablet"];
        }
        [cliInfo appendFormat:@"&%@", @"IOS"];
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        NSString *build = [infoDictionary objectForKey:@"CFBundleVersion"];
        [cliInfo appendFormat:@"&%@b%@", version, build];
        CGRect bounds = UIScreen.mainScreen.bounds;
        int width = (int)bounds.size.width;
        int height = (int)bounds.size.height;
        [cliInfo appendFormat:@"&%d,%d", width, height];
        /*&* 规定请求头 */
        self.cliInfo = [cliInfo copy];
        if (enabledSecurity) {
            [self.manager setSecurityPolicy:[self customSecurityPolicy]];
        }
    }
    return self;
}

#pragma mark - getters and setters

- (void)setEnabledMD5Sign:(BOOL)enabledMD5Sign
{
    if (_enabledMD5Sign != enabledMD5Sign) {
        _enabledMD5Sign = enabledMD5Sign;
        if (enabledMD5Sign) {
            [self registerQueryStringSerializationWithBlock];
        }else {
            [self.requestFormSerializer setQueryStringSerializationWithBlock:nil];
        }
    }
}

#pragma mark - private method

/*&* 发送请求ToKen 失效通知 */
- (void)sendRequestDataTokenNoAvailNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PWRequestDataTokenNoAvailNotification object:nil];
    });
}

/*&* requestFormSerializer 请求参数MD5签名 */
- (void)registerQueryStringSerializationWithBlock
{
    __weak PWAPIController *weakSelf = self;
    [self.requestFormSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) { @autoreleasepool {
        __strong PWAPIController *strongSelf = weakSelf;
        NSString *query = @"";
        NSString *sign = @"";
        if ([parameters isKindOfClass:[NSDictionary class]] && parameters) {
            
            if (((NSDictionary *)parameters).count > 0) {
                query = AFQueryStringFromParameters(parameters);
                query = [query stringByAppendingString:@"&"];
                // 按照参数排序 升序
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
                NSDictionary *dictionary = parameters;
                for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
                    id nestedValue = dictionary[nestedKey];
                    sign = [sign stringByAppendingFormat:@"%@",nestedValue];
                }
            }
        }
    
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval time = [date timeIntervalSince1970];
        NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
        sign = [sign stringByAppendingFormat:@"%@%@",timeString,strongSelf.toKen ? strongSelf.toKen : @""];
        NSString *signMd5 = [sign md5String];
        query = [query stringByAppendingFormat:@"timestamp=%@&sign=%@",timeString,signMd5];
        return query;
        }
    }];
}

- (void)cancelQueryStringSerializationWithBlock
{
    [self.requestFormSerializer setQueryStringSerializationWithBlock:nil];
}

/*&* 请求任务 dataTask */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                      success:(void (^)(NSString *message, id data))success
                                        error:(void (^)(NSString *message, int code))error
                                      failure:(void (^)(NSError *error))failure
{
    __weak PWAPIController *weakSelf = self;
    NSURLSessionDataTask *dataTask = [self.manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable err) {
        __strong PWAPIController *strongSelf = weakSelf;
        if (err) {
            APILogError(@"%@, 请求failure %@",response.URL,err);
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(err);
            });
        } else {
            int code = ((NSNumber *)responseObject[@"code"]).intValue;
            NSString *message = responseObject[@"message"];
            if (code == 200) {
                id data = responseObject[@"data"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(message, data);
                });
            } else {
                APILogError(@"%@, 请求error %@",response.URL,responseObject);
                /*&* token 失效 */
                if (code == 40006) {
                    [strongSelf sendRequestDataTokenNoAvailNotification];
                }else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        error(message, code);
                    });
                }
            }
        }
    }];
    return dataTask;
}

#pragma mark - public method

- (void)cancelAllDataTask
{
    for (NSURLSessionDataTask *dataTask in self.manager.dataTasks) {
        if (dataTask.state != NSURLSessionTaskStateCompleted) {
            //            NSLog(@"taskIdentifier = %ld",dataTask.taskIdentifier);
            [dataTask cancel];
        }
    }
}

- (void)cancelDataTask:(NSInteger)taskIdentifier
{
    for (NSURLSessionDataTask *dataTask in self.manager.dataTasks) {
        if (dataTask.taskIdentifier == taskIdentifier) {
            if (dataTask.state != NSURLSessionTaskStateCompleted) {
                [dataTask cancel];
            }
            break;
        }
    }
}

- (void)cancelAllDownloadTask
{
    for (NSURLSessionDataTask *downloadTask in self.manager.downloadTasks) {
        if (downloadTask.state != NSURLSessionTaskStateCompleted) {
            [downloadTask cancel];
        }
    }
}

- (void)sendRequest:(NSURLRequest *)request
            success:(void (^)(NSString *message, id data))success
              error:(void (^)(NSString *message, int code))error
            failure:(void (^)(NSError *error))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:request success:success error:error failure:failure];
    [dataTask resume];
}

- (void)sendRequestWillRedirect:(NSURLRequest *)request
                        redirect:(void (^)(NSString *url))redirect
{
    __weak PWAPIController *weakSelf = self;
    [self.manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
        __strong PWAPIController *strongSelf = weakSelf;
        redirect(request.URL.absoluteString);
        [strongSelf.manager setTaskWillPerformHTTPRedirectionBlock:nil];
        return nil;
    }];
    [[self.manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:nil] resume];
}

- (NSMutableURLRequest *)requestFormWithMethod:(NSString *)method
                                     URLString:(NSString *)URLString
                                    parameters:(id)parameters
                                enabledMD5Sign:(BOOL)enabledMD5Sign
{
    NSError *error = nil;
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:[NSURL URLWithString:self.baseURL]] absoluteString];
    /*&* EnabledMD5Sign 无参数不能传nil */
    id parame;
    if (enabledMD5Sign) {
        parame = parameters ? parameters : @{};
        [self registerQueryStringSerializationWithBlock];
    }else {
        parame = parameters;
        [self cancelQueryStringSerializationWithBlock];
    }
    /*&* request */
    NSMutableURLRequest *request = [self.requestFormSerializer requestWithMethod:method URLString:urlString parameters:parame error:&error];
    request.timeoutInterval = 30;
    if (error) {
        NSAssert(NO, @"!!! Error: http request serialization error !!!\n%@\n", [error localizedDescription]);
    }
    [request setValue:self.cliInfo forHTTPHeaderField:@"CLI_INFO"];
    if (self.toKen.length > 0 && self.toKen) {
        [request setValue:self.toKen forHTTPHeaderField:@"x_access_token"];
    }
    [request setValue:MST_RequestApiversion forHTTPHeaderField:@"apiversion"];
    return request;
}

- (NSMutableURLRequest *)requestJsonWithMethod:(NSString *)method
                                     URLString:(NSString *)URLString
                                    parameters:(id)parameters
                                enabledMD5Sign:(BOOL)enabledMD5Sign
{
    NSError *error = nil;
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:[NSURL URLWithString:self.baseURL]] absoluteString];
    if (enabledMD5Sign) {
        NSString *sign = @"";
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval time = [date timeIntervalSince1970];
        NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
        
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                           options:0
                                                             error:&jsonError];
        NSString *jsonString = @"";
        if (jsonError) {
             NSAssert(NO, @"!!! Error: jsonString serialization error !!!\n%@\n", [jsonError localizedDescription]);
        }else {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        /*&* 去掉空格 */
        jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        sign = [NSString stringWithFormat:@"%@%@%@",jsonString,timeString,self.toKen];
        /*&* md5 */
        NSString *signMd5 = [sign md5String];
        urlString = [urlString stringByAppendingFormat:@"?timestamp=%@&sign=%@",timeString,signMd5];
    }
    /*&* request */
    NSMutableURLRequest *request = [self.requestJsonSerializer requestWithMethod:method URLString:urlString parameters:parameters error:&error];
    request.timeoutInterval = 30;
    if (error) {
        NSAssert(NO, @"!!! Error: http request serialization error !!!\n%@\n", [error localizedDescription]);
    }
    [request setValue:self.cliInfo forHTTPHeaderField:@"CLI_INFO"];
    if (self.toKen.length > 0 && self.toKen) {
        [request setValue:self.toKen forHTTPHeaderField:@"x_access_token"];
    }
    [request setValue:MST_RequestApiversion forHTTPHeaderField:@"apiversion"];
    return request;
}


- (void)requestWithPath:(NSString *)aPath
             withParams:(NSDictionary *)params
         withMethodType:(NetworkMethod)method
        withContentType:(ContentType)contentType
        withEnabledSign:(BOOL)enabledSign
            andDataTask:(void (^)(NSURLSessionDataTask *dataTask))dataTask
             andSuccess:(void (^)(NSString *message, id data))success
               andError:(void (^)(NSString *message, int code))error
             andFailure:(void (^)(NSError *error))failure
{
    /*&* 请求类型 */
    NSString *networkmethod;
    switch (method) {
        case Get:{
            networkmethod = @"GET";
        }
            break;
        case Post:{
            networkmethod = @"POST";
        }
            break;
        default:
            break;
    }
    
    /*&* request */
    NSMutableURLRequest *request;
    switch (contentType) {
        case FormForm:
            request = [self requestFormWithMethod:networkmethod URLString:aPath parameters:params enabledMD5Sign:enabledSign];
            break;
        case JsonForm:
            request = [self requestJsonWithMethod:networkmethod URLString:aPath parameters:params enabledMD5Sign:enabledSign];
            break;
        default:
            break;
    }
    /*&* new data task */
    NSURLSessionDataTask *newDataTask = [self dataTaskWithRequest:request success:success error:error failure:failure];
    [newDataTask resume];
    if (dataTask) {
        dataTask(newDataTask);
    }
}

#if __has_include(<ReactiveObjC/ReactiveObjC.h>)

+ (RACSignal *)requestWithPath:(NSString *)aPath
                    withParams:(NSDictionary *)params
                withMethodType:(NetworkMethod)method
               withContentType:(ContentType)contentType
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 请求任务
        __block NSURLSessionDataTask *task = nil;
        [[PWAPIController sharedInstance] requestWithPath:aPath withParams:params withMethodType:method withContentType:contentType withEnabledSign:YES andDataTask:^(NSURLSessionDataTask *dataTask) {
            // 获取请求任务
            task = dataTask;
        } andSuccess:^(NSString *message, id data) {
            
            [PWAPIController requestLogWithTask:task params:params error:nil data:data];
            [subscriber sendNext:RACTuplePack(data, message)];
            [subscriber sendCompleted];
        } andError:^(NSString *message, int code) {
            
            NSError *errorWithRes = [NSError errorWithDomain:@"The server returns an error" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
            [PWAPIController requestLogWithTask:task params:params error:errorWithRes data:nil];
            [subscriber sendError:errorWithRes];
        } andFailure:^(NSError *error) {
            
            [PWAPIController requestLogWithTask:task params:params error:error data:nil];
            [subscriber sendError:error];
        }];
        
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }];
    
    return [[signal replayLazily] setNameWithFormat:@"-requestWithPath: %@ params: %@ method: %d",aPath, params, method];
}

#else
#endif

+ (void)requestLogWithTask:(NSURLSessionTask *)task params:(id)params error:(NSError *)error data:(id)data{
    NSLog(@">>>>>>>>>>>>>>>>>>>>>👇 REQUEST FINISH 👇>>>>>>>>>>>>>>>>>>>>>>>>>>");
    NSLog(@"request%@=======>:%@", error?@"失败":@"成功", task.currentRequest.URL.absoluteString);
    NSLog(@"requestBody======>:%@", params);
    NSLog(@"requstHeader=====>:%@", task.currentRequest.allHTTPHeaderFields);
    NSLog(@"response=========>:%@", task.response);
    NSLog(@"error============>:%@", error);
    NSLog(@"data=============>:%@",data);
    NSLog(@"<<<<<<<<<<<<<<<<<<<<<👆 REQUEST FINISH 👆<<<<<<<<<<<<<<<<<<<<<<<<<<");
}

- (void)downloadFileWithPath:(NSString *)aPath
                  withParams:(NSDictionary *)params
            downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
             downloadSuccess:(void (^)(NSURLResponse *response, NSURL *filePath))downloadSuccessBlock
             downloadFailure:(void (^)(NSError *error))downloadFailureBlock
{
    NSURLSessionDownloadTask *task =
    [self.manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:aPath]] progress:^(NSProgress * _Nonnull downloadProgress) {
        downloadProgressBlock(downloadProgress);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (!error) {
            downloadSuccessBlock(response,filePath);
        }else{
            downloadFailureBlock(error);
        }
    }];
    [task resume];
}

@end
