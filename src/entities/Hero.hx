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
    public static inline var FALL_FAST_VEL = 300;
    public static inline var FALL_WALL_VEL = 90;
    public static inline var AIR_FRICTION_X = .999;
    public static inline var GRAVITY = .996;
    public static inline var GRAVITY_JUMP = .93;
    public static inline var GRAVITY_FAST = .9993;
    public static inline var JUMP_VEL = 290.;
    public static inline var JUMP_COYOTE_TIME = .1;
    public static inline var JUMP_BUFFER_TIME = .15;
    public static inline var WALL_JUMP_DIST = 2;
    public static inline var WALL_JUMP_VEL_Y = 250.;
    public static inline var WALL_JUMP_VEL_X = 170.;
    public static inline var WALL_JUMP_TIME = .3;
    public static inline var WALL_JUMP_ACC_X = .9;
    public static inline var WALL_JUMP_FRICTION_X = .997;
    public static inline var WALL_JUMP_COYOTE_TIME = .1;
    var bitmap : Bitmap;
    public var eyeOffsetX(default, null) = 0;
    public var eyeOffsetY(default, null) = 0;
    var groundTimer : Float;
    var wallLeftTimer : Float;
    var wallRightTimer : Float;
    var jumpBufferTimer : Float;
    var wallJumpTimer : Float;
    var prevFacing : Facing;

    public function new() {
        super();
        bitmap = new Bitmap(Assets.getTile("entities", "hero"));
        Game.inst.world.add(bitmap, Game.LAYER_HERO);
        collisionEnabled = canPushBorder = canPushEntities = true;
        setHitbox(IBounds.fromValues(0, 0, bitmap.tile.iwidth, bitmap.tile.iheight));
        movementType = Alternate;
    }

    public function spawn() {
        x = Game.inst.level.heroSpawnX;
        y = Game.inst.level.heroSpawnY;
        vx = vy = 0.;
        groundTimer = wallLeftTimer = wallRightTimer = 0.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        wallJumpTimer = WALL_JUMP_TIME + 1.;
        prevFacing = None;
        updateGraphics();
    }

    override public function delete() {
        bitmap.remove();
        super.delete();
    }

    override public function update(dt:Float) {
        // TODO: Use wall jump dist
        var onGround = hitDown, wallLeft = hitLeft, wallRight = hitRight;
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
        var sliding = !fastFall && ((facing == Left && wallLeft) || (facing == Right && wallRight)) && vy > 0;
        wallJumpTimer += dt;
        var wallJumping = wallJumpTimer <= WALL_JUMP_TIME;
        if(wallJumping) {
            var t = wallJumpTimer / WALL_JUMP_TIME;
            var moveAcc = Util.lerp(WALL_JUMP_ACC_X, 1., t);
            var frictionX = Util.lerp(WALL_JUMP_FRICTION_X, onGround ? 1. : AIR_FRICTION_X, t);
            if(facing == Left) {
                vx = Util.sodStep(vx, -MOVE_VEL, moveAcc, dt);
            } else if(facing == Right) {
                vx = Util.sodStep(vx, MOVE_VEL, moveAcc, dt);
            } else {
                vx = Util.sodStep(vx, 0, frictionX, dt);
            }
        } else {
            if(facing == Left) {
                vx = -MOVE_VEL;
            } else if(facing == Right) {
                vx = MOVE_VEL;
            } else {
                vx = onGround || fastFall ? 0 : Util.sodStep(vx, 0, AIR_FRICTION_X, dt);
            }
        }
        if(onGround) {
            groundTimer = 0.;
        } else {
            groundTimer += dt;
            jumpBufferTimer += dt;
        }
        if(wallLeft) wallLeftTimer = 0.;
        else wallLeftTimer += dt;
        if(wallRight) wallRightTimer = 0.;
        else wallRightTimer += dt;
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
        if(!jumped && !onGround) {
            if(controller.isPressed(Action.jump) || (controller.isDown(Action.jump) && jumpBufferTimer <= JUMP_BUFFER_TIME)) {
                if(wallLeftTimer < wallRightTimer) {
                    if(wallLeft || (vy > 0 && wallLeftTimer < WALL_JUMP_COYOTE_TIME)) {
                        wallJump(1);
                    }
                } else {
                    if(wallRight || (vy > 0 && wallRightTimer < WALL_JUMP_COYOTE_TIME)) {
                        wallJump(-1);
                    }
                }
            }
        }
        vy = Util.sodStep(vy, fastFall ? FALL_FAST_VEL : (sliding ? FALL_WALL_VEL : FALL_VEL), fastFall ? GRAVITY_FAST : (jumping ? GRAVITY_JUMP : GRAVITY), dt);
        if(sliding) {
            vy = Util.sodStep(vy, 0, .99, dt);
        }
        super.update(dt);
        for(g in Gem.all) {
            if(g.collides(this)) {
                Audio.playSound("gem");
                Game.inst.levelComplete();
            }
        }
        var dir = Game.inst.level.entityTouchesDeath(this);
        var len : Float = dir.dx * dir.dx + dir.dy * dir.dy;
        if(len > 0) {
            len = Math.sqrt(len);
            die(dir.dx / len, dir.dy / len);
        }
        updateGraphics();
    }
    
    public override function die(dx:Float, dy:Float) {
        super.die(dx, dy);
        Game.inst.onDeath(dx, dy);
        Audio.playSound("death", false, .5);
    }

    function jump() {
        if(groundTimer > JUMP_COYOTE_TIME) return false;
        groundTimer = JUMP_COYOTE_TIME + 1.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        vy = -JUMP_VEL;
        Audio.playSound("jump", false, .3);
        return true;
    }
    function wallJump(dx:Int) {
        vx = WALL_JUMP_VEL_X * dx;
        vy = -WALL_JUMP_VEL_Y;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        wallJumpTimer = 0.;
        Audio.playSound("wallJump", false, .3);
        return true;
    }

    function updateGraphics() {
        bitmap.x = x + (bitmap.scaleX < 0 ? bitmap.tile.iwidth : 0);
        bitmap.y = y;
    }
}