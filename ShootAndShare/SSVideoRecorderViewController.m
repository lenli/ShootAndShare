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
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface SSVideoRecorderViewController () <SSCaptureManagerDelegate>
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) SSCaptureManager *captureManager;

@property (weak, nonatomic) IBOutlet UILabel *recordingResponseLabel;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIView *cameraPreviewView;
- (IBAction)captureButtonTapped:(UIButton *)sender;

@end

@implementation SSVideoRecorderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.captureManager = [[SSCaptureManager alloc] initWithView:self.cameraPreviewView];
    self.captureManager.delegate = self;
    [self.recordingResponseLabel setHidden:YES];
    
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
    self.captureButton.enabled = NO;
    [self.recordingResponseLabel setHidden:NO];
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
                 [self.recordingResponseLabel setHidden:YES];
                 self.captureButton.enabled = YES;
                 
                 NSString *title;
                 NSString *message;
                 
                 if (error) {
                     title = @"Failed to Save Video";
                     message = [error localizedDescription];
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                     [alert show];
                 } else {
                     [self postToFacebookWithVideo:recordedFile];
                 }
             });
         }];
        
        
    });
}

- (void)postToFacebookWithVideo:(NSURL *)videoPath {
    
    __block ACAccount * facebookAccount;
    ACAccountStore* accountStore = [[ACAccountStore alloc] init];
    
    NSDictionary *readEmailPermisson = @{
                                            ACFacebookAppIdKey: @"1425921937668923", // Using old appID
                                            ACFacebookPermissionsKey: @[@"email", ],
                                            @"ACFacebookAudienceKey": ACFacebookAudienceFriends
                                            };
    NSDictionary *publishWritePermisson = @{
                                         ACFacebookAppIdKey: @"1425921937668923", // Using old appID
                                         ACFacebookPermissionsKey: @[@"publish_actions", ],
                                         @"ACFacebookAudienceKey": ACFacebookAudienceFriends
                                         };
    ACAccountType *facebookAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    [accountStore requestAccessToAccountsWithType:facebookAccountType options:readEmailPermisson completion:^(BOOL granted, NSError *error) {
        if (granted) {
            [accountStore requestAccessToAccountsWithType:facebookAccountType options:publishWritePermisson completion:^(BOOL granted, NSError *error) {
                if (granted) {
                    NSArray *accounts = [accountStore
                                         accountsWithAccountType:facebookAccountType];
                    facebookAccount = [accounts lastObject];
                    
                    NSLog(@"access to facebook account ok %@", facebookAccount.username);
                    
                    NSURL *url = [NSURL URLWithString:@"https://graph.facebook.com/me/videos"];
                    
                    NSData *videoData = [NSData dataWithContentsOfURL:videoPath];
                    
                    NSString *status = @"Testing123";
                    NSDictionary *params = @{@"title":status, @"description":status};
                    
                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                            requestMethod:SLRequestMethodPOST
                                                                      URL:url
                                                               parameters:params];
                    [request addMultipartData:videoData
                                     withName:@"source"
                                         type:@"video/quicktime"
                                     filename:[videoPath absoluteString]];
                    
                    request.account = facebookAccount;
                    [request performRequestWithHandler:^(NSData *data,
                                                         NSHTTPURLResponse *response,NSError * error){
                        NSLog(@"response = %@", response);
                        NSLog(@"error = %@", [error localizedDescription]);
                        
                        NSString *title;
                        NSString *message;
                        
                        if (error) {
                            title = @"Failed to Post Video";
                            message = [error localizedDescription];
                        } else {
                            title = @"Video Posted to Facebook";
                            message = nil;
                        }
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                        message:message
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                        
                    }];
                } else {
                    NSLog(@"access to facebook is not granted: %@", [error localizedDescription]);
                    // extra handling here if necesary
                    
                }
            }];
        }
    }];
}


@end
