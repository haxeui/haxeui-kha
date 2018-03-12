package haxe.ui.backend;

import kha.Scheduler;

class TimerBase {
    private var _timerId:Int = -1;
    private var _stopped:Bool = false;  //Needed if the stop method is called in the callback execution

    public function new(delay:Int, callback:Void->Void) {
        _timerId = Scheduler.addBreakableTimeTaskToGroup(0, function() {
            if (_stopped == false) {
                callback();
            }

            return !_stopped;
        }, 0, delay / 1000);
    }

    public function stop() {
        _stopped = true;
        Scheduler.removeTimeTask(_timerId);
    }
}