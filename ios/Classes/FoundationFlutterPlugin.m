#import "FoundationFlutterPlugin.h"
#if __has_include(<foundation_flutter/foundation_flutter-Swift.h>)
#import <foundation_flutter/foundation_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "foundation_flutter-Swift.h"
#endif

@implementation FoundationFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFoundationFlutterPlugin registerWithRegistrar:registrar];
}
@end
