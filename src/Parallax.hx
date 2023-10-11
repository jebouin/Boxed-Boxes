package ;

import h2d.SpriteBatch;
import h2d.Tile;
import h2d.Object;

class Parallax extends Object {
    var batch : SpriteBatch;
    var leftElements : Array<BatchElement> = [];
    var rightElements : Array<BatchElement> = [];
    var tile : Tile;
    var sliceHeight : Int;
    var atlasSliceCount : Int;
    var displayedSliceCount : Int;
    var sliceIndexMid : Int;
    public var speed : Float;
    var centerOffY : Float;
    var midSlicePos : Float;
    var levelWidth : Int;
    var levelHeight : Int;

    public function new(tile:Tile, sliceHeight:Int, layer:Int, speed:Float, levelWidth:Int, levelHeight:Int) {
        super();
        Game.inst.world.add(this, layer);
        this.sliceHeight = sliceHeight;
        this.tile = tile;
        this.speed = speed;
        this.levelWidth = levelWidth;
        this.levelHeight = levelHeight;
        batch = new SpriteBatch(tile, this);
        atlasSliceCount = Std.int(tile.iheight / sliceHeight);
        displayedSliceCount = Math.ceil(Main.HEIGHT / sliceHeight) + 1;
        for(i in 0...displayedSliceCount) {
            var el = new BatchElement(tile);
            batch.add(el);
            leftElements.push(el);
            el = new BatchElement(tile);
            batch.add(el);
            rightElements.push(el);
        }
        midSlicePos = (levelHeight * .5 - sliceHeight * .5);
        sliceIndexMid = Math.floor(midSlicePos / sliceHeight);
        centerOffY = midSlicePos - sliceIndexMid * sliceHeight;
    }

    public function update() {
        if(Game.inst == null) return;
        var xMin = Game.inst.camera.clampedTargetX - Main.WIDTH2;
        var yMin = Game.inst.camera.clampedTargetY - Main.HEIGHT2;
        var xOff = (Game.inst.camera.clampedTargetX - levelWidth * .5) * (1. - speed);
        xMin = Math.floor((xMin - xOff) / tile.width) * tile.iwidth + xOff;
        var yOff = midSlicePos + (Game.inst.camera.clampedTargetY - levelHeight * .5) * (1. - speed);
        var sliceIndexBase = Math.floor((yMin - yOff) / sliceHeight);
        yMin = sliceIndexBase * sliceHeight + yOff;
        for(i in 0...displayedSliceCount) {
            var sliceIndex = sliceIndexBase + i;
            var atlasIndex = Util.iclamp((atlasSliceCount >> 1) + sliceIndex, 0, atlasSliceCount - 1);
            var sub = tile.sub(0, atlasIndex * sliceHeight, tile.iwidth, sliceHeight);
            leftElements[i].t = rightElements[i].t = sub;
            leftElements[i].x = xMin;
            rightElements[i].x = xMin + tile.iwidth;
            leftElements[i].y = rightElements[i].y = yMin + i * sliceHeight;
        }
    }
}