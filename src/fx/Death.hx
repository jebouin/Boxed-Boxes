package fx;

import h2d.Tile;
import h2d.Bitmap;
import h2d.Graphics;

class Pixel {
    public var b : Bitmap;
    public var accx : Float;
    public var accy : Float;
    public var vx : Float = 0.;
    public var vy : Float = 0.;
    public var x : Float;
    public var y : Float;
    public var toX : Float;
    public var toY : Float;
    public var width : Int;
    public var height : Int;

    public function new(x:Float, y:Float, toX:Float, toY:Float, width:Int, height:Int) {
        this.x = x;
        this.y = y;
        this.toX = toX;
        this.toY = toY;
        this.width = width;
        this.height = height;
        var tile = Tile.fromColor(0xFFFFFF, width, height);
        b = new Bitmap(tile);
        Game.inst.world.add(b, Game.LAYER_FX_FRONT);
        var acc = Util.randCircle(1000, 2000);
        accx = acc.x;
        accy = acc.y;
        update(0, 0);
    }

    public function update(dt:Float, t:Float) {
        vx += accx * dt;
        vy += accy * dt;
        x += vx * dt;
        y += vy * dt;
        b.x = toX * t + x * (1. - t);
        b.y = toY * t + y * (1. - t);
    }

    public function delete() {
        b.remove();
    }
}

class Death {
    public var fromX : Float;
    public var fromY : Float;
    public var toX : Float;
    public var toY : Float;
    var pixels : Array<Pixel> = [];
    var over : Graphics;

    public function new(fromX:Int, fromY:Int, toX:Int, toY:Int, dx:Float, dy:Float) {
        this.fromX = fromX;
        this.fromY = fromY;
        this.toX = toX;
        this.toY = toY;
        var centerX = fromX + 4;
        var centerY = fromY + 8;
        for(i in 0...2) {
            for(j in 0...4) {
                var x = fromX + i * 4;
                var y = fromY + j * 4;
                var tx = toX + i * 4;
                var ty = toY + j * 4;
                var cdx : Float = (x + 2) - centerX;
                var cdy : Float = (y + 2) - centerY;
                var dist = Math.sqrt(cdx * cdx + cdy * cdy);
                cdx /= dist;
                cdy /= dist;
                var pixel = new Pixel(x, y, tx, ty, 4, 4);
                pixel.vx = -dx * 200 + cdx * 100;
                pixel.vy = -dy * 200 + cdy * 100;
                pixels.push(pixel);
            }
        }
        over = new Graphics();
        over.beginFill(0xFF0000);
        over.drawRect(0, 0, Main.WIDTH, Main.HEIGHT);
        over.endFill();
        over.blendMode = Add;
        Game.inst.hud.add(over, Game.LAYER_FLASH);
        over.alpha = .7;
    }

    public function delete() {
        for(p in pixels) {
            p.delete();
        }
        over.remove();
    }

    public function update(dt:Float, t:Float) {
        for(p in pixels) {
            p.update(dt, t);
        }
    }

    public function updateConstantRate(dt:Float) {
        over.alpha = Util.sodStep(over.alpha, 0., .998, dt);
    }
}