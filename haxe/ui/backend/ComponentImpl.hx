package haxe.ui.backend;

import haxe.Timer;
import haxe.ui.Toolkit;
import haxe.ui.backend.kha.ImageCache;
import haxe.ui.backend.kha.MouseHelper;
import haxe.ui.backend.kha.ScissorHelper;
import haxe.ui.backend.kha.StyleHelper;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Rectangle;
import haxe.ui.styles.Style;
import haxe.ui.util.MathUtil;
import kha.Color;
import kha.graphics2.Graphics;
import kha.graphics2.ImageScaleQuality;
import kha.input.KeyCode;
import kha.input.Keyboard;

class ComponentImpl extends ComponentBase {
    private var _eventMap:Map<String, UIEvent->Void>;

    private var lastMouseX:Float = -1;
    private var lastMouseY:Float = -1;
	
	// For doubleclick detection
	private var _lastClickTime:Float = 0;
	private var _lastClickTimeDiff:Float = MathUtil.MAX_INT;
	private var _lastClickX:Float = -1;
	private var _lastClickY:Float = -1;

    public function new() {
        super();
        _eventMap = new Map<String, UIEvent->Void>();
        
        #if (kha_android || kha_android_native || kha_ios)
        cast(this, Component).addClass(":mobile");
        #end
    }

    // lets cache certain items so we dont have to loop multiple times per frame
    private var _cachedScreenX:Null<Float> = null;
    private var _cachedScreenY:Null<Float> = null;
    private var _cachedClipComponent:Component = null;
    private var _cachedClipComponentNone:Null<Bool> = null;
    private var _cachedRootComponent:Component = null;
    private var _cachedOpacity:Null<Float> = null;
    
    private function clearCaches() {
        _cachedScreenX = null;
        _cachedScreenY = null;
        _cachedClipComponent = null;
        _cachedClipComponentNone = null;
        _cachedRootComponent = null;
        _cachedOpacity = null;
    }
    
    private function cacheScreenPos() {
        if (_cachedScreenX != null && _cachedScreenY != null) {
            return;
        }
        
        var c:Component = cast(this, Component);
        var xpos:Float = 0;
        var ypos:Float = 0;
        while (c != null) {
            if (c.parentComponent == null) {
                xpos += c.left / Toolkit.scaleX;
                ypos += c.top / Toolkit.scaleY;
            } else {
                xpos += c.left;
                ypos += c.top;
            }
            if (c.componentClipRect != null) {
                xpos -= c.componentClipRect.left;
                ypos -= c.componentClipRect.top;
            }
            c = c.parentComponent;
        }
        
        _cachedScreenX = xpos;
        _cachedScreenY = ypos;
    }
    
    private var screenX(get, null):Float;
    private function get_screenX():Float {
        cacheScreenPos();
        return _cachedScreenX;
    }

    private var screenY(get, null):Float;
    private function get_screenY():Float {
        cacheScreenPos();
        return _cachedScreenY;
    }

    private function findRootComponent():Component {
        if (_cachedRootComponent != null) {
            return _cachedRootComponent;
        }
        
        var c:Component = cast(this, Component);
        while (c.parentComponent != null) {
            c = c.parentComponent;
        }
        
        _cachedRootComponent = c;
        
        return c;
    }
    
    private function isRootComponent():Bool {
        return (findRootComponent() == this);
    }
    
    private function findClipComponent():Component {
        if (_cachedClipComponent != null) {
            return _cachedClipComponent;
        } else if (_cachedClipComponentNone == true) {
            return null;
        }
        
        var c:Component = cast(this, Component);
        var clip:Component = null;
        while (c != null) {
            if (c.componentClipRect != null) {
                clip = c;
                break;
            }
            c = c.parentComponent;
        }

        _cachedClipComponent = clip;
        if (clip == null) {
            _cachedClipComponentNone = true;
        }
        
        return clip;
    }

