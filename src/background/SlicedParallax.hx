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

// Assumes only 3 slices
class SlicedParallax extends Parallax {
    public static inline var TILE_WIDTH = 512;
    public static inline var TILE_HEIGHT = 256;
    public static inline var DISPLACE_POINT_COUNT_X = 16 + 1;
    public static inline var DISPLACE_POINT_COUNT_Y = 9 + 1;
    var leftElements : Array<Graphics> = [];
    var rightElements : Array<Graphics> = [];
    var atlasSliceCount : Int;
    var displayedSliceCount : Int;
    var sliceIndexMid : Int;
    var centerOffY : Float;
    var midSlicePos : Float;
    var displace : Bool;
    public var displaceTop : Bool = true;
    public var displaceBottom : Bool = true;
    var tiles : Array<Tile> = [];
    var disp : Vector<Vector<Point> >;
    var timer : Float = 0.;
    public var displaceMultX : Float = 0.;
    public var displaceMultY : Float = 0.;
    public var displaceScrollX : Float = 40.;
    public var displaceScrollY : Float = 20.;
    public var scrollX : Float = 0.;
    public var scrollY : Float = 0.;

    public function new(tile:Tile, sliceHeight:Int, layer:Int, speed:Float, levelWidth:Int, levelHeight:Int, displace:Bool) {
        super(layer, speed, levelWidth, levelHeight);
        this.displace = displace;
        parallaxWidth = tile.iwidth;
        parallaxHeight = sliceHeight;
        this.levelWidth = levelWidth;
        this.levelHeight = levelHeight;
        atlasSliceCount = Std.int(tile.iheight / sliceHeight);
        for(i in 0...atlasSliceCount) {
            var sub = tile.sub(0, i * sliceHeight, tile.iwidth, sliceHeight);
            var pixels = sub.getTexture().capturePixels(0, 0, IBounds.fromValues(sub.ix, sub.iy, sub.iwidth, sub.iheight));
            var square = Pixels.alloc(512, 256, ARGB);
            square.blit(0, 0, pixels, 0, 0, sub.iwidth, sub.iheight);
            tiles.push(Tile.fromPixels(square));
            square.dispose();
            pixels.dispose();
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
        midSlicePos = (Game.inst.level.heroSpawnY - sliceHeight * .75 + Game.inst.level.backgroundOffsetY);
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

    override public function update(dt:Float) {
        if(!super.update(dt)) return false;
        var cameraClampedTargetX = -Game.inst.world.x + Main.WIDTH2;
        var cameraClampedTargetY = -Game.inst.world.y + Main.HEIGHT2;
        var xMin = cameraClampedTargetX - Main.WIDTH2;
        var yMin = cameraClampedTargetY - Main.HEIGHT2;
        var xOff = (cameraClampedTargetX - levelWidth * .5 + timer * scrollX) * (1. - speed);
        xMin = Math.floor((xMin - xOff) / parallaxWidth) * parallaxWidth + xOff;
        var yOff = midSlicePos + (cameraClampedTargetY - levelHeight * .5 + timer * scrollY) * (1. - speed);
        var sliceIndexBase = Math.floor((yMin - yOff) / parallaxHeight);
        yMin = sliceIndexBase * parallaxHeight + yOff;
        for(i in 0...displayedSliceCount) {
            var sliceIndex = sliceIndexBase + i;
            var atlasIndex = Util.iclamp((atlasSliceCount >> 1) + sliceIndex, 0, atlasSliceCount - 1);
            var displace = this.displace;
            if(!displaceTop && atlasIndex == 0) displace = false;
            if(!displaceBottom && atlasIndex == atlasSliceCount - 1) displace = false;
            var displaceBelow = (displaceBottom && atlasIndex == atlasSliceCount - 2) || (displace && atlasIndex == atlasSliceCount - 3);
            renderTile(leftElements[i], tiles[atlasIndex], displace, displaceBelow);
            renderTile(rightElements[i], tiles[atlasIndex], displace, displaceBelow);
            leftElements[i].x = Math.round(xMin);
            rightElements[i].x = Math.round(xMin + parallaxWidth);
            leftElements[i].y = rightElements[i].y = Math.round(yMin + i * parallaxHeight);
        }
        timer += dt;
        if(displace) {
            for(i in 0...DISPLACE_POINT_COUNT_Y) {
                for(j in 0...DISPLACE_POINT_COUNT_X) {
                    var nx = Std.int(j / (DISPLACE_POINT_COUNT_X - 1) * Assets.noiseWidth + timer * displaceScrollX * displaceMultX / 10) % Assets.noiseWidth;
                    var ny = Std.int(i / (DISPLACE_POINT_COUNT_Y - 1) * Assets.noiseHeight + timer * displaceScrollY * displaceMultY / 10) % Assets.noiseHeight;
                    disp[i][j].x = Assets.noiseMapX[ny][nx] * displaceMultX;
                    disp[i][j].y = Assets.noiseMapY[ny][nx] * displaceMultY;
                }
            }
        }
        return true;
    }

    function renderTile(g:Graphics, t:Tile, displace:Bool, displaceBelow:Bool) {
        g.clear();
        if(displace) {
            var uMax = parallaxWidth / TILE_WIDTH, vMax = parallaxHeight / TILE_HEIGHT;
            var cntX = DISPLACE_POINT_COUNT_X - 1;
            var cntY = DISPLACE_POINT_COUNT_Y - 1;
            for(i in 0...cntY) {
                for(j in 0...cntX) {
                    var x1 = j * parallaxWidth / cntX, y1 = i * parallaxHeight / cntY;
                    var x2 = (j + 1) * parallaxWidth / cntX, y2 = (i + 1) * parallaxHeight / cntY;
                    var u1 = j / cntX * uMax, v1 = i / cntY * vMax;
                    var u2 = (j + 1) / cntX * uMax, v2 = (i + 1) / cntY * vMax;
                    g.beginTileFill(0, 0, 1, 1, t);
                    g.addVertex(x1 + disp[i][j].x, y1 + disp[i][j].y, 1, 1, 1, 1, u1, v1);
                    g.addVertex(x2 + disp[i][j + 1].x, y1 + disp[i][j + 1].y, 1, 1, 1, 1, u2, v1);
                    g.addVertex(x2 + disp[i + 1][j + 1].x, y2 + (displaceBelow || i < cntY - 1 ? disp[i + 1][j + 1].y : 0), 1, 1, 1, 1, u2, v2);
                    g.addVertex(x1 + disp[i + 1][j].x, y2 + (displaceBelow || i < cntY - 1 ? disp[i + 1][j].y : 0), 1, 1, 1, 1, u1, v2);
                    g.endFill();
                }
            }
        } else {
            g.beginTileFill(0, 0, 1, 1, t);
            g.drawRect(0, 0, parallaxWidth, parallaxHeight);
            g.endFill();
        }
    }
}