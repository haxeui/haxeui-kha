package haxe.ui.backend;

import kha.Scheduler;

class TimerImpl {
    private var _timerId:Int = -1;
    private var _stopped:Bool = false;  //Needed if the stop method is called in the callback execution

    public function new(delay:Int, callback:Void->Void) {
        _timerId = Scheduler.addBreakableTimeTaskToGroup(0, function() {
            if (_stopped == false) {
                callback();
            }

            return !_stopped;
        }, delay / 1000, 0, 0);
    }

    public function stop() {
        _stopped = true;
        Scheduler.removeTimeTask(_timerId);
    }
}