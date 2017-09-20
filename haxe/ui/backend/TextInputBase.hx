package haxe.ui.backend;

class TextInputBase extends TextDisplayBase {
    public function new() {
        super();
    }

    private var _password:Bool = false;
    private var _hscrollPos:Float = 0;
    private var _vscrollPos:Float = 0;
}