package haxe.ui.backend;

import haxe.ui.core.Component;

@:enum @:unreflective
enum BatchOperation {
    DrawStyle(c:ComponentImpl);
    DrawImage(c:ComponentImpl);
    DrawText(c:ComponentImpl);
    DrawCustom(c:ComponentImpl);
    ApplyScissor(x:Int, y:Int, w:Int, h:Int);
    ClearScissor;
}
