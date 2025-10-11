// This file is generated and will be overwritten automatically.

#import <Foundation/Foundation.h>

@protocol MBXDeviceLocationProvider;

NS_SWIFT_NAME(TelemetryLocationProvider)
__attribute__((visibility ("default")))
@interface MBXTelemetryLocationProvider : NSObject

// This class provides custom init which should be called
- (nonnull instancetype)init NS_UNAVAILABLE;

// This class provides custom init which should be called
+ (nonnull instancetype)new NS_UNAVAILABLE;

+ (void)setDeviceLocationProviderForLocationProvider:(nonnull id<MBXDeviceLocationProvider>)locationProvider;
+ (nonnull id<MBXDeviceLocationProvider>)getDeviceLocationProvider __attribute((ns_returns_retained));

@end
