//
//  SSCaptureManager.m
//  ShootAndShare
//
//  Created by Leonard Li on 8/18/14.
//  Copyright (c) 2014 Leonard Li. All rights reserved.
//

#import "SSCaptureManager.h"
#import <AVFoundation/AVFoundation.h>

@interface SSCaptureManager () <AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureMovieFileOutput *fileOutput;
@property (strong, nonatomic) NSURL *squareOutputFileURL;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) UIView *previewView;
@property (readwrite, nonatomic) BOOL isRecording;

@end


@implementation SSCaptureManager 
- (instancetype)initWithView:(UIView *)previewView {
    
    self = [super init];
    if (self) {
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        self.previewView = previewView;
        
        [self initializeVideoDeviceInput];
        [self initializeAudioDeviceInput];
        [self initializeDeviceOutput];
        
        [self.captureSession startRunning];
    }
    return self;
}

- (void)initializeVideoDeviceInput {
    NSError *error;
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice
                                                                              error:&error];
    if (error) {
        NSLog(@"Video input creation failed");
    }
    
	if (deviceInput && [self.captureSession canAddInput:deviceInput]) {
        [self.captureSession addInput:deviceInput];
    } else {
        NSLog(@"Error setting video input device");
    }
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.previewView.bounds;
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [self.previewView.layer addSublayer:self.previewLayer];
    [self.captureSession startRunning];
}

- (void)initializeAudioDeviceInput {
    NSError *error;
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];

    if (error) {
        NSLog(@"Audio input creation failed");
    }
    
	if (audioDevice && [self.captureSession canAddInput:audioInput]) {
        [self.captureSession addInput:audioInput];
    } else {
        NSLog(@"Error setting audio input device");
    }
}

- (void)initializeDeviceOutput {
    self.fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    CMTime maxDuration = CMTimeMakeWithSeconds(120, 2);
    self.fileOutput.maxRecordedDuration = maxDuration;
    self.fileOutput.minFreeDiskSpaceLimit = (360*480);
    
    if (self.fileOutput && [self.captureSession canAddOutput:self.fileOutput]) {
        [self.captureSession addOutput:self.fileOutput];
    } else {
        NSLog(@"Error setting file output");
    }
}

- (void)startRecordingForTwoSeconds {
    [self startRecording];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self stopRecording];
    });
}

- (void)startRecording {
    if (!self.isRecording) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
        NSString* dateTimePrefix = [formatter stringFromDate:[NSDate date]];
        
        int fileNamePostfix = 0;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = nil;
        do
            filePath =[NSString stringWithFormat:@"/%@/%@-%i.mp4", documentsDirectory, dateTimePrefix, fileNamePostfix++];
        while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
        
        NSURL *fileURL = [NSURL URLWithString:[@"file://" stringByAppendingString:filePath]];
        [self.fileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
        
    }
}

- (void)stopRecording {
    if (self.isRecording) {
        [self.fileOutput stopRecording];
    }
}

- (void)convertVideoToSquare:(NSURL *)filePath
                   withError:(NSError *)recordingError {
    // output file
    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString* outputPath = [docFolder stringByAppendingPathComponent:@"squareVideo.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    
    // input file
    AVAsset* asset = [AVAsset assetWithURL:filePath];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // input clip
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    // make it square
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    videoComposition.frameDuration = CMTimeMake(1, 60);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(120, 2));
    
    // rotate to portrait
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, 0);
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject:instruction];
    
    // export
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL=[NSURL fileURLWithPath:outputPath];
    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        NSLog(@"Exporting Square Video Done!");
        
        if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
            [self.delegate didFinishRecordingToOutputFileAtURL:[NSURL fileURLWithPath:outputPath] error:recordingError];
        }
    }];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)                 captureOutput:(AVCaptureFileOutput *)captureOutput
    didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
                       fromConnections:(NSArray *)connections {
    self.isRecording = YES;
}

- (void)                 captureOutput:(AVCaptureFileOutput *)captureOutput
   didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                       fromConnections:(NSArray *)connections
                                 error:(NSError *)error {
    self.isRecording = NO;
    if (error) {
        NSLog(@"Error capturing Output: %@", [error localizedDescription]);
    }
    [self convertVideoToSquare:outputFileURL withError:error];
}

@end
