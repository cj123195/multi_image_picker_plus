//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<multi_image_picker_plus/MultiImagePickerPlusPlugin.h>)
#import <multi_image_picker_plus/MultiImagePickerPlusPlugin.h>
#else
@import multi_image_picker_plus;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [MultiImagePickerPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"MultiImagePickerPlusPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
}

@end
