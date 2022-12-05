package haxe.ui.backend.kha;

import haxe.ui.styles.Style;
import kha.graphics2.Graphics;

class StyleHelper {
    public static function paintStyle(g:Graphics, style:Style, x:Float, y:Float, w:Float, h:Float):Void {
        #if kha_sdf_painter
        haxe.ui.backend.kha.stylers.DefaultStyler.paintStyle(g, style, x, y, w, h);
        #else
        haxe.ui.backend.kha.stylers.DefaultStyler.paintStyle(g, style, x, y, w, h);
        #end
    }
}