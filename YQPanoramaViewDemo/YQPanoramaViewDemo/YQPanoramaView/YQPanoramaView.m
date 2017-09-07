//
//  YQPanaromView.m
//  YQPanaromViewDEMO
//
//  Created by problemchild on 2017/9/5.
//  Copyright © 2017年 freakyyang. All rights reserved.
//

@import SceneKit;
@import SpriteKit;

#import "YQPanoramaView.h"

@interface YQPanoramaView ()<UIScrollViewDelegate>

@property(nonatomic,strong)SCNNode *cameraNode;

@property(nonatomic,strong)SCNView *tscnView;

@property(nonatomic,strong)SCNNode *ballNode;

@property CGPoint firstLocation;
@property CGPoint lastLocation;
@property CGPoint last2Location;

@property (nonatomic,assign)CGFloat firstXAngle;
@property (nonatomic,assign)CGFloat firstYAngle;
@property (nonatomic,assign)CGFloat first2XAngle;
@property (nonatomic,assign)CGFloat first2YAngle;

@property CGFloat lastZoomScale;
@property CGFloat firstZoomScale;

@property CGFloat nowCameraDis;
@property CGFloat maxCameraDis;
@property CGFloat minCameraDis;

@property CGFloat cameraPositionZ;

@property(nonatomic,strong)UIScrollView *mainSCRV;
@property(nonatomic,strong)UIImageView *SCRVZoomView;

@property (nonatomic,strong) NSTimer *animationTimer_pan;
@property (nonatomic,strong) NSTimer *animationTimer_zoom;
@property int animationCount_pan;
@property int animationCount_zoom;
@property BOOL allowAnimation;

@end

@implementation YQPanoramaView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    [self defaultSetting];
    
    self.tscnView = [[SCNView alloc]initWithFrame:self.bounds];
    self.tscnView.scene = [SCNScene scene];
    [self addSubview:self.tscnView];
    
    //camera
    self.cameraNode = [SCNNode node];
    self.cameraNode.camera = [SCNCamera camera];
    self.cameraNode.camera.automaticallyAdjustsZRange = YES;
    self.cameraNode.position = SCNVector3Make(0, 0, self.cameraPositionZ);
    self.cameraNode.camera.xFov = self.nowCameraDis;
    self.cameraNode.camera.yFov = self.nowCameraDis;
    [self.tscnView.scene.rootNode addChildNode:self.cameraNode];
    
    //ball
    self.ballNode = [SCNNode node];
    SCNSphere *ball = [SCNSphere sphereWithRadius:100];
    ball.segmentCount = 50;
    self.ballNode.geometry = ball;
    self.ballNode.geometry.firstMaterial.doubleSided = NO;
    self.ballNode.geometry.firstMaterial.cullMode = SCNCullModeFront;
    self.ballNode.position = SCNVector3Make(0, 0, 0);
    [self.tscnView.scene.rootNode addChildNode:self.ballNode];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(paned:)];
    [self.tscnView addGestureRecognizer:pan];
    
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(zoomed:)];
    [self.tscnView addGestureRecognizer:pinch];
    
    return self;
}

-(void)setImage:(UIImage *)image{
    _image = image;
    self.ballNode.geometry.firstMaterial.diffuse.contents = image;
    self.ballNode.geometry.firstMaterial.diffuse.mipFilter = SCNFilterModeLinear;
    self.ballNode.geometry.firstMaterial.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(-1, 1, 1), 1, 0, 0);
}

- (void)defaultSetting{
    self.lastZoomScale = 1;
    self.nowCameraDis = 60;
    self.maxCameraDis = 120;
    self.minCameraDis = 40;
    self.cameraPositionZ = 90;
    _Fisheye = YES;
    _scrollInertia = YES;
}

-(void)setFisheye:(BOOL)Fisheye{
    if(Fisheye){
        self.cameraPositionZ = 90;
        self.nowCameraDis = 60;
        self.cameraNode.camera.xFov = self.nowCameraDis;
        self.cameraNode.camera.yFov = self.nowCameraDis;
        self.cameraNode.position = SCNVector3Make(0, 0, self.cameraPositionZ);
    }else{
        self.cameraPositionZ = 0;
        self.nowCameraDis = 40;
        self.cameraNode.camera.xFov = self.nowCameraDis;
        self.cameraNode.camera.yFov = self.nowCameraDis;
        self.cameraNode.position = SCNVector3Make(0, 0, 0);
    }
}

