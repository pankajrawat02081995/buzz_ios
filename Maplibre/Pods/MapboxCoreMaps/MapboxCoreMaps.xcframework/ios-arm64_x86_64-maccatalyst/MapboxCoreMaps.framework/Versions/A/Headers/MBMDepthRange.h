// This file is generated and will be overwritten automatically.

#import <Foundation/Foundation.h>

/** Represents depth range (min & max) used to render 3D content. */
NS_SWIFT_NAME(DepthRange)
__attribute__((visibility ("default")))
@interface MBMDepthRange : NSObject

// This class provides custom init which should be called
- (nonnull instancetype)init NS_UNAVAILABLE;

// This class provides custom init which should be called
+ (nonnull instancetype)new NS_UNAVAILABLE;

- (nonnull instancetype)initWithMin:(float)min
                                max:(float)max;

/** Minimum depth value. Ranges between 0 and 1. */
@property (nonatomic, readonly) float min;

/** Maximum depth value. Ranges between 0 and 1. */
@property (nonatomic, readonly) float max;


@end
