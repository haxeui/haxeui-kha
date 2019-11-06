package haxe.ui.backend;

import haxe.ui.core.Screen;
import haxe.ui.util.ColorUtil;
import kha.Assets;
import kha.Framebuffer;
import kha.System;

class AppImpl extends AppBase {
    private var _callback:Void->Void;
    private var _backgroudColor:Int = 0;
    
    public function new() {
    }
    
    private override function init(callback:Void->Void, onEnd:Void->Void = null) {
        _callback = callback;
        var title:String = Toolkit.backendProperties.getProp("haxe.ui.kha.title", "");
        var width:Int = Toolkit.backendProperties.getPropInt("haxe.ui.kha.width", 800);
        var height:Int = Toolkit.backendProperties.getPropInt("haxe.ui.kha.height", 600);
        
        #if js
        var canvas = cast(js.Browser.document.getElementById('khanvas'), js.html.CanvasElement);
        canvas.width = width;
        canvas.height = height;      
        #end
        
        _backgroudColor = ColorUtil.parseColor(Toolkit.backendProperties.getProp("haxe.ui.kha.background.color", "0xFFFFFF"));
        System.start( { title: title, width: width, height: height }, initialized);
    }

    private function initialized(_) {
        Assets.loadEverything(assetsLoaded);
    }

    private function assetsLoaded() {
        System.notifyOnFrames(render);
        _callback();
    }

    public function render(framebuffers:Array<Framebuffer>):Void {

        var g = framebuffers[0].g2;
        g.begin(true, _backgroudColor);
        Screen.instance.renderTo(g);
        g.end();
    }
}