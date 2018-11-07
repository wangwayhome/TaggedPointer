//
//  ViewController.m
//  TaggedPointer
//
//  Created by wangwayhome on 2018/11/5.
//  Copyright © 2018 wangwayhome. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
        NSNumber *number1 = @(1);
        NSNumber *number2 = @(2);
        NSNumber *number3 = @(3);
        NSNumber *numberFFFF = @(0xFFFF);
        
        NSLog(@"number1 pointer is %p", number1);
        NSLog(@"number2 pointer is %p", number2);
        NSLog(@"number3 pointer is %p", number3);
        NSLog(@"numberffff pointer is %p", numberFFFF);
    



    
//    dispatch_queue_t queue = dispatch_queue_create("parallel", DISPATCH_QUEUE_CONCURRENT);
//    for (int i = 0; i < 100000 ; i++) {
//        dispatch_async(queue, ^{
//            self.sString = [NSString stringWithFormat:@"1"];
//            NSLog(@"_sString : %@, %s, %p", self.sString, object_getClassName(self.sString), self.sString);
//
//        });
//    }
    



}


@end
