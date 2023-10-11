package save;

import haxe.ds.IntMap;
import hxbit.Serializable;

class GameData implements Serializable {
    @:s public var levelsCompleted(default, null) : IntMap<Bool> = new IntMap<Bool>();
    @:s public var levelsCompletedShown(default, null) : IntMap<Bool> = new IntMap<Bool>();

    public function new() {
        init();
    }

    public function init() {
        for(i in 1...Title.LEVEL_COUNT + 1) {
            levelsCompleted.set(i, false);
            levelsCompletedShown.set(i, false);
        }
        #if debug
        /*for(i in 1...Title.LEVEL_COUNT + 1) {
            levelsCompleted.set(i, false);
        }*/
        #end
    }

    public function completeLevel(id:Int) {
        levelsCompleted.set(id, true);
        Save.saveGame();
    }
    public function showCompletedLevel(id:Int) {
        levelsCompletedShown.set(id, true);
        Save.saveGame();
    }
}