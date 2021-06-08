/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's photo capture delegate object.
*/

@import AVFoundation;
@import CoreLocation;

@interface AVCamPhotoCaptureDelegate : NSObject<AVCapturePhotoCaptureDelegate>

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)(void))willCapturePhotoAnimation livePhotoCaptureHandler:(void (^)( BOOL capturing ))livePhotoCaptureHandler completionHandler:(void (^)( AVCamPhotoCaptureDelegate *photoCaptureDelegate ))completionHandler photoProcessingHandler:(void (^)(BOOL))animate;

@property (nonatomic, readonly) AVCapturePhotoSettings *requestedPhotoSettings;

// Save the location of captured photos
@property (nonatomic) CLLocation *location;

@end
