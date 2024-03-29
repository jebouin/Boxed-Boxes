package entities;

import ui.MouseInput;
import h2d.Graphics;
import h2d.col.IBounds;
import h2d.Bitmap;
import Controller;
import audio.Audio;

enum Facing {
    None;
    Up;
    Right;
    Down;
    Left;
}

class Hero extends Entity {
    public static inline var MOVE_VEL = 75.;
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
    public static inline var WALL_JUMP_FACE_TIME = .1;
    var anim : Anim;
    #if debug_collisions
    var debugGraphics : Graphics;
    #end
    public var eyeOffsetX(default, null) = 0;
    public var eyeOffsetY(default, null) = 0;
    var isOnGround : Bool = false;
    var hasWallLeft : Bool = false;
    var hasWallRight : Bool = false;
    var isSlidingAnim : Bool = false;
    var isSlidingPhysics : Bool = false;
    var groundTimer : Float;
    var wallLeftTimer : Float;
    var wallRightTimer : Float;
    var jumpBufferTimer : Float;
    var wallJumpTimer : Float;
    var faceLeftTimer : Float;
    var faceRightTimer : Float;
    var facing : Facing;
    var prevFacing : Facing;
    var prevTriedPushingHorizontal : Bool;
    var curAnimName : String;

    public function new() {
        super();
        anim = new Anim(Assets.getAnimData("entities", "heroRun").tiles, 20, true);
        Game.inst.world.add(anim, Game.LAYER_HERO);
        collisionEnabled = canPushBorders = canPushEntities = true;
        setHitbox(IBounds.fromValues(0, 0, Level.TS, 2 * Level.TS));
        #if debug_collisions
        debugGraphics = new Graphics();
        debugGraphics.beginFill(0xFFFFFF);
        debugGraphics.drawRect(hitbox.x, hitbox.y, hitbox.width, hitbox.height);
        debugGraphics.endFill();
        Game.inst.world.add(debugGraphics, Game.LAYER_DEBUG);
        #end
    }

    public function spawn() {
        x = Game.inst.level.heroSpawnX;
        y = Game.inst.level.heroSpawnY;
        vx = vy = 0.;
        groundTimer = wallLeftTimer = wallRightTimer = 0.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        wallJumpTimer = WALL_JUMP_TIME + 1.;
        faceLeftTimer = faceRightTimer = WALL_JUMP_FACE_TIME + 1.;
        prevFacing = None;
        updateGraphics();
    }

    override public function delete() {
        anim.remove();
        #if debug_collisions
        debugGraphics.remove();
        #end
        super.delete();
    }

