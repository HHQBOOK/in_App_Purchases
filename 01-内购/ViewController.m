//
//  ViewController.m
//  1-内购(in_App Purchases)
//
//  Created by 韩贺强 on 16/7/16.
//  Copyright © 2016年 com.baiduniang. All rights reserved.
//

#import "ViewController.h"
#import <StoreKit/StoreKit.h>   //内购导入框架


@interface ViewController ()<SKProductsRequestDelegate,SKPaymentTransactionObserver>
/**
 *  装所有 可销售内购商品的数组
 */
@property (nonatomic, strong) NSArray * productsArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  

    
    //有内购需要的App 调试需要 真机,并且是未越狱的真机
    //需要先在真机 "设置"-> "APP Store 和 iTunes Store" ->将账号换成 在网站注册的 测试账号(假的,否则真扣钱)
    //需要在 APP中 设置 bundel ID 和 在 网站注册时候一样.
    // 有内购需求的App 需要 安装在App里按钮 苹果develop 网站里面配置好 ios_development.cer 和 xxx.mobileprovision(配置文件),只要双击一下,一闪就算安装好了
    
    //1> App 想苹果请求可销售商品
    //2> 代理方法获得可销售商品
    //3> 展示商品(tableView等)
    //4>用户选择商品
    //5 > 根据用户选择的商品,给用户小票(商品转payment类型),那小票去排队
    //6> 监听 交易队列变化
    //7> 用户去交钱,我们监听用户付款状态
    //8> 付款成功, 我们给用户相应的增值服务
    // 9> 结束交易 (否则用户下一次进来还是在交易)
    

    
    self.navigationItem.title = @"测试";
    UIBarButtonItem *restoreButton = [[UIBarButtonItem alloc]initWithTitle:@"恢复购买" style:UIBarButtonItemStylePlain target:self action:@selector(restoreButtonClick:)];
        self.navigationItem.leftBarButtonItem = restoreButton;
    
    //0 需要获得可销售商品(就是我们的APP内购商品的 productsID)
    NSString * productPath = [[NSBundle mainBundle] pathForResource:@"products.json" ofType:nil];
    
    //把JSON 转为 data
    NSData *jsonData = [NSData dataWithContentsOfFile:productPath];
    
    //反序列化
    NSArray *productArr = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    NSLog(@"%@",productArr);
    
    //我们需要取出 [{productId:"xxxx"}]  数组里的字典里面的 key 对应的Value值
    //传统写法 ----------------------------------------------
    NSMutableArray *tempArr = [NSMutableArray array];
    
    for (NSDictionary *dict in productArr) {
        NSString * valueStr = dict[@"productId"];
        
        [tempArr addObject:valueStr];
    }
    NSLog(@"%@",tempArr);
    //----------------------------------------------------------
    
    //KVC 取值
    NSArray *tempArr2 = [productArr valueForKey:@"productId"];
    NSLog(@"%@",tempArr2);
    
    //1>App向苹果请求可销售商品
    SKProductsRequest * proRequest = [[SKProductsRequest alloc]initWithProductIdentifiers:[NSSet setWithArray:tempArr2]];
    
    //2 >获取可销售的 商品 (通过代理)
    //2.1
    proRequest.delegate = self;
    
    //2.2 需要开始请求
    [proRequest start];
    
    //6 监听 付款队列的变化,增加一个监听者,遵守SKPaymentTransactionObserver 协议就行
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
}

/** 2.3
 *  当获取到苹果允许销售的商品 时候调用
 *
 *  @param request  销售内购商品的请求
 *  @param response 苹果对我的请求的返回的响应 (里面有产品数组,以及不允许销售商品的 ID)
 */
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    
    //遍历,获得每一个可销售商品的信息
    for (SKProduct *product in response.products) {
        
        NSLog(@"产品价格%@---产品ID %@---产品标题 %@----产品描述 %@",product.price,product.productIdentifier,product.localizedTitle,product.localizedDescription);
    }
    
    //给全局数组赋值,里面装可销售 商品
    self.productsArray = response.products;
    
    //赋值后,需要刷新数据源
    [self.tableView reloadData];
}