    @:access(haxe.ui.core.Component)
    private function inBounds(x:Float, y:Float):Bool {
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
        if (_cachedOpacity != null) {
            return _cachedOpacity;
        }
        
        var opacity:Float = 1;
        var c:Component = cast(this, Component);
        while (c != null) {
            if (c.style.opacity != null) {
                opacity *= c.style.opacity;
            }
            c = c.parentComponent;
        }
        
        _cachedOpacity = opacity;
        
        return opacity;
    }

    private function isOffscreen():Bool {
        var x:Float = screenX;
        var y:Float = screenY;
        var w:Float = this.width;
        var h:Float = this.height;
        
        var clipComponent = findClipComponent();
        var thisRect = new Rectangle(x, y, w, h);
        if (clipComponent != null && clipComponent != this) {
            var screenClipRect = new Rectangle(clipComponent.screenX + clipComponent.componentClipRect.left, clipComponent.screenY + clipComponent.componentClipRect.top, clipComponent.componentClipRect.width, clipComponent.componentClipRect.height);
            return !screenClipRect.intersects(thisRect);
        } else {
            var screenRect = new Rectangle(0, 0, Screen.instance.width, Screen.instance.height);
            return !screenRect.intersects(thisRect);
        }
        
        return false;
    }
    
    private var _batchStyleOperations:Array<BatchOperation>;
    private var _batchImageOperations:Array<BatchOperation>;
    private var _batchTextOperations:Array<BatchOperation>;
    private function clearBatchOperations() {
        findRootComponent()._batchStyleOperations = [];
        findRootComponent()._batchImageOperations = [];
        findRootComponent()._batchTextOperations = [];
    }
    
    private function addBatchStyleOperation(op:BatchOperation) {
        findRootComponent()._batchStyleOperations.push(op);
    }

    private function addBatchImageOperation(op:BatchOperation) {
        findRootComponent()._batchImageOperations.push(op);
    }

    private function addBatchTextOperation(op:BatchOperation) {
        findRootComponent()._batchTextOperations.push(op);
    }

    private static inline function useBatching() {
        if (Screen.instance.options == null) {
            return true;
        }
        if (Screen.instance.options.noBatch == true) {
            return false;
        }
        return true;
    }
    
    @:access(haxe.ui.core.Component)
    public function renderTo(g:Graphics) {
        if (this.isReady == false || cast(this, Component).hidden == true) {
            return;
        }
        
        clearCaches();
        
        if (isOffscreen() == true) {
            return;
        }
        
        if (useBatching() == true && isRootComponent()) {
            clearBatchOperations();
        }
        
        var x:Float = screenX;
        var y:Float = screenY;
        var w:Float = this.width;
        var h:Float = this.height;
        
        var style:Style = this.style;
        if (style == null) {
            return;
        }
        
        var clipRect:Rectangle = cast(this, Component).componentClipRect;
        if (clipRect != null) {
            var clx = Std.int((x + clipRect.left) * Toolkit.scaleX);
            var cly = Std.int((y + clipRect.top) * Toolkit.scaleY);
            var clw = Math.ceil(clipRect.width * Toolkit.scaleX);
            var clh = Math.ceil(clipRect.height * Toolkit.scaleY);
            if (useBatching() == true) {
                addBatchStyleOperation(ApplyScissor(clx, cly, clw, clh));
                addBatchImageOperation(ApplyScissor(clx, cly, clw, clh));
                addBatchTextOperation(ApplyScissor(clx, cly, clw, clh));
            } else {
                if (clw >= 0 && clh >= 0) {
                    ScissorHelper.pushScissor(g, clx, cly, clw, clh);
                }
            }
        }
        
        if (useBatching() == true) {
            addBatchStyleOperation(DrawStyle(this));
        } else {
            renderStyleTo(g, this);
        }

        if (_imageDisplay != null && _imageDisplay._buffer != null) {
            if (useBatching() == true) {
                addBatchImageOperation(DrawImage(this));
            } else {
                renderImageTo(g, this);
            }
        }

        if (_textDisplay != null || _textInput != null) {
            if (useBatching() == true) {
                addBatchTextOperation(DrawText(this));
            } else {
                renderTextTo(g, this);
            }
        }

        if (useBatching() == true) {
            addBatchStyleOperation(DrawCustom(this));
        } else {
            renderCustom(g);
        }
        
        for (c in cast(this, Component).childComponents) {
            c.renderTo(g);
        }

        if (useBatching() == false) {
            g.opacity = 1;
        }
        
        if (clipRect != null) {
            if (useBatching() == true) {
                addBatchStyleOperation(ClearScissor);
                addBatchImageOperation(ClearScissor);
                addBatchTextOperation(ClearScissor);
            } else {
                ScissorHelper.popScissor();
            }
        }
        
        if (useBatching() == true && isRootComponent()) {
            renderToBatch(g);
        }
        
        clearCaches();
    }
    
