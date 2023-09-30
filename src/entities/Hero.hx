package entities;

import h2d.col.IBounds;
import h2d.Bitmap;
import Controller;

enum Facing {
    None;
    Up;
    Right;
    Down;
    Left;
}

class Hero extends Entity {
    public static inline var MOVE_VEL = 90.;
    public static inline var FALL_VEL = 180;
    public static inline var FALL_FAST_VEL = 150;
    public static inline var AIR_FRICTION_X = .995;
    public static inline var GRAVITY = .996;
    public static inline var GRAVITY_JUMP = .93;
    public static inline var GRAVITY_FAST = .9993;
    public static inline var JUMP_VEL = 290.;
    public static inline var JUMP_COYOTE_TIME = .1;
    public static inline var JUMP_BUFFER_TIME = .15;
    var bitmap : Bitmap;
    public var eyeOffsetX(default, null) = 0;
    public var eyeOffsetY(default, null) = 0;
    var groundTimer : Float;
    var jumpBufferTimer : Float;
    var prevFacing : Facing;

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
        vx = vy = 0.;
        groundTimer = 0.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        prevFacing = None;
        updateGraphics();
        updateBorder();
    }

    override public function delete() {
        bitmap.remove();
        super.delete();
    }

    override public function update(dt:Float) {
        var onGround = hitDown;
        var controller = Main.inst.controller;
        var ca = controller.getAnalogAngleXY(Action.moveX, Action.moveY), cd = controller.getAnalogDistXY(Action.moveX, Action.moveY);
        var facing = None;
        if(cd > .5) {
            if(Util.fabs(ca + Math.PI * .5) <= Math.PI * .25) {
                facing = Up;
            } else if(Util.fabs(ca) <= Math.PI * .25) {
                facing = Right;
                bitmap.scaleX = 1;
            } else if(Util.fabs(ca - Math.PI * .5) <= Math.PI * .25) {
                facing = Down;
            } else {
                facing = Left;
                bitmap.scaleX = -1;
            }
        }
        var fastFall = facing == Down;
        if(facing == Left) {
            vx = -MOVE_VEL;
        } else if(facing == Right) {
            vx = MOVE_VEL;
        } else {
            vx = onGround || fastFall ? 0 : Util.sodStep(vx, 0, AIR_FRICTION_X, dt);
        }
        if(onGround) {
            groundTimer = 0.;
        } else {
            groundTimer += dt;
            jumpBufferTimer += dt;
        }
        var jumping = vy < 0 && controller.isDown(Action.jump);
        if(vy < 0 && controller.isReleased(Action.jump)) {
            vy *= .5;
        }
        var jumped = false;
        if(controller.isPressed(Action.jump)) {
            if(jump()) {
                jumped = true;
            } else {
                jumpBufferTimer = 0.;
            }
        } else if(onGround && controller.isDown(Action.jump) && jumpBufferTimer <= JUMP_BUFFER_TIME) {
            jumped = jump();
        }
        vy = Util.sodStep(vy, fastFall ? FALL_FAST_VEL : FALL_VEL, fastFall ? GRAVITY_FAST : (jumping ? GRAVITY_JUMP : GRAVITY), dt);
        super.update(dt);
        updateGraphics();
    }

    function jump() {
        if(groundTimer > JUMP_COYOTE_TIME) return false;
        groundTimer = JUMP_COYOTE_TIME + 1.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        vy = -JUMP_VEL;
        return true;
    }

    function updateGraphics() {
        bitmap.x = x + (bitmap.scaleX < 0 ? bitmap.tile.iwidth : 0);
        bitmap.y = y;
    }
}