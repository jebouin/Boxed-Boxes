import h2d.Bitmap;
import h2d.Tile;
import Controller.Action;
import h2d.Text;
import h2d.Flow;
import SceneManager.Scene;

class LevelCell extends Flow {
    public var selected(default, set) : Bool = false;
    public var locked(default, null) : Bool = false;
    public var completed(default, null) : Bool = false;

    public function new(id:Int, parent:Flow) {
        super(parent);
	    backgroundTile = Assets.getTile("entities", "levelCell");
		borderWidth = borderHeight = 6;
		minWidth = minHeight = 24;
		horizontalAlign = verticalAlign = Middle;
        locked = id > 1 && Std.random(3) == 0;
        if(locked) {
            backgroundTile = Tile.fromColor(0x0, 1, 1, 0);
            var lock = new Bitmap(Assets.getTile("entities", "levelCellLocked"), this);
        } else {
            var levelText = new Text(Assets.fontLarge, this);
            levelText.text = Std.string(id);
        }
    }
    
    public function set_selected(v:Bool) {
        if(locked) return v;
        if(v) {
            backgroundTile = Assets.getTile("entities", "levelCellSelected");
        } else {
            backgroundTile = Assets.getTile("entities", "levelCell");
        }
        selected = v;
        return v;
    }
}

class Title extends Scene {
    public static inline var HOLD_TIME = .22;
    public static inline var REPEAT_TIME = .08;
    public static inline var GROUP_WIDTH = 3;
    public static inline var GROUP_HEIGHT = 3;
    public static inline var GROUP_COUNT = 3;
    public static var GROUP_NAMES = ["Autumn Forest", "Moonlit Lagoon", "Spiky Cave"];
    public static var GROUP_COLORS = [0x63c74d, 0x0095e9, 0xe43b44];
    public static var inst : Title;
    var curI : Int = 0;
    var curJ : Int = 0;
    var curGroup : Int = 0;
    var container : Flow;
    var cells : Array<Array<Array<LevelCell> > > = [];
    var holdTimer : Float = 0.;
    var repeatTimer : Float = 0.;
    var lastMovementAction : Controller.Action = Action.menuEnter;

    public function new() {
        super();
        if(inst != null) {
            throw "Title scene already exists";
        }
        container = new Flow(hud);
        container.minWidth = Main.WIDTH;
        container.minHeight = Main.HEIGHT;
        container.layout = Vertical;
        container.horizontalAlign = Middle;
        container.paddingTop = 5;
        container.backgroundTile = Tile.fromColor(0x181425, 1, 1);
        var title = new Text(Assets.fontLarge, container);
        title.text = "SELECT A LEVEL";
        title.textColor = 0xfee761;
        var menu = new Flow(container);
        menu.paddingTop = 9;
        menu.horizontalSpacing = 12;
        for(k in 0...GROUP_COUNT) {
            cells.push([]);
            var group = new Flow(menu);
            group.layout = Vertical;
            group.horizontalAlign = Middle;
            group.verticalSpacing = 5;
            group.backgroundTile = Assets.getTile("entities", "groupBorder" + k);
            group.borderWidth = group.borderHeight = 6;
            group.paddingHorizontal = group.paddingVertical = 3;
            var groupTitle = new Text(Assets.font, group);
            groupTitle.text = GROUP_NAMES[k];
            groupTitle.textColor = GROUP_COLORS[k];
            var groupMenu = new Flow(group);
            groupMenu.layout = Vertical;
            groupMenu.verticalSpacing = 1;
            for(i in 0...GROUP_HEIGHT) {
                cells[k].push([]);
                var row = new Flow(groupMenu);
                row.horizontalSpacing = 1;
                for(j in 0...GROUP_WIDTH) {
                    var cell = new LevelCell(i * GROUP_WIDTH + j + 1, row);
                    cells[k][i].push(cell);
                }
            }
        }
        updateSelected();
    }

    override public function delete() {
        super.delete();
        inst = null;
    }

    override public function update(dt:Float) {
        super.update(dt);
        var controller = Main.inst.controller;
        if(controller.isPressed(Action.menuLeft)) {
            lastMovementAction = Action.menuLeft;
            holdTimer = 0;
            moveSelection(0, -1);
        }
        if(controller.isPressed(Action.menuRight)) {
            lastMovementAction = Action.menuRight;
            holdTimer = 0;
            moveSelection(0, 1);
        }
        if(controller.isPressed(Action.menuUp)) {
            lastMovementAction = Action.menuUp;
            holdTimer = 0;
            moveSelection(-1, 0);
        }
        if(controller.isPressed(Action.menuDown)) {
            lastMovementAction = Action.menuDown;
            holdTimer = 0;
            moveSelection(1, 0);
        }
        function checkHoldAction(action, di, dj) {
            if(lastMovementAction == action) {
                if(controller.isDown(action)) {
                    holdTimer += dt;
                    if(holdTimer > HOLD_TIME) {
                        repeatTimer += dt;
                        if(repeatTimer > REPEAT_TIME) {
                            repeatTimer -= REPEAT_TIME;
                            moveSelection(di, dj);
                        }
                    }
                } else {
                    holdTimer = 0;
                }
            }
        }
        checkHoldAction(Action.menuLeft, 0, -1);
        checkHoldAction(Action.menuRight, 0, 1);
        checkHoldAction(Action.menuUp, -1, 0);
        checkHoldAction(Action.menuDown, 1, 0);
        if(controller.isPressed(Action.menuEnter)) {
            delete();
            new Game(1 + curGroup * GROUP_HEIGHT * GROUP_WIDTH + curI * GROUP_WIDTH + curJ);
        }
    }

    function moveSelection(di:Int, dj:Int) {
        while(dj < 0) {
            if(curJ > 0) {
                if(!cells[curGroup][curI][curJ - 1].locked) {
                    curJ--;
                }
            } else if(curGroup > 0) {
                if(!cells[curGroup - 1][curI][GROUP_WIDTH - 1].locked) {
                    curGroup--;
                    curJ = GROUP_WIDTH - 1;
                }
            }
            dj++;
        }
        while(dj > 0) {
            if(curJ < GROUP_WIDTH - 1) {
                if(!cells[curGroup][curI][curJ + 1].locked) {
                    curJ++;
                }
            } else if(curGroup < GROUP_COUNT - 1) {
                if(!cells[curGroup + 1][curI][0].locked) {
                    curGroup++;
                    curJ = 0;
                }
            }
            dj--;
        }
        while(di < 0) {
            if(curI > 0) {
                if(!cells[curGroup][curI - 1][curJ].locked) {
                    curI--;
                }
            }
            di++;
        }
        while(di > 0) {
            if(curI < GROUP_HEIGHT - 1) {
                if(!cells[curGroup][curI + 1][curJ].locked) {
                    curI++;
                }
            }
            di--;
        }
        updateSelected();
    }

    function updateSelected() {
        for(k in 0...GROUP_COUNT) {
            for(i in 0...GROUP_HEIGHT) {
                for(j in 0...GROUP_WIDTH) {
                    cells[k][i][j].selected = curGroup == k && curI == i && curJ == j;
                }
            }
        }
    }
}