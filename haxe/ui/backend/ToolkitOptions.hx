package haxe.ui.backend;

typedef ToolkitOptions = {
    ?noBatch:Null<Bool>,
    ?showFPS:Null<Bool>,

    // see https://github.com/Kode/Kha/wiki/Managing-Your-Assets#assets-names
    ?flattenAssetPaths:Bool,

    ?mouseInput: MouseInputOptions,
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
