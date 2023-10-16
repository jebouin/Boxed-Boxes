package save;

import haxe.ds.IntMap;
import hxbit.Serializable;
#if int_ng
import integration.Newgrounds;
#end

class GameData implements Serializable {
    public static inline var SAVE_COOLDOWN = 1.;
    @:s public var levelsCompleted(default, null) : IntMap<Bool> = new IntMap<Bool>();
    @:s public var levelsCompletedShown(default, null) : IntMap<Bool> = new IntMap<Bool>();
    @:s public var musicEnabled(default, null) : Bool;
    @:s public var soundEnabled(default, null) : Bool;
    var timeSinceLevelCompletedShown : Float = 0;

    public function new() {
        init();
    }

    public function update(dt:Float) {
        var prev = timeSinceLevelCompletedShown;
        timeSinceLevelCompletedShown += dt;
        if(prev <= SAVE_COOLDOWN && timeSinceLevelCompletedShown > SAVE_COOLDOWN) {
            Save.saveGame();
        }
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
        timeSinceLevelCompletedShown = 0;
    }

    public function setMuteState(musicEnabled:Bool, soundEnable:Bool) {
        this.musicEnabled = musicEnabled;
        this.soundEnabled = soundEnable;
        Save.saveGame();
    }
}