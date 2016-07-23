package haxe.ui.backend;

import kha.Assets;
import kha.Color;
import kha.Font;
import kha.FontStyle;
import kha.graphics2.Graphics;
import kha.Image;

class TextDisplayBase {
    public var _font:Font;
    //public var _fontStyle:FontStyle;

    public function new() {
        _font = Assets.fonts.arial;
    }

    public var left(default, default):Float;
    public var top(default, default):Float;
    public var width(default, default):Float;
    public var height(default, default):Float;

    private var _fontSize:Float = 14;
    public var fontSize(get, set):Float;
    private function get_fontSize():Float {
        return _fontSize;
    }
    private function set_fontSize(value:Float):Float {
        _fontSize = value;
        return value;
    }

    private var _fontName:String;
    public var fontName(get, set):String;
    private function get_fontName():String {
        return _fontName;
    }
    private function set_fontName(value:String):String {
        if (_fontName == value) {
            return value;
        }

        _fontName = value;
        var newFont:Font = Reflect.field(Assets.fonts, _fontName);
        if (newFont != null) {
            _font = newFont;
        }

        return value;
    }
    private var _text:String;
    public var text(get, set):String;
    private function get_text():String {
        return _text;
    }

    private function set_text(value:String):String {
        _text = value;
        return value;
    }

    public var textWidth(get, null):Float;
    private function get_textWidth():Float {
        if (_text == null || _text.length == 0 || _font == null) {
            return 0;
        }
        return _font.width(Std.int(_fontSize), _text);
    }

    public var textHeight(get, null):Float;
    private function get_textHeight():Float {
        if (_text == null || _text.length == 0 || _font == null) {
            return 0;
        }
        return _font.height(Std.int(_fontSize)) + 1;
    }

    public var color(get, set):Int;
    private function get_color():Int {
        return 0;
    }
    private function set_color(value:Int):Int {
        return value;
    }
}