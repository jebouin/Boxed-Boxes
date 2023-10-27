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
    @:s public var levelBestTimes(default, null) : IntMap<Int> = new IntMap<Int>();
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
            levelBestTimes.set(i, -1);
        }
        #if debug
        /*for(i in 1...Title.LEVEL_COUNT + 1) {
            levelsCompleted.set(i, Std.random(2) == 0);
            levelsCompletedShown.set(i, false);
        }*/
        #end
    }

    public function completeLevel(id:Int, playTimer:Int) {
        levelsCompleted.set(id, true);
        var curTimer = levelBestTimes.get(id);
        if(curTimer == null || curTimer == -1 || playTimer < curTimer) {
            levelBestTimes.set(id, playTimer);
        }
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

    public function areAllLevelsCompleted() {
        var count = 0;
        for(k in levelsCompleted.keys()) {
            if(levelsCompleted.get(k)) count++;
        }
        return count == Title.LEVEL_COUNT;
    }

    public function getLevelTimeSum() {
        var sum = 0;
        for(k in levelBestTimes.keys()) {
            var time = levelBestTimes.get(k);
            if(time != null && time != -1) sum += time;
        }
        return sum;
    }
}