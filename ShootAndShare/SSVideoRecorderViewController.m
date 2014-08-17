//
//  SSVideoRecorderViewController.m
//  ShootAndShare
//
//  Created by Leonard Li on 8/17/14.
//  Copyright (c) 2014 Leonard Li. All rights reserved.
//

#import "SSVideoRecorderViewController.h"

@interface SSVideoRecorderViewController ()
@property (weak, nonatomic) IBOutlet UIView *cameraPreviewView;

@end

@implementation SSVideoRecorderViewController

- (void)viewDidLoad
{
    NSLog(@"view did load");
    [super viewDidLoad];
    [self setupCamera];
}

- (void)setupCamera {
    NSLog(@"Setup Camera");
    // Session
    AVCaptureSession *session = [AVCaptureSession new];
    [session setSessionPreset:AVCaptureSessionPresetMedium];
    
    // Capture device
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    
    // Capture Device Input
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
	if ( [session canAddInput:deviceInput] )
        [session addInput:deviceInput];
    
    // Preview
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    previewLayer.frame = self.cameraPreviewView.bounds;
    [previewLayer setVideoGravity:AVLayerVideoGravityResize];
    
    [self.cameraPreviewView.layer addSublayer:previewLayer];
    
    [session startRunning];
}

@end
