# 一枚崩溃引发的Tagged Pointer思考

本次调试的环境变量：

```

1、iOS 9 模拟器

2、Xcode 10.1

3、macOS 10.14

```

### 抛砖引玉

请问下面代码会不会崩溃，在哪种情况下会崩溃？

如果会，请列举有哪些情况可能造成崩溃？

如果不会，请列举在哪些情况不会崩溃？

```objective-c
@property(nonatomic, strong) NSString *sString;
    
dispatch_queue_t queue = dispatch_queue_create("parallel",DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < 100000 ; i++) {
        dispatch_async(queue, ^{
            self.sString = [NSString stringWithFormat:@"1"];
        });
    }
```

![img](https://ws4.sinaimg.cn/large/006tNbRwly1fwx6hxxitfj308c08cdfw.jpg)



答案分割线

------

会崩溃的情况：

1、![image-20181105141038978](https://ws4.sinaimg.cn/large/006tNbRwly1fwx5npgtc1j31dc0rawod.jpg)

当 OBJC_DISABLE_TAGGED_POINTERS设置为yes；

必崩；

2、  当 OBJC_DISABLE_TAGGED_POINTERS设置为NO；

把 string的值改大；self.sString = [NSString stringWithFormat:@"1000000000000000"];

必崩；



打印下面代码观察sString的类型

```objective-c
NSLog(@"_sString : %@, %s, %p", self.sString, object_getClassName(self.sString),self.sString);

```

输出：

```c
_sString : 1, NSTaggedPointerString, 0xa000000000000311
```

 `NSTaggedPointerString`，居然是它，它究竟是什么，它从哪里来，它要去哪里？引发思考世界上最终极的三大哲学问题

![img](https://ws2.sinaimg.cn/large/006tNbRwly1fwx14ni8unj308c08c0su.jpg)

------



### Tagged Pointer

#### 1、Tagged Pointer 来自哪里？

##### 背景：

*在2013年9月，苹果推出了[iPhone5s](http://en.wikipedia.org/wiki/IPhone_5S)，与此同时，iPhone5s配备了首个采用64位架构的[A7双核处理器](http://en.wikipedia.org/wiki/Apple_A7)，为了节省内存和提高执行效率，苹果提出了`Tagged Pointer`的概念。*

对于64位程序，**我们的数据类型的长度是跟CPU的长度有关的**。

![img](https://ws2.sinaimg.cn/large/006tNbRwly1fwzg4ebszoj31i004sglg.jpg)

上图可知原来的设计缺陷明显：

1、一些对象占用的内存会翻倍；

2、维护程序中的对象需要 分配内存，维护引用计数，管理生命周期，使用对象给程序的运行增加了负担。



##### 于是乎诞生了Tagged Pointer

苹果对于Tagged Pointer特点的介绍：

1. Tagged Pointer专门用来存储小的对象，例如NSNumber和NSDate

2. Tagged Pointer指针的值不再是地址了，而是真正的值。所以，实际上它不再是一个对象了，它只是一个披着对象皮的普通变量而已。所以，它的内存并不存储在堆中，也不需要malloc和free。

3. 在内存读取上有着3倍的效率，创建时比以前快106倍。


概括起来，好处是  **3倍的访问速度提升，100倍的创建、销毁速度提升**。





### 2、Tagged Pointer 是什么？

##### 首先来看看没有使用Tagged Pointer的指针情况是如何的

![image-20181107135439441](https://ws1.sinaimg.cn/large/006tNbRwly1fwzgfoqms4j313c0dqjur.jpg)



##### 引入了Tagged Pointer对象之后，64位CPU下NSNumber的内存图变成了以下这样：

![image-20181107135507386](https://ws2.sinaimg.cn/large/006tNbRwly1fwzgg7imr1j314y0m6jx2.jpg)

**一个对象的指针拆成两部分，一部分直接保存数据，另一部分作为特殊标记，表示这是一个特别的指针，不指向任何一个地址。**

*由于NSNumber、NSDate一类的变量本身的值需要占用的内存大小常常不需要8个字节，拿整数来说，4个字节所能表示的有符号整数就可以达到20多亿（注：2^31=2147483648，另外1位作为符号位)，对于绝大多数情况都是可以处理的。*

#### Tagged Pointer的类对象有：NSDate、NSNumber、NSString  ...等等

来自Apple 的代码头文件可以看到最新支持哪些类对象

```c
// https://opensource.apple.com/source/objc4/objc4-706/runtime/objc-internal.h

{
    OBJC_TAG_NSAtom            = 0, 
    OBJC_TAG_1                 = 1, 
    OBJC_TAG_NSString          = 2, 
    OBJC_TAG_NSNumber          = 3, 
    OBJC_TAG_NSIndexPath       = 4, 
    OBJC_TAG_NSManagedObjectID = 5, 
    OBJC_TAG_NSDate            = 6, 
    OBJC_TAG_RESERVED_7        = 7, 

    OBJC_TAG_First60BitPayload = 0, 
    OBJC_TAG_Last60BitPayload  = 6, 
    OBJC_TAG_First52BitPayload = 8, 
    OBJC_TAG_Last52BitPayload  = 263, 

    OBJC_TAG_RESERVED_264      = 264
};
```



##### 例子：

```objective-c
        NSNumber *number1 = @(1);
        NSNumber *number2 = @(2);
        NSNumber *number3 = @(3);
        NSNumber *numberFFFF = @(0xFFFF);
        
        NSLog(@"number1 pointer is %p", number1);
        NSLog(@"number2 pointer is %p", number2);
        NSLog(@"number3 pointer is %p", number3);
        NSLog(@"numberffff pointer is %p", numberFFFF);
```

**开启**Tagged Pointer 情况下输出：

```c
 number1 pointer is 0xb000000000000012
 number2 pointer is 0xb000000000000022
 number3 pointer is 0xb000000000000032
 numberffff pointer is 0xb0000000000ffff2
```

由此可见去掉 0xb和2 之后 ，中间number1的值为1.



**在环境变量中设置OBJC_DISABLE_TAGGED_POINTERS=YES强制不启用Tagged Pointer**

**关闭**Tagged Pointer 情况下输出：

```
 number1 pointer is 0x7f8250c0a200
 number2 pointer is 0x7f8250c0a220
 number3 pointer is 0x7f8250d00f70
 numberffff pointer is 0x7f8250e19ad0
```

不启用后上面的例子就会得到这样的结果，也就表示关闭成功了。



