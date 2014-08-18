//
//  SSVideoRecorderViewController.m
//  ShootAndShare
//
//  Created by Leonard Li on 8/17/14.
//  Copyright (c) 2014 Leonard Li. All rights reserved.
//

#import "SSVideoRecorderViewController.h"
#import "SSCaptureManager.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface SSVideoRecorderViewController () <SSCaptureManagerDelegate>
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) SSCaptureManager *captureManager;
@property (weak, nonatomic) IBOutlet UIView *cameraPreviewView;
- (IBAction)captureButtonTapped:(UIButton *)sender;

@end

@implementation SSVideoRecorderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.captureManager = [[SSCaptureManager alloc] initWithView:self.cameraPreviewView];
    self.captureManager.delegate = self;
    
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
        [self saveRecordedFile:outputFileURL];
    } else {
        NSLog(@"Error capturing video: %@", [error localizedDescription]);
    }
}

- (IBAction)captureButtonTapped:(UIButton *)sender {
    [self.captureManager startRecordingForTwoSeconds];
}


- (void)saveRecordedFile:(NSURL *)recordedFile {
    NSLog(@"Saving to Album");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary writeVideoAtPathToSavedPhotosAlbum:recordedFile
                                         completionBlock:
         ^(NSURL *assetURL, NSError *error) {
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 NSString *title;
                 NSString *message;
                 
                 if (error != nil) {
                     
                     title = @"Failed to save video";
                     message = [error localizedDescription];
                 }
                 else {
                     title = @"Saved!";
                     message = nil;
                 }
                 
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
                 [alert show];
             });
         }];
    });
}

@end
