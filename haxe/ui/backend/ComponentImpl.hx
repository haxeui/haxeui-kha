package haxe.ui.backend;

import haxe.ui.backend.kha.StyleHelper;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Rectangle;
import haxe.ui.styles.Style;
import kha.Color;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.input.Keyboard;
import kha.input.Mouse;

class ComponentImpl extends ComponentBase {
    //public var parent:ComponentBase;
    private var _eventMap:Map<String, UIEvent->Void>;

    private var lastMouseX = -1;
    private var lastMouseY = -1;

    public function new() {
        super();
        _eventMap = new Map<String, UIEvent->Void>();
    }

    public var screenX(get, null):Float;
    private function get_screenX():Float {
        var c:Component = cast(this, Component);
        var xpos:Float = 0;
        while (c != null) {
            xpos += Math.fceil(c.left);
            if (c.componentClipRect != null) {
                xpos -= Math.fceil(c.componentClipRect.left);
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
            if (c.componentClipRect != null) {
                ypos -= c.componentClipRect.top;
            }
            c = c.parentComponent;
        }
        return ypos;
    }

    public function findClipComponent():Component {
        var c:Component = cast(this, Component);
        var clip:Component = null;
        while (c != null) {
            if (c.componentClipRect != null) {
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
        var sx = screenX * Toolkit.scaleX;
        var sy = screenY * Toolkit.scaleY;
        var cx = cast(this, Component).componentWidth * Toolkit.scaleX;
        var cy = cast(this, Component).componentHeight * Toolkit.scaleY;

        if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
            b = true;
        }

        // let make sure its in the clip rect too
        if (b == true) {
            var clip:Component = findClipComponent();
            if (clip != null) {
                b = false;
                var sx = (clip.screenX + clip.componentClipRect.left) * Toolkit.scaleX;
                var sy = (clip.screenY + clip.componentClipRect.top) * Toolkit.scaleY;
                var cx = clip.componentClipRect.width * Toolkit.scaleX;
                var cy = clip.componentClipRect.height * Toolkit.scaleY;
                if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
                    b = true;
                }
            }
        }
        return b;
    }

    //***********************************************************************************************************
    // Style related
    //***********************************************************************************************************
    private function calcOpacity():Float {
        var opacity:Float = 1;
        var c:Component = cast(this, Component);
        while (c != null) {
            if (c.style.opacity != null) {
                opacity *= c.style.opacity;
            }
            c = c.parentComponent;
        }
        return opacity;
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
        if (style == null) {
            return;
        }
        var clipRect:Rectangle = cast(this, Component).componentClipRect;

        if (clipRect != null) {
            g.scissor(Math.floor(x + clipRect.left), Math.floor(y + clipRect.top), Math.ceil(clipRect.width), Math.ceil(clipRect.height));
        }

        var opacity = calcOpacity();
        g.opacity = opacity;
        StyleHelper.paintStyle(g, style, x, y, w, h);

        if (_imageDisplay != null && _imageDisplay._buffer != null) {
            if (_imageDisplay.scaled == true) {
                g.drawScaledImage(_imageDisplay._buffer, x + _imageDisplay.left, y + _imageDisplay.top, _imageDisplay.imageWidth, _imageDisplay.imageHeight);
            } else {
                g.drawImage(_imageDisplay._buffer, x + _imageDisplay.left, y + _imageDisplay.top);
            }
        }

        if (style.color != null) {
            g.color = style.color | 0xFF000000;
        } else {
            g.color = Color.Black | 0xFF000000;
        }

        if (_textDisplay != null) {
            _textDisplay.renderTo(g, x, y);
        }

        if (_textInput != null) {
            _textInput.renderTo(g, x, y);
        }

        g.color = Color.White;

        for (c in cast(this, Component).childComponents) {
            c.renderTo(g);
        }

        g.opacity = 1;
        
        if (clipRect != null) {
            g.disableScissor();
        }
    }

    private var _componentBuffer:kha.Image;
    public function renderToScaled(g:Graphics, scaleX:Float, scaleY:Float) {
        var cx:Int = Std.int(cast(this, Component).width);
        var cy:Int = Std.int(cast(this, Component).height);

        if (_componentBuffer == null || _componentBuffer.width != cx || _componentBuffer.height != cy) {
            if (_componentBuffer != null) {
                _componentBuffer.unload();
            }
            _componentBuffer = kha.Image.createRenderTarget(cx, cy);
        }

        _componentBuffer.g2.begin(true, 0xFFFFFFFF);
        renderTo(_componentBuffer.g2);
        _componentBuffer.g2.end();

        g.drawScaledImage(_componentBuffer, 0, 0, cx * scaleX, cy * scaleY);
    }

    private override function handleSize(width:Null<Float>, height:Null<Float>, style:Style) {
        if (width == null || height == null || width <= 0 || height <= 0) {
            return;
        }
        
        if (style.clip != null && style.clip == true) {
            cast(this, Component).componentClipRect = new Rectangle(0, 0, width, height);
        }
    }

    private override function handleVisibility(show:Bool):Void {
        var c:Component = cast(this, Component);
        for (child in c.childComponents) {
            child.handleVisibility(show);
        }
    }

    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private override function mapEvent(type:String, listener:UIEvent->Void) {
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
            case MouseEvent.MOUSE_WHEEL:
                if (!_eventMap.exists(MouseEvent.MOUSE_WHEEL)) {
                    Mouse.get().notify(null, null, null, __onMouseWheel, null);
                    _eventMap.set(MouseEvent.MOUSE_WHEEL, listener);
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
            case MouseEvent.RIGHT_MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    Mouse.get().notify(__onMouseDown, __onMouseUp, null, null);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_DOWN, listener);
                }

            case MouseEvent.RIGHT_MOUSE_UP:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    Mouse.get().notify(null, __onMouseUp, null, null);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_UP, listener);
                }
            case MouseEvent.RIGHT_CLICK:
                if (_eventMap.exists(MouseEvent.RIGHT_CLICK) == false) {
                    _eventMap.set(MouseEvent.RIGHT_CLICK, listener);

                    if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                        Mouse.get().notify(__onMouseDown, __onMouseUp, null, null);
                        _eventMap.set(MouseEvent.RIGHT_MOUSE_DOWN, listener);
                    }

                    if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                        Mouse.get().notify(null, __onMouseUp, null, null);
                        _eventMap.set(MouseEvent.RIGHT_MOUSE_UP, listener);
                    }
                }
			case KeyboardEvent.KEY_DOWN:
				if (_eventMap.exists(KeyboardEvent.KEY_DOWN) == false) {
                    Keyboard.get().notify(__onKeyDown, null, null);
                    _eventMap.set(KeyboardEvent.KEY_DOWN, listener);
                }
			case KeyboardEvent.KEY_UP:
				if (_eventMap.exists(KeyboardEvent.KEY_UP) == false) {
                    Keyboard.get().notify(null, __onKeyUp, null);
                    _eventMap.set(KeyboardEvent.KEY_UP, listener);
                }
        }
    }

    private override function unmapEvent(type:String, listener:UIEvent->Void) {

    }

    private var _mouseOverFlag:Bool = false;
    private function __onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int) {
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true && _mouseOverFlag == false) {
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            _mouseOverFlag = true;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OVER);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OVER);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        } else if (i == false && _mouseOverFlag == true) {
            _mouseOverFlag = false;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OUT);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OUT);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
    }

    private var _mouseDownFlag:Bool = false;
    private function __onMouseDown(button:Int, x:Int, y:Int) {
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true && _mouseDownFlag == false) {
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            _mouseDownFlag = true;
            var type = button == 0 ? haxe.ui.events.MouseEvent.MOUSE_DOWN: haxe.ui.events.MouseEvent.RIGHT_MOUSE_DOWN;
            var fn:UIEvent->Void = _eventMap.get(type);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(type);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
    }

    private function __onMouseUp(button:Int, x:Int, y:Int) {
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true) {
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            if (_mouseDownFlag == true) {
                var type = button == 0 ? haxe.ui.events.MouseEvent.CLICK: haxe.ui.events.MouseEvent.RIGHT_CLICK;
                var fn:UIEvent->Void = _eventMap.get(type);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(type);
                    mouseEvent.screenX = x / Toolkit.scaleX;
                    mouseEvent.screenY = y / Toolkit.scaleY;
                    fn(mouseEvent);
                }
            }

            _mouseDownFlag = false;
            var type = button == 0 ? haxe.ui.events.MouseEvent.MOUSE_UP: haxe.ui.events.MouseEvent.RIGHT_MOUSE_UP;
            var fn:UIEvent->Void = _eventMap.get(type);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(type);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
        _mouseDownFlag = false;
    }

    private function __onMouseWheel(delta: Int) {
        var fn = _eventMap.get(MouseEvent.MOUSE_WHEEL);

        if (fn == null) {
            return;
        }

        if (!inBounds(lastMouseX, lastMouseY)) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        mouseEvent.screenX = lastMouseX / Toolkit.scaleX;
        mouseEvent.screenY = lastMouseY / Toolkit.scaleY;
        mouseEvent.delta = Math.max(-1, Math.min(1, -delta));
        fn(mouseEvent);
    }
	
	private function __onKeyDown(key:KeyCode) {
		if (cast(this, Component).hasClass(":active") == false) {
			return;
		}
		
		var fn = _eventMap.get(KeyboardEvent.KEY_DOWN);
		
		if (fn == null) {
            return;
        }
		
		var keyEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN);
		keyEvent.keyCode = key;
		fn(keyEvent);
	}
	
	private function __onKeyUp(key:KeyCode) {
		if (cast(this, Component).hasClass(":active") == false) {
			return;
		}
		
		var fn = _eventMap.get(KeyboardEvent.KEY_UP);
		
		if (fn == null) {
            return;
        }
		
		var keyEvent = new KeyboardEvent(KeyboardEvent.KEY_UP);
		keyEvent.keyCode = key;
		fn(keyEvent);
	}

    private function hasComponentOver(ref:Component, x:Int, y:Int):Bool {
        var array:Array<Component> = getComponentsAtPoint(x, y);
        if (array.length == 0) {
            return false;
        }

        return !hasChildRecursive(cast ref, cast array[array.length - 1]);
    }

    private function getComponentsAtPoint(x:Int, y:Int):Array<Component> {
        var array:Array<Component> = new Array<Component>();
        for (r in Screen.instance.rootComponents) {
            findChildrenAtPoint(r, x, y, array);
        }
        return array;
    }

    private function findChildrenAtPoint(child:Component, x:Int, y:Int, array:Array<Component>) {
        if (child.inBounds(x, y) == true) {
            array.push(child);
            for (c in child.childComponents) {
                findChildrenAtPoint(c, x, y, array);
            }
        }
    }

    public function hasChildRecursive(parent:Component, child:Component):Bool {
        if (parent == child) {
            return true;
        }
        var r = false;
        for (t in parent.childComponents) {
            if (t == child) {
                r = true;
                break;
            }

            r = hasChildRecursive(t, child);
        }

        return r;
    }
}
