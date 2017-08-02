//
//  WalletCoordinator.m
//  qtum wallet
//
//  Created by Vladimir Lebedevich on 02.03.17.
//  Copyright © 2017 PixelPlex. All rights reserved.
//

#import "WalletCoordinator.h"

#import "WalletOutput.h"
#import "BalancePageOutput.h"
#import "TokenListOutput.h"
#import "HistoryItemOutput.h"
#import "RecieveOutput.h"

#import "WalletTableSource.h"
#import "TabBarCoordinator.h"
#import "HistoryDataStorage.h"
#import "Spendable.h"
#import "TokenDetailsViewController.h"
#import "TokenDetailsTableSource.h"
#import "QRCodeViewController.h"
#import "ShareTokenPopUpViewController.h"

#import "WalletNavigationController.h"
#import "TokenListViewController.h"
#import "TokenFunctionViewController.h"
#import "ContractInterfaceManager.h"
#import "TokenFunctionDetailViewController.h"
#import "ResultTokenInputsModel.h"
#import "ContractArgumentsInterpretator.h"
#import "NSString+Extension.h"
#import "TransactionManager.h"
#import "ContractFileManager.h"
#import "WalletManager.h"
#import "AddressLibruaryCoordinator.h"

@interface WalletCoordinator () <TokenListOutputDelegate, QRCodeViewControllerDelegate, WalletOutputDelegate, HistoryItemOutputDelegate, RecieveOutputDelegate, ShareTokenPopupViewControllerDelegate, PopUpViewControllerDelegate, TokenDetailOutputDelegate, AddressLibruaryCoordinator>

@property (strong, nonatomic) UINavigationController* navigationController;

@property (strong, nonatomic) NSObject<BalancePageOutput>* pageViewController;
@property (weak, nonatomic) NSObject<WalletOutput> *walletViewController;
@property (weak, nonatomic) NSObject<TokenListOutput> *tokenController;
@property (weak, nonatomic) NSObject <TokenDetailOutput> *tokenDetailsViewController;

@property (assign, nonatomic) BOOL isNewDataLoaded;
@property (assign, nonatomic) BOOL isBalanceLoaded;
@property (assign, nonatomic) BOOL isHistoryLoaded;

@property (strong, nonatomic) id<Spendable> wallet;
@property (strong, nonatomic) dispatch_queue_t requestQueue;

@property (strong, nonatomic) WalletTableSource* delegateDataSource;
@property (strong, nonatomic) id <TokenDetailDataDisplayManager> tokenDetailsTableSource;

@end

@implementation WalletCoordinator

