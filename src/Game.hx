package ;

import SceneManager.Scene;

class Game extends Scene {
    public static var inst : Game;

    public function new() {
        super();
        if(inst != null) {
            throw "Game scene already exists";
        }
        inst = this;
    }

    override public function delete() {
        super.delete();
        inst = null;
    }

    override public function update(dt:Float) {
        super.update(dt);
        trace("UPDATE");
    }
}