package haxe.ui.backend;

import haxe.ui.backend.kha.StyleHelper;
import haxe.ui.core.Component;
import haxe.ui.core.ImageDisplay;
import haxe.ui.core.MouseEvent;
import haxe.ui.core.TextDisplay;
import haxe.ui.core.TextInput;
import haxe.ui.core.UIEvent;
import haxe.ui.styles.Style;
import haxe.ui.assets.ImageInfo;
import haxe.ui.util.ColorUtil;
import haxe.ui.util.Rectangle;
import haxe.ui.util.Slice9;
import haxe.ui.util.Slice9.Slice9Rects;
import kha.Color;
import kha.graphics2.Graphics;
import kha.input.Mouse;

class ComponentBase {
    public var parent:ComponentBase;
    private var __children:Array<ComponentBase>;
    private var _eventMap:Map<String, UIEvent->Void>;

    public function new() {
        _eventMap = new Map<String, UIEvent->Void>();
        __children = new Array<ComponentBase>();
    }

    private function createDelegate(native:Bool) {

    }

    public var screenX(get, null):Float;
    private function get_screenX():Float {
        var c:Component = cast(this, Component);
        var xpos:Float = 0;
        while (c != null) {
            xpos += Math.fceil(c.left);
            if (c.clipRect != null) {
                xpos -= Math.fceil(c.clipRect.left);
            }
            c = c.parentComponent;
        }
        return xpos;
    }

    public var screenY(get, null):Float;
    private function get_screenY():Float {
        var c:Component = cast(this, Component);
        var ypos:Float = 0;
        while (c != null) {
            ypos += c.top;
            if (c.clipRect != null) {
                ypos -= c.clipRect.top;
            }
            c = c.parentComponent;
        }
        return ypos;
    }

    public function findClipComponent():Component {
        var c:Component = cast(this, Component);
        var clip:Component = null;
        while (c != null) {
            if (c.clipRect != null) {
                clip = c;
                break;
            }
            c = c.parentComponent;
        }

        return clip;
    }

    @:access(haxe.ui.core.Component)
    private function inBounds(x:Int, y:Int):Bool {
        if (cast(this, Component).hidden == true) {
            return false;
        }

        var b:Bool = false;
        var sx = screenX;
        var sy = screenY;
        var cx = cast(this, Component).componentWidth;
        var cy = cast(this, Component).componentHeight;

        if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
            b = true;
        }

