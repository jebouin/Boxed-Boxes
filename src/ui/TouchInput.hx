package ui;

import h2d.Flow;
import h2d.Interactive;
import h2d.Object;
import h2d.Bitmap;

class TouchInput {
    var container : Flow;
    var leftIcon : Flow;
    var rightIcon : Flow;
    var jumpIcon : Flow;
    var curLeftDown : Bool = false;
    var curRightDown : Bool = false;
    var curJumpDown : Bool = false;
    public var isLeftDown : Bool = false;
    public var isRightDown : Bool = false;
    public var isJumpDown : Bool = false;
    public var wasLeftDown : Bool = false;
    public var wasRightDown : Bool = false;
    public var wasJumpDown : Bool = false;

    public function new() {
        container = new Flow();
        container.minWidth = Main.WIDTH;
        container.horizontalSpacing = 5;
        container.y = Main.HEIGHT - 35;
        container.x = 5;
        Game.inst.hud.add(container);
        function createButton(name, setf) {
            var flow = new Flow(container);
            var icon = new Bitmap(Assets.getTile("entities", name), flow);
            flow.enableInteractive = true;
            flow.interactive.allowMultiClick = true;
            flow.interactive.onPush = function(e) {
                setf(true);
            };
            flow.interactive.onRelease = function(e) {
                setf(false);
            };
            return flow;
        }
        leftIcon = createButton("touchInputLeft", function(v) {curLeftDown = v;});
        rightIcon = createButton("touchInputRight", function(v) {curRightDown = v;});
        jumpIcon = createButton("touchInputJump", function(v) {curJumpDown = v;});
        var props = container.getProperties(jumpIcon);
        props.horizontalAlign = Right;
        props.paddingRight = 10;
    }

    public function delete() {
        container.remove();
    }

    public function update(dt:Float) {

    }

    public function afterUpdate() {
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