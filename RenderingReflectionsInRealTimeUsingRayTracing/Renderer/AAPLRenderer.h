/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for renderer class which performs Metal setup and per frame rendering
*/

#import <MetalKit/MetalKit.h>

typedef NS_ENUM( uint8_t, RenderMode )
{
    RMNoRaytracing = 0,
    RMMetalRaytracing = 1,
    RMReflectionsOnly = 2
};

// Platform independent renderer class.   Implements the MTKViewDelegate protocol which
//   allows it to accept per-frame update and drawable resize callbacks.
@interface AAPLRenderer : NSObject <MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
- (void)setRenderMode:(RenderMode)renderMode;
- (void)setCameraPanSpeedFactor:(float)speedFactor;

@end

