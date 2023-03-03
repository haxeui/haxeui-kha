package haxe.ui.backend;

import haxe.ui.core.Component;
import haxe.ui.components.Canvas;

@:enum @:unreflective
enum BatchOperation {
    DrawStyle(c:ComponentImpl);
    DrawImage(c:ComponentImpl);
    DrawText(c:ComponentImpl);
    DrawCustom(c:ComponentImpl);
    DrawComponentGraphics(c:Canvas);
    ApplyScissor(x:Int, y:Int, w:Int, h:Int);
    ClearScissor;
}
