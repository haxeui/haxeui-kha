package haxe.ui.backend.kha;

import haxe.ui.backend.ToolkitOptions;
import kha.input.Keyboard;

class KeyboardHelper {
    public static var listen: KeyListenerCallback;
    public static var unlisten: KeyListenerCallback;

    public static inline function isInitialized() {
        return listen != null;
    }

    public static function init( ?opts: KeyboardInputOptions ) {
        if (opts != null && opts.listen == null && Keyboard.get() == null) {
            return;
        }
        listen = opts != null && opts.listen != null ? opts.listen : Keyboard.get().notify;
        unlisten = opts != null && opts.unlisten != null ? opts.unlisten : Keyboard.get().remove;
    }
}
