package save;

import haxe.ds.IntMap;
import hxbit.Serializable;

class GameData implements Serializable {
    @:s public var levelsCompleted(default, null) : IntMap<Bool> = new IntMap<Bool>();

    public function new() {
        init();
    }

    public function init() {
        for(i in 0...Title.LEVEL_COUNT) {
            levelsCompleted.set(i + 1, false);
        }
        #if debug
        levelsCompleted.set(1, true);
        levelsCompleted.set(2, true);
        #end
    }

    public function completeLevel(id:Int) {
        levelsCompleted.set(id, true);
        Save.saveGame();
    }
}