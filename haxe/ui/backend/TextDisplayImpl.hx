package haxe.ui.backend;

import kha.Font;
import kha.graphics2.Graphics;

class TextDisplayImpl extends TextBase {
    private var _font:Font;
    private var _textAlign:String;
    private var _fontSize:Float = 14;
    private var _fontName:String;
    private var _color:Int;

    public function new() {
        super();
        _fontSize = 14 * Toolkit.scale;
    }
    
    //***********************************************************************************************************
    // Validation functions
    //***********************************************************************************************************
    private override function validateStyle():Bool {
        var measureTextRequired:Bool = false;
        
        if (_textStyle != null) {
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
            }
            
            if (_textStyle.fontSize != null && _fontSize != _textStyle.fontSize) {
                _fontSize = _textStyle.fontSize * Toolkit.scale;
                measureTextRequired = true;
            }

            if (_fontName != _textStyle.fontName && _fontInfo != null && _fontInfo.data != _font) {
                _font = _fontInfo.data;
                measureTextRequired = true;
            }
            
            if (_color != _textStyle.color) {
                _color = _textStyle.color;
            }
        }
        
        return measureTextRequired;
    }
    
    private override function validateDisplay() {
        if (_width == 0 && _textWidth > 0) {
            _width = _textWidth;
        }
        if (_height == 0 && _textHeight > 0) {
            _height = _textHeight;
        }
    }
    
    private var _lines:Array<String>;
    private override function measureText() {
        if (_text == null || _text.length == 0 || _font == null) {
            _textWidth = 0;
            _textHeight = 0;
            return;
        }

        if (_width <= 0) {
            _lines = new Array<String>();
            _lines.push(_text);
            _textWidth = _font.width(Std.int(_fontSize), _text);
            _textHeight = _font.height(Std.int(_fontSize));
            return;
        }


        var maxWidth:Float = _width * Toolkit.scale;
        _lines = new Array<String>();
        var lines = _text.split("\n");
        var biggestWidth:Float = 0;
        for (line in lines) {
            var tw = _font.width(Std.int(_fontSize), line);
            if (tw > maxWidth) {
                var words = Lambda.list(line.split(" "));
                while (!words.isEmpty()) {
                    line = words.pop();
                    tw = _font.width(Std.int(_fontSize), line);
                    biggestWidth = Math.max(biggestWidth, tw);
                    var nextWord = words.pop();
                    while (nextWord != null && (tw = _font.width(Std.int(_fontSize), line + " " + nextWord)) <= maxWidth) {
                        biggestWidth = Math.max(biggestWidth, tw);
                        line += " " + nextWord;
                        nextWord = words.pop();
                    }
                    _lines.push(line);
                    if (nextWord != null) {
                        words.push(nextWord);
                    }
                }
            } else {
                biggestWidth = Math.max(biggestWidth, tw);
                if (line != '') {
                    _lines.push(line);
                }
            }
        }

        _textWidth = biggestWidth / Toolkit.scale;
        _textHeight = (_font.height(Std.int(_fontSize)) * _lines.length) / Toolkit.scale;
        
        _textWidth = Math.round(_textWidth + 1);
        _textHeight = Math.round(_textHeight);
        
        if (_textWidth % 2 != 0) {
            _textWidth++;
        }
        if (_textHeight % 2 != 0) {
            _textHeight++;
        }
    }

    public function renderTo(g:Graphics, x:Float, y:Float) {
        if (_lines != null) {
            g.font = _font;
            g.fontSize = Std.int(_fontSize);

            var ty:Float = y + _top;
            for (line in _lines) {
                var tx:Float = x;
            
                switch(_textAlign) {
                    case "center":
                        tx += ((_width - _textWidth) * Toolkit.scale) / 2;

                    case "right":
                        tx += (_width - _textWidth) * Toolkit.scale;

                    default:
                        tx += _left;
                }

                g.drawString(line, tx, ty);
                ty += _font.height(Std.int(_fontSize));
            }
        }
    }
}
