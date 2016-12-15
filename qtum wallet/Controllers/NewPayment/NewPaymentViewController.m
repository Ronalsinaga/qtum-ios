//
//  NewPaymentViewController.m
//  qtum wallet
//
//  Created by Sharaev Vladimir on 18.11.16.
//  Copyright © 2016 Designsters. All rights reserved.
//

#import "NewPaymentViewController.h"
#import "TransactionManager.h"
#import "QRCodeViewController.h"
#import "TextFieldWithLine.h"

@interface NewPaymentViewController () <UITextFieldDelegate, QRCodeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet TextFieldWithLine *addressTextField;
@property (weak, nonatomic) IBOutlet TextFieldWithLine *amountTextField;

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UILabel *residueValueLabel;

- (IBAction)backbuttonPressed:(id)sender;
- (IBAction)makePaymentButtonWasPressed:(id)sender;
@end

@implementation NewPaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDoneButtonToAmountTextField];
    
    if (self.dictionary) {
        [self qrCodeScanned:self.dictionary];
    }
    
    self.residueValueLabel.text = self.currentBalance;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:self.amountTextField]) {
//        [self calculateResidue:nil];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField isEqual:self.amountTextField]) {
        NSMutableString *newString = [textField.text mutableCopy];
        [newString replaceCharactersInRange:range withString:string];
        NSString *complededString = [newString stringByReplacingOccurrencesOfString:@"," withString:@"."];
        [self calculateResidue:complededString];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)addDoneButtonToAmountTextField
{
    UIToolbar* toolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    toolbar.barTintColor = [UIColor groupTableViewBackgroundColor];
    toolbar.items = @[
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)],
                      ];
    [toolbar sizeToFit];
    
    self.amountTextField.inputAccessoryView = toolbar;
}

- (void)done:(id)sender
{
    [self.amountTextField resignFirstResponder];
}

- (void)calculateResidue:(NSString *)string
{
    double amount;
    if (string) {
        amount = [string doubleValue];
    }else{
        amount = [self.amountTextField.text doubleValue];
    }
    double balance = [self.currentBalance doubleValue];
    
    double residue = balance - amount;
    self.residueValueLabel.text = [NSString stringWithFormat:@"%lf", residue];
}

#pragma mark - Action

- (IBAction)backbuttonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)makePaymentButtonWasPressed:(id)sender
{
    NSNumber *amount = @([self.amountTextField.text doubleValue]);
    NSString *address = self.addressTextField.text;
    
    NSArray *array = @[@{@"amount" : amount, @"address" : address}];
    
    TransactionManager *transactionManager = [[TransactionManager alloc] initWith:array];
    
    [SVProgressHUD show];
    
    __weak typeof(self) weakSelf = self;
    [transactionManager sendTransactionWithSuccess:^{
        [SVProgressHUD showSuccessWithStatus:@"Done"];
        [weakSelf backbuttonPressed:nil];
    } andFailure:^(NSString *message){
        [SVProgressHUD dismiss];
        [weakSelf showAlertWithTitle:@"Error" mesage:message andActions:nil];
    }];
}

#pragma mark - QRCodeViewControllerDelegate

- (void)qrCodeScanned:(NSDictionary *)dictionary
{
    self.addressTextField.text = dictionary[PUBLIC_ADDRESS_STRING_KEY];
    self.amountTextField.text = dictionary[AMOUNT_STRING_KEY];
}

#pragma mark - 

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = segue.identifier;
    
    if ([segueID isEqualToString:@"NewPaymentToQrCode"]) {
        QRCodeViewController *vc = (QRCodeViewController *)segue.destinationViewController;
        
        vc.delegate = self;
    }
}

@end
