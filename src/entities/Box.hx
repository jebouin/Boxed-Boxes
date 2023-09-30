package entities;

import h2d.col.IBounds;
import h3d.shader.SpecularTexture;
import h2d.Bitmap;

class Box extends Entity {
    var bitmap : Bitmap;

    public function new(x:Int, y:Int) {
        super();
        bitmap = new Bitmap(Assets.getTile("entities", "box"));
        Game.inst.world.add(bitmap, Game.LAYER_ENTITIES);
        this.x = x;
        this.y = y;
        updateGraphics();
        collisionEnabled = true;
        hitbox = IBounds.fromValues(0, 0, bitmap.tile.iwidth, bitmap.tile.iheight);
    }

    override public function delete() {
        super.delete();
        bitmap.remove();
    }

    override public function update(dt:Float) {
        super.update(dt);
        updateGraphics();
    }

    function updateGraphics() {
        bitmap.x = x;
        bitmap.y = y;
    }
}