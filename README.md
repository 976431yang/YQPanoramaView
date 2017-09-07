# YQPanoramaView
iOS端-720°全景环绕图展示控件，带鱼眼效果，仿insta360


#### 微博：畸形滴小男孩
##### iOS端-720°全景环绕图展示控件，带鱼眼效果，仿insta360

## 效果（开启鱼眼效果）：
#### 动图加载较慢，请耐心等候
 ![image](https://github.com/976431yang/YQPanoramaView/blob/master/YQPanoramaViewDemo/screenShot/1.gif) 
 ![image](https://github.com/976431yang/YQPanoramaView/blob/master/YQPanoramaViewDemo/screenShot/2.gif)</br>
 ![image](https://github.com/976431yang/YQPanoramaView/blob/master/YQPanoramaViewDemo/screenShot/3.gif) 
 ![image](https://github.com/976431yang/YQPanoramaView/blob/master/YQPanoramaViewDemo/screenShot/4.gif) 
  </br>
  - 如果不需要鱼眼效果，可以关闭，关闭后形变会少一些。

</br></br>

## 原片源：

#### 使用本控件的前提，是你得有一张全景环绕图的导出图。比如下面这张：

![image](https://github.com/976431yang/YQPanoramaView/blob/master/YQPanoramaViewDemo/screenShot/before.jpeg) 

- 注意上下边缘，是由球型拉伸开的。

#### 上面那张图片显示出来的效果如下：

- 不要问我如何生成上面那张图，因为我也不知道^_^。我只做了如何显示，并没做如何生成^_^。

- 现在网络上会有一些这种图，如果你有全景相机的话，也可以导出这种图。

![image](https://github.com/976431yang/YQPanoramaView/blob/master/YQPanoramaViewDemo/screenShot/after.jpeg)
</br>

## 使用：
##### 直接拖到工程中
##### 引入
```objective-c
#import "YQPanoramaView.h"
```
##### 使用非常简单
```objective-c
    //初始化
    self.panaromview = [[YQPanoramaView alloc]initWithFrame:CGRectMake(20,20,
                                                                       self.view.frame.size.width-40,
                                                                       self.view.frame.size.height-80)];
    
    //设图片
    self.panaromview.image = [UIImage imageNamed:@"WechatIMG67.jpeg"];
    
    //显示
    [self.view addSubview:self.panaromview];
```

##### 如果需要关闭“鱼眼效果”

- 开启后，在视野较窄的时候，形变并不大。在视野较广的时候会有形变，但效果很漂亮，类似Insta360。
- 关闭后形变会变少，但查看效果并不是太好，类似微博和小米的全景图效果。


```objective-c
    self.panaromview.Fisheye = NO;
```

##### 如果需要关闭“滑动惯性”

- 追求滑动稳定的话可以关闭。

```objective-c
    self.panaromview.Fisheye = NO;
```
