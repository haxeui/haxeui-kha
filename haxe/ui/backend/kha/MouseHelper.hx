package haxe.ui.backend.kha;

import haxe.ui.events.MouseEvent;
import kha.input.Mouse;

class MouseHelper {
    public static var currentMouseX:Int = 0;
    public static var currentMouseY:Int = 0;
    
    private static var _hasOnMouseDown:Bool = false;
    private static var _hasOnMouseUp:Bool = false;
    private static var _hasOnMouseMove:Bool = false;
    private static var _hasOnMouseWheel:Bool = false;
    
    private static var _callbacks:Map<String, Array<MouseEvent->Void>> = new Map<String, Array<MouseEvent->Void>>();
    public static function notify(event:String, callback:MouseEvent->Void) {
        switch (event) {
            case MouseEvent.MOUSE_DOWN:
                if (_hasOnMouseDown == false) {
                    Mouse.get().notify(onMouseDown, null, null, null);
                    _hasOnMouseDown = true;
                }
            case MouseEvent.MOUSE_UP:
                if (_hasOnMouseUp == false) {
                    Mouse.get().notify(null, onMouseUp, null, null);
                    _hasOnMouseUp = true;
                }
            case MouseEvent.MOUSE_MOVE:
                if (_hasOnMouseMove == false) {
                    Mouse.get().notify(null, null, onMouseMove, null);
                    _hasOnMouseMove = true;
                }
            case MouseEvent.MOUSE_WHEEL:
                if (_hasOnMouseWheel == false) {
                    Mouse.get().notify(null, null, null, onMouseWheel);
                    _hasOnMouseWheel = true;
                }
        }
        
        var list = _callbacks.get(event);
        if (list == null) {
            list = new Array<MouseEvent->Void>();
            _callbacks.set(event, list);
        }
        
        list.push(callback);
    }
    
    public static function remove(event:String, callback:MouseEvent->Void) {
        var list = _callbacks.get(event);
        if (list != null) {
            list.remove(callback);
            if (list.length == 0) {
                _callbacks.remove(event);
                
                switch (event) {
                    case MouseEvent.MOUSE_DOWN:
                        if (_hasOnMouseDown == true) {
                            Mouse.get().remove(onMouseDown, null, null, null);
                            _hasOnMouseDown = false;
                        }
                    case MouseEvent.MOUSE_UP:
                        if (_hasOnMouseUp == true) {
                            Mouse.get().remove(null, onMouseUp, null, null);
                            _hasOnMouseUp = false;
                        }
                    case MouseEvent.MOUSE_MOVE:
                        if (_hasOnMouseMove == true) {
                            Mouse.get().remove(null, null, onMouseMove, null);
                            _hasOnMouseMove = false;
                        }
                    case MouseEvent.MOUSE_WHEEL:
                        if (_hasOnMouseWheel == true) {
                            Mouse.get().remove(null, null, null, onMouseWheel);
                            _hasOnMouseWheel = false;
                        }
                }
            }
        }
    }
    
    private static function onMouseDown(button:Int, x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_DOWN);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_DOWN);
        event.screenX = x;
        event.screenY = y;
        event.data = button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseUp(button:Int, x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_UP);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_UP);
        event.screenX = x;
        event.screenY = y;
        event.data = button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseMove(x:Int, y:Int, moveX:Int, moveY:Int) {
        if (moveX == 0 && moveY == 0) {
            return;
        }
        currentMouseX = x;
        currentMouseY = y;
        
        var list = _callbacks.get(MouseEvent.MOUSE_MOVE);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_MOVE);
        event.screenX = x;
        event.screenY = y;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseWheel(delta:Float) {
        var list = _callbacks.get(MouseEvent.MOUSE_WHEEL);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        event.delta = delta;
        for (l in list) {
            l(event);
        }
    }
}