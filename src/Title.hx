import h2d.Interactive;
import h2d.col.Point;
import fx.Fx;
import h2d.ScaleGrid;
import save.Save;
import h2d.Bitmap;
import h2d.Tile;
import Controller.Action;
import h2d.Text;
import h2d.Flow;
import SceneManager.Scene;
import audio.Audio;

enum LevelCellState {
    Locked;
    Unlocking;
    Unlocked;
    Completing;
    Completed;
}

class LevelCell extends Flow {
    public static inline var COMPLETE_TIME = .5;
    public static inline var UNLOCK_TIME = .2;
    public var selected(default, set) : Bool = false;
    public var group(default, null) : Int;
    public var state(default, set) : LevelCellState = Locked;
    var id : Int;
    var lockBitmap : Bitmap;
    var levelText : Text;
    var selectedBorder : Anim;
    var over : ScaleGrid;
    var onCompleted : Void->Void;
    var cellI : Int;
    var cellJ : Int;
    var lockedTiles : Array<Tile>;
    var timer : Float = 0.;

    public function new(id:Int, parent:Flow, group:Int, i:Int, j:Int, initState:LevelCellState, onClick:Void->Void, onOver:Void->Void, onOut:Void->Void, onCompleted:Void->Void) {
        super(parent);
        this.id = id;
        this.group = group;
        this.cellI = i;
        this.cellJ = j;
        this.state = initState;
        this.onCompleted = onCompleted;
        lockedTiles = Assets.getAnimData("entities", "levelCellLocked").tiles;
	    backgroundTile = Assets.getTile("entities", "levelCell");
		borderWidth = borderHeight = 6;
		minWidth = minHeight = 26;
		horizontalAlign = verticalAlign = Middle;
        lockBitmap = new Bitmap(lockedTiles[0], this);
        levelText = new Text(Assets.fontLarge, this);
        levelText.text = Std.string(id);
        var props = getProperties(levelText);
        props.offsetX = 1;
        props.offsetY = -1;
        enableInteractive = true;
        interactive.onClick = function(e) {
            if(state == Locked) return;
            onClick();
        };
        interactive.onOver = function(e) {
            if(state == Locked) return;
            if(!Main.inst.selectWithMouse) return;
            onOver();
        }
        interactive.onOut = function(e) {
            if(state == Locked) return;
            onOut();
        }
        interactive.name = "levelCell" + id;
        var data = Assets.getAnimData("entities", "cellBorder");
        selectedBorder = new Anim(data.tiles, data.fps, true, this);
        props = getProperties(selectedBorder);
        props.isAbsolute = true;
        over = new ScaleGrid(Assets.getTile("entities", "levelCellOver"), 6, 6, 6, 6, this);
        over.width = over.height = 26;
        props = getProperties(over);
        props.isAbsolute = true;
        over.visible = false;
        updateGraphics();
    }
    
    public function set_selected(v:Bool) {
        selectedBorder.visible = state != Locked && v;
        if(state == Locked) return v;
        selected = v;
        updateGraphics();
        return v;
    }

    public function update(dt:Float) {
        selectedBorder.update(dt);
        if(state == Unlocking) {
            timer += dt;
            if(timer > UNLOCK_TIME) {
                state = Unlocked;
            }
            updateGraphics();
        } else if(state == Completing) {
            timer += dt;
            if(timer > COMPLETE_TIME) {
                state = Completed;
                over.visible = false;
                onCompleted();
            } else {
                var t = timer / COMPLETE_TIME;
                over.alpha = 1. - t;
            }
            updateGraphics();
        }
    }

    public function unlock() {
        if(state != Locked) return;
        state = Unlocking;
        timer = 0;
        updateGraphics();
    }

    public function complete() {
        if(state != Unlocked) return;
        state = Completing;
        timer = 0;
        over.visible = true;
        var pos = Title.inst.getCellPos(group, cellI, cellJ);
        Title.inst.fx.levelCellCompleted(pos.x, pos.y);
        updateGraphics();
        Audio.playSound("cellComplete");
    }

