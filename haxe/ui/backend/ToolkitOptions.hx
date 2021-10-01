package haxe.ui.backend;

typedef ToolkitOptions = {
    ?noBatch:Null<Bool>,
    ?showFPS:Null<Bool>,

    // see https://github.com/Kode/Kha/wiki/Managing-Your-Assets#assets-names
    ?flattenAssetPaths:Bool,

    ?mouseInput: MouseInputOptions,
    ?keyboardInput: KeyboardInputOptions,
}

typedef MouseListenerCallback = (
    (Int, Int, Int) -> Void,
    (Int, Int, Int) -> Void,
    (Int, Int, Int, Int) -> Void,
    (Int) -> Void,
    () -> Void
) -> Void;

typedef MouseInputOptions = {
    final ?listen: MouseListenerCallback;
    final ?unlisten: MouseListenerCallback;
}

typedef KeyListenerCallback = (
    kha.input.KeyCode -> Void,
    kha.input.KeyCode -> Void,
    String -> Void
) -> Void;

typedef KeyboardInputOptions = {
    final ?listen: KeyListenerCallback;
    final ?unlisten: KeyListenerCallback;
}
