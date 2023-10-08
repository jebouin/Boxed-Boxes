package ;

import h2d.Tile;
import h2d.Object;
import h2d.Bitmap;

class Parallax extends Object {
    var tile : Tile;
    var topLeft : Bitmap;
    var topRight : Bitmap;
    var bottomLeft : Bitmap;
    var bottomRight : Bitmap;
    public var speed : Float;

    public function new(tile:Tile, layer:Int, speed:Float) {
        super();
        Game.inst.world.add(this, layer);
        this.tile = tile;
        this.speed = speed;
        topLeft = new Bitmap(tile, this);
        topRight = new Bitmap(tile, this);
        bottomLeft = new Bitmap(tile, this);
        bottomRight = new Bitmap(tile, this);
    }

    public function update() {
        if(Game.inst == null) return;
        var ccx = -Game.inst.world.x;
        var ccy = -Game.inst.world.y;
        var px = (-speed * ccx) % tile.width;
        if(px < 0) px += tile.width;
        var py = (-speed * ccy) % tile.height;
        if(py < 0) py += tile.height;
        var cx = Math.round(ccx + px);
        var cy = Math.round(ccy + py);
        topLeft.x = bottomLeft.x = cx - tile.width;
        topLeft.y = topRight.y = cy - tile.height;
        topRight.x = bottomRight.x = cx;
        bottomLeft.y = bottomRight.y = cy;
    }
}