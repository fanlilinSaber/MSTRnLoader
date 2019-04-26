//
//  PWAPIController.h
//  Unity-iPhone
//
//  Created by Dan Jiang on 2017/5/4.
//
//

#import <Foundation/Foundation.h>

/**
 *  *&*  网络请求ToKen失效通知 *
 */
extern NSString * const PWRequestDataTokenNoAvailNotification;

/**
 *  *&* 请求方式 *
 */
typedef enum {
    Get = 0,
    Post,
} NetworkMethod;

/**
 *  *&* 请求参数提交方式 *
 */
typedef enum {
    /*&* form表单形式提交 */
    FormForm= 0,
    /*&* json的形式提交 */
    JsonForm,
} ContentType;

/**
 网络请求Controller
 */
@interface PWAPIController : NSObject

/**
 网络请求单例类

 @return PWAPIController Object
 */
+ (instancetype)sharedInstance;

/*&* 请求Token */
@property (nonatomic, copy) NSString *toKen;
/*&* 请求参数是否MD5签名 */
@property (nonatomic, assign, getter=isEnabledMD5Sign) BOOL enabledMD5Sign;

/**
 init (单例默认已经初始化)
 
 @param baseURL 请求baseURL
 @return PWAPIController Object
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL;

/**
 取消所有请求任务
 */
- (void)cancelAllDataTask;

/**
 取消指定请求任务

 @param taskIdentifier 请求任务 taskIdentifier
 */
- (void)cancelDataTask:(NSInteger)taskIdentifier;

/**
 取消所有下载任务
 */
- (void)cancelAllDownloadTask;

/**
 发送网络请求

 @param request request
 @param success 请求成功回调
 @param error 请求异常回调
 @param failure 请求失败回调
 */
- (void)sendRequest:(NSURLRequest *)request
            success:(void (^)(NSString *message, id data))success
              error:(void (^)(NSString *message, int code))error
            failure:(void (^)(NSError *error))failure;

/**
 发送请求来获取最终请求URL

 @param request request
 @param redirect 回调最终请求URL
 */
- (void)sendRequestWillRedirect:(NSURLRequest *)request
                       redirect:(void (^)(NSString *url))redirect;

/**
 请求 request 请求格式序列化 二进制格式 application/x-www-form-urlencoded

 @param method 请求方式
 @param URLString 请求URL
 @param parameters 请求参数
 @return request
 */
- (NSMutableURLRequest *)requestFormWithMethod:(NSString *)method
                                     URLString:(NSString *)URLString
                                    parameters:(id)parameters
                                enabledMD5Sign:(BOOL)enabledMD5Sign;

/**
 请求 request 请求格式序列化 JSON编码格式 multipart/form-data

 @param method 请求方式
 @param URLString 请求URL
 @param parameters 请求参数
 @return request
 */
- (NSMutableURLRequest *)requestJsonWithMethod:(NSString *)method
                                     URLString:(NSString *)URLString
                                    parameters:(id)parameters
                                enabledMD5Sign:(BOOL)enabledMD5Sign;

/**
 网络请求

 @param aPath 接口路径
 @param params 请求参数
 @param method 请求方式
 @param contentType 请求参数提交方式
 @param enabledSign 是否签名验证
 @param dataTask 网络请求 dataTask 回调
 @param success 网络请求成功回调
 @param error 网络请求发生错误回调
 @param failure 网络请求失败回调
 */
- (void)requestWithPath:(NSString *)aPath
             withParams:(NSDictionary *)params
         withMethodType:(NetworkMethod)method
        withContentType:(ContentType)contentType
        withEnabledSign:(BOOL)enabledSign
            andDataTask:(void (^)(NSURLSessionDataTask *dataTask))dataTask
             andSuccess:(void (^)(NSString *message, id data))success
               andError:(void (^)(NSString *message, int code))error
             andFailure:(void (^)(NSError *error))failure;

#if __has_include(<ReactiveObjC/ReactiveObjC.h>)

+ (RACSignal *)requestWithPath:(NSString *)aPath
                    withParams:(NSDictionary *)params
                withMethodType:(NetworkMethod)method
               withContentType:(ContentType)contentType;
#else
#endif

/**
 下载任务

 @param aPath aPath
 @param params 参数
 @param downloadProgressBlock 下载进度回调
 @param downloadSuccessBlock 下载完成回调
 @param downloadFailureBlock 下载失败回调
 */
- (void)downloadFileWithPath:(NSString *)aPath
                  withParams:(NSDictionary *)params
            downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
             downloadSuccess:(void (^)(NSURLResponse *response, NSURL *filePath))downloadSuccessBlock
             downloadFailure:(void (^)(NSError *error))downloadFailureBlock;

@end