-(void)paned:(UIPanGestureRecognizer *)pan{
    
    if(pan.state == UIGestureRecognizerStateBegan){
        [self.animationTimer_pan invalidate];
        self.animationTimer_pan = nil;
        self.allowAnimation = NO;
        self.firstLocation = self.lastLocation;
    }else if(pan.state == UIGestureRecognizerStateChanged){
        CGPoint targetLocation = [pan translationInView:self.tscnView];
        
        CGFloat zoomRait = (self.nowCameraDis-self.minCameraDis)/(self.maxCameraDis-self.minCameraDis);//0~1
        zoomRait = 0.5 + 0.5*zoomRait;//0.5~1
        
        targetLocation = CGPointMake(targetLocation.x*zoomRait + self.firstLocation.x,
                                     targetLocation.y*zoomRait + self.firstLocation.y);
        
        self.last2Location = self.lastLocation;
        self.lastLocation = targetLocation;
        
        CGFloat rait = -(M_PI * 2)/(self.tscnView.frame.size.width) * 0.5;
        
        CGFloat YAngle = rait * targetLocation.x;
        CGFloat XAngle = rait * targetLocation.y;
        
        [self doScrollWithXangle:-XAngle Yangle:-YAngle animationDuration:0];
        
        //NSLog(@"%f",-YAngle - self.firstYAngle);
        if(-YAngle - self.firstYAngle>1){
            //NSLog(@"===========wait To Fix");
        }
        
        if(self.firstXAngle != -XAngle){
            self.first2XAngle = self.firstXAngle;
            self.firstXAngle = -XAngle;
        }
        if(self.firstYAngle != -YAngle){
            self.first2YAngle = self.firstYAngle;
            self.firstYAngle = -YAngle;
        }
    }else if(pan.state == UIGestureRecognizerStateEnded && self.scrollInertia){
        //挑战自己，手写惯性————————T_T
        [self.animationTimer_pan invalidate];
        self.animationCount_pan = 20;
        self.allowAnimation = YES;
        self.animationTimer_pan = [NSTimer timerWithTimeInterval:0.05
                                                         repeats:YES
                                                           block:^(NSTimer * _Nonnull timer)
                                   {
                                       self.animationCount_pan--;
                                       if(self.animationCount_pan<=0){
                                           [timer invalidate];
                                       }else if(self.allowAnimation){
                                           CGFloat countRait = ((double)self.animationCount_pan/20.0);
                                           CGFloat newXangle = self.firstXAngle+(self.firstXAngle-self.first2XAngle)*countRait;
                                           CGFloat newYangle = self.firstYAngle+(self.firstYAngle-self.first2YAngle)*countRait;
                                           
                                           CGPoint oldLocation = self.lastLocation;
                                           self.lastLocation = CGPointMake(self.lastLocation.x+(self.lastLocation.x-self.last2Location.x)*countRait,
                                                                           self.lastLocation.y+(self.lastLocation.y-self.last2Location.y)*countRait);
                                           self.last2Location = oldLocation;
                                           
                                           [self doScrollWithXangle:newXangle Yangle:newYangle animationDuration:0.05];
                                           
                                           CGFloat Xoldvalue = self.firstXAngle;
                                           CGFloat Yoldvalue = self.firstYAngle;
                                           
                                           self.firstXAngle = newXangle;
                                           self.firstYAngle = newYangle;
                                           self.first2XAngle = Xoldvalue;
                                           self.first2YAngle = Yoldvalue;
                                       }
                                       
                                   }];
        [[NSRunLoop currentRunLoop]addTimer:self.animationTimer_pan forMode:NSRunLoopCommonModes];
    }
}

- (void)doScrollWithXangle:(CGFloat)Xangle Yangle:(CGFloat)YAngle animationDuration:(CGFloat)duration{
    if(Xangle > M_PI*0.5){
        Xangle = M_PI * 0.5;
    }else if(Xangle < -M_PI*0.5){
        Xangle = - M_PI * 0.5;
    }
    NSArray *AfterAngles = [self transformX:0 Y:0 Z:self.cameraPositionZ
                                   inXAngle:Xangle
                                     YAngle:YAngle
                                     ZAngle:0];
    CGFloat newXAngle = ((NSNumber *)AfterAngles[0]).doubleValue;
    CGFloat newYAngle = ((NSNumber *)AfterAngles[1]).doubleValue;
    CGFloat newZAngle = ((NSNumber *)AfterAngles[2]).doubleValue;
    
    [self.cameraNode runAction:[SCNAction rotateToX:Xangle y:YAngle z:0 duration:duration]];
    [self.cameraNode runAction:[SCNAction moveTo:SCNVector3Make(newXAngle,
                                                                newYAngle,
                                                                newZAngle)
                                        duration:duration]];
}

-(void)zoomed:(UIPinchGestureRecognizer *)zoom{
    
    if(zoom.state == UIGestureRecognizerStateBegan){
        [self.animationTimer_zoom invalidate];
        self.allowAnimation = NO;
        self.firstZoomScale = self.nowCameraDis;
    }else{
        self.nowCameraDis = self.firstZoomScale / (zoom.scale);
        //NSLog(@"%f",self.nowCameraDis);
        if(self.nowCameraDis > 130){
            self.nowCameraDis = 130;
        }
        if(self.nowCameraDis < 10){
            self.nowCameraDis = 10;
        }
        self.cameraNode.camera.xFov = self.nowCameraDis;
        self.cameraNode.camera.yFov = self.nowCameraDis;
        
    }
    if(zoom.state == UIGestureRecognizerStateEnded && self.scrollInertia){
        //挑战自己，手写弹性————————T_T
        
        if(self.nowCameraDis < self.minCameraDis){
            [self.animationTimer_zoom invalidate];
            self.allowAnimation = YES;
            self.animationTimer_zoom = [NSTimer timerWithTimeInterval:0.01
                                                              repeats:YES
                                                                block:^(NSTimer * _Nonnull timer)
                                        {
                                            if(self.allowAnimation){
                                                self.nowCameraDis = self.nowCameraDis+(self.minCameraDis-self.nowCameraDis)/20;
                                                self.cameraNode.camera.xFov = self.nowCameraDis;
                                                self.cameraNode.camera.yFov = self.nowCameraDis;
                                            }
                                            if(self.nowCameraDis>self.minCameraDis+1){
                                                [timer invalidate];
                                            }
                                        }];
            [[NSRunLoop currentRunLoop]addTimer:self.animationTimer_zoom forMode:NSRunLoopCommonModes];
        }
        if(self.nowCameraDis > self.maxCameraDis){
            [self.animationTimer_zoom invalidate];
            self.allowAnimation = YES;
            self.animationTimer_zoom = [NSTimer timerWithTimeInterval:0.01
                                                              repeats:YES
                                                                block:^(NSTimer * _Nonnull timer)
                                        {
                                            if(self.allowAnimation){
                                                self.nowCameraDis = self.nowCameraDis-(self.nowCameraDis-self.maxCameraDis)/20;
                                                self.cameraNode.camera.xFov = self.nowCameraDis;
                                                self.cameraNode.camera.yFov = self.nowCameraDis;
                                            }
                                            if(self.nowCameraDis<self.maxCameraDis-1){
                                                [timer invalidate];
                                            }
                                        }];
            [[NSRunLoop currentRunLoop]addTimer:self.animationTimer_zoom forMode:NSRunLoopCommonModes];
        }
    }
}

- (NSArray *)transformX:(CGFloat)X Y:(CGFloat)Y Z:(CGFloat)Z
               inXAngle:(CGFloat)XAngle YAngle:(CGFloat)YAngle ZAngle:(CGFloat)ZAngle
{
    CGFloat afterX = X,afterY = Y,afterZ = Z;
    
    if(ZAngle != 0){
        CGFloat ZPointAngle = 0;
        if(afterY != 0){
            ZPointAngle = atan(afterX/afterY);
        }else{
            ZPointAngle = 0.5*M_PI*(afterX>0?1:-1);
        }
        CGFloat ZAfterAngle = ZPointAngle + ZAngle;
        CGFloat ZR = sqrt(afterX*afterX+afterY*afterY);
        afterX += (afterY<0?-1:1)*sin(ZAfterAngle)*ZR - afterX;
        afterY += (afterY<0?-1:1)*cos(ZAfterAngle)*ZR - afterY;
    }
    
    if(XAngle != 0){
        CGFloat XPointAngle = 0;
        if(afterY != 0){
            XPointAngle = atan(afterZ/afterY);
        }else{
            XPointAngle = 0.5*M_PI*(afterZ>0?1:-1);
        }
        CGFloat XAfterAngle = XPointAngle + XAngle;
        CGFloat XR = sqrt(afterY*afterY+afterZ*afterZ);
        afterZ += (afterY<0?-1:1)*sin(XAfterAngle)*XR - afterZ;
        afterY += (afterY<0?-1:1)*cos(XAfterAngle)*XR - afterY;
    }
    
    if(YAngle != 0){
        CGFloat YPointAngle = 0;
        if(afterZ != 0){
            YPointAngle = atan(afterX/afterZ);
        }else{
            YPointAngle = 0.5*M_PI*(afterX>0?1:-1);
        }
        CGFloat YAfterAngle = YPointAngle + YAngle;
        CGFloat YR = sqrt(afterX*afterX+afterZ*afterZ);
        afterX += (afterZ<0?-1:1)*sin(YAfterAngle)*YR - afterX;
        afterZ += (afterZ<0?-1:1)*cos(YAfterAngle)*YR - afterZ;
    }
    
    return @[[NSNumber numberWithDouble:afterX],
             [NSNumber numberWithDouble:afterY],
             [NSNumber numberWithDouble:afterZ]];
}

@end
