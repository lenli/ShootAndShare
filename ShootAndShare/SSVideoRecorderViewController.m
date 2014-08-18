//
//  SSVideoRecorderViewController.m
//  ShootAndShare
//
//  Created by Leonard Li on 8/17/14.
//  Copyright (c) 2014 Leonard Li. All rights reserved.
//

#import "SSVideoRecorderViewController.h"
#import "SSCaptureManager.h"

@interface SSVideoRecorderViewController () <SSCaptureManagerDelegate>
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) SSCaptureManager *captureManager;
@property (weak, nonatomic) IBOutlet UIView *cameraPreviewView;


@end

@implementation SSVideoRecorderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.captureManager = [[SSCaptureManager alloc] initWithView:self.cameraPreviewView];
    self.captureManager.delegate = self;
    
    [self.captureManager startRecording];
    [self.captureManager stopRecording];
}


- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                                      error:(NSError *)error {
    NSLog(@"didFinishRecordingToOutputFileAtURL");
    
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    
    if (recordedSuccessfully) {
        NSLog(@"recordedSuccessfully");
    } else {
        NSLog(@"Error capturing video.  Please try again.");
    }
}
@end
