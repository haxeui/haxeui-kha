package haxe.ui.backend.kha;

import kha.Color;
import kha.Font;
import kha.Scheduler;
import kha.StringExtensions;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.System;

typedef CharPosition = {
    row:Int,
    column:Int
}

typedef CaretInfo = {
    > CharPosition,
    visible:Bool,
    force:Bool,
    timerId:Int
}

typedef SelectionInfo = {
    start:CharPosition,
    end:CharPosition
}

class TextField {
    public var id:String = null; // for debugging

    public static inline var SPACE:Int = 32;
    public static inline var CR:Int = 10;
    public static inline var LF:Int = 13;

    private var _selectionInfo:SelectionInfo = {start: {row: -1, column: -1}, end: {row: -1, column: -1}};
    private var _caretInfo:CaretInfo = {row: -1, column: -1, visible: false, force: false, timerId: -1};

    private static var _hasCutCopyPasteListner:Bool = false;
    public function new() {
        Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, null, null);
        Keyboard.get().notify(onKeyDown, onKeyUp, onKeyPress);

        if (!_hasCutCopyPasteListner) {
            _hasCutCopyPasteListner = true;
            // Only one cutCopyPaste is set at once, as opposed to the listener list for keyboard/mouse.
            // these functions are overriden by any component stealing focus
            System.notifyOnCutCopyPaste(onCut, onCopy, onPaste);
        }
        recalc();
    }

    //*****************************************************************************************************************//
    // PUBLIC API                                                                                                      //
    //*****************************************************************************************************************//
    public var left:Float = 0;
    public var top:Float = 0;

    public var editable:Bool = true;

    public var textColor:Color = Color.Black;
    public var backgroundColor:Color = Color.White;

    public var selectedTextColor:Color = Color.White;
    public var selectedBackgroundColor:Color = 0xFF3390FF;

    public var scrollTop:Int = 0;
    public var scrollLeft:Float = 0;

    private var _textChanged:Array<String->Void> = [];
    private var _caretMoved:Array<CharPosition->Void> = [];
    public function notify(textChanged:String->Void, caretMoved:CharPosition->Void) {
        if (textChanged != null) {
            _textChanged.push(textChanged);
        }
        if (caretMoved != null) {
            _caretMoved.push(caretMoved);
        }
    }

    public function remove(textChanged:String->Void, caretMoved:CharPosition->Void) {
        if (textChanged != null) {
            _textChanged.remove(textChanged);
        }
        if (caretMoved != null) {
            _caretMoved.remove(caretMoved);
        }
    }
    
    private function notifyTextChanged() {
        for (l in _textChanged) {
            l(_text);
        }
    }

    private function notifyCaretMoved() {
        for (l in _caretMoved) {
            l(_caretInfo);
        }
    }

    private var _lines:Array<Array<Int>> = null;
    private var _text:String = "";
    public var text(get, set):String;
    private function get_text():String {
        return _text;
    }
    private function set_text(value:String):String {
        if (value == _text) {
            return value;
        }

        _text = value;
        if (value == null || value.length == 0) {
            if (isActive == true) {
                _caretInfo.row = 0;
                _caretInfo.column = 0;
            } else {
                _caretInfo.row = -1;
                _caretInfo.column = -1;
            }
            resetSelection();
        }

        recalc();
        notifyTextChanged();
        return value;
    }

    private var _width:Float = 200;
    public var width(get, set):Float;
    private function get_width():Float {
        return _width;
    }
    private function set_width(value:Float):Float {
        if (value == _width) {
            return value;
        }

        _width = value;
        recalc();
        return value;
    }

    private var _height:Float = 100;
    public var height(get, set):Float;
    private function get_height():Float {
        return _height;
    }
    private function set_height(value:Float):Float {
        if (value == _height) {
            return value;
        }

        _height = value;
        recalc();
        return value;
    }

    private var _password:Bool = false;
    public var password(get, set):Bool;
    private function get_password():Bool {
        return _password;
    }
    private function set_password(value:Bool):Bool {
        if (value == _password) {
            return value;
        }

        _password = value;
        recalc();
        return value;
    }

    private var _font:Font;
    public var font(get, set):Font;
    private function get_font():Font {
        return _font;
    }
    private function set_font(value:Font):Font {
        if (value == _font) {
            return value;
        }

        _font = value;
        recalc();
        return value;
    }

    private var _fontSize:Int = 14;
    public var fontSize(get, set):Int;
    private function get_fontSize():Int {
        return _fontSize;
    }
    private function set_fontSize(value:Int):Int {
        if (value == _fontSize) {
            return value;
        }

        _fontSize = value;
        recalc();
        return value;
    }

    private var _multiline:Bool = true;
    public var multiline(get, set):Bool;
    private function get_multiline():Bool {
        return _multiline;
    }
    private function set_multiline(value:Bool):Bool {
        if (value == _multiline) {
            return value;
        }

        _multiline = value;
        recalc();
        return value;
    }

    private var _wordWrap:Bool = true;
    public var wordWrap(get, set):Bool;
    private function get_wordWrap():Bool {
        return _wordWrap;
    }
    private function set_wordWrap(value:Bool):Bool {
        if (value == _wordWrap) {
            return value;
        }

        _wordWrap = value;
        recalc();
        return value;
    }

    private var _autoHeight:Bool;
    public var autoHeight(get, set):Bool;
    private function get_autoHeight():Bool {
        return _autoHeight;
    }
    private function set_autoHeight(value:Bool):Bool {
        if (value == _autoHeight) {
            return value;
        }

        _autoHeight = value;
        recalc();
        return value;
    }

    public var maxVisibleLines(get, null):Int;
    private inline function get_maxVisibleLines():Int {
        return Math.round(height / font.height(fontSize));
    }

    public var numLines(get, null):Int;
    private inline function get_numLines():Int {
        return _lines.length;
    }

    private function resetSelection() {
        _selectionInfo.start.row = -1;
        _selectionInfo.start.column = -1;
        _selectionInfo.end.row = -1;
        _selectionInfo.end.column = -1;
    }

    public var hasSelection(get, null):Bool;
    private function get_hasSelection():Bool {
        return (_selectionInfo.start.row > -1 && _selectionInfo.start.column > -1
                && _selectionInfo.end.row > -1 && _selectionInfo.end.column > -1);
    }

    public var selectionStart(get, null):Int;
    private function get_selectionStart():Int {
        return posToIndex(_selectionInfo.start);
    }

    public var selectionEnd(get, null):Int;
    private function get_selectionEnd():Int {
        return posToIndex(_selectionInfo.end);
    }

    public var caretPosition(get, set):Int;
    private function get_caretPosition():Int {
        return posToIndex(_caretInfo);
    }
    private function set_caretPosition(value:Int):Int {
        var pos = indexToPos(value);
        _caretInfo.row = pos.row;
        _caretInfo.column = pos.column;
        scrollToCaret();
        return value;
    }

    //*****************************************************************************************************************//
    // HELPERS                                                                                                         //
    //*****************************************************************************************************************//
    private static var _currentFocus:TextField;
    public var isActive(get, null):Bool;
    private function get_isActive():Bool {
        return (_currentFocus == this);
    }

    private function recalc() {
        splitLines();
        if (autoHeight == true && _font != null) {
            height = requiredHeight;
        }
    }

    private function inBounds(x:Float, y:Float):Bool {
        if (x >= left && y >= top && x <= left + width && y <= top + height) {
            return true;
        }
        return false;
    }

    public var requiredWidth(get, null):Float;
    private function get_requiredWidth():Float {
        var rw:Float = 0;
        for (line in _lines) {
            var lineWidth = font.widthOfCharacters(fontSize, line, 0, line.length);
            if (lineWidth > rw) {
                rw = lineWidth;
            }
        }
        return rw;
    }

    public var requiredHeight(get, null):Float;
    private function get_requiredHeight():Float {
        return _lines.length * font.height(fontSize);
    }

    private function moveCaretRight() {
        if (_caretInfo.row >= _lines.length) {
            return;
        }
        if (_caretInfo.column < _lines[_caretInfo.row].length) {
            _caretInfo.column++;
        } else if (_caretInfo.row < _lines.length - 1) {
            _caretInfo.column = 0;
            _caretInfo.row++;
        }
    }

    private function moveCaretLeft() {
        if (_caretInfo.column > 0) {
            _caretInfo.column--;
        } else if (_caretInfo.row > 0) {
            _caretInfo.row--;
            _caretInfo.column = _lines[_caretInfo.row].length;
        }
    }

    private function handleNegativeSelection() {
        if (caretPosition <= selectionStart) {
            _selectionInfo.start.row = _caretInfo.row;
            _selectionInfo.start.column = _caretInfo.column;
        } else {
            _selectionInfo.end.row = _caretInfo.row;
            _selectionInfo.end.column = _caretInfo.column;
        }
    }

    private function handlePositiveSelection() {
        if (caretPosition >= selectionEnd) {
            _selectionInfo.end.row = _caretInfo.row;
            _selectionInfo.end.column = _caretInfo.column;
        } else {
            _selectionInfo.start.row = _caretInfo.row;
            _selectionInfo.start.column = _caretInfo.column;
        }
    }

    private function performKeyOperation(code:KeyCode) {
        var orginalCaretPos:CharPosition = { row: _caretInfo.row, column: _caretInfo.column };

        switch (code) {
            case Return:
                if (multiline) {
                    insertText("\n");
                }

            case Left:
                moveCaretLeft();

                if (_ctrl) {
                    while((_caretInfo.column > 0 || _caretInfo.row > 0) && _text.charCodeAt(posToIndex(_caretInfo)-1) == SPACE) {
                        moveCaretLeft();
                    }
                    while((_caretInfo.column > 0 || _caretInfo.row > 0) && _text.charCodeAt(posToIndex(_caretInfo)-1) != SPACE) {
                        moveCaretLeft();
                    }
                }

                scrollToCaret();

                if (_shift == true) {
                    handleNegativeSelection();
                } else {
                    resetSelection();
                }

            case Right:
                moveCaretRight();

                if (_ctrl) {
                    while((_caretInfo.column < _lines[_caretInfo.row].length && _caretInfo.row < _lines.length) && _text.charCodeAt(posToIndex(_caretInfo)) != SPACE) {
                        moveCaretRight();
                    }
                    while((_caretInfo.column < _lines[_caretInfo.row].length && _caretInfo.row < _lines.length) && _text.charCodeAt(posToIndex(_caretInfo)) == SPACE) {
                        moveCaretRight();
                    }
                }

                scrollToCaret();

                if (_shift == true) {
                    handlePositiveSelection();
                } else {
                    resetSelection();
                }

            case Up:
                if (_caretInfo.row > 0) {
                    _caretInfo.column = findClosestColumn(_caretInfo, -1);
                    _caretInfo.row--;
                }
                scrollToCaret();

                if (_shift == true) {
                    handleNegativeSelection();
                } else {
                    resetSelection();
                }

            case Down:
                if (_caretInfo.row < _lines.length - 1) {
                    _caretInfo.column = findClosestColumn(_caretInfo, 1);
                    _caretInfo.row++;
                }
                scrollToCaret();

                if (_shift == true) {
                    handlePositiveSelection();
                } else {
                    resetSelection();
                }

            case Backspace:
                if (_text.length > 0) {
                    if (hasSelection) {
                        insertText("");
                    } else {
                        if (_ctrl) {
                            var caretIndex = posToIndex(_caretInfo);
                            var caretDisplacement = 0;
                            while (caretIndex+caretDisplacement > 0 && _text.charCodeAt(caretIndex+caretDisplacement-1) == SPACE)
                                caretDisplacement--;
                            while (caretIndex+caretDisplacement > 0 && _text.charCodeAt(caretIndex+caretDisplacement-1) != SPACE)
                                caretDisplacement--;

                            deleteCharsFromCaret(caretDisplacement);
                            scrollToCaret();
                        } else {
                            deleteCharsFromCaret(-1);
                        }
                    }
                }

            case Delete:
                if (_text.length > 0) {
                    if (hasSelection) {
                        insertText("");
                    } else {
                        if (_ctrl) {
                            // Delete until the start of the next word
                            var caretIndex = posToIndex(_caretInfo);
                            var caretDisplacement = 0;
                            while (_text.charCodeAt(caretIndex+caretDisplacement) != SPACE && caretIndex+caretDisplacement < _text.length)
                                caretDisplacement++;
                            while (_text.charCodeAt(caretIndex+caretDisplacement) == SPACE && caretIndex+caretDisplacement < _text.length)
                                caretDisplacement++;

                            deleteCharsFromCaret(caretDisplacement, false);
                            caretPosition = caretIndex; // Updates _caretInfo (text changes may alter row/column, for instance after wrapping)
                            scrollToCaret();

                        } else {
                            deleteCharsFromCaret(1, false);
                        }
                    }
                }

            case Home:
                scrollLeft = 0;
                _caretInfo.column = 0;
                scrollToCaret();

                if (_shift == true) {
                    handleNegativeSelection();
                } else {
                    resetSelection();
                }

            case End:
                var line = _lines[_caretInfo.row];
                scrollLeft = font.widthOfCharacters(fontSize, line, 0, line.length) - width + caretWidth;
                if (scrollLeft < 0) {
                    scrollLeft = 0;
                }
                _caretInfo.column = line.length;
                scrollToCaret();

                if (_shift == true) {
                    handlePositiveSelection();
                } else {
                    resetSelection();
                }
            case A:
                if (_ctrl) {
                    _selectionInfo.start.row = 0;
                    _selectionInfo.start.column = 0;
                    
                    var line = _lines[_lines.length-1];
                    
                    _caretInfo.row = _lines.length-1;
                    _caretInfo.column = line.length;
                    _selectionInfo.end.row = _lines.length-1;
                    _selectionInfo.end.column = line.length;
                    scrollToCaret();
                }

            case _:
        }

        if (_caretInfo.row != orginalCaretPos.row || _caretInfo.column != orginalCaretPos.column) {
           notifyCaretMoved();
        }
    }

    private function insertText(s:String) {
        var start:CharPosition = _caretInfo;
        var end:CharPosition = _caretInfo;
        if (_selectionInfo.start.row != -1 && _selectionInfo.start.column != -1) {
            start = _selectionInfo.start;
        }
        if (_selectionInfo.end.row != -1 && _selectionInfo.end.column != -1) {
            end = _selectionInfo.end;
        }


        var startIndex = posToIndex(start);
        var endIndex = posToIndex(end);

        var before = text.substring(0, startIndex);
        var after = text.substring(endIndex, text.length);

        text = before + s + after;
        var delta = s.length - (endIndex - startIndex);

        caretPosition = endIndex + delta;
        notifyCaretMoved();
        scrollToCaret();
        
        Scheduler.addBreakableTimeTask(function () {
            caretPosition = endIndex + delta;
            notifyCaretMoved();
            scrollToCaret();
        
            return false;
        }, .001);
        
        
        resetSelection();
    }

    private var caretLeft(get, null):Float;
    private function get_caretLeft():Float {
        var line = _lines[_caretInfo.row];
        var xpos:Float = left - scrollLeft;
        if (line == null) {
            return xpos;
        }
        return xpos + font.widthOfCharacters(fontSize, line, 0, _caretInfo.column);
    }

    private var caretTop(get, null):Float;
    private function get_caretTop():Float {
        var ypos:Float = top;
        return ypos + ((_caretInfo.row - scrollTop) * font.height(fontSize));
    }

    private var caretWidth(get, null):Float;
    private function get_caretWidth():Float {
        return 1;
    }

    private var caretHeight(get, null):Float;
    private function get_caretHeight():Float {
        return font.height(fontSize);
    }

    //*****************************************************************************************************************//
    // EVENTS                                                                                                          //
    //*****************************************************************************************************************//
    private static inline var REPEAT_TIMER_GROUP:Int = 1234;
    private var _repeatTimerId:Int = -1;
    private var _downKey:KeyCode = KeyCode.Unknown;
    private var _shift:Bool = false;
    private var _ctrl:Bool = false;
    
    private static function onCut() {
        if (_currentFocus == null) {
            return "";
        }

        if (_currentFocus.password) {
            return "";
        }

        if (_currentFocus.hasSelection) {
            var cutText = _currentFocus._text.substring(_currentFocus.posToIndex(_currentFocus._selectionInfo.start), _currentFocus.posToIndex(_currentFocus._selectionInfo.end));
            _currentFocus.insertText("");
            return cutText;
        }

        return "";
    }

    private static function onCopy() {
        if (_currentFocus == null) {
            return "";
        }

        if (_currentFocus.password) {
            return "";
        }

        if (_currentFocus.hasSelection) {
            return _currentFocus._text.substring(_currentFocus.posToIndex(_currentFocus._selectionInfo.start), _currentFocus.posToIndex(_currentFocus._selectionInfo.end));
        }

        return "";
    }
    
    private static function onPaste(text:String) {
        if (_currentFocus == null) {
            return;
        }

        _currentFocus.insertText(text);
    }
    
    private function onKeyDown(code:KeyCode) {
        if (isActive == false) {
            return;
        }

        if ((code == CR || code == LF) && multiline == false) {
            return;
        }

        switch (code) {
            case Shift:
                if (!hasSelection) {
                    _selectionInfo.start.row = _caretInfo.row;
                    _selectionInfo.start.column = _caretInfo.column;
                    _selectionInfo.end.row = _caretInfo.row;
                    _selectionInfo.end.column = _caretInfo.column;
                }
                _shift = true;
            case Control:
                _ctrl = true;
            case _:
        }

        _downKey = code;
        _caretInfo.force = true;
        _caretInfo.visible = true;

        performKeyOperation(code);

        Scheduler.removeTimeTasks(REPEAT_TIMER_GROUP);
        Scheduler.addTimeTaskToGroup(REPEAT_TIMER_GROUP, function() {
            if (_downKey != KeyCode.Unknown) {
                Scheduler.addTimeTaskToGroup(REPEAT_TIMER_GROUP, onKeyRepeat, 0, 1 / 30);
            }
        }, .6);
    }

    private function onKeyRepeat() {
        if (_downKey != KeyCode.Unknown) {
            performKeyOperation(_downKey);
        }
    }

    private function onKeyPress(character:String) {
        if (isActive == false) {
            return;
        }

        if ((character.charCodeAt(0) == CR || character.charCodeAt(0) == LF) && multiline == false) {
            return;
        }

        insertText(character);

        _caretInfo.force = false;
        _caretInfo.visible = true;
        _downKey = KeyCode.Unknown;
        Scheduler.removeTimeTasks(REPEAT_TIMER_GROUP);
    }

    private function onKeyUp(code:KeyCode) {
        if (isActive == false) {
            return;
        }

        switch (code) {
            case Shift:
                _shift = false;
            case Control:
                _ctrl = false;
            case _:
        }

        _caretInfo.force = false;
        _caretInfo.visible = true;
        _downKey = KeyCode.Unknown;
        Scheduler.removeTimeTask(_repeatTimerId);
        Scheduler.removeTimeTasks(REPEAT_TIMER_GROUP);
    }

    private var _mouseDownPos:CharPosition = null;
    private function onMouseDown(button:Int, x:Int, y:Int) {
        if (_font == null || inBounds(x, y) == false) {
            return;
        }

        /*
        if (_currentFocus != null && _currentFocus != this) {
            _currentFocus.onBlur();
        }
        _currentFocus = this;
        */

        var localX = x - left + scrollLeft;
        var localY = y - top;

        resetSelection();
        var pos = coordsToPos(localX, localY);
        if (pos != null) {
            _caretInfo.row = pos.row;
            _caretInfo.column = pos.column;
            scrollToCaret();
            if (_currentFocus != null) {
                _currentFocus.onFocus();
            }
        }
        _mouseDownPos = pos;

    }

    private function coordsToPos(localX:Float, localY:Float):CharPosition {
        var pos = {
            row: 0,
            column: 0
        }

        pos.row = scrollTop + Std.int(localY / font.height(fontSize));
        if (pos.row > _lines.length - 1) {
            pos.row = _lines.length - 1;
        }
        var line = _lines[pos.row];
        if (line == null) {
            return null;
        }
        var totalWidth:Float = 0;
        var i = 0;
        var inText = false;
        for (ch in line) {
            var charWidth = font.widthOfCharacters(fontSize, [ch], 0, 1);
            if (totalWidth + charWidth > localX) {
                pos.column = i;
                var delta = localX - totalWidth;
                if (delta > charWidth * 0.6) {
                    pos.column++;
                }
                inText = true;
                break;
            } else {
                totalWidth += charWidth;
            }
            i++;
        }

        if (inText == false) {
            pos.column = line.length;
        }

        return pos;
    }

    private function onMouseUp(button:Int, x:Int, y:Int) {
        _mouseDownPos = null;
    }

    private function onMouseMove(x:Int, y:Int, moveX:Int, moveY:Int) {
        if (_font == null) {
            return;
        }

        if (_mouseDownPos == null) {
            return;
        }

        if (isActive == false) {
            return;
        }

        if (inBounds(x, y) == false) {
            if (y < top && scrollTop == 0) {
                y = Std.int(top);
            } else if (y > top + height) {
                y = Std.int(top + height);
            }
        }

        var localX = x - left + scrollLeft;
        var localY = y - top;
        var pos = coordsToPos(localX, localY);
        if (pos != null) {
            var startIndex = posToIndex(_mouseDownPos);
            var endIndex = posToIndex(pos);

            if (endIndex > startIndex) {
                _selectionInfo.start.row = _mouseDownPos.row;
                _selectionInfo.start.column = _mouseDownPos.column;
                _selectionInfo.end = pos;

                _caretInfo.row = pos.row;
                _caretInfo.column = pos.column;
                scrollToCaret();
            } else {
                _selectionInfo.start.row = pos.row;
                _selectionInfo.start.column = pos.column;
                _selectionInfo.end = _mouseDownPos;

                _caretInfo.row = pos.row;
                _caretInfo.column = pos.column;
                scrollToCaret();
            }
        }
    }

    public function focus() {
        onFocus();
    }
    
    private function onFocus() {
        if (_currentFocus != null && _currentFocus != this) {
            _currentFocus.onBlur();
        }
        _currentFocus = this;
        
        if (_caretInfo.timerId == -1) {
            _caretInfo.visible = false;
            _caretInfo.timerId = Scheduler.addTimeTask(function() {
                _caretInfo.visible = !_caretInfo.visible;
            }, 0, .4);
        }
    }

    public function blur() {
        onBlur();
    }
    
    private function onBlur() {
        Scheduler.removeTimeTask(_caretInfo.timerId);
        _caretInfo.timerId = -1;
        _caretInfo.visible = false;
        _currentFocus = null;

        resetSelection();
    }

    public function destroy() {
        Mouse.get().remove(onMouseDown, onMouseUp, onMouseMove, null, null);
        Keyboard.get().remove(onKeyDown, onKeyUp, onKeyPress);
        _textChanged = null;
        _caretMoved = null;
    }

    //*****************************************************************************************************************//
    // UTIL                                                                                                            //
    //*****************************************************************************************************************//
    private function splitLines() {
        _lines = [];

        if (text == null || _font == null) {
            return;
        }

        if (multiline == false) {
            var text = text.split("\n").join("").split("\r").join("");
            if (password == true) {
                var passwordText = "";
                for (i in 0...text.length) {
                    passwordText += "*";
                }
                text = passwordText;
            }
            _lines.push(StringExtensions.toCharArray(text));
        } else if (wordWrap == false) {
            var arr = StringTools.replace(StringTools.replace(text, "\r\n", "\n"), "\r", "\n").split("\n");
            for (a in arr) {
                _lines.push(StringExtensions.toCharArray(a));
            }
        } else if (wordWrap == true) {
            var totalWidth:Float = 0;
            var spaceIndex:Int = -1;
            var start = 0;
            for (i in 0...text.length) {
                var charCode = text.charCodeAt(i);
                if (charCode == SPACE) {
                    spaceIndex = i;
                } else if (charCode == CR || charCode == LF) {
                    _lines.push(StringExtensions.toCharArray(text.substring(start, i)));
                    start = i + 1;
                    totalWidth = 0;
                    spaceIndex = -1;
                    continue;
                }

                var charWidth = font.widthOfCharacters(fontSize, [charCode], 0, 1);
                if (totalWidth + charWidth > width) {
                    _lines.push(StringExtensions.toCharArray(text.substring(start, spaceIndex)));
                    start = spaceIndex + 1;
                    var remain = StringExtensions.toCharArray(text.substring(spaceIndex + 1, i + 1));
                    totalWidth = font.widthOfCharacters(fontSize, remain, 0, remain.length);
                } else {
                    totalWidth += charWidth;
                }
            }

            if (start < text.length) {
                _lines.push(StringExtensions.toCharArray(text.substring(start, text.length)));
            }
        }
    }

    private function deleteCharsFromCaret(count:Int = 1, moveCaret:Bool = true) {
        deleteChars(count, _caretInfo, moveCaret);
    }

    private function deleteChars(count:Int, from:CharPosition, moveCaret:Bool = true) {
        var fromIndex = posToIndex(from);
        var toIndex = fromIndex + count;

        var startIndex = fromIndex;
        var endIndex = toIndex;
        if (startIndex > endIndex) {
            startIndex = toIndex;
            endIndex = fromIndex;
        }

        if (endIndex > text.length)
            endIndex = text.length;

        var before = text.substring(0, startIndex);
        var after = text.substring(endIndex, text.length);

        text = before + after;
        if (moveCaret == true) {
            caretPosition = endIndex + count;
        }
    }

    private function posToIndex(pos:CharPosition) {
        var index = 0;
        var i = 0;
        for (line in _lines) {
            if (i == pos.row) {
                var column = pos.column;
                if (line.length < pos.column) {
                    column = line.length-1;
                }
                index += column;
                break;
            } else {
                index += line.length + 1;
            }
            i++;
        }

        return index;
    }

    private function indexToPos(index:Int):CharPosition {
        var pos:CharPosition = { row: 0, column: 0 };

        var count:Int = 0;
        for (line in _lines) {
            if (index <= line.length) {
                pos.column = index;
                break;
            } else {
                index -= (line.length + 1);
                pos.row++;
            }
        }

        return pos;
    }

    private function scrollToCaret() {
        ensureRowVisible(_caretInfo.row);

        if (_lines.length < maxVisibleLines) {
            scrollTop = 0;
        }

        var line = _lines[_caretInfo.row];
        if (caretLeft - left > width) {
            scrollLeft += caretLeft - left - width + 50;

            if (scrollLeft + width > font.widthOfCharacters(fontSize, line, 0, line.length)) {
                scrollLeft = font.widthOfCharacters(fontSize, line, 0, line.length) - width + caretWidth;
                if (scrollLeft < 0) {
                    scrollLeft = 0;
                }
            }
        } else if (caretLeft - left < 0) {
            scrollLeft += (caretLeft - left) - 50;

            if (scrollLeft < 0 || font.widthOfCharacters(fontSize, line, 0, line.length) <= width) {
                scrollLeft = 0;
            }
        }
        notifyCaretMoved();
    }

    private function ensureRowVisible(row:Int) {
        if (row >= scrollTop && row <= scrollTop + maxVisibleLines - 1) {
            return;
        }

        if (row < scrollTop + maxVisibleLines) {
            scrollTop = row;
        } else {
            scrollTop = row - maxVisibleLines + 1;
        }
    }

    private function findClosestColumn(origin:CharPosition, offset:Int) {
        var closestColumn = origin.column;
        var offsetLine = _lines[origin.row + offset];
        if (closestColumn > offsetLine.length) {
            closestColumn = offsetLine.length;
        }
        return closestColumn;
    }

    //*****************************************************************************************************************//
    // RENDER                                                                                                          //
    //*****************************************************************************************************************//
    public function render(g:Graphics) {
        if (_font == null) {
            return;
        }
        
        g.color = backgroundColor;
        g.fillRect(left, top, width, height);

        ScissorHelper.pushScissor(g, Math.round(left), Math.round(top), Math.round(width), Math.round(height));

        g.font = font;
        g.fontSize = fontSize;

        var xpos:Float = left - scrollLeft;
        var ypos:Float = top;

        var start = scrollTop;
        var end = start + maxVisibleLines;

        if (start > 0) {
            start--; // show one less line so it looks nicer
            ypos -= font.height(fontSize);
        }
        if (end > _lines.length) {
            end = _lines.length;
        }
        if (end < _lines.length) {
            end++; // show one additonal line so it looks nicer
        }

        for (i in start...end) {
            xpos = left - scrollLeft;
            var line = _lines[i];

            if (i >= _selectionInfo.start.row && i <= _selectionInfo.end.row) {
                if (i == _selectionInfo.start.row && _selectionInfo.start.row == _selectionInfo.end.row) {
                    g.color = textColor;
                    g.drawCharacters(line, 0, _selectionInfo.start.column, xpos, ypos);
                    xpos += font.widthOfCharacters(fontSize, line, 0, _selectionInfo.start.column);

                    g.color = selectedBackgroundColor;
                    g.fillRect(xpos, ypos, font.widthOfCharacters(fontSize, line, _selectionInfo.start.column, (_selectionInfo.end.column) - (_selectionInfo.start.column)), font.height(fontSize));

                    g.color = selectedTextColor;
                    g.drawCharacters(line, _selectionInfo.start.column, (_selectionInfo.end.column) - (_selectionInfo.start.column), xpos, ypos);
                    xpos += font.widthOfCharacters(fontSize, line, _selectionInfo.start.column, (_selectionInfo.end.column) - (_selectionInfo.start.column));

                    g.color = textColor;
                    g.drawCharacters(line, _selectionInfo.end.column, line.length, xpos, ypos);
                } else if (i == _selectionInfo.start.row && _selectionInfo.start.row != _selectionInfo.end.row) {
                    g.color = textColor;
                    g.drawCharacters(line, 0, _selectionInfo.start.column, xpos, ypos);
                    xpos += font.widthOfCharacters(fontSize, line, 0, _selectionInfo.start.column);

                    g.color = selectedBackgroundColor;
                    g.fillRect(xpos, ypos, font.widthOfCharacters(fontSize, line, _selectionInfo.start.column, line.length - (_selectionInfo.start.column)), font.height(fontSize));

                    g.color = selectedTextColor;
                    g.drawCharacters(line, _selectionInfo.start.column, line.length - (_selectionInfo.start.column), xpos, ypos);
                } else if (i == _selectionInfo.end.row && _selectionInfo.start.row != _selectionInfo.end.row) {
                    g.color = selectedBackgroundColor;
                    g.fillRect(xpos, ypos, font.widthOfCharacters(fontSize, line, 0, _selectionInfo.end.column), font.height(fontSize));

                    g.color = selectedTextColor;
                    g.drawCharacters(line, 0, _selectionInfo.end.column, xpos, ypos);
                    xpos += font.widthOfCharacters(fontSize, line, 0, _selectionInfo.end.column);

                    g.color = textColor;
                    g.drawCharacters(line, _selectionInfo.end.column, line.length - (_selectionInfo.end.column), xpos, ypos);
                } else {
                    g.color = selectedBackgroundColor;
                    g.fillRect(xpos, ypos, font.widthOfCharacters(fontSize, line, 0, line.length), font.height(fontSize));

                    g.color = selectedTextColor;
                    g.drawCharacters(line, 0, line.length, xpos, ypos);
                }

            } else {
                g.color = textColor;
                g.drawCharacters(line, 0, line.length, xpos, ypos);
            }

            ypos += font.height(fontSize);
        }

        if (_caretInfo.row > -1 && _caretInfo.column > -1 && (_caretInfo.visible == true || _caretInfo.force == true)) {
            g.color = textColor;
            g.fillRect(caretLeft, caretTop, caretWidth, caretHeight);
        }

        ScissorHelper.popScissor();
    }
}
