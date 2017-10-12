package haxe.ui.backend;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.DialogButton;
import haxe.ui.core.Component;
import haxe.ui.core.MouseEvent;
import haxe.ui.core.UIEvent;
import kha.input.Mouse;
import kha.System;
import kha.graphics2.Graphics;

class ScreenBase {
    private var _mapping:Map<String, UIEvent->Void>;

    public function new() {
        _mapping = new Map<String, UIEvent->Void>();
    }

    public var options(default, default):Dynamic;

    public var width(get, null):Float;
    public function get_width():Float {
        return System.windowWidth();
    }

    public var height(get, null):Float;
    public function get_height() {
        return System.windowHeight();
    }

    public var dpi(get, null):Float;
    private function get_dpi():Float {
        return System.screenDpi();
    }

    public var focus(get, set):Component;
    private function get_focus():Component {
        return null;
    }
    private function set_focus(value:Component):Component {
        return value;
    }

    public var title(get,set):String;
    private inline function get_title():String {
        #if js
        return js.Browser.document.title;
        #else
        trace("WARNING: this platform doesnt support dynamic titles");
        return "";
        #end
    }
    private inline function set_title(s:String):String {
        #if js
        js.Browser.document.title = s;
        return s;
        #else
        trace("WARNING: this platform doesnt support dynamic titles");
        return "";
        #end
    }

    private var _topLevelComponents:Array<Component> = new Array<Component>();
    public function addComponent(component:Component) {
        _topLevelComponents.push(component);
        resizeComponent(component);
        //component.dispatchReady();
    }

    public function removeComponent(component:Component) {
        _topLevelComponents.remove(component);
    }

    private function resizeComponent(c:Component) {
        if (c.percentWidth > 0) {
            c.width = (this.width * c.percentWidth) / 100;
        }
        if (c.percentHeight > 0) {
            c.height = (this.height * c.percentHeight) / 100;
        }
    }

    public function renderTo(g:Graphics) {
        for (c in _topLevelComponents) {
            c.renderTo(g);
        }
    }

    private function handleSetComponentIndex(child:Component, index:Int) {
    }

    //***********************************************************************************************************
    // Dialogs
    //***********************************************************************************************************
    public function messageDialog(message:String, title:String = null, options:Dynamic = null, callback:DialogButton->Void = null):Dialog {
        return null;
    }

    public function showDialog(content:Component, options:Dynamic = null, callback:DialogButton->Void = null):Dialog {
        return null;
    }

    public function hideDialog(dialog:Dialog):Bool {
        return false;
    }


    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private function supportsEvent(type:String):Bool {
        if (type == MouseEvent.MOUSE_MOVE
            || type == MouseEvent.MOUSE_DOWN
            || type == MouseEvent.MOUSE_UP) {
                return true;
            }
        return false;
    }

    private function mapEvent(type:String, listener:UIEvent->Void) {
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

    private function unmapEvent(type:String, listener:UIEvent->Void) {
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
        _mapping.get(haxe.ui.core.MouseEvent.MOUSE_MOVE)(mouseEvent);
    }

    private function __onMouseDown(button:Int, x:Int, y:Int) {
        if (_mapping.exists(MouseEvent.MOUSE_DOWN) == false) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_DOWN);
        mouseEvent.screenX = x / Toolkit.scaleX;
        mouseEvent.screenY = y / Toolkit.scaleY;
        _mapping.get(haxe.ui.core.MouseEvent.MOUSE_DOWN)(mouseEvent);
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
