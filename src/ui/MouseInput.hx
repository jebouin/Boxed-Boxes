package ui;

import h2d.Tile;
import hxd.Event;
import h2d.Flow;
import h2d.Interactive;
import h2d.Object;
import h2d.Bitmap;

class MouseInput {
    var container : Flow;
    public var enabled : Bool = true;
    var curLeftDown : Bool = false;
    var curRightDown : Bool = false;
    var curJumpDown : Bool = false;
    public var isLeftDown : Bool = false;
    public var isRightDown : Bool = false;
    public var isJumpDown : Bool = false;
    public var wasLeftDown : Bool = false;
    public var wasRightDown : Bool = false;
    public var wasJumpDown : Bool = false;
    var mouseDown : Bool = false;
    var mouseX : Float = 0.;

    public function new() {
        container = new Flow();
        container.minWidth = Main.WIDTH;
        container.minHeight = Main.HEIGHT;
        Game.inst.hud.add(container);
        container.enableInteractive = true;
        container.interactive.onPush = onPush;
        container.interactive.onRelease = onRelease;
        container.interactive.onMove = onMove;
        container.interactive.enableRightButton = true;
    }

    public function delete() {
        container.remove();
    }

    public function onPush(e:Event) {
        if(e.button == 0) {
            mouseDown = true;
        } else if(e.button == 1) {
            curJumpDown = true;
        }
    }

    public function onMove(e:Event) {
        mouseX = e.relX;
    }

    public function onRelease(e:Event) {
        if(e.button == 0) {
            mouseDown = false;
        } else if(e.button == 1) {
            curJumpDown = false;
        }
    }

    public function update(dt:Float) {
    }

    public function afterUpdate() {
        if(!enabled) {
            isLeftDown = isRightDown = isJumpDown = false;
        } else if(mouseDown) {
            var dx = mouseX - (Game.inst.hero.x + Game.inst.world.x);
            if(dx < -10) {
                curLeftDown = true;
                curRightDown = false;
            } else if(dx > 10) {
                curLeftDown = false;
                curRightDown = true;
            } else {
                curLeftDown = false;
                curRightDown = false;
            }
        } else {
            curLeftDown = false;
            curRightDown = false;
        }
        wasLeftDown = isLeftDown;
        wasRightDown = isRightDown;
        wasJumpDown = isJumpDown;
        isLeftDown = curLeftDown;
        isRightDown = curRightDown;
        isJumpDown = curJumpDown;
    }

    public function isLeftPressed() {
        return isLeftDown && !wasLeftDown;
    }
    public function isRightPressed() {
        return isRightDown && !wasRightDown;
    }
    public function isJumpPressed() {
        return isJumpDown && !wasJumpDown;
    }
    public function isLeftReleased() {
        return !isLeftDown && wasLeftDown;
    }
    public function isRightReleased() {
        return !isRightDown && wasRightDown;
    }
    public function isJumpReleased() {
        return !isJumpDown && wasJumpDown;
    }

    public function hide() {
        container.visible = false;
    }
    public function show() {
        container.visible = true;
    }
}