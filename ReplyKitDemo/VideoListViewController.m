//
//  VideoListViewController.m
//  ReplyKitDemo
//
//  Created by Yang.Lv on 2017/8/7.
//  Copyright © 2017年 czl. All rights reserved.
//

#import "VideoListViewController.h"
#import "VideoModel.h"
#import "BSScreenRecorder.h"
#import "SHBAVController.h"

static NSString *VIDEO_LIST_CELL = @"video_list_cell_id";

@interface VideoListViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation VideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataArray = [NSMutableArray array];
    
    self.tableview.delegate = self;
    self.tableview.dataSource = self;
    [self.tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:VIDEO_LIST_CELL];
    
    [self loadVideoList];
}

- (void)loadVideoList
{
    [[BSScreenRecorder shareRecorder]  loadVideoListCompleted:^(NSArray *result) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSString *path in result) {
            VideoModel *model = [[VideoModel alloc] init];
            model.filePath = path;
            [array addObject:model];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataArray setArray:array];
            [self.tableview reloadData];
        });
    }];
}

#pragma mark -  UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VIDEO_LIST_CELL forIndexPath:indexPath];
    cell.imageView.image = [self.dataArray[indexPath.row] thumnailImage];
    cell.textLabel.text = [self.dataArray[indexPath.row] fileName];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *url = [NSURL fileURLWithPath:[self.dataArray[indexPath.row] filePath]];
    SHBAVController *vc = [[SHBAVController alloc] initWithUrl:url];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
