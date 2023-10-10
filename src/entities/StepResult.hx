package entities;

import haxe.ds.IntMap;

class StepResult {
    public static function newLeft() {
        return new StepResult(-1, 0);
    }
    public static function newRight() {
        return new StepResult(1, 0);
    }
    public static function newUp() {
        return new StepResult(0, -1);
    }
    public static function newDown() {
        return new StepResult(0, 1);
    }

    public var dx : Int = 0;
    public var dy : Int = 0;
    public var success : Bool = true;
    public var triedPushingHorizontal : Bool = false;
    public var pushedEntities : IntMap<Bool> = new IntMap<Bool>();
    public var pushedBorders : IntMap<Bool> = new IntMap<Bool>();

    function new(dx:Int, dy:Int) {
        this.dx = dx;
        this.dy = dy;
    }

    public function apply(parent:Entity) {
        if(dx != 0) {
            parent.triedPushingHorizontal = triedPushingHorizontal;
        }
        if(success) {
            parent.rx -= dx;
            parent.ry -= dy;
        } else {
            moveBack();
        }
    }

    public function fail() {
        if(!success) return;
        success = false;
    }

    public function moveBack() {
        for(id in pushedEntities.keys()) {
            var entity = Entity.idToEntity.get(id);
            entity.x -= dx;
            entity.y -= dy;
        }
        for(id in pushedBorders.keys()) {
            var border = Border.idToBorder.get(id);
            border.bounds.x -= dx;
            border.bounds.y -= dy;
            border.updateWalls();
        }
    }

    public function toString() {
        var str = "";
        if(dx < 0) str += "left";
        if(dx > 0) str += "right";
        if(dy < 0) str += "up";
        if(dy > 0) str += "down";
        if(!success) str += " (failed)";
        if(triedPushingHorizontal) str += " (tried pushing horizontally)";
        if(pushedEntities.keys().hasNext()) {
            for(id in pushedEntities.keys()) {
                str += " (pushed entity " + id + ")";
            }
        }
        if(pushedBorders.keys().hasNext()) {
            for(id in pushedBorders.keys()) {
                str += " (pushed border " + id + ")";
            }
        }
        return str;
    }
}