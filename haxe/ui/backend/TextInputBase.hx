package haxe.ui.backend;

class TextInputBase extends TextDisplayBase {
    public function new() {
        super();
    }

    public var hscrollPos:Float;
    public var vscrollPos:Float;
    public var multiline:Bool;
    public var password:Bool;
    public var wordWrap:Bool;
}