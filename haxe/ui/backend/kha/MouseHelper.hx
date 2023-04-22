package haxe.ui.backend.kha;

import haxe.ui.backend.ToolkitOptions;
import haxe.ui.events.MouseEvent;
import kha.input.Mouse;

class MouseHelper {
    public static var currentMouseX:Int = 0;
    public static var currentMouseY:Int = 0;

    private static var _hasOnMouseDown:Bool = false;
    private static var _hasOnMouseUp:Bool = false;
    private static var _hasOnMouseMove:Bool = false;
    private static var _hasOnMouseWheel:Bool = false;

    static var listen: MouseListenerCallback;
    static var unlisten: MouseListenerCallback;

    public static inline function isInitialized() {
        return listen != null;
    }

    public static function init( ?opts: MouseInputOptions ) {
        if (opts != null && opts.listen == null && Mouse.get() == null) {
            return;
        }
        if (opts == null && Mouse.get() == null) {
            return;
        }
        listen = opts != null && opts.listen != null ? opts.listen : Mouse.get().notify;
        unlisten = opts != null && opts.unlisten != null ? opts.unlisten : Mouse.get().remove;

        if (_cachedCallbacks != null) {
            for (item in _cachedCallbacks) {
                notify(item.event, item.callback);
            }
            _cachedCallbacks = null;
        }
    }

    private static var _callbacks:Map<String, Array<MouseEvent->Void>> = new Map<String, Array<MouseEvent->Void>>();
    private static var _cachedCallbacks:Array<{event:String, callback:MouseEvent->Void}> = null;
    public static function notify(event:String, callback:MouseEvent->Void) {
        if (!isInitialized()) {
            if (_cachedCallbacks == null) {
                _cachedCallbacks = [];
            }
            _cachedCallbacks.push({event: event, callback: callback});
            return;
        }

        switch (event) {
            case MouseEvent.MOUSE_DOWN:
                if (_hasOnMouseDown == false) {
                    listen(onMouseDown, null, null, null, null);
                    _hasOnMouseDown = true;
                }
            case MouseEvent.MOUSE_UP:
                if (_hasOnMouseUp == false) {
                    listen(null, onMouseUp, null, null, null);
                    _hasOnMouseUp = true;
                }
            case MouseEvent.MOUSE_MOVE:
                if (_hasOnMouseMove == false) {
                    listen(null, null, onMouseMove, null, null);
                    _hasOnMouseMove = true;
                }
            case MouseEvent.MOUSE_WHEEL:
                if (_hasOnMouseWheel == false) {
                    listen(null, null, null, onMouseWheel, null);
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
        if (!isInitialized()) {
            if (_cachedCallbacks != null) {
                var itemToRemove = null;
                for (item in _cachedCallbacks) {
                    if (item.event == event && item.callback == callback) {
                        itemToRemove = item;
                        break;
                    }
                }
                if (itemToRemove != null) {
                    _cachedCallbacks.remove(itemToRemove);
                }
            }
            return;
        }

        var list = _callbacks.get(event);
        if (list != null) {
            list.remove(callback);
            if (list.length == 0) {
                _callbacks.remove(event);

                switch (event) {
                    case MouseEvent.MOUSE_DOWN:
                        if (_hasOnMouseDown == true) {
                            unlisten(onMouseDown, null, null, null, null);
                            _hasOnMouseDown = false;
                        }
                    case MouseEvent.MOUSE_UP:
                        if (_hasOnMouseUp == true) {
                            unlisten(null, onMouseUp, null, null, null);
                            _hasOnMouseUp = false;
                        }
                    case MouseEvent.MOUSE_MOVE:
                        if (_hasOnMouseMove == true) {
                            unlisten(null, null, onMouseMove, null, null);
                            _hasOnMouseMove = false;
                        }
                    case MouseEvent.MOUSE_WHEEL:
                        if (_hasOnMouseWheel == true) {
                            unlisten(null, null, null, onMouseWheel, null);
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