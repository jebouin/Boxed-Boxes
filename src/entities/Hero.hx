package entities;

import h2d.col.IBounds;
import h2d.Bitmap;
import Controller;

class Hero extends Entity {
    var bitmap : Bitmap;
    public var eyeOffsetX(default, null) = 0;
    public var eyeOffsetY(default, null) = 0;

    public function new() {
        super();
        bitmap = new Bitmap(Assets.getTile("entities", "hero"));
        Game.inst.world.add(bitmap, Game.LAYER_HERO);
        collisionEnabled = canPushBorder = canPushEntities = true;
        hitbox = IBounds.fromValues(0, 0, bitmap.tile.iwidth, bitmap.tile.iheight);
    }

    public function spawn() {
        x = Game.inst.level.heroSpawnX;
        y = Game.inst.level.heroSpawnY;
        Game.inst.border.initPosition();
        updateGraphics();
    }

    override public function delete() {
        bitmap.remove();
        super.delete();
    }

    override public function update(dt:Float) {
        var controller = Main.inst.controller;
        var controllerAngle = controller.getAnalogAngleXY(Action.moveX, Action.moveY);
        var controllerDist = controller.getAnalogDistXY(Action.moveX, Action.moveY);
        var cx = controllerDist * Math.cos(controllerAngle), cy = controllerDist * Math.sin(controllerAngle);
        move(120 * cx * dt, 120 * cy * dt);
        super.update(dt);
        updateGraphics();
    }

    function updateGraphics() {
        bitmap.x = x;
        bitmap.y = y;
    }
}