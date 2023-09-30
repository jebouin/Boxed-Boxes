package entities;

import h2d.ScaleGrid;
import h2d.col.IBounds;
import h3d.shader.SpecularTexture;
import h2d.Bitmap;

class Box extends Entity {
    public static inline var FALL_VEL = 180;
    public static inline var GRAVITY = .996;
    var grid : ScaleGrid;

    public function new(x:Int, y:Int, width:Int, height:Int) {
        super();
        grid = new ScaleGrid(Assets.getTile("entities", "box"), 6, 6, 6, 6);
        grid.width = width;
        grid.height = height;
        Game.inst.world.add(grid, Game.LAYER_ENTITIES);
        this.x = x;
        this.y = y;
        updateGraphics();
        collisionEnabled = true;
        hitbox = IBounds.fromValues(0, 0, width, height);
    }

    override public function delete() {
        super.delete();
        grid.remove();
    }

    override public function update(dt:Float) {
        vy = Util.sodStep(vy, FALL_VEL, GRAVITY, dt);
        super.update(dt);
        updateGraphics();
    }

    function updateGraphics() {
        grid.x = x;
        grid.y = y;
    }
}