    public function updateGraphics() {
        switch(state) {
            case Locked:
                lockBitmap.visible = true;
                levelText.visible = false;
                backgroundTile = Tile.fromColor(0x0, 1, 1, 0);
            case Unlocking:
                var t = Util.fmin(timer / UNLOCK_TIME, .99);
                lockBitmap.visible = true;
                levelText.visible = false;
                backgroundTile = lockedTiles[Std.int(t * lockedTiles.length)];
            case Unlocked:
                lockBitmap.visible = false;
                levelText.visible = true;
                backgroundTile = Assets.getTile("entities", (selected ? "levelCellSelected" : "levelCell"));
                levelText.textColor = 0x8b9bb4;
            case Completing:
                lockBitmap.visible = false;
                levelText.visible = true;
                backgroundTile = Assets.getTile("entities", (selected ? "levelCellCompletedSelected" : "levelCellCompleted") + group);
                levelText.textColor = 0xFFFFFF;
            case Completed:
                lockBitmap.visible = false;
                levelText.visible = true;
                backgroundTile = Assets.getTile("entities", (selected ? "levelCellCompletedSelected" : "levelCellCompleted") + group);
                levelText.textColor = 0xFFFFFF;
        }
        if(levelText.visible) {
            levelText.alpha = selected ? 1 : .85;
        }
    }

    public function set_state(v:LevelCellState) {
        state = v;
        return v;
    }
}

class Title extends Scene {
    public static var MUSIC_FADE_TIME = .2;
    static var _layer = 0;
    public static var LAYER_FX_BACK = _layer++;
    public static var LAYER_HUD = _layer++;
    public static var LAYER_FX_MID = _layer++;
    public static var LAYER_FX_FRONT = _layer++;
    public static inline var HOLD_TIME = .22;
    public static inline var REPEAT_TIME = .08;
    public static inline var GROUP_WIDTH = 3;
    public static inline var GROUP_HEIGHT = 3;
    public static inline var GROUP_COUNT = 3;
    public static inline var LEVEL_COUNT = GROUP_WIDTH * GROUP_HEIGHT * GROUP_COUNT;
    public static var GROUP_NAMES = ["Autumn Forest", "Moonlit Lagoon", "Spiky Cave"];
    public static var GROUP_COLORS = [0x63c74d, 0x0095e9, 0xe43b44];
    public static var GROUP_COMPLETED_TO_UNLOCK = [0, 6, 15];
    public static var GROUP_MUSIC_NAMES = ["forest", "lagoon", "cave"];
    public static var SHOW_COMPLETED_DELAY = .25;
    public static var SHOW_COMPLETED_INTERVAL = .1;
    public static var SHOW_UNLOCKED_DELAY = .2;
    public static var SHOW_UNLOCKED_INTERVAL = .0;
    public static var inst : Title;
    var curI : Int = 0;
    var curJ : Int = 0;
    var curGroup : Int = 0;
    public var container : Flow;
    var cells : Array<Array<Array<LevelCell> > > = [];
    var holdTimer : Float = 0.;
    var repeatTimer : Float = 0.;
    var lastMovementAction : Controller.Action = Action.menuEnter;
    var menu : Flow;
    public var fx : Fx;
    var toShowComplete : Array<LevelCell> = [];
    var toShowUnlocked : Array<LevelCell> = [];
    var timer : Float = 0.;
    var curMusicName : String = null;

    public function new(curLevelId:Int) {
        super();
        if(inst != null) {
            throw "Title scene already exists";
        }
        inst = this;
        fx = new Fx(hud, hud, hud, LAYER_FX_FRONT, LAYER_FX_MID, LAYER_FX_BACK);
        container = new Flow();
        hud.add(container, LAYER_HUD);
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
        menu.paddingTop = 15;
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
            var prevCompletedCount = completedCount;
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
                    var completedShown = Save.gameData.data.levelsCompletedShown.get(levelId);
                    var topCompleted = i > 0 && Save.gameData.data.levelsCompleted.get(levelId - GROUP_WIDTH);
                    var leftCompleted = j > 0 && Save.gameData.data.levelsCompleted.get(levelId - 1);
                    var bottomCompleted = i < GROUP_HEIGHT - 1 && Save.gameData.data.levelsCompleted.get(levelId + GROUP_WIDTH);
                    var rightCompleted = j < GROUP_WIDTH - 1 && Save.gameData.data.levelsCompleted.get(levelId + 1);
                    var topCompletedShown = i > 0 && Save.gameData.data.levelsCompletedShown.get(levelId - GROUP_WIDTH);
                    var leftCompletedShown = j > 0 && Save.gameData.data.levelsCompletedShown.get(levelId - 1);
                    var bottomCompletedShown = i < GROUP_HEIGHT - 1 && Save.gameData.data.levelsCompletedShown.get(levelId + GROUP_WIDTH);
                    var rightCompletedShown = j < GROUP_WIDTH - 1 && Save.gameData.data.levelsCompletedShown.get(levelId + 1);
                    var locked = groupLocked || ((i > 0 || j > 0) && !topCompleted && !leftCompleted && !rightCompleted && !bottomCompleted && !completed);
                    var lockedShown = groupLocked || ((i > 0 || j > 0) && !topCompletedShown && !leftCompletedShown && !rightCompletedShown && !bottomCompletedShown && !completedShown);
                    var state = (lockedShown && !completed) ? Locked : (completedShown ? Completed : Unlocked);
                    var cell = new LevelCell(levelId, row, k, i, j, state, function() {
                        chooseLevel(k, i, j);
                    }, function() {
                        curI = i; curJ = j; curGroup = k;
                        Audio.playSound("menuMove");
                        updateSelected();
                    }, function() {}, function() {
                        Save.gameData.data.showCompletedLevel(levelId);
                    });
                    if(state == Unlocked && completed) {
                        toShowComplete.push(cell);
                    }
                    if(state == Locked && !locked) {
                        toShowUnlocked.push(cell);
                    }
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
                lockText.text = "LOCKED\n" + prevCompletedCount + "/" + GROUP_COMPLETED_TO_UNLOCK[k];
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
        fx.clear();
        inst = null;
    }