-(instancetype)initWithNavigationController:(UINavigationController*)navigationController{
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _isNewDataLoaded = YES;
        _requestQueue = dispatch_queue_create("com.pixelplex.requestQueue", DISPATCH_QUEUE_SERIAL);
        [self subcribeEvents];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - QRCodeViewControllerDelegate

- (void)didQRCodeScannedWithQRCodeItem:(QRCodeItem *)item {
    [self.navigationController popViewControllerAnimated:NO];
    [self.delegate createPaymentFromQRCodeItem:item];
}

#pragma mark - Coordinatorable

-(void)start{
    
    NSObject<WalletOutput> *controller = [[ControllersFactory sharedInstance] createWalletViewController];
    controller.delegate = self;
    
    [self configWallet];
    [controller setWallet:self.wallet];
    self.delegateDataSource = [[TableSourcesFactory sharedInstance] createWalletSource];
    self.delegateDataSource.delegate = self;
    self.delegateDataSource.wallet = self.wallet;
    self.delegateDataSource.haveTokens = [[ContractManager sharedInstance] allActiveTokens].count > 0;
    controller.tableSource = self.delegateDataSource;
    self.walletViewController = controller;
    
    NSObject<TokenListOutput>* tokenController = [[ControllersFactory sharedInstance] createTokenListViewController];
    tokenController.tokens = [[ContractManager sharedInstance] allActiveTokens];
    tokenController.delegate = self;
    controller.delegate = self;
    self.tokenController = tokenController;
    
    self.pageViewController = (NSObject<BalancePageOutput> *)self.navigationController.viewControllers[0];
    self.pageViewController.controllers = @[controller, tokenController];
    [self.pageViewController setScrollEnable:[[ContractManager sharedInstance] allTokens].count > 0];
}

#pragma mark - WalletCoordinatorDelegate

- (void)refreshTableViewData {
    
    if (self.isNewDataLoaded) {
        [self refreshHistory];
    }
}

- (void)didSelectHistoryItemIndexPath:(NSIndexPath *)indexPath withItem:(HistoryElement*) item {
    
    NSObject<HistoryItemOutput> *controller = [[ControllersFactory sharedInstance] createHistoryItem];
    controller.item = item;
    controller.delegate = self;
    [self.navigationController pushViewController:[controller toPresent] animated:YES];
}

#pragma mark - TokenListOutputDelegate

- (void)didSelectTokenIndexPath:(NSIndexPath *)indexPath withItem:(Contract*) item{

    NSObject <TokenDetailOutput> *output = [[ControllersFactory sharedInstance] createTokenDetailsViewController];
    self.tokenDetailsViewController = output;
    self.tokenDetailsTableSource = [[TableSourcesFactory sharedInstance] createTokenDetailSource];
    self.tokenDetailsTableSource.token = item;
    output.token = item;
    output.delegate = self;
    output.source = self.tokenDetailsTableSource;
    [self.navigationController pushViewController:[output toPresent] animated:YES];
}

#pragma mark - TokenDetailOutputDelegate 


-(void)showAddressInfoWithSpendable:(id <Spendable>) spendable {
    
    NSObject<RecieveOutput> *vc = [[ControllersFactory sharedInstance] createRecieveViewController];
    vc.wallet = spendable;
    vc.delegate = self;
    [self.navigationController pushViewController:[vc toPresent] animated:YES];
}

- (void)didBackPressed{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didShareTokenButtonPressed {
    
    ShareTokenPopUpViewController *vc = [[PopUpsManager sharedInstance] showShareTokenPopUp:self presenter:nil completion:nil];
    vc.addressString = self.tokenDetailsViewController.token.contractAddress;
    NSArray *arr = [[ContractFileManager sharedInstance] abiWithTemplate:self.tokenDetailsViewController.token.templateModel.path];
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:arr options:NSJSONWritingPrettyPrinted error:nil];
    NSString * abiString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    vc.abiString = abiString;
}



#pragma mark - Configuration

-(void)configWallet {
    
    self.wallet = (id <Spendable>)[ApplicationCoordinator sharedInstance].walletManager.wallet;
}

-(void)setWalletToDelegates {
    
    self.delegateDataSource.wallet = self.wallet;
    [self.walletViewController setWallet:self.wallet];
}

#pragma mark - Private Methods

-(void)refreshHistory {
    
    __weak __typeof(self)weakSelf = self;
    dispatch_async(_requestQueue, ^{
        [weakSelf.walletViewController startLoading];
        weakSelf.isHistoryLoaded = NO;
        id <Spendable> spendable = (id<Spendable>)(weakSelf.wallet);
        NSInteger index = spendable.historyStorage.pageIndex + 1; //next page
        [weakSelf.wallet updateHistoryWithHandler:^(BOOL success) {
            weakSelf.isHistoryLoaded = YES;
            if (success) {
                [weakSelf.walletViewController reloadTableView];
            }
            [weakSelf stopRefreshing];
        } andPage:index];
    });
}

-(void)reloadHistory {
    
    __weak __typeof(self)weakSelf = self;
    dispatch_async(_requestQueue, ^{
        [weakSelf.walletViewController startLoading];
        weakSelf.isHistoryLoaded = NO;
        [weakSelf.wallet updateHistoryWithHandler:^(BOOL success) {
            weakSelf.isHistoryLoaded = YES;
            if (success) {
                [weakSelf.walletViewController reloadTableView];
            }
            [weakSelf stopRefreshing];
        } andPage:0];
    });
}

-(void)stopRefreshing{
    
    if (self.isBalanceLoaded && self.isHistoryLoaded) {
        [self.walletViewController stopLoading];
    }
}

-(void)subcribeEvents{

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSpendables) name:kWalletDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTokens) name:kTokenDidChange object:nil];
}