    private function renderCustom(g:Graphics) {
        
    }
    
    private function renderToBatch(g:Graphics) {
        renderToBatchOperations(g, _batchStyleOperations);
        renderToBatchOperations(g, _batchImageOperations);
        renderToBatchOperations(g, _batchTextOperations);
    }
    
    private function renderToBatchOperations(g:Graphics, operations:Array<BatchOperation>) {
        for (op in operations) {
            switch (op) {
                case ApplyScissor(sx, sy, sw, sh):
                    if (sw >= 0 && sh >= 0) {
                        ScissorHelper.pushScissor(g, sx, sy, sw, sh);
                    }
                case DrawStyle(c):
                    renderStyleTo(g, c);
                case DrawImage(c):
                    renderImageTo(g, c);
                case DrawText(c):    
                    renderTextTo(g, c);
                case DrawCustom(c):
                    c.renderCustom(g);
                case ClearScissor:
                    ScissorHelper.popScissor();
            }
        }
    }
    
    private var _prevStyle:Style = null;
    private function renderStyleTo(g:Graphics, c:ComponentImpl) {
        g.opacity = c.calcOpacity();
        var x:Float = c.screenX;
        var y:Float = c.screenY;
        var w:Float = c.width;
        var h:Float = c.height;
        var style:Style = c.style;
        
        var usePrevStyle:Bool = false;
        if (style.backgroundImage != null) {
            usePrevStyle = !ImageCache.has(style.backgroundImage);
        }
        
        if (usePrevStyle == false) {
            StyleHelper.paintStyle(g, style, x, y, w, h);
            c._prevStyle = style;
        } else if (c._prevStyle != null) {
            StyleHelper.paintStyle(g, c._prevStyle, x, y, w, h);
        }
        
        g.opacity = 1;
    }
    
    private function renderImageTo(g:Graphics, c:ComponentImpl) {
        g.opacity = c.calcOpacity();
        
        var x:Float = c.screenX;
        var y:Float = c.screenY;
        var w:Float = c.width;
        var h:Float = c.height;
        var imageX = (x + c._imageDisplay.left) * Toolkit.scaleX;
        var imageY = (y + c._imageDisplay.top) * Toolkit.scaleY;
        var orgScaleQuality = g.imageScaleQuality;
        g.imageScaleQuality = ImageScaleQuality.Low;
        if (c._imageDisplay.scaled == true) {
            g.drawScaledImage(c._imageDisplay._buffer, imageX, imageY, c._imageDisplay.imageWidth, c._imageDisplay.imageHeight);
        } else if (Toolkit.scale != 1) {
            g.drawScaledImage(c._imageDisplay._buffer, imageX, imageY, c._imageDisplay.imageWidth * Toolkit.scaleX, c._imageDisplay.imageHeight * Toolkit.scaleY);
        } else {
            g.drawImage(c._imageDisplay._buffer, imageX, imageY);
        }
        g.imageScaleQuality = orgScaleQuality;
        
        g.opacity = 1;
    }
    
