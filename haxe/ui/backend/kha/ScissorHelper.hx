package haxe.ui.backend.kha;

import haxe.ui.geom.Rectangle;
import kha.graphics2.Graphics;

typedef ScissorEntry = {
    var g:Graphics;
    var rect:Rectangle;
}

class ScissorHelper {
    private static var _stack:Array<ScissorEntry> = new Array<ScissorEntry>();
    private static var _pos:Int = 0;
     
    public static function pushScissor(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
        if (_pos + 1 > _stack.length) {
            _stack.push({
                g: null,
                rect: new Rectangle(),
            });
        }
        var entry = _stack[_pos];
        entry.g = g;
        entry.rect.set(x, y, w, h);
        _pos++;
        
        applyScissor(g, x, y, w, h);
    }
    
    public static function popScissor():Void {
        _pos--;
        var g = _stack[_pos].g;
        _stack[_pos].g = null;
        if (_pos == 0) {
            g.disableScissor();
        } else {
            var entry = _stack[_pos - 1];
            applyScissor(entry.g, Std.int(entry.rect.left), Std.int(entry.rect.top), Std.int(entry.rect.width), Std.int(entry.rect.height));
        }
    }
    
    private static var _cacheRect:Rectangle = new Rectangle();
    private static function applyScissor(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
        if (_pos > 1) {
            var entry = _stack[_pos - 2];
            _cacheRect.set(x, y, w, h);
            var intersection = entry.rect.intersection(_cacheRect);
            x = Std.int(intersection.left);
            y = Std.int(intersection.top);
            w = Std.int(intersection.width);
            h = Std.int(intersection.height);
            if (x < entry.rect.left) {
                x = Std.int(entry.rect.left);
            }
            if (y < entry.rect.top) {
                y = Std.int(entry.rect.top);
            }
        }
        g.scissor(x, y, w, h);
    }
}    
