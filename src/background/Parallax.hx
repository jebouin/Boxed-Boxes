package background;

import hxd.Res;
import h2d.col.Point;
import haxe.ds.Vector;
import h2d.col.IBounds;
import hxd.Pixels;
import h3d.mat.Texture;
import h2d.Graphics;
import h2d.SpriteBatch;
import h2d.Tile;
import h2d.Object;

class Parallax extends Object {
    public var speed : Float;
    var parallaxWidth : Int;
    var parallaxHeight : Int;
    var levelWidth : Int;
    var levelHeight : Int;

    public function new(layer:Int, speed:Float, levelWidth:Int, levelHeight:Int) {
        this.speed = speed;
        this.levelWidth = levelWidth;
        this.levelHeight = levelHeight;
        super();
        Game.inst.world.add(this, layer);
    }

    public function update(dt:Float) {
        if(Game.inst == null) return false;
        return true;
    }
}