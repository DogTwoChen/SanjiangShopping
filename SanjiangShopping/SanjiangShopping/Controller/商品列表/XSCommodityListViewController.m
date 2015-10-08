//
//  XSCommodityListViewController.m
//  SanjiangShopping
//
//  Created by 薛纪杰 on 15/9/9.
//  Copyright (c) 2015年 Sanjiang Shopping Club Co., Ltd. All rights reserved.
//

#import "XSCommodityListViewController.h"

#import "XSCommodityViewController.h"

#import "XSSearchTableViewController.h"
#import "XSResultTableViewController.h"
#import "XSSearchBarHelper.h"
#import "XSNavigationBarHelper.h"

#import "XSFilterViewController.h"

#import "XSCommodityListTableViewCell.h"

#import "UtilsMacro.h"

#import <AFNetworking.h>
#import "NetworkConstant.h"
#import "CommodityListModel.h"
#import <MJExtension.h>
#import <UIImageView+WebCache.h>

#import "ThemeColor.h"

static NSString * const cellID = @"commodityList";

@interface XSCommodityListViewController ()
<XSSegmentControlDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSMutableArray   *segmentArr;
@property (strong, nonatomic) UITableView      *tableView;

@property (strong, nonatomic) XSResultTableViewController *resultTableViewController;
@property (strong, nonatomic) XSSearchTableViewController *searchTableViewController;

@property (strong, nonatomic) CommodityListModel *commodityListModel;
@property (copy, nonatomic)   NSString *urlStr;

@property (strong, nonatomic) XSFilterViewController *filterController;

@end

@implementation XSCommodityListViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 状态栏样式
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    // 隐藏TabBar
    self.tabBarController.tabBar.hidden = YES;
    self.definesPresentationContext = YES;
    
    if (self.searchController.active) {
        self.searchController.active = NO;
    }
    
    _segmentControl.selectedIndex = 0;
    
    _urlStr = [NSString stringWithFormat:@"%@%@:%@%@1", PROTOCOL, SERVICE_ADDRESS, DEFAULT_PORT, ROUTER_COMMODITY_LIST];
    [self reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
    
    // 加载搜索框
    [self loadSearchBar];
    
    NSArray *segmentTitles = @[@"综合排序", @"销量", @"价格", @"筛选"];
    _segmentControl = [[XSSegmentControl alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 44)];
    _segmentControl.titles = segmentTitles;
    _segmentControl.delegate = self;
    _segmentControl.selectedIndex = 0;
    _segmentControl.layer.borderColor = [OTHER_SEPARATOR_COLOR CGColor];
    _segmentControl.layer.borderWidth = 1.0f;
    [self.view addSubview:_segmentControl];
    
    CGFloat x = 0;
    CGFloat y = _segmentControl.frame.origin.y + _segmentControl.frame.size.height;
    CGFloat width = _segmentControl.frame.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height - y;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = OTHER_SEPARATOR_COLOR;
    [self.view addSubview:_tableView];
    
    [_tableView registerClass:[XSCommodityListTableViewCell class] forCellReuseIdentifier:cellID];
    [_tableView registerNib:[UINib nibWithNibName:@"XSCommodityListTableViewCell" bundle:nil] forCellReuseIdentifier:cellID];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_searchTableViewController.tableView removeFromSuperview];
    _searchTableViewController = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)segmentItemSelected:(XSSegmentControlItem *)item {
    
    if (item.tag == 3) {
        
        if (!_filterController) {
            _filterController = [[XSFilterViewController alloc] init];
        }
        
        if (![self.view.subviews containsObject:_filterController.view]) {
            [self.view addSubview:_filterController.view];
            _filterController.view.frame = CGRectMake(_tableView.frame.origin.x + _tableView.frame.size.width, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height);
            [UIView animateWithDuration:0.4 animations:^{
                _filterController.view.frame = _tableView.frame;
            }];
        }
        
        return;
    }
    
    if (_filterController != nil) {
        [UIView animateWithDuration:0.4 animations:^{
            _filterController.view.frame = CGRectMake(_tableView.frame.origin.x + _tableView.frame.size.width, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height);
        } completion:^(BOOL finished) {
            [_filterController.view removeFromSuperview];
            _filterController = nil;
        }];
    }
    
    _urlStr = [NSString stringWithFormat:@"%@%@:%@%@%ld", PROTOCOL, SERVICE_ADDRESS, DEFAULT_PORT, ROUTER_COMMODITY_LIST, (long)item.tag % 3 + 1];
    [self loadJSONData];
}