    private function renderTextTo(g:Graphics, c:ComponentImpl) {
        g.opacity = c.calcOpacity();
        var x:Float = c.screenX;
        var y:Float = c.screenY;
        var w:Float = c.width;
        var h:Float = c.height;
        var style:Style = c.style;
        
        
        if (style.color != null) {
            g.color = style.color | 0xFF000000;
        } else {
            g.color = Color.Black | 0xFF000000;
        }

        if (c._textDisplay != null) {
            c._textDisplay.renderTo(g, x * Toolkit.scaleX, y * Toolkit.scaleY);
        }
        
        if (c._textInput != null) {
            c._textInput.renderTo(g, x * Toolkit.scaleX, y * Toolkit.scaleY);
        }
        
        g.color = Color.White;
        g.opacity = 1;
    }

    private var _componentBuffer:kha.Image;
    public function renderToScaled(g:Graphics, scaleX:Float, scaleY:Float) {
        var cx:Int = Std.int(cast(this, Component).width * Toolkit.scaleX);
        var cy:Int = Std.int(cast(this, Component).height * Toolkit.scaleY);

        if (_componentBuffer == null || _componentBuffer.width != cx || _componentBuffer.height != cy) {
            if (_componentBuffer != null) {
                _componentBuffer.unload();
            }
            _componentBuffer = kha.Image.createRenderTarget(cx, cy);
        }

        g.end();
        _componentBuffer.g2.begin(true, 0xFFFFFFFF);
        renderTo(_componentBuffer.g2);
        _componentBuffer.g2.end();
        g.begin();

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
    @:access(haxe.ui.backend.TextInputImpl)
    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_MOVE, listener);
                }
                
            case MouseEvent.MOUSE_OVER:
                if (_eventMap.exists(MouseEvent.MOUSE_OVER) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_OVER, listener);
                }
                
            case MouseEvent.MOUSE_OUT:
                if (_eventMap.exists(MouseEvent.MOUSE_OUT) == false) {
                    _eventMap.set(MouseEvent.MOUSE_OUT, listener);
                }

            case MouseEvent.MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                }

            case MouseEvent.MOUSE_UP:
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_UP, listener);
                }
                
            case MouseEvent.MOUSE_WHEEL:
                if (_eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    MouseHelper.notify(MouseEvent.MOUSE_WHEEL, __onMouseWheel);
                    _eventMap.set(MouseEvent.MOUSE_WHEEL, listener);
                }
                
            case MouseEvent.CLICK:
                if (_eventMap.exists(MouseEvent.CLICK) == false) {
                    _eventMap.set(MouseEvent.CLICK, listener);

                    if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                    }

                    if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MOUSE_UP, listener);
                    }
                }
                
			case MouseEvent.DBL_CLICK:
                if (_eventMap.exists(MouseEvent.DBL_CLICK) == false) {
                    _eventMap.set(MouseEvent.DBL_CLICK, listener);
					
                    if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onDoubleClick);
                        _eventMap.set(MouseEvent.MOUSE_UP, listener);
                    }
                }
                
            case MouseEvent.RIGHT_MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_DOWN, listener);
                }

            case MouseEvent.RIGHT_MOUSE_UP:
                if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.RIGHT_MOUSE_UP, listener);
                }
                
            case MouseEvent.RIGHT_CLICK:
                if (_eventMap.exists(MouseEvent.RIGHT_CLICK) == false) {
                    _eventMap.set(MouseEvent.RIGHT_CLICK, listener);

                    if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.RIGHT_MOUSE_DOWN, listener);
                    }

                    if (_eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
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
                
            case UIEvent.CHANGE: 
                if (_eventMap.exists(type) == false) {
                    if (hasTextInput() == true) {
                        getTextInput()._tf.notify(onTextInputChanged, null);
                    }
                }
        }
    }
    
    private function onTextInputChanged(s:String) {
        dispatch(new UIEvent(UIEvent.CHANGE));
    }
    
    @:access(haxe.ui.backend.TextInputImpl)
    private override function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_OVER:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_OUT:
                _eventMap.remove(type);

            case MouseEvent.MOUSE_DOWN:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }

            case MouseEvent.MOUSE_UP:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_UP, __onMouseUp);
                }
                
            case MouseEvent.MOUSE_WHEEL:
                _eventMap.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_WHEEL, __onMouseWheel);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.CLICK:
                _eventMap.remove(type);
                
			case MouseEvent.DBL_CLICK:
                _eventMap.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_UP, __onDoubleClick);
                
            case MouseEvent.RIGHT_MOUSE_DOWN:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }

            case MouseEvent.RIGHT_MOUSE_UP:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_UP, __onMouseUp);
                }
                
            case MouseEvent.RIGHT_CLICK:
                _eventMap.remove(type);
                
			case KeyboardEvent.KEY_DOWN:
                _eventMap.remove(type);
                Keyboard.get().remove(__onKeyDown, null, null);
                
			case KeyboardEvent.KEY_UP:
                _eventMap.remove(type);
                Keyboard.get().remove(null, __onKeyUp, null);
                
            case UIEvent.CHANGE: 
                _eventMap.remove(type);
                if (hasTextInput() == true) {
                    getTextInput()._tf.remove(onTextInputChanged, null);
                }
        }
    }

    private var _mouseOverFlag:Bool = false;
    private function __onMouseMove(event:MouseEvent) {
        var x = event.screenX;
        var y = event.screenY;
        
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true) {
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_MOVE);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_MOVE);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
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
    private function __onMouseDown(event:MouseEvent) {
        var button:Int = event.data;
        var x = event.screenX;
        var y = event.screenY;
        
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

    private function __onMouseUp(event:MouseEvent) {
        var button:Int = event.data;
        var x = event.screenX;
        var y = event.screenY;
        
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
				
				if (type == haxe.ui.events.MouseEvent.CLICK) {
					_lastClickTimeDiff = Timer.stamp() - _lastClickTime;
					_lastClickTime = Timer.stamp();
					if (_lastClickTimeDiff >= 0.5) { // 0.5 seconds
						_lastClickX = x;
						_lastClickY = y;
					}
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
	
	private function __onDoubleClick(event:MouseEvent) {
        var button:Int = event.data;
        var x = event.screenX;
        var y = event.screenY;
        
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true && button == 0) {
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
			
            _mouseDownFlag = false;
			var mouseDelta:Float = MathUtil.distance(x, y, _lastClickX, _lastClickY);
			if (_lastClickTimeDiff < 0.5 && mouseDelta < 5) { // 0.5 seconds
				var type = haxe.ui.events.MouseEvent.DBL_CLICK;
				var fn:UIEvent->Void = _eventMap.get(type);
				if (fn != null) {
					var mouseEvent = new haxe.ui.events.MouseEvent(type);
					mouseEvent.screenX = x / Toolkit.scaleX;
					mouseEvent.screenY = y / Toolkit.scaleY;
					fn(mouseEvent);
				}
			}
        }
        _mouseDownFlag = false;
    }

    private function __onMouseWheel(event:MouseEvent) {
        var delta = event.delta;
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

    private function hasComponentOver(ref:Component, x:Float, y:Float):Bool {
        var array:Array<Component> = getComponentsAtPoint(x, y);
        if (array.length == 0) {
            return false;
        }

        return !hasChildRecursive(cast ref, cast array[array.length - 1]);
    }

    private function getComponentsAtPoint(x:Float, y:Float):Array<Component> {
        var array:Array<Component> = new Array<Component>();
        for (r in Screen.instance.rootComponents) {
            findChildrenAtPoint(r, x, y, array);
        }
        return array;
    }

    private function findChildrenAtPoint(child:Component, x:Float, y:Float, array:Array<Component>) {
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
            if (r == true) {
                break;
            }
        }

        return r;
    }
}
