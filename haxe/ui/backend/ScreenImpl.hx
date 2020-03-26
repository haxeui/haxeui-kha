package haxe.ui.backend;

import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import kha.Assets;
import kha.Color;
import kha.Display;
import kha.Font;
import kha.Scheduler;
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

    public override function addComponent(component:Component):Component {
        _topLevelComponents.push(component);
        resizeComponent(component);
        //component.dispatchReady();
		return component;
    }

    public override function removeComponent(component:Component):Component {
        _topLevelComponents.remove(component);
		return component;
    }

    public function renderTo(g:Graphics) {
        for (c in _topLevelComponents) {
            c.renderTo(g);
        }
        updateFPS(g);
    }

    private var _deltaTime:Float;
    private var _lastTime:Float;
    public var fps:Float = 0;
    private var _fpsFont:Font = null;
    private function updateFPS(g:Graphics) {
        var currentTime = Scheduler.time();
        _deltaTime = currentTime - _lastTime;
        _lastTime = currentTime;
        var nFps = 1.0 / _deltaTime;
        if (Math.isFinite(nFps)) {
            fps = Math.round(nFps);
        }

        var showFPS = options != null ? options.showFPS : false;
        #if haxeui_show_fps
        var showFPS = true;
        #end
        if (showFPS == true) {
            g.color = Color.Black;
            if (_fpsFont == null) {
                _fpsFont = Font.fromBytes(Resource.getBytes("styles/default/arial.ttf"));
            }
            g.font = _fpsFont;
            g.fontSize = Std.int(14 * Toolkit.scale);
            var fpsString = "FPS: " + fps;
            var cy = _fpsFont.height(g.fontSize) + 3;
            var cx = _fpsFont.width(g.fontSize, fpsString) + 6;
            g.fillRect(0, 0, cx, cy);
            g.color = Color.White;
            g.drawString(fpsString, 2, 2);
            g.font = null;
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
