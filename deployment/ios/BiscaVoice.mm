#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AuthenticationServices/AuthenticationServices.h>
#import BISCA_SWIFT_HEADER
#include "core/config/engine.h"
#include "core/object/class_db.h"

// Compiled against the exact source version of the exported Godot archive.
class BiscaVoice : public Object {
    GDCLASS(BiscaVoice, Object);
protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("invoke", "method", "args_json"), &BiscaVoice::invoke);
        ClassDB::bind_method(D_METHOD("drain"), &BiscaVoice::drain);
        ClassDB::bind_method(D_METHOD("tracking_permission", "request"), &BiscaVoice::tracking_permission);
        ClassDB::bind_method(D_METHOD("gdpr_allows_tracking"), &BiscaVoice::gdpr_allows_tracking);
        ClassDB::bind_method(D_METHOD("open_photo"), &BiscaVoice::open_photo);
        ClassDB::bind_method(D_METHOD("open_camera"), &BiscaVoice::open_camera);
        ClassDB::bind_method(D_METHOD("drain_photo"), &BiscaVoice::drain_photo);
        ClassDB::bind_method(D_METHOD("open_auth", "url"), &BiscaVoice::open_auth);
        ClassDB::bind_method(D_METHOD("drain_auth"), &BiscaVoice::drain_auth);
        ClassDB::bind_method(D_METHOD("cancel_auth"), &BiscaVoice::cancel_auth);
    }
public:
    // Conservative ATT gating for EEA users using the IAB TCF purpose consent string.
    // UMP status OBTAINED means the choice was recorded, not that tracking was accepted.
    // Purposes 1 (store/access information), 3 (create personalised advertising profiles)
    // and 4 (use profiles to select personalised advertising) must all be consented to.
    // This does not replace a complete CMP/vendor/legal-basis check for actual tracking.
    bool gdpr_allows_tracking() {
        NSString *purposes = [[NSUserDefaults standardUserDefaults]
            stringForKey:@"IABTCF_PurposeConsents"];
        if (![purposes isKindOfClass:[NSString class]] || purposes.length < 4) {
            return false;
        }
        return [purposes characterAtIndex:0] == '1' &&
               [purposes characterAtIndex:2] == '1' &&
               [purposes characterAtIndex:3] == '1';
    }

    String tracking_permission(bool request) {
        NSString *purpose = [NSBundle.mainBundle objectForInfoDictionaryKey:@"NSUserTrackingUsageDescription"];
        if (![purpose isKindOfClass:[NSString class]] || purpose.length == 0) {
            return "unavailable";
        }
        if (@available(iOS 14, *)) {
            switch ([ATTrackingManager trackingAuthorizationStatus]) {
                case ATTrackingManagerAuthorizationStatusAuthorized: return "authorized";
                case ATTrackingManagerAuthorizationStatusRestricted:
                case ATTrackingManagerAuthorizationStatusDenied: return "denied";
                case ATTrackingManagerAuthorizationStatusNotDetermined: break;
                default: return "denied";
            }
            if (request) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    static bool presenting = false;
                    if (presenting || UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
                        ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusNotDetermined) return;
                    presenting = true;
                    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                        dispatch_async(dispatch_get_main_queue(), ^{ presenting = false; });
                    }];
                });
            }
            return "pending";
        }
        return "denied";
    }

    void open_auth(const String &url) {
        @autoreleasepool { [BiscaAuthNative.shared open:[NSString stringWithUTF8String:url.utf8().get_data()]]; }
    }
    String drain_auth() {
        @autoreleasepool { return String::utf8([BiscaAuthNative.shared drain].UTF8String); }
    }
    void cancel_auth() { [BiscaAuthNative.shared cancel]; }
    void open_photo() { [BiscaPhotoNative.shared open]; }
    void open_camera() { [BiscaPhotoNative.shared openCamera]; }
    String drain_photo() {
        @autoreleasepool { return String::utf8([BiscaPhotoNative.shared drain].UTF8String); }
    }
    void invoke(const String &method, const String &args_json) {
        @autoreleasepool {
            [BiscaVoiceNative.shared invoke:[NSString stringWithUTF8String:method.utf8().get_data()]
                                  argsJSON:[NSString stringWithUTF8String:args_json.utf8().get_data()]];
        }
    }
    String drain() {
        @autoreleasepool { return String::utf8([BiscaVoiceNative.shared drain].UTF8String); }
    }
};

static BiscaVoice *singleton = nullptr;
void bisca_voice_initialize() {
    if (singleton) return;
    ClassDB::register_class<BiscaVoice>();
    singleton = memnew(BiscaVoice);
    Engine::get_singleton()->add_singleton(Engine::Singleton("BiscaVoice", singleton));
}
void bisca_voice_deinitialize() {
    if (!singleton) return;
    [BiscaVoiceNative.shared invoke:@"stop" argsJSON:@"[]"];
    Engine::get_singleton()->remove_singleton("BiscaVoice");
    memdelete(singleton);
    singleton = nullptr;
}