        // let make sure its in the clip rect too
        if (b == true) {
            var clip:Component = findClipComponent();
            if (clip != null) {
                b = false;
                var sx = clip.screenX + clip.clipRect.left;
                var sy = clip.screenY + clip.clipRect.top;
                var cx = clip.clipRect.width;
                var cy = clip.clipRect.height;
                if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
                    b = true;
                }
            }
        }
        return b;
    }

    //***********************************************************************************************************
    // Text related
    //***********************************************************************************************************
    private var _textDisplay:TextDisplay;
    public function createTextDisplay(text:String = null):TextDisplay {
        if (_textDisplay == null) {
            _textDisplay = new TextDisplay();
        }
        if (text != null) {
            _textDisplay.text = text;
        }
        return _textDisplay;
    }

    public function getTextDisplay():TextDisplay {
        return createTextDisplay();
    }

    public function hasTextDisplay():Bool {
        return (_textDisplay != null);
    }

    private var _textInput:TextInput;
    public function createTextInput(text:String = null):TextInput {
        if (_textInput == null) {
            _textInput = new TextInput();
        }
        if (text != null) {
            _textInput.text = text;
        }
        return _textInput;
    }

    public function getTextInput():TextInput {
        return createTextInput();
    }

    public function hasTextInput():Bool {
        return (_textInput != null);
    }

    //***********************************************************************************************************
    // Image related
    //***********************************************************************************************************
    private var _imageDisplay:ImageDisplay;
    public function createImageDisplay():ImageDisplay {
        if (_imageDisplay == null) {
            _imageDisplay = new ImageDisplay();
        }

        /*
        if (resource != null) {
            _imageDisplay.update(resource, type);
        }
        */
        return _imageDisplay;
    }

    public function getImageDisplay():ImageDisplay {
        return createImageDisplay();
    }

    public function hasImageDisplay():Bool {
        return (_imageDisplay != null);
    }


    public function removeImageDisplay():Void {
        if (_imageDisplay != null) {
            _imageDisplay.dispose();
            _imageDisplay = null;
            //dirty = true;
        }
    }

    //***********************************************************************************************************
    // Style related
    //***********************************************************************************************************
    private function applyStyle(stye:Style) {
    }


    private function calcAlpha():Float {
        var alpha:Float = 1;
        var c:Component = cast(this, Component);
        while (c != null) {
            if (c.style.opacity != null) {
                alpha *= c.style.opacity;
            }
            c = c.parentComponent;
        }
        return alpha;
    }

    @:access(haxe.ui.core.Component)
    public function renderTo(g:Graphics) {
        if (cast(this, Component).isReady == false || cast(this, Component).hidden == true) {
            return;
        }

        var x:Int = Math.floor(screenX);
        var y:Int = Math.floor(screenY);
        var w:Int = Math.ceil(cast(this, Component).componentWidth);
        var h:Int = Math.ceil(cast(this, Component).componentHeight);


        var style:Style = cast(this, Component).style;
        var clipRect:Rectangle = cast(this, Component).clipRect;

        if (clipRect != null) {
            g.scissor(Math.floor(x + clipRect.left), Math.floor(y + clipRect.top), Math.ceil(clipRect.width), Math.ceil(clipRect.height));
        }

        //style.opacity = calcAlpha();
        StyleHelper.paintStyle(g, style, x, y, w, h);

        if (_imageDisplay != null && _imageDisplay._buffer != null) {
            g.drawImage(_imageDisplay._buffer, x + _imageDisplay.left, y + _imageDisplay.top);
        }

        if (style.color != null) {
            g.color = style.color | 0xFF000000;
        } else {
            g.color = Color.Black;
        }

        if (_textDisplay != null) {
            g.font = _textDisplay._font;
            g.fontSize = Std.int(_textDisplay.fontSize);
            g.drawString(_textDisplay.text, x + _textDisplay.left,  y + _textDisplay.top + 1);
        }

        if (_textInput != null) {
            g.font = _textInput._font;
            g.fontSize = Std.int(_textInput.fontSize);
            g.drawString(_textInput.text, x + _textInput.left, y + _textInput.top + 1);
        }

        g.color = Color.White;

        for (c in cast(this, Component).childComponents) {
            c.renderTo(g);
        }

        if (clipRect != null) {
            g.disableScissor();
        }

    }

    private function handleSize(width:Null<Float>, height:Null<Float>, style:Style) {
        if (width == null || height == null || width <= 0 || height <= 0) {
            return;
        }
    }

    public function handleCreate(native:Bool) {

    }

    public function handlePreReposition():Void {
    }

    public function handlePostReposition():Void {
    }

    private function handlePosition(left:Null<Float>, top:Null<Float>, style:Style):Void {
        if (left != null) {
        }
        if (top != null) {
        }
    }

    private function handleReady() {

    }

    private function handleClipRect(value:Rectangle):Void {
    }

    private function handleAddComponent(child:Component):Component {
        return child;
    }

    private function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        return child;
    }

    private function handleVisibility(show:Bool):Void {
        var c:Component = cast(this, Component);
        for (child in c.childComponents) {
            child.handleVisibility(show);
        }
    }

    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_OVER:
                if (_eventMap.exists(MouseEvent.MOUSE_OVER) == false) {
                    Mouse.get().notify(null, null, __onMouseMove, null);
                    _eventMap.set(MouseEvent.MOUSE_OVER, listener);
                }
            case MouseEvent.MOUSE_OUT:
                if (_eventMap.exists(MouseEvent.MOUSE_OUT) == false) {
                    //Mouse.get().notify(null, null, __onMouseMove, null);
                    _eventMap.set(MouseEvent.MOUSE_OUT, listener);
                }

            case MouseEvent.MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                    Mouse.get().notify(__onMouseDown, __onMouseUp, null, null);
                    _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                }

            case MouseEvent.MOUSE_UP:
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                    Mouse.get().notify(null, __onMouseUp, null, null);
                    _eventMap.set(MouseEvent.MOUSE_UP, listener);
                }

            case MouseEvent.CLICK:
                if (_eventMap.exists(MouseEvent.CLICK) == false) {
                    _eventMap.set(MouseEvent.CLICK, listener);

                    if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                        Mouse.get().notify(__onMouseDown, __onMouseUp, null, null);
                        _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                    }

                    if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                        Mouse.get().notify(null, __onMouseUp, null, null);
                        _eventMap.set(MouseEvent.MOUSE_UP, listener);
                    }
                }
        }
    }

    private function unmapEvent(type:String, listener:UIEvent->Void) {

    }

    private var _mouseOverFlag:Bool = false;
    private function __onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int) {
        var i = inBounds(x, y);
        if (i == true && _mouseOverFlag == false) {
            _mouseOverFlag = true;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.core.MouseEvent.MOUSE_OVER);
            if (fn != null) {
                var mouseEvent = new haxe.ui.core.MouseEvent(haxe.ui.core.MouseEvent.MOUSE_OVER);
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
            }
        } else if (i == false && _mouseOverFlag == true) {
            _mouseOverFlag = false;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.core.MouseEvent.MOUSE_OUT);
            if (fn != null) {
                var mouseEvent = new haxe.ui.core.MouseEvent(haxe.ui.core.MouseEvent.MOUSE_OUT);
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
            }
        }
    }

    private var _mouseDownFlag:Bool = false;
    private function __onMouseDown(button:Int, x:Int, y:Int) {
        var i = inBounds(x, y);
        if (i == true && _mouseDownFlag == false) {
            _mouseDownFlag = true;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.core.MouseEvent.MOUSE_DOWN);
            if (fn != null) {
                var mouseEvent = new haxe.ui.core.MouseEvent(haxe.ui.core.MouseEvent.MOUSE_DOWN);
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
            }
        }
    }


    private function __onMouseUp(button:Int, x:Int, y:Int) {
        var i = inBounds(x, y);
        if (i == true) {
            if (_mouseDownFlag == true) {
                var fn:UIEvent->Void = _eventMap.get(haxe.ui.core.MouseEvent.CLICK);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.core.MouseEvent(haxe.ui.core.MouseEvent.CLICK);
                    mouseEvent.screenX = x;
                    mouseEvent.screenY = y;
                    fn(mouseEvent);
                }
            }

            _mouseDownFlag = false;

            var fn:UIEvent->Void = _eventMap.get(haxe.ui.core.MouseEvent.MOUSE_UP);
            if (fn != null) {
                var mouseEvent = new haxe.ui.core.MouseEvent(haxe.ui.core.MouseEvent.MOUSE_UP);
                mouseEvent.screenX = x;
                mouseEvent.screenY = y;
                fn(mouseEvent);
            }
        }
        _mouseDownFlag = false;
    }
}