import save.Save;
import h2d.Bitmap;
import h2d.Tile;
import Controller.Action;
import h2d.Text;
import h2d.Flow;
import SceneManager.Scene;

class LevelCell extends Flow {
    public var selected(default, set) : Bool = false;
    public var locked(default, null) : Bool = false;
    public var completed(default, set) : Bool = false;
    public var group(default, null) : Int;

    public function new(id:Int, parent:Flow, group:Int, completed:Bool, locked:Bool) {
        super(parent);
        this.group = group;
        this.completed = completed;
        this.locked = locked;
	    backgroundTile = Assets.getTile("entities", "levelCell");
		borderWidth = borderHeight = 6;
		minWidth = minHeight = 25;
		horizontalAlign = verticalAlign = Middle;
        if(locked) {
            backgroundTile = Tile.fromColor(0x0, 1, 1, 0);
            var lock = new Bitmap(Assets.getTile("entities", "levelCellLocked"), this);
        } else {
            var levelText = new Text(Assets.fontLarge, this);
            levelText.text = Std.string(id);
            levelText.textColor = completed ? 0xFFFFFF : 0x8b9bb4;
            var props = getProperties(levelText);
            props.offsetX = 1;
        }
    }
    
    public function set_selected(v:Bool) {
        if(locked) return v;
        if(completed) {
            if(v) {
                backgroundTile = Assets.getTile("entities", "levelCellCompletedSelected" + group);
            } else {
                backgroundTile = Assets.getTile("entities", "levelCellCompleted" + group);
            }
        } else {
            if(v) {
                backgroundTile = Assets.getTile("entities", "levelCellSelected");
            } else {
                backgroundTile = Assets.getTile("entities", "levelCell");
            }
        }
        selected = v;
        return v;
    }

    public function set_completed(v:Bool) {
        completed = v;
        return v;
    }
}

class Title extends Scene {
    public static inline var HOLD_TIME = .22;
    public static inline var REPEAT_TIME = .08;
    public static inline var GROUP_WIDTH = 3;
    public static inline var GROUP_HEIGHT = 2;
    public static inline var GROUP_COUNT = 3;
    public static inline var LEVEL_COUNT = GROUP_WIDTH * GROUP_HEIGHT * GROUP_COUNT;
    public static var GROUP_NAMES = ["Autumn Forest", "Moonlit Lagoon", "Spiky Cave"];
    public static var GROUP_COLORS = [0x63c74d, 0x0095e9, 0xe43b44];
    public static var GROUP_COMPLETED_TO_UNLOCK = [0, 4, 10];
    public static var inst : Title;
    var curI : Int = 0;
    var curJ : Int = 0;
    var curGroup : Int = 0;
    var container : Flow;
    var cells : Array<Array<Array<LevelCell> > > = [];
    var holdTimer : Float = 0.;
    var repeatTimer : Float = 0.;
    var lastMovementAction : Controller.Action = Action.menuEnter;
    var menu : Flow;

    public function new(curLevelId:Int) {
        super();
        if(inst != null) {
            throw "Title scene already exists";
        }
        inst = this;
        container = new Flow(hud);
        container.minWidth = Main.WIDTH;
        container.minHeight = Main.HEIGHT;
        container.layout = Vertical;
        container.horizontalAlign = Middle;
        container.paddingTop = 16;
        container.backgroundTile = Tile.fromColor(0x181425, 1, 1);
        var title = new Text(Assets.fontLarge, container);
        title.text = "SELECT A LEVEL";
        title.textColor = 0xfee761;
        createMenu();
        curI = Std.int((curLevelId - 1) % (GROUP_HEIGHT * GROUP_WIDTH) / GROUP_WIDTH);
        curJ = (curLevelId - 1) % GROUP_WIDTH;
        curGroup = Std.int((curLevelId - 1) / (GROUP_HEIGHT * GROUP_WIDTH));
        updateSelected();
    }

