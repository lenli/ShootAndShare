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
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) UIView *previewView;

@end


@implementation SSCaptureManager 
- (instancetype)initWithView:(UIView *)previewView {
    
    self = [super init];
    if (self) {
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
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
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResize];
    
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

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)                 captureOutput:(AVCaptureFileOutput *)captureOutput
    didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
                       fromConnections:(NSArray *)connections {
    _isRecording = YES;
}

- (void)                 captureOutput:(AVCaptureFileOutput *)captureOutput
   didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                       fromConnections:(NSArray *)connections error:(NSError *)error {
    _isRecording = NO;
    
    if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
        [self.delegate didFinishRecordingToOutputFileAtURL:outputFileURL error:error];
    }
}

@end
