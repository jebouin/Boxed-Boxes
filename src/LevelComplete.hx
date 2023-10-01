import h2d.filter.Mask;
import h2d.Graphics;
import save.Save;
import h2d.Bitmap;
import h2d.Tile;
import Controller.Action;
import h2d.Text;
import h2d.Flow;
import SceneManager.Scene;

class MenuLine extends Flow {
    public var selected(default, set) : Bool = false;
    var onPress : Void->Void;

    public function new(str:String, parent:Flow, onPress:Void->Void) {
        this.onPress = onPress;
        super(parent);
        var text = new Text(Assets.font, this);
        text.text = str;
        borderWidth = borderHeight = 6;
        paddingBottom = 3;
        paddingTop = 2;
        minWidth = 70;
        horizontalAlign = Middle;
    }
    
    public function set_selected(v:Bool) {
        if(v) {
            backgroundTile = Assets.getTile("entities", "buttonSelected");
        } else {
            backgroundTile = Assets.getTile("entities", "button");
        }
        selected = v;
        return v;
    }

    public function press() {
        onPress();
    }
}

class LevelComplete extends Scene {
    public static inline var HOLD_TIME = .22;
    public static inline var REPEAT_TIME = .08;
    public static var inst : LevelComplete;
    var curId : Int = 0;
    var container : Flow;
    var holdTimer : Float = 0.;
    var repeatTimer : Float = 0.;
    var lastMovementAction : Controller.Action = Action.menuEnter;
    var lines : Array<MenuLine> = [];
    var groupId : Int;
    var levelId : Int;
    var globalLevelId : Int;
    var timer : Float = 0.;
    var maskX : Float;
    var maskY : Float;

    public function new(groupId:Int, levelId:Int, globalLevelId:Int, maskX:Float, maskY:Float) {
        super();
        if(inst != null) {
            throw "LevelComplete scene already exists";
        }
        this.groupId = groupId;
        this.levelId = levelId;
        this.globalLevelId = globalLevelId;
        this.maskX = maskX;
        this.maskY = maskY;
        var back = new Graphics(world);
        back.beginFill(0x181425);
        back.drawRect(0, 0, Main.WIDTH, Main.HEIGHT);
        back.endFill();
        container = new Flow(hud);
        container.minWidth = Main.WIDTH;
        container.minHeight = Main.HEIGHT;
        container.layout = Vertical;
        container.horizontalAlign = Middle;
        container.paddingTop = 30;
        container.backgroundTile = Tile.fromColor(0x181425, 1, 1);
        var title = new Text(Assets.fontLarge, container);
        title.text = Title.GROUP_NAMES[groupId];
        title.textColor = Title.GROUP_COLORS[groupId];
        var complete = new Text(Assets.font, container);
        complete.text = "LEVEL " + globalLevelId + " COMPLETE!";
        var props = container.getProperties(complete);
        props.paddingTop = 10;
        var menu = new Flow(container);
        menu.paddingTop = 9;
        menu.layout = Vertical;
        menu.verticalSpacing = 4;
        menu.horizontalAlign = Middle;
        function addLine(str:String, onPressed) {
            var flow = new MenuLine(str, menu, onPressed);
            lines.push(flow);
        }
        if(levelId < Title.GROUP_WIDTH * Title.GROUP_HEIGHT) {
            addLine("Continue", onContinuePressed);
            addLine("Restart", onRestartPressed);
            addLine("Level select", onTitlePressed);
        } else {
            addLine("Level select", onTitlePressed);
            addLine("Restart", onRestartPressed);
        }
        updateSelected();
        hud.visible = false;
    }

    function onContinuePressed() {
        delete();
        new Game(false, globalLevelId + 1);
    }
    function onRestartPressed() {
        delete();
        new Game(true, globalLevelId);
    }
    function onTitlePressed() {
        delete();
        new Title(globalLevelId);
    }

    override public function delete() {
        super.delete();
        inst = null;
    }

    override public function update(dt:Float) {
        super.update(dt);
        var controller = Main.inst.controller;
        if(controller.isPressed(Action.menuUp)) {
            lastMovementAction = Action.menuUp;
            holdTimer = 0;
            moveSelection(-1);
        }
        if(controller.isPressed(Action.menuDown)) {
            lastMovementAction = Action.menuDown;
            holdTimer = 0;
            moveSelection(1);
        }
        function checkHoldAction(action, dir) {
            if(lastMovementAction == action) {
                if(controller.isDown(action)) {
                    holdTimer += dt;
                    if(holdTimer > HOLD_TIME) {
                        repeatTimer += dt;
                        if(repeatTimer > REPEAT_TIME) {
                            repeatTimer -= REPEAT_TIME;
                            moveSelection(dir);
                        }
                    }
                } else {
                    holdTimer = 0;
                }
            }
        }
        checkHoldAction(Action.menuUp, -1);
        checkHoldAction(Action.menuDown, 1);
        if(controller.isPressed(Action.menuEnter)) {
            lines[curId].press();
            Audio.playSound("menuSelect");
        }
        if(controller.isPressed(Action.menuQuit) || controller.isPressed(Action.pause)) {
            onTitlePressed();
            Audio.playSound("menuSelect");
        }
        timer += dt;
        var t = timer / .5;
        if(t > 1) {
            t = 1.;
        }
        var scale = 1. - Math.pow(1. - t, 2.);
        hud.scaleX = hud.scaleY = scale;
        hud.visible = true;
        hud.x = maskX * (1. - scale);
        hud.y = maskY * (1. - scale);
    }

    function moveSelection(dir:Int) {
        var moved = false;
        if(dir == -1) {
            if(curId > 0) {
                curId--;
                moved = true;
            }
        } else if(dir == 1) {
            if(curId < lines.length - 1) {
                curId++;
                moved = true;
            }
        }
        if(moved) {
            Audio.playSound("menuMove");
        }
        updateSelected();
    }

    function updateSelected() {
        for(i in 0...lines.length) {
            lines[i].selected = curId == i;
        }
    }
}