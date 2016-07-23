package haxe.ui.backend;

import kha.Scheduler;

class TimerBase {
    private var _timerId:Int;

    public function new(delay:Int, callback:Void->Void) {
        _timerId = Scheduler.addTimeTask(callback, 0, delay / 1000);
    }

    public function stop() {
        Scheduler.removeTimeTask(_timerId);
    }
}