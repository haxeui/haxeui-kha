package haxe.ui.backend;

import haxe.ui.assets.FontInfo;
import haxe.ui.core.Component;
import haxe.ui.core.TextDisplay.TextDisplayData;
import haxe.ui.styles.Style;
import kha.Font;
import kha.graphics2.Graphics;

class TextDisplayBase {
    public var _font:Font;

    private var _displayData:TextDisplayData = new TextDisplayData();
     
    public var parentComponent:Component;
    
    public function new() {
    }

    private var _text:String;
    private var _left:Float = 0;
    private var _top:Float = 0;
    private var _width:Float = 0;
    private var _height:Float = 0;
    private var _textWidth:Float = 0;
    private var _textHeight:Float = 0;
    private var _textStyle:Style;

    private var _textAlign:String;
    private var _fontSize:Float = 14;
    private var _fontName:String;
    private var _color:Int;
    
    private var _fontInfo:FontInfo;
    
    //***********************************************************************************************************
    // Validation functions
    //***********************************************************************************************************

    private function validateData() {
        
    }
    
    private function validateStyle():Bool {
        var measureTextRequired:Bool = false;
        
        if (_textStyle != null) {
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
            }
            
            if (_fontSize != _textStyle.fontSize) {
                _fontSize = _textStyle.fontSize;
                measureTextRequired = true;
            }
            
            if (_fontName != _textStyle.fontName && _fontInfo != null) {
                _font = _fontInfo.data;
                measureTextRequired = true;
            }
            
            if (_color != _textStyle.color) {
                _color = _textStyle.color;
            }
        }
        
        return measureTextRequired;
    }
    
    private function validatePosition() {
        
    }
    
    private function validateDisplay() {
        
    }
    
    private var _lines:Array<String>;
    function measureText() {
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
                if (line != '') {
                    _lines.push(line);
                }
            }
        }

        _textHeight = _font.height(Std.int(_fontSize)) * _lines.length;
    }

    public function renderTo(g:Graphics, x:Float, y:Float) {
        if (_lines != null) {
            g.font = _font;
            g.fontSize = Std.int(_fontSize);

            var tx:Float = x;
            var ty:Float = y + _top + 1;

            switch(_textAlign) {
                case "center":
                    tx += (_width - _textWidth) / 2;

                case "right":
                    tx += _width - _textWidth;

                default:
                    tx += _left;
            }

            for (line in _lines) {
                g.drawString(line, tx, ty);
                ty += _font.height(Std.int(_fontSize));
            }
        }
    }
}