#pragma mark - 加载搜索框
- (void)reloadData {
    NSString *keyword = _searchWords;
    if (keyword == nil) {
        keyword = @"搜索商品名称/商品编号";
    }
    [XSSearchBarHelper hackStandardSearchBar:_searchController.searchBar keyword:keyword];
    
    [self loadJSONData];
}

- (void)loadJSONData {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:@"utf-8" forHTTPHeaderField:@"charset"];
    [manager.requestSerializer setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    __weak typeof(self) weakSelf = self;
    [manager GET:_urlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        weakSelf.commodityListModel = [CommodityListModel objectWithKeyValues:responseObject];
        [weakSelf.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未连接" message:@"无法加载数据" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        NSLog(@"%@", error);
    }];
}

- (void)loadSearchBar {

    _resultTableViewController = [[XSResultTableViewController alloc] init];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:_resultTableViewController];
    _searchController.searchBar.searchBarStyle             = UISearchBarStyleMinimal;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.dimsBackgroundDuringPresentation     = NO;
    
    _searchController.delegate             = self;
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate   = self;
    
    // 设置搜索框样式
    NSString *keyword = _searchWords;
    if (keyword == nil) {
        keyword = @"搜索商品名称/商品编号";
    }
    [XSSearchBarHelper hackStandardSearchBar:_searchController.searchBar keyword:keyword];
    
    self.navigationItem.titleView = _searchController.searchBar;
}

#pragma mark - Table View Data Source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _commodityListModel.data.list.count;
}

- (XSCommodityListTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XSCommodityListTableViewCell *cell = (XSCommodityListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    CommodityListItemModel *item = _commodityListModel.data.list[indexPath.row];

    [cell.picture sd_setImageWithURL:[NSURL URLWithString:item.img]];
    cell.name.text = item.name;
    cell.pn.text = [NSString stringWithFormat:@"￥%@", item.pn];
    cell.rate.text = [NSString stringWithFormat:@"好评率%@%%", item.rate];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = BACKGROUND_COLOR;
    return cell;
}

#pragma mark - Table View Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XSCommodityViewController *viewController = [[XSCommodityViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Search Bar Delegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"开始搜索");
    if ([searchBar.text isEqualToString:@""]) {
        NSLog(@"搜索默认热词");
        XSSearchBarHelper *searchBarHelper = [[XSSearchBarHelper alloc] initWithNavigationBar:_searchController.searchBar];
        [searchBarHelper peek];
        searchBar.text = searchBarHelper.UISearchBarTextField.placeholder;
    }
    [_searchTableViewController.recentSearchData addUniqueString:searchBar.text];
    [_searchTableViewController.tableView reloadData];
}

#pragma mark - Search Result Updater
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSLog(@"%@", searchController.searchBar.text);
}

#pragma mark - Search Controller Delegate
- (void)presentSearchController:(UISearchController *)searchController {
    NSLog(@"开始进入搜索");
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    NSLog(@"将要进入搜索");
    
    self.navigationItem.hidesBackButton = YES;
    
    _searchTableViewController = [[XSSearchTableViewController alloc] init];
    _searchTableViewController.searchBar = _searchController.searchBar;
    _searchTableViewController.contextViewController = self;
    _searchTableViewController.tableView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:_searchTableViewController.tableView];
    
    _searchController.searchBar.showsCancelButton = YES;
    UIView *firstView = _searchController.searchBar.subviews[0];
    for (UIView *secondView in firstView.subviews) {
        if ([secondView isKindOfClass:NSClassFromString(@"UINavigationButton")]) {
            UIButton *cancelButton = (UIButton *)secondView;
            cancelButton.tintColor = [UIColor lightGrayColor];
        }
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    NSLog(@"进入搜索");
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    NSLog(@"将要隐藏搜索");
    if (_searchTableViewController != nil) {
        [_searchTableViewController.tableView removeFromSuperview];
        _searchTableViewController = nil;
    }
    
    [UIView animateWithDuration:0.4 animations:^{
        self.navigationItem.hidesBackButton = NO;
    }];
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    NSLog(@"隐藏搜索");
}

@end