    function createMenu() {
        if(menu != null) {
            menu.remove();
            cells = [];
        }
        menu = new Flow(container);
        menu.paddingTop = 9;
        menu.horizontalSpacing = 12;
        var completedCount = 0;
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
            var groupLocked = completedCount < GROUP_COMPLETED_TO_UNLOCK[k];
            var groupMenu = new Flow(group);
            groupMenu.layout = Vertical;
            groupMenu.verticalSpacing = 1;
            for(i in 0...GROUP_HEIGHT) {
                cells[k].push([]);
                var row = new Flow(groupMenu);
                row.horizontalSpacing = 1;
                for(j in 0...GROUP_WIDTH) {
                    var levelId = k * GROUP_HEIGHT * GROUP_WIDTH + i * GROUP_WIDTH + j + 1;
                    var completed = Save.gameData.data.levelsCompleted.get(levelId);
                    var topCompleted = i > 0 && Save.gameData.data.levelsCompleted.get(levelId - GROUP_WIDTH);
                    var leftCompleted = j > 0 && Save.gameData.data.levelsCompleted.get(levelId - 1);
                    var bottomCompleted = i < GROUP_HEIGHT - 1 && Save.gameData.data.levelsCompleted.get(levelId + GROUP_WIDTH);
                    var rightCompleted = j < GROUP_WIDTH - 1 && Save.gameData.data.levelsCompleted.get(levelId + 1);
                    var locked = groupLocked || ((i > 0 || j > 0) && !topCompleted && !leftCompleted && !rightCompleted && !bottomCompleted && !completed);
                    var cell = new LevelCell(levelId, row, k, completed, locked);
                    cells[k][i].push(cell);
                    if(completed) {
                        completedCount++;
                    }
                }
            }
            if(groupLocked) {
                var width = group.outerWidth, height = group.outerHeight;
                groupTitle.visible = groupMenu.visible = false;
                var lockText = new Text(Assets.font, group);
                lockText.text = "LOCKED\n" + completedCount + "/" + GROUP_COMPLETED_TO_UNLOCK[k];
                lockText.maxWidth = 36;
                lockText.textColor = 0x3a4466;
                lockText.textAlign = Center;
                group.minWidth = width;
                group.minHeight = height;
            }
        }
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
            tryMoveSelection(0, -1);
        }
        if(controller.isPressed(Action.menuRight)) {
            lastMovementAction = Action.menuRight;
            holdTimer = 0;
            tryMoveSelection(0, 1);
        }
        if(controller.isPressed(Action.menuUp)) {
            lastMovementAction = Action.menuUp;
            holdTimer = 0;
            tryMoveSelection(-1, 0);
        }
        if(controller.isPressed(Action.menuDown)) {
            lastMovementAction = Action.menuDown;
            holdTimer = 0;
            tryMoveSelection(1, 0);
        }
        function checkHoldAction(action, di, dj) {
            if(lastMovementAction == action) {
                if(controller.isDown(action)) {
                    holdTimer += dt;
                    if(holdTimer > HOLD_TIME) {
                        repeatTimer += dt;
                        if(repeatTimer > REPEAT_TIME) {
                            repeatTimer -= REPEAT_TIME;
                            tryMoveSelection(di, dj);
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
            new Game(true, 1 + curGroup * GROUP_HEIGHT * GROUP_WIDTH + curI * GROUP_WIDTH + curJ);
        }
    }

    function moveSelection(di:Int, dj:Int) {
        if(dj < 0) {
            if(curJ > 0) {
                curJ--;
            } else if(curGroup > 0) {
                curGroup--;
                curJ = GROUP_WIDTH - 1;
            } else {
                return false;
            }
        } else if(dj > 0) {
            if(curJ < GROUP_WIDTH - 1) {
                curJ++;
            } else if(curGroup < GROUP_COUNT - 1) {
                curGroup++;
                curJ = 0;
            } else {
                return false;
            }
        } else if(di < 0) {
            if(curI > 0) {
                curI--;
            } else {
                return false;
            }
        } else if(di > 0) {
            if(curI < GROUP_HEIGHT - 1) {
                curI++;
            } else {
                return false;
            }
        }
        return true;
    }

    function tryMoveSelection(di:Int, dj:Int) {
        var prevI = curI, prevJ = curJ, prevGroup = curGroup;
        if(!moveSelection(di, dj)) return;
        while(cells[curGroup][curI][curJ].locked) {
            if(!moveSelection(di, dj)) {
                curI = prevI;
                curJ = prevJ;
                curGroup = prevGroup;
                break;
            }
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

    public function forceCompleteLevel() {
        var levelId = 1 + curGroup * GROUP_HEIGHT * GROUP_WIDTH + curI * GROUP_WIDTH + curJ;
        Save.gameData.data.completeLevel(levelId);
        createMenu();
        updateSelected();
    }
}