    override public function update(dt:Float) {
        super.update(dt);
        for(k in 0...GROUP_COUNT) {
            for(i in 0...GROUP_HEIGHT) {
                for(j in 0...GROUP_WIDTH) {
                    cells[k][i][j].update(dt);
                }
            }
        }
        timer += dt;
        if(toShowComplete.length > 0) {
            if(timer > SHOW_COMPLETED_DELAY) {
                timer -= SHOW_COMPLETED_INTERVAL;
                var cell = toShowComplete.shift();
                cell.complete();
                if(toShowComplete.length == 0) {
                    timer = 0.;
                }
            }
        } else if(toShowUnlocked.length > 0) {
            var unlocked = false;
            while(toShowUnlocked.length > 0 && timer > SHOW_UNLOCKED_DELAY) {
                unlocked = true;
                timer -= SHOW_UNLOCKED_INTERVAL;
                var cell = toShowUnlocked.shift();
                cell.unlock();
                if(toShowUnlocked.length == 0) {
                    timer = 0.;
                }
            }
            if(unlocked) {
                Audio.playSound("cellUnlock");
            }
        }
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
            chooseLevel(curGroup, curI, curJ);
        }
        fx.update(dt);
    }

    override public function updateConstantRate(dt:Float) {
        fx.updateConstantRate(dt);
    }

    function chooseLevel(curGroup:Int, curI:Int, curJ:Int) {
        Audio.playSound("menuSelect");
        delete();
        Audio.stopMusic(Audio.MUSIC_FADE_IN_TIME);
        Audio.playMusic(GROUP_MUSIC_NAMES[curGroup], null, Audio.MUSIC_FADE_IN_TIME);
        new Game(true, 1 + curGroup * GROUP_HEIGHT * GROUP_WIDTH + curI * GROUP_WIDTH + curJ);
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
        var moved = true;
        while(cells[curGroup][curI][curJ].state == Locked) {
            if(!moveSelection(di, dj)) {
                curI = prevI;
                curJ = prevJ;
                curGroup = prevGroup;
                moved = false;
                break;
            }
        }
        if(moved) {
            Audio.playSound("menuMove");
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
        updateMusic();
    }

    public function forceCompleteLevel() {
        var levelId = 1 + curGroup * GROUP_HEIGHT * GROUP_WIDTH + curI * GROUP_WIDTH + curJ;
        Save.gameData.data.completeLevel(levelId);
        createMenu();
        updateSelected();
    }

    // Hacky, for some reason cell absX/absY return 0,0?
    public function getCellPos(k:Int, i:Int, j:Int) {
        var baseX = 30;
        var baseY = 71;
        return new Point(baseX + 6 + k * (20 + 26 * GROUP_WIDTH) + j * 26, baseY + 6 + i * 26);
    }

    function updateMusic() {
        var musicName = GROUP_MUSIC_NAMES[curGroup];
        if(musicName != curMusicName) {
            curMusicName = musicName;
            Audio.stopMusic(MUSIC_FADE_TIME);
            Audio.playMusic(musicName + "Back", MUSIC_FADE_TIME);
        }
    }
}