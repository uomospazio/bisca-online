#import <Foundation/Foundation.h>
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
        ClassDB::bind_method(D_METHOD("open_photo"), &BiscaVoice::open_photo);
        ClassDB::bind_method(D_METHOD("open_camera"), &BiscaVoice::open_camera);
        ClassDB::bind_method(D_METHOD("drain_photo"), &BiscaVoice::drain_photo);
    }
public:
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