-(void)updateSpendables {
    
    NSArray *tokensArray = [[ContractManager sharedInstance] allActiveTokens];
    self.delegateDataSource.haveTokens = tokensArray.count > 0;
    [self.walletViewController reloadTableView];
    self.tokenController.tokens = tokensArray;
    [self.tokenController reloadTable];
    
    if (tokensArray.count == 0) {
        [self.pageViewController scrollToRootIfNeededAnimated:YES];
    } else {
        [self.pageViewController setScrollingToTokensAvailableIfNeeded];
    }
}

-(void)updateTokens{
    
    [self configWallet];
    [self setWalletToDelegates];
    
    __weak __typeof(self)weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [weakSelf updateSpendables];
    });
}

-(void)showAddressControllFlow {
    
    AddressLibruaryCoordinator* coordinator = [[AddressLibruaryCoordinator alloc] initWithNavigationViewController:self.navigationController];
    [coordinator start];
    coordinator.delegate = self;
    [self addDependency:coordinator];
}

#pragma mark - AddressLibruaryCoordinator

- (void)coordinatorLibraryDidEnd:(AddressLibruaryCoordinator*)coordinator {
    [self removeDependency:coordinator];
}

#pragma mark - ShareTokenPopupViewControllerDelegate and PopUpViewControllerDelegate

- (void)copyAddressButtonPressed:(PopUpViewController *)sender {
    
    [[PopUpsManager sharedInstance] hideCurrentPopUp:YES completion:nil];
    [self copyTextAndShowPopUp:self.tokenDetailsViewController.token.contractAddress isAbi:NO];
}

- (void)copyAbiButtonPressed:(PopUpViewController *)sender {
    
    [[PopUpsManager sharedInstance] hideCurrentPopUp:YES completion:nil];
    [self copyTextAndShowPopUp:[[ContractFileManager sharedInstance] escapeAbiWithTemplate:self.tokenDetailsViewController.token.templateModel.path] isAbi:YES];
}

- (void)copyTextAndShowPopUp:(NSString *)text isAbi:(BOOL)isAbi {
    
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    NSString* keyString = text;
    [pb setString:keyString];
    
    PopUpContent *content = isAbi ? [PopUpContentGenerator contentForAbiCopied] : [PopUpContentGenerator contentForAddressCopied];
    [[PopUpsManager sharedInstance] showInformationPopUp:self withContent:content presenter:nil completion:nil];
}

- (void)okButtonPressed:(PopUpViewController *)sender {
    [[PopUpsManager sharedInstance] hideCurrentPopUp:YES completion:nil];
}

#pragma mark - WalletOutputDelegate

- (void)didShowQRCodeScan {
    QRCodeViewController *vc = [[ControllersFactory sharedInstance] createQRCodeViewControllerForWallet];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)didRefreshTableViewBalanceLocal:(BOOL)isLocal {
    
    __weak __typeof(self)weakSelf = self;
    dispatch_async(_requestQueue, ^{
        weakSelf.isBalanceLoaded = NO;
        [weakSelf.walletViewController startLoading];
        [weakSelf.wallet updateBalanceWithHandler:^(BOOL success) {
            
            weakSelf.isBalanceLoaded = YES;
            if (success) {
                [weakSelf.walletViewController reloadTableView];
            }
            [weakSelf stopRefreshing];
        }];
    });
}

- (void)didReloadTableViewData {
    if (self.isNewDataLoaded) {
        self.isBalanceLoaded = YES;
        [self reloadHistory];
    }
}

- (void)didShowAddressControll {
    [self showAddressControllFlow];
}


@end
