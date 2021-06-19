package haxe.ui.backend;

import haxe.ui.backend.kha.TextField;
import kha.Color;
import kha.Font;
import kha.graphics2.Graphics;

class TextInputImpl extends TextBase {
    private var _tf:TextField;
    public var _font:Font;

    private var _textAlign:String;
    private var _fontSize:Float = 14;
    private var _fontName:String;
    private var _color:Int = -1;
    private var _backgroundColor:Int = -1;
    
    public function new() {
        super();
        _tf = new TextField();
        _tf.notify(onTextChanged, onCaretMoved);
    }

    public override function focus() {
        _tf.focus();
    }
    
    public override function blur() {
        _tf.blur();
    }
    
    private function onTextChanged(text) {
        _text = text;
        if (_inputData.onChangedCallback != null) {
            _inputData.onChangedCallback();
        }
    }
    
    private function onCaretMoved(pos) {
        _inputData.hscrollPos = _tf.scrollLeft;
        _inputData.vscrollPos = _tf.scrollTop;
        if (_inputData.onScrollCallback != null) {
            _inputData.onScrollCallback();
        }
    }
    
    private override function validateData() {
        if (_text != null) {
            _tf.text = normalizeText(_text);
        }
        
        _tf.scrollLeft = _inputData.hscrollPos;
        _tf.scrollTop = Std.int(_inputData.vscrollPos);
    }
    
    private override  function validateStyle():Bool {
        var measureTextRequired:Bool = false;
        
        if (_textStyle != null) {
            _tf.multiline = _displayData.multiline;
            _tf.wordWrap = _displayData.wordWrap;
            _tf.password = _inputData.password;
            
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
            }
            
            if (_textStyle.fontSize != null && _fontSize != _textStyle.fontSize) {
                _fontSize = _textStyle.fontSize;
                _tf.fontSize = Std.int(_fontSize);
                measureTextRequired = true;
            }
            
            if (_fontName != _textStyle.fontName && _fontInfo != null) {
                _fontName = _textStyle.fontName;
                _font = _fontInfo.data;
                _tf.font = _font;
                measureTextRequired = true;
            }
            
            if (_textStyle.color != null && _color != _textStyle.color) {
                _color = _textStyle.color;
                _tf.textColor = Color.fromValue(_textStyle.color | 0xFF000000);
            }
            
            if (_textStyle.backgroundColor != null && _backgroundColor != _textStyle.backgroundColor) {
                _backgroundColor = _textStyle.backgroundColor;
                _tf.backgroundColor = Color.fromValue(_textStyle.backgroundColor | 0xFF000000);
            }
            
        }
        
        return measureTextRequired;
    }
    
    private override function validateDisplay() {
        if (_width > 0) {
            _tf.width = _width;
        }
        if (_height > 0) {
            _tf.height = _height;
        }
    }

    public function renderTo(g:Graphics, x:Float, y:Float) {
        _tf.left = x + _left;
        _tf.top = y + _top;
        _tf.render(g);
    }
    
    private override function measureText() {
        if (_font == null) {
            return;
        }
        
        if (_text == null || _text.length == 0 || _font == null) {
            _textWidth = 0;
            _textHeight = _font.height(Std.int(_fontSize));
            return;
        }

        if (_width <= 0) {
            _textWidth = _font.width(Std.int(_fontSize), _text);
            _textHeight = _font.height(Std.int(_fontSize));
            return;
        }

        _tf.width = _width;
        _textWidth = _tf.requiredWidth;
        _textHeight = _tf.requiredHeight;

        if (_textHeight <= 0) {
            _textHeight = _font.height(Std.int(_fontSize));
        }
        _textHeight += 2;
        
        _inputData.hscrollMax = _tf.requiredWidth - _tf.width;
        _inputData.hscrollPageSize = (_tf.width * _inputData.hscrollMax) / _tf.requiredWidth;
        
        _inputData.vscrollMax = _tf.numLines - _tf.maxVisibleLines;
        _inputData.vscrollPageSize = (_tf.maxVisibleLines * _inputData.vscrollMax) / _tf.numLines;
    }
    
    private function normalizeText(text:String):String {
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }
}