//3 通过tableview展示数据  可销售商品的数据
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.productsArray.count;
}
//3.1
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *ID = @"storeCell";
    UITableViewCell *cell  = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    }
    
    SKProduct *product = self.productsArray[indexPath.row];
    
    cell.textLabel.text = product.localizedTitle;
    //    cell.detailTextLabel.text = product.price.stringValue;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",[product.price description]];
    
    
    /*源代码:
     cell.detailTextLabel.text = product.price;--->引起Crash.报错如下 是因为price类型是 NSDecimalNumber.
     报错:
     reason: '-[NSDecimalNumber isEqualToString:]: unrecognized selector sent to instance 0x7fa11ad28f10'
     更改1:    cell.detailTextLabel.text = product.price.stringValue;
     更改2:    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",[product.price description]];
     (1/2留下一个就行.)
     */
    
    return cell;
}

//4 用户选择商品(屠龙刀 ,大药瓶等), 代理方法
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    // 4.1 取出用户选择的产品
    SKProduct *product = self.productsArray[indexPath.row];
    
    //4.2 拿商品转换类型 (根据商品是什么样的,商家给用户小票,让用户拿着小票去排队付款)
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    
    //5 .  排队,等付款
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

/**
 *  7. 监听付款队列发生了变化时候调用   直白:更新付款队列的情报
 *
 *  @param queue        付款队列 交易队列
 *  @param transactions 所有的交易(别人也在交易,存在许多交易在队列里,放进一个数组里)
 */
/*
 SKPaymentTransactionStatePurchasing,    // 交易正在被加入队列
 SKPaymentTransactionStatePurchased,     // 交易在队列中, 用户已经付款.客户端需要完成交易
 SKPaymentTransactionStateFailed,        // 交易失败
 SKPaymentTransactionStateRestored,      // 交易从交易历史中被恢复.  客户端需要完成交易.
 SKPaymentTransactionStateDeferred       // 交易暂时不确定. 加入交易队列了,在犹豫要不要付款. iOS8新增
 */
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    
    //遍历所有交易,得出没有交易的状态
    for (SKPaymentTransaction * payTran in transactions) {
        
                if(payTran.transactionState == SKPaymentTransactionStatePurchased){
        
        //8. 用户付款成功,我们提供相应增值服务.
        NSLog(@"用户已经付款,我方App给他提供增值服务");
        
        //9 结束交易.  操作队列结束本次 交易.
        [[SKPaymentQueue defaultQueue] finishTransaction:payTran];
                }
    
                if(payTran.transactionState == SKPaymentTransactionStateRestored){
        
        //8. 用户付款成功,我们提供相应增值服务.
                    NSLog(@"用户已经付款,我方App给他提供增值服务");
        
        //9 结束交易.  操作队列结束本次 交易.
                    [[SKPaymentQueue defaultQueue] finishTransaction:payTran];
                }
        
               //增加一个判断.如果失败,失败的原因是什么(不是用户主动取消的情况)
                 if (payTran.transactionState == SKPaymentTransactionStateFailed) {
                    if (payTran.error.code != SKErrorPaymentCancelled) {
                        NSLog(@"交易失败： %@", payTran.error.localizedDescription);
                    }
                }
    }
    
}
// 10 :一键 恢复购买装备 (例如换手机了)
-(void)restoreButtonClick:(UIButton *)sender{
    // 付款队列 恢复 已经完成的 所有交易
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    // 付款队列 恢复 已经完成的 所有交易 需要应用程序的 用户名. (用户可能有3个号)(用户填写用户名去后台验证密码)
    //    [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:<#(nullable NSString *)#>];
}

@end

