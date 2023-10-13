package ;

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
    public static inline var DISPLACE_POINT_COUNT_Y = 32 + 1;
    public static inline var DISPLACE_POINT_COUNT_X = 18 + 1;
    var leftElements : Array<Graphics> = [];
    var rightElements : Array<Graphics> = [];
    var sliceHeight : Int;
    var sliceWidth : Int;
    var atlasSliceCount : Int;
    var displayedSliceCount : Int;
    var sliceIndexMid : Int;
    public var speed : Float;
    var centerOffY : Float;
    var midSlicePos : Float;
    var levelWidth : Int;
    var levelHeight : Int;
    var displace : Bool;
    var tiles : Array<Tile> = [];
    var disp : Vector<Vector<Point> >;
    var timer : Float = 0.;

    public function new(tile:Tile, sliceHeight:Int, layer:Int, speed:Float, levelWidth:Int, levelHeight:Int, displace:Bool) {
        this.displace = displace;
        super();
        Game.inst.world.add(this, layer);
        this.sliceHeight = sliceHeight;
        this.sliceWidth = tile.iwidth;
        this.speed = speed;
        this.levelWidth = levelWidth;
        this.levelHeight = levelHeight;
        atlasSliceCount = Std.int(tile.iheight / sliceHeight);
        for(i in 0...atlasSliceCount) {
            var sub = tile.sub(0, i * sliceHeight, tile.iwidth, sliceHeight);
            var pixels = sub.getTexture().capturePixels(0, 0, IBounds.fromValues(sub.ix, sub.iy, sub.iwidth, sub.iheight));
            tiles.push(Tile.fromPixels(pixels));
            trace(tiles[i]);
        }
        displayedSliceCount = Math.ceil(Main.HEIGHT / sliceHeight) + 1;
        for(i in 0...displayedSliceCount) {
            var g = new Graphics(this);
            g.tileWrap = true;
            leftElements.push(g);
            g = new Graphics(this);
            g.tileWrap = true;
            rightElements.push(g);
        }
        midSlicePos = (levelHeight * .5 - sliceHeight * .5);
        sliceIndexMid = Math.floor(midSlicePos / sliceHeight);
        centerOffY = midSlicePos - sliceIndexMid * sliceHeight;
        if(displace) {
            disp = new Vector<Vector<Point> >(DISPLACE_POINT_COUNT_Y);
            for(i in 0...DISPLACE_POINT_COUNT_Y) {
                disp[i] = new Vector<Point>(DISPLACE_POINT_COUNT_X);
                for(j in 0...DISPLACE_POINT_COUNT_X) {
                    disp[i][j] = new Point(0, 0);
                }
            }
        }
    }

    public function update(dt:Float) {
        if(Game.inst == null) return;
        var cameraClampedTargetX = -Game.inst.world.x + Main.WIDTH2;
        var cameraClampedTargetY = -Game.inst.world.y + Main.HEIGHT2;
        var xMin = cameraClampedTargetX - Main.WIDTH2;
        var yMin = cameraClampedTargetY - Main.HEIGHT2;
        var xOff = (cameraClampedTargetX - levelWidth * .5) * (1. - speed);
        xMin = Math.floor((xMin - xOff) / sliceWidth) * sliceWidth + xOff;
        var yOff = midSlicePos + (cameraClampedTargetY - levelHeight * .5) * (1. - speed);
        var sliceIndexBase = Math.floor((yMin - yOff) / sliceHeight);
        yMin = sliceIndexBase * sliceHeight + yOff;
        for(i in 0...displayedSliceCount) {
            var sliceIndex = sliceIndexBase + i;
            var atlasIndex = Util.iclamp((atlasSliceCount >> 1) + sliceIndex, 0, atlasSliceCount - 1);
            renderTile(leftElements[i], tiles[atlasIndex]);
            renderTile(rightElements[i], tiles[atlasIndex]);
            leftElements[i].x = xMin;
            rightElements[i].x = xMin + sliceWidth;
            leftElements[i].y = rightElements[i].y = yMin + i * sliceHeight;
        }
        timer += dt;
        if(displace) {
            for(i in 0...DISPLACE_POINT_COUNT_Y) {
                for(j in 0...DISPLACE_POINT_COUNT_X) {
                    disp[i][j].x = Math.sin(timer * 5 + i * .5 + j * .3) * 1.;
                    disp[i][j].y = Math.sin(timer * 3 + i * .5 + j * .3) * 1.;
                }
            }
        }
    }

    function renderTile(g:Graphics, t:Tile) {
        g.clear();
        if(displace) {
            var cntX = DISPLACE_POINT_COUNT_X - 1;
            var cntY = DISPLACE_POINT_COUNT_Y - 1;
            for(i in 0...cntY) {
                for(j in 0...cntX) {
                    var x1 = j * sliceWidth / cntX, y1 = i * sliceHeight / cntY;
                    var x2 = (j + 1) * sliceWidth / cntX, y2 = (i + 1) * sliceHeight / cntY;
                    var u1 = j / cntX, v1 = i / cntY;
                    var u2 = (j + 1) / cntX, v2 = (i + 1) / cntY;
                    g.beginTileFill(0, 0, 1, 1, t);
                    g.addVertex(x1 + disp[i][j].x, y1 + disp[i][j].y, 1, 1, 1, 1, u1, v1);
                    g.addVertex(x2 + disp[i][j + 1].x, y1 + disp[i][j + 1].y, 1, 1, 1, 1, u2, v1);
                    g.addVertex(x2 + disp[i + 1][j + 1].x, y2 + disp[i + 1][j + 1].y, 1, 1, 1, 1, u2, v2);
                    g.addVertex(x1 + disp[i + 1][j].x, y2 + disp[i + 1][j].y, 1, 1, 1, 1, u1, v2);
                    g.endFill();
                }
            }
        } else {
            g.beginTileFill(0, 0, 1, 1, t);
            g.drawRect(0, 0, sliceWidth, sliceHeight);
            g.endFill();
        }
    }
}