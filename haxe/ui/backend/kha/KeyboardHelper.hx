package haxe.ui.backend.kha;

import haxe.ui.backend.ToolkitOptions;

class KeyboardHelper {
    public static var listen: KeyListenerCallback;
    public static var unlisten: KeyListenerCallback;

    public static function isInitialized() {
        return listen != null;
    }

    public static function init( ?opts: KeyboardInputOptions ) {
        listen = opts != null && opts.listen != null ? opts.listen : kha.input.Keyboard.get().notify;
        unlisten = opts != null && opts.unlisten != null ? opts.unlisten : kha.input.Keyboard.get().remove;
    }
}
