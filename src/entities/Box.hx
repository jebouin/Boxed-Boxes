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
        grid = new ScaleGrid(Assets.getTile("entities", "boxInside"), 6, 6, 6, 6);
        grid.width = width;
        grid.height = height;
        Game.inst.world.add(grid, Game.LAYER_ENTITIES);
        this.x = x;
        this.y = y;
        updateGraphics();
        collisionEnabled = true;
        setHitbox(hitbox = IBounds.fromValues(0, 0, width, height));
        updateBorderConstraint();
        grid.tile = Assets.getTile("entities", "box" + (isInside ? "Inside" : "Outside"));
    }

    override public function delete() {
        super.delete();
        grid.remove();
    }

    override public function updateBeforeMove(dt:Float) {
        vy = Util.sodStep(vy, FALL_VEL, GRAVITY, dt);
        super.updateBeforeMove(dt);
    }

    override public function updateAfterMove(dt:Float) {
        super.updateAfterMove(dt);
        updateGraphics();
    }

    function updateGraphics() {
        grid.x = x;
        grid.y = y;
    }

    override function onBorderConstraintFixed() {
        die(0, 0);
    }

    override public function toString() {
        return "Box " + id + " at (" + (x + hitbox.xMin) + ", " + (y + hitbox.yMin) + ") to (" + (x + hitbox.xMax) + ", " + (y + hitbox.yMax) + ")";
    }
}