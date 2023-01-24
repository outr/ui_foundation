#import "FoundationFlutterPlugin.h"
#if __has_include(<ui_foundation/ui_foundation-Swift.h>)
#import <ui_foundation/ui_foundation-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ui_foundation-Swift.h"
#endif

@implementation FoundationFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFoundationFlutterPlugin registerWithRegistrar:registrar];
}
@end
