package haxe.ui.backend;

import kha.Scheduler;

class CallLaterImpl {
    public function new(fn:Void->Void) {
        Scheduler.addTimeTask(fn, 0.001);
    }
}