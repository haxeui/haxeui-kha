package haxe.ui.backend;

typedef ToolkitOptions = {
    ?autoNotifyInput:Null<Bool>,
    ?noBatch:Null<Bool>,
    ?showFPS:Null<Bool>,

    // see https://github.com/Kode/Kha/wiki/Managing-Your-Assets#assets-names
    ?flattenAssetPaths:Bool,
}
