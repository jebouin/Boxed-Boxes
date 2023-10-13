package save;

import haxe.ds.IntMap;
import hxbit.Serializable;
#if int_ng
import integration.Newgrounds;
#end

class GameData implements Serializable {
    @:s public var levelsCompleted(default, null) : IntMap<Bool> = new IntMap<Bool>();
    @:s public var levelsCompletedShown(default, null) : IntMap<Bool> = new IntMap<Bool>();
    @:s public var musicEnabled(default, null) : Bool;
    @:s public var soundEnabled(default, null) : Bool;

    public function new() {
        init();
    }

    public function init() {
        musicEnabled = soundEnabled = true;
        for(i in 1...Title.LEVEL_COUNT + 1) {
            levelsCompleted.set(i, false);
            levelsCompletedShown.set(i, false);
        }
        #if debug
        /*for(i in 1...Title.LEVEL_COUNT + 1) {
            levelsCompleted.set(i, Std.random(2) == 0);
            levelsCompletedShown.set(i, false);
        }*/
        #end
    }

    public function completeLevel(id:Int) {
        levelsCompleted.set(id, true);
        Save.saveGame();
        #if int_ng
        Newgrounds.checkMedals();
        #end
    }
    public function showCompletedLevel(id:Int) {
        levelsCompletedShown.set(id, true);
        Save.saveGame();
    }

    public function setMuteState(musicEnabled:Bool, soundEnable:Bool) {
        this.musicEnabled = musicEnabled;
        this.soundEnabled = soundEnable;
        Save.saveGame();
    }
}