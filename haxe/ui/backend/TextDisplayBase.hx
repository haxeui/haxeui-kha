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
    
    private var _width:Float = 0;
    public var width(get, set):Float;
    private function get_width():Float {
        return _width;
    }
    private function set_width(value:Float):Float {
        if (value == _width) {
            return value;
        }
        
        _width = value;
        splitText();
        
        return value;
    }
    
    private var _height:Float = 0;
    public var height(get, set):Float;
    private function get_height():Float {
        return _height;
    }
    private function set_height(value:Float):Float {
        if (value == _height) {
            return value;
        }
        
        _height = value;
        splitText();
        
        return value;
    }

    private var _fontSize:Float = 14;
    public var fontSize(get, set):Float;
    private function get_fontSize():Float {
        return _fontSize;
    }
    private function set_fontSize(value:Float):Float {
        if (value == _fontSize) {
            return value;
        }
        
        splitText();
        
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

        splitText();
        
        return value;
    }
    private var _text:String;
    public var text(get, set):String;
    private function get_text():String {
        return _text;
    }

    private function set_text(value:String):String {
        if (_text == value) {
            return value;
        }
        _text = value;
        splitText();
        return value;
    }

    private var _textWidth:Float = 0;
    public var textWidth(get, null):Float;
    private function get_textWidth():Float {
        return _textWidth;
    }

    private var _textHeight:Float = 0;
    public var textHeight(get, null):Float;
    private function get_textHeight():Float {
        return _textHeight;
    }

    public var color(get, set):Int;
    private function get_color():Int {
        return 0;
    }
    private function set_color(value:Int):Int {
        return value;
    }
    
    private var _lines:Array<String>;
    function splitText() {
        if (_text == null || _text.length == 0 || _font == null) {
            _textWidth = 0;
            _textHeight = 0;
            return;
        }
        
        if (_width <= 0) {
            _lines = new Array<String>();
            _lines.push(_text);
            _textWidth = _font.width(Std.int(_fontSize), _text);
            _textHeight = _font.height(Std.int(_fontSize)) + 1;
            return;
        }
        
        
        var maxWidth:Float = _width;
        _lines = new Array<String>();
        var lines = _text.split("\n");
        for (line in lines) {
            var tw = _font.width(Std.int(_fontSize), line);
            if (tw > maxWidth) {
                var words = Lambda.list(line.split(" "));
                while (!words.isEmpty()) {
                    line = words.pop();
                    tw = _font.width(Std.int(_fontSize), line);
                    _textWidth = Math.max(_textWidth, tw);
                    var nextWord = words.pop();
                    while (nextWord != null && (tw = _font.width(Std.int(_fontSize), line + " " + nextWord)) <= maxWidth) {
                        _textWidth = Math.max(_textWidth, tw);
                        line += " " + nextWord;
                        nextWord = words.pop();
                    }
                    _lines.push(line);
                    if (nextWord != null) {
                        words.push(nextWord);
                    }
                }
            } else {
                _textWidth = Math.max(_textWidth, tw);
                _lines.push(line);
            }
        }
        
        _textHeight = _font.height(Std.int(_fontSize)) * _lines.length;
    }
    
    public function renderTo(g:Graphics, x:Float, y:Float) {
        if (_lines != null) {
            g.font = _font;
            g.fontSize = Std.int(fontSize);
            
            var tx:Float = x + left;
            var ty:Float = y + top + 1;
            
            for (line in _lines) {
                g.drawString(line, tx, ty);
                ty += _font.height(Std.int(_fontSize));
            }
        }        
    }
}
