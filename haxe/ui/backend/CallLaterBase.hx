package haxe.ui.backend;

import kha.Scheduler;

class CallLaterBase {
    public function new(fn:Void->Void) {
        Scheduler.addTimeTask(fn, 0);
    }
}