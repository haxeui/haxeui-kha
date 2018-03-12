package haxe.ui.backend;

import kha.Scheduler;

class CallLaterBase extends TimerBase {
    public function new(fn:Void->Void) {
        super(0, function() {
            stop();
            fn();
        });
    }
}