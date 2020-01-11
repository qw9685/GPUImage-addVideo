//
//  GPUImageViewController.m
//  视频功能开发
//
//  Created by mac on 2019/7/18.
//  Copyright © 2019 cc. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ViewController ()

@property (nonatomic,strong) GPUImageMovieWriter *movieWriter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addFilter];
}

- (void)addFilter{
    NSURL *path1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"mp4"]];
    NSURL *path2 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"2" ofType:@"mp4"]];
    
    AVAsset* inputAsset1 = [AVAsset assetWithURL:path1];
    AVAsset* inputAsset2 = [AVAsset assetWithURL:path2];
    
    NSString *outPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];//输出文件
    NSURL* outUrl = [NSURL fileURLWithPath:outPath];
    [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];
    
    //输入源1
    GPUImageMovie* imageMovie1 = [[GPUImageMovie alloc] initWithURL:path1];
    imageMovie1.shouldRepeat = NO;//循转播放
    imageMovie1.playAtActualSpeed = YES;//预览视频时的速度是否要保持真实的速度
    imageMovie1.runBenchmark = YES;//打印处理的frame
    
    //输入源2
    GPUImageMovie* imageMovie2 = [[GPUImageMovie alloc] initWithURL:path2];
    imageMovie2.shouldRepeat = NO;//循转播放
    imageMovie2.playAtActualSpeed = YES;//预览视频时的速度是否要保持真实的速度
    imageMovie2.runBenchmark = YES;//打印处理的frame
    
    
    //输出源
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:outUrl size:[self getVideoOutPutNaturalSizeWithAsset:inputAsset1]];
    self.movieWriter.transform = [self getVideoOrientationWithAsset:inputAsset1];
    self.movieWriter.encodingLiveVideo = NO;//视频是否循环播放
    self.movieWriter.shouldPassthroughAudio = YES;//是否使用源音源
    
    // 滤镜
    GPUImageDissolveBlendFilter * filter = [[GPUImageDissolveBlendFilter  alloc] init];
    filter.mix = 0.5;
        
    [filter addTarget:self.movieWriter];
    [imageMovie1 addTarget:filter];
    [imageMovie2 addTarget:filter];
    
    [self.movieWriter startRecording];
    [imageMovie1 startProcessing];
    [imageMovie2 startProcessing];

    __weak typeof(self) weakSelf = self;
    [self.movieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        NSLog(@"合并完成");
        [filter removeTarget:strongSelf.movieWriter];
        [strongSelf.movieWriter finishRecording];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AVPlayerViewController *playerVc = [[AVPlayerViewController alloc]init];
            playerVc.player = [[AVPlayer alloc]initWithURL:outUrl];
            [playerVc.player play];
            [strongSelf presentViewController:playerVc animated:YES completion:nil];
        });
    }];
    
    [self.movieWriter setFailureBlock:^(NSError *error) {
        NSLog(@"合成失败：error = %@",error.description);
    }];
}

//获取视频旋转角度
- (CGAffineTransform)getVideoOrientationWithAsset:(AVAsset*)asset{
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
    return videoTrack.preferredTransform;
}
//获取视频分辨率
- (CGSize)getVideoOutPutNaturalSizeWithAsset:(AVAsset*)asset{
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
    CGFloat width = videoTrack.naturalSize.width;
    CGFloat height = videoTrack.naturalSize.height;
    
    CGSize size = CGSizeZero;
    CGAffineTransform videoTransform = videoTrack.preferredTransform;//矩阵旋转角度
    
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        size = CGSizeMake(width, height);
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        size = CGSizeMake(width, height);
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        size = CGSizeMake(width, height);
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        size = CGSizeMake(height, width);
    }
    
    return size;
}

@end
