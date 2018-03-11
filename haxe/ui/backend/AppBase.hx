package haxe.ui.backend;

import haxe.ui.util.ColorUtil;
import haxe.ui.Preloader.PreloadItem;
import haxe.ui.core.Screen;
import kha.Image;
import kha.Scaler;
import kha.Scheduler;
import kha.ScreenRotation;
import kha.System;
import kha.Framebuffer;
import kha.Assets;

class AppBase {
    private var _callback:Void->Void;
    private var _backgroudColor:Int = 0;
    public function new() {

    }

    private function build() {

    }

    private function init(callback:Void->Void, onEnd:Void->Void = null) {
        _callback = callback;
        var title:String = Toolkit.backendProperties.getProp("haxe.ui.kha.title", "");
        var width:Int = Toolkit.backendProperties.getPropInt("haxe.ui.kha.width", 800);
        var height:Int = Toolkit.backendProperties.getPropInt("haxe.ui.kha.height", 600);
        _backgroudColor = ColorUtil.parseColor(Toolkit.backendProperties.getProp("haxe.ui.kha.background.color", "0xFFFFFF"));
        System.init( { title: title, width: width, height: height }, initialized);
    }

    private function initialized() {
        Assets.loadEverything(assetsLoaded);
    }

    private function assetsLoaded() {
        System.notifyOnRender(render);
        _callback();
    }

    public function render(framebuffer:Framebuffer):Void {

        var g = framebuffer.g2;
        g.begin(true, _backgroudColor);

        for (c in Screen.instance.rootComponents) {
            if (Toolkit.scaleX == 1 && Toolkit.scaleY == 1) {
                c.renderTo(g);
            } else {
                c.renderToScaled(g, Toolkit.scaleX, Toolkit.scaleY);
            }
        }

        g.end();
    }

    private function getToolkitInit():Dynamic {
        return {
        };
    }

    public function start() {

    }
    
    private function buildPreloadList():Array<PreloadItem> {
        return [];
    }
}