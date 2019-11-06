package haxe.ui.backend;

import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import kha.Display;
import kha.System;
import kha.graphics2.Graphics;
import kha.input.Mouse;

class ScreenImpl extends ScreenBase {
    private var _mapping:Map<String, UIEvent->Void>;

    public function new() {
        _mapping = new Map<String, UIEvent->Void>();
    }

    public override function get_width():Float {
        return System.windowWidth() / Toolkit.scaleX;
    }

    public override function get_height() {
        return System.windowHeight() / Toolkit.scaleY;
    }

    private override function get_dpi():Float {
        return Display.primary.pixelsPerInch;
    }

    private override function get_title():String {
        #if js
        return js.Browser.document.title;
        #else
        trace("WARNING: this platform doesnt support dynamic titles");
        return "";
        #end
    }
    private override function set_title(s:String):String {
        #if js
        js.Browser.document.title = s;
        return s;
        #else
        trace("WARNING: this platform doesnt support dynamic titles");
        return "";
        #end
    }

    public override function addComponent(component:Component) {
        _topLevelComponents.push(component);
        resizeComponent(component);
        //component.dispatchReady();
    }

    public override function removeComponent(component:Component) {
        _topLevelComponents.remove(component);
    }

    public function renderTo(g:Graphics) {
        for (c in _topLevelComponents) {
            if (Toolkit.scaleX == 1 && Toolkit.scaleY == 1) {
                c.renderTo(g);
            } else {
                c.renderToScaled(g, Toolkit.scaleX, Toolkit.scaleY);
            }
        }
    }

    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private override function supportsEvent(type:String):Bool {
        if (type == MouseEvent.MOUSE_MOVE
            || type == MouseEvent.MOUSE_DOWN
            || type == MouseEvent.MOUSE_UP) {
                return true;
            }
        return false;
    }

    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    Mouse.get().notify(null, null, __onMouseMove, null);
                }
            case MouseEvent.MOUSE_DOWN:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    Mouse.get().notify(__onMouseDown, null, null, null);
                }
            case MouseEvent.MOUSE_UP:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    Mouse.get().notify(null, __onMouseUp, null, null);
                }
        }

    }

    private override function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                _mapping.remove(type);
                Mouse.get().remove(null, null, __onMouseMove, null);
            case MouseEvent.MOUSE_DOWN:
                _mapping.remove(type);
                Mouse.get().remove(__onMouseDown, null, null, null);
            case MouseEvent.MOUSE_UP:
                _mapping.remove(type);
                Mouse.get().remove(null, __onMouseUp, null, null);
        }
    }

    private function __onMouseMove(x:Int, y:Int, movementX:Int, movementY:Int) {
        if (_mapping.exists(MouseEvent.MOUSE_MOVE) == false) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);
        mouseEvent.screenX = x / Toolkit.scaleX;
        mouseEvent.screenY = y / Toolkit.scaleY;
        _mapping.get(haxe.ui.events.MouseEvent.MOUSE_MOVE)(mouseEvent);
    }

    private function __onMouseDown(button:Int, x:Int, y:Int) {
        if (_mapping.exists(MouseEvent.MOUSE_DOWN) == false) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_DOWN);
        mouseEvent.screenX = x / Toolkit.scaleX;
        mouseEvent.screenY = y / Toolkit.scaleY;
        _mapping.get(haxe.ui.events.MouseEvent.MOUSE_DOWN)(mouseEvent);
    }

    private function __onMouseUp(button:Int, x:Int, y:Int) {
        if (_mapping.exists(MouseEvent.MOUSE_UP) == false) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_UP);
        mouseEvent.screenX = x / Toolkit.scaleX;
        mouseEvent.screenY = y / Toolkit.scaleY;
        _mapping.get(MouseEvent.MOUSE_UP)(mouseEvent);
    }
}
