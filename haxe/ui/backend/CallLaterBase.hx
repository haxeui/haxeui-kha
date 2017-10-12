package haxe.ui.backend;

import kha.Scheduler;

class CallLaterBase {
    public function new(fn:Void->Void) {
        Scheduler.addFrameTask(fn, 0);
    }
}