    override public function updateBeforeMove(dt:Float) {
        // TODO: Check collision each frame
        var controller = Main.inst.controller, touchInput = Game.inst.touchInput, mouseInput = Game.inst.mouseInput;
        var ca = controller.getAnalogAngleXY(Action.moveX, Action.moveY), cd = controller.getAnalogDistXY(Action.moveX, Action.moveY);
        faceLeftTimer += dt;
        faceRightTimer += dt;
        facing = None;
        if(cd > .5) {
            if(Util.fabs(ca + Math.PI * .5) <= Math.PI * .25) {
                facing = Up;
            } else if(Util.fabs(ca) <= Math.PI * .25) {
                facing = Right;
            } else if(Util.fabs(ca - Math.PI * .5) <= Math.PI * .25) {
                facing = Down;
            } else {
                facing = Left;
            }
            Game.inst.onPlayerMoved();
        }
        if(touchInput.isLeftDown != touchInput.isRightDown) {
            facing = touchInput.isLeftDown ? Left : Right;
            Game.inst.onPlayerMoved();
        } else if(mouseInput.isLeftDown != mouseInput.isRightDown) {
            facing = mouseInput.isLeftDown ? Left : Right;
            Game.inst.onPlayerMoved();
        }
        if(facing == Right) {
            anim.scaleX = 1;
            faceRightTimer = 0;
        } else if(facing == Left) {
            anim.scaleX = -1;
            faceLeftTimer = 0;
        }
        var fastFall = facing == Down;
        isSlidingAnim = !fastFall && ((facing == Left && hasWallLeft) || (facing == Right && hasWallRight));
        isSlidingPhysics = isSlidingAnim && vy > 0;
        wallJumpTimer += dt;
        var wallJumping = wallJumpTimer <= WALL_JUMP_TIME;
        if(wallJumping) {
            var t = wallJumpTimer / WALL_JUMP_TIME;
            var moveAcc = Util.lerp(WALL_JUMP_ACC_X, 1., t);
            var frictionX = Util.lerp(WALL_JUMP_FRICTION_X, isOnGround ? 1. : AIR_FRICTION_X, t);
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
                vx = isOnGround || fastFall ? 0 : Util.sodStep(vx, 0, AIR_FRICTION_X, dt);
            }
        }
        if(isOnGround) {
            groundTimer = 0.;
        } else {
            groundTimer += dt;
            jumpBufferTimer += dt;
        }
        if(hasWallLeft) wallLeftTimer = 0.;
        else wallLeftTimer += dt;
        if(hasWallRight) wallRightTimer = 0.;
        else wallRightTimer += dt;
        var jumpDown = controller.isDown(Action.jump) || touchInput.isJumpDown || mouseInput.isJumpDown;
        var jumpPressed = controller.isPressed(Action.jump) || touchInput.isJumpPressed() || mouseInput.isJumpPressed();
        var jumpReleased = controller.isReleased(Action.jump) || touchInput.isJumpReleased() || mouseInput.isJumpReleased();
        var jumping = vy < 0 && jumpDown;
        if(vy < 0 && jumpReleased) {
            vy *= .5;
        }
        var jumped = false;
        if(jumpPressed) {
            if(jump()) {
                jumped = true;
            } else {
                jumpBufferTimer = 0.;
            }
        } else if(isOnGround && jumpDown && jumpBufferTimer <= JUMP_BUFFER_TIME) {
            jumped = jump();
        }
        if(!jumped && !isOnGround) {
            if(jumpPressed || (jumpDown && jumpBufferTimer <= JUMP_BUFFER_TIME)) {
                if(wallLeftTimer < wallRightTimer) {
                    if(faceLeftTimer <= WALL_JUMP_FACE_TIME && (hasWallLeft || (vy > 0 && wallLeftTimer < WALL_JUMP_COYOTE_TIME))) {
                        wallJump(1);
                    }
                } else {
                    if(faceRightTimer <= WALL_JUMP_FACE_TIME && (hasWallRight || (vy > 0 && wallRightTimer < WALL_JUMP_COYOTE_TIME))) {
                        wallJump(-1);
                    }
                }
            }
        }
        vy = Util.sodStep(vy, fastFall ? FALL_FAST_VEL : (isSlidingPhysics ? FALL_WALL_VEL : FALL_VEL), fastFall ? GRAVITY_FAST : (jumping ? GRAVITY_JUMP : GRAVITY), dt);
        if(isSlidingPhysics) {
            vy = Util.sodStep(vy, 0, .99, dt);
        }
        super.updateBeforeMove(dt);
    }

    override public function updateAfterMove(dt:Float) {
        super.updateAfterMove(dt);
        var res = StepResult.newDown();
        tryStepDown(res);
        isOnGround = !res.success;
        res.moveBack();
        res = StepResult.newLeft();
        tryStepLeft(res);
        hasWallLeft = !res.success;
        res.moveBack();
        res = StepResult.newRight();
        tryStepRight(res);
        hasWallRight = !res.success;
        res.moveBack();
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
        var newAnimName = "idle";
        var newFrame = 0.;
        if(!isOnGround) {
            if(isSlidingAnim) {
                newAnimName = "wallSlide";
            } else if(facing == Left || facing == Right) {
                newAnimName = "jumpSide";
            } else {
                newAnimName = "jumpNeutral";
            }
        } else {
            if(facing == None || facing == Up || facing == Down) {
                newAnimName = curAnimName == "jumpSide" || curAnimName == "jumpNeutral" || curAnimName == "land" ? "land" : "idle";
            } else {
                if(triedPushingHorizontal) {
                    newAnimName = "runPush";
                    newFrame = anim.currentFrame;
                } else {
                    newAnimName = "run";
                    newFrame = anim.currentFrame;
                }
            }
        }
        if(newAnimName != curAnimName) {
            curAnimName = newAnimName;
            var fullAnimName = "hero" + curAnimName.toUpperCase().charAt(0) + curAnimName.substr(1);
            var data = Assets.getAnimData("entities", fullAnimName);
            anim.play(data.tiles, newFrame);
            anim.speed = data.fps;
            anim.loops = true;
        }
        if(curAnimName == "jumpSide") {
            anim.currentFrame = Util.fclamp(anim.frames.length / 2 + vy / 50, 0, anim.frames.length - 1);
        } else if(curAnimName == "jumpNeutral") {
            var frame = (vy - (-JUMP_VEL)) / (FALL_VEL - (-JUMP_VEL)) * anim.frames.length;
            anim.currentFrame = Util.fclamp(frame, 0, anim.frames.length - 1);
        } else if(curAnimName == "land") {
            anim.loops = false;
        }
        var curFrame = Std.int(anim.currentFrame);
        anim.update(dt);
        var newFrame = Std.int(anim.currentFrame);
        if(curAnimName == "run" || curAnimName == "runPush") {
            if(newFrame != curFrame && (newFrame == 3 || newFrame == 9)) {
                Game.inst.fx.footStep(anim.x - 2 * anim.scaleX, anim.y - 1, Util.sign(anim.scaleX), newFrame == 3);
                Audio.playSound(newFrame == 3 ? "stepFront" : "stepBack");
            }
        }
        updateGraphics();
    }
    
    public override function die(dx:Float, dy:Float) {
        super.die(dx, dy);
        Game.inst.onDeath(dx, dy);
        Game.inst.fx.die(dx, dy);
        Audio.playSound("death", false, .5);
    }

    function jump() {
        if(groundTimer > JUMP_COYOTE_TIME) return false;
        groundTimer = JUMP_COYOTE_TIME + 1.;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        vy = -JUMP_VEL;
        Audio.playSound("jump", false, .3);
        var dx = facing == Left ? -1 : (facing == Right ? 1 : 0);
        Game.inst.fx.jump(anim.x - 4 * dx, anim.y, dx);
        return true;
    }
    function wallJump(dx:Int) {
        vx = WALL_JUMP_VEL_X * dx;
        vy = -WALL_JUMP_VEL_Y;
        jumpBufferTimer = JUMP_BUFFER_TIME + 1.;
        wallJumpTimer = 0.;
        Audio.playSound("wallJump", false, .3);
        Game.inst.fx.wallJump(anim.x - dx * anim.frames[0].iwidth * .5, anim.y - 4, dx);
        return true;
    }

    function updateGraphics() {
        anim.x = x + (hitbox.xMin + hitbox.xMax) * .5;
        anim.y = y + hitbox.yMax;
        #if debug_collisions
        anim.visible = false;
        debugGraphics.x = x;
        debugGraphics.y = y;
        #end
    }

    override public function toString() {
        return "Hero at (" + (x + hitbox.xMin) + ", " + (y + hitbox.yMin) + ") to (" + (x + hitbox.xMax) + ", " + (y + hitbox.yMax) + ")";
    }
}