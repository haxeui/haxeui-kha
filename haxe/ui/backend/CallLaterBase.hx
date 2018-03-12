package haxe.ui.backend;

import kha.Scheduler;

class CallLaterBase {
    public function new(fn:Void->Void) {
        haxe.Timer.delay(function() {
            Scheduler.addTimeTask(fn, 0);
        }, 1); //Avoids infinite loop execution in `Kha.Scheduler.executeTimeTasks` if `callLater` is called from another callLater's callback
    }
}