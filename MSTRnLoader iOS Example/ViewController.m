//
//  ViewController.m
//  MSTRnLoader iOS Example
//
//  Created by Fan Li Lin on 2019/4/16.
//  Copyright © 2019 puwang. All rights reserved.
//

#import "ViewController.h"
#import "PWAPIController.h"
#import "PWPersistenceController.h"
#import "MSTAPI.h"
#import "MSTRnAppModel+CoreDataProperties.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <React/RCTRootView.h>
#import "RNListCell.h"
#import "MSTFileDownloader.h"
#import "RNListModel.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
/*&* <##>*/
@property (nonatomic, strong) UITableView *tableView;
/*&* <##>*/
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"http://192.168.0.231:9001" forKey:MST_ResourceServerKey];
    [defaults synchronize];
    
    // tableView
    [self.view addSubview:self.tableView];
    
    // 刷新请求数据
    UIBarButtonItem *updateItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(handleBarButtonEvent:)];
    self.navigationItem.rightBarButtonItems = @[updateItem];
    
    

//    [MSTHotUpdate bundleURL];
}


- (void)loadLocalData
{
    __weak __typeof__ (self) self_weak_ = self;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"mmaId" ascending:YES];
    [[PWPersistenceController sharedInstance] asyncFindObjectWithEntityName:@"MSTRnAppModel" predicate:nil sortDescriptors:@[sortDescriptor] andFinalResultBlock:^(NSArray *finalResult) {
        __strong __typeof__(self) self = self_weak_;
        if (finalResult.count > 0) {
            NSMutableArray *array = [NSMutableArray new];
            for (MSTRnAppModel *model in finalResult) {
                model.file = @"http://192.168.0.240/group1/M00/00/4A/wKgA8Fy_9wOAFjCjHdckTJ9y0Y4785.zip";
                RNListModel *new = [[RNListModel alloc] init];
                new.rnAppInfo = model;
                [array addObject:new];
            }
            self.dataSource = array;
            [self.tableView reloadData];
        }
    }];
    
}


#pragma mark - handleBarButtonEvent

- (void)handleBarButtonEvent:(UIBarButtonItem *)item
{
    __weak __typeof__ (self) self_weak_ = self;
    [[PWAPIController sharedInstance] setToKen:@"207525e1128dc301f2b40eb95c9a71c1"];
    [[PWAPIController sharedInstance] requestWithPath:@"api/mma/listbyuser" withParams:nil withMethodType:Get withContentType:FormForm withEnabledSign:YES andDataTask:^(NSURLSessionDataTask *dataTask) {
        
    } andSuccess:^(NSString *message, id data) {
        __strong __typeof__(self) self = self_weak_;
        NSLog(@"data = %@",data);
//        self.dataSource = data;
//        [self.tableView reloadData];
        
        [[PWPersistenceController sharedInstance] createObjectWithEntityName:@"MSTRnAppModel"
                                                                  primaryKey:@"mmaId"
                                                                   dataArray:data
                                                                  completion:^(BOOL finished) {
                                                                      [self loadLocalData];
                                                                      
            
        }];
    } andError:^(NSString *message, int code) {
        NSLog(@"message = %@",message);
        
    } andFailure:^(NSError *error) {
        NSLog(@"error = %@",error);
    }];
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
//    }
////    NSString *name = self.dataSource[indexPath.row][@"name"];
//    MSTRnAppModel *appModel = self.dataSource[indexPath.row];
//
//    cell.textLabel.text = appModel.name;
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"mmaId = %d, version = %d",appModel.mmaId, appModel.version];
//    [cell.imageView setImage:[UIImage imageNamed:@"ar_tagging_select"]];
    
    RNListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
   
    NSString *taskIdentifier = [NSString stringWithFormat:@"rn%ld",indexPath.row];
    cell.taskIdentifier = taskIdentifier;
    cell.model = self.dataSource[indexPath.row];
    return cell;
}

// 必须指定高度，不然 startDownloadForURL 回调里面 标识会判断错误，暂时不知道原因，
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setEditing:false animated:true];
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    void(^rowActionHandler)(UITableViewRowAction *, NSIndexPath *) = ^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        NSLog(@"%@", action);
        [self setEditing:false animated:true];
        RNListModel *appModel = self.dataSource[indexPath.row];
        
        if ([action.title isEqualToString:@"删除"]) {
            

        }
        else if ([action.title isEqualToString:@"更新"]){
            if (appModel.rnAppInfo.file == nil) {
                [self alertPromptWithTitle:@"提示" message:@"资源下载文件地址为nil" handler:nil];
            }else {
//                [MSTHotUpdate hot]
//                MSTHotUpdate *update = [[MSTHotUpdate alloc] init];
//                NSDictionary *options = @{@"updateUrl" : appModel.file,
//                                          @"hashName" : [NSString stringWithFormat:@"rn%@%d%d", appModel.name,appModel.mmaId,appModel.version],
//                                          };
//
//                [update downloadFileWithPath:appModel.file options:options downloadProgress:nil downloadSuccess:^(NSString *filePath) {
//
//                    NSLog(@"下载成功了 %@",filePath);
//
//                    appModel.bundleURL = [filePath stringByAppendingPathComponent:@"main.jsbundle"];
//
//                } downloadFailure:^(NSError *error) {
//
//                }];
//
//                self.update = update;
                
                RNListCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                [cell startDownloadForURL:[NSURL URLWithString:appModel.rnAppInfo.file]];
                
            }

        }
        
    };
    
    UITableViewRowAction *action1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:rowActionHandler];
    
    UITableViewRowAction *action2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"更新" handler:rowActionHandler];
    
    action2.backgroundColor = [UIColor orangeColor];
    
    
    return @[action1,action2];
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RNListModel *appModel = self.dataSource[indexPath.row];
    
    if (appModel.rnAppInfo.bundleURL.length > 0) {
        
        NSURL *jsCodeLocation = [NSURL fileURLWithPath:appModel.rnAppInfo.bundleURL];
        RCTRootView *rootView =
        [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                    moduleName:@"MyApp"
                             initialProperties:nil
                                 launchOptions:nil];
        
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view = rootView;
        [self.navigationController pushViewController:vc animated:YES];
    }
}




- (void)alertPromptWithTitle:(NSString *)title message:(NSString *)message handler:(void (^ __nullable)(UIAlertAction *action))handler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:handler];
    [alert addAction:action];
    
    [self presentViewController:alert animated:YES completion:nil];
}



#pragma mark - getters and setters

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.tableFooterView = [UIView new];
//        _tableView.estimatedRowHeight = 84;
//        _tableView.rowHeight = 64;
        _tableView.cellLayoutMarginsFollowReadableWidth = NO;
        [_tableView registerClass:[RNListCell class] forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

@end
