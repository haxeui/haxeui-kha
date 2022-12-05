package haxe.ui.backend.kha.stylers;

import haxe.ui.styles.Style;
import kha.graphics2.Graphics;

class SdfStyler {
    // placholder for now, will eventually use sdf shaders to do round / gradient shapes
    public static function paintStyle(g:Graphics, style:Style, x:Float, y:Float, w:Float, h:Float):Void {
        DefaultStyler.paintStyle(g, style, x, y, w, h);
    }
}