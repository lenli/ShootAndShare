//
//  SSCaptureManager.h
//  ShootAndShare
//
//  Created by Leonard Li on 8/18/14.
//  Copyright (c) 2014 Leonard Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SSCaptureManagerDelegate <NSObject>
- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                                      error:(NSError *)error;
@end

@interface SSCaptureManager : NSObject
@property (weak, nonatomic) id<SSCaptureManagerDelegate> delegate;
@property (readonly, nonatomic) BOOL isRecording;

- (instancetype)initWithView:(UIView *)view;
- (void)startRecordingForTwoSeconds;
- (void)startRecording;
- (void)stopRecording;

@end
