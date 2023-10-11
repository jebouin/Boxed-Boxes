package fx;

import h2d.Tile;
import h2d.Bitmap;
import h2d.Layers;

enum ScreenShakeType {
    Bounce;
    Noise;
}

class Fx {
    var sbFront : CustomSpriteBatch;
    var sbMid : CustomSpriteBatch;
    var sbBack : CustomSpriteBatch;
    public var shakeX : Float = 0.;
    public var shakeY : Float = 0.;
    var shakeDX : Float = 0.;
    var shakeDY : Float = 0.;
    var shakeSOD : SecondOrderDynamics;
    var shakeTimer : Float = 0.;
    var shakeType : ScreenShakeType;
    var flashTimer : Float = 0.;
    var flashSOD : SecondOrderDynamics;
    var flashBitmap : Bitmap;
    var flashLayers : Layers = null;

    public function new(frontLayers:Layers, midLayers:Layers, backLayers:Layers, frontLayer:Int, midLayer:Int, backLayer:Int) {
        sbFront = new CustomSpriteBatch(hxd.Res.gfx.entities_png.toTile());
        sbMid = new CustomSpriteBatch(hxd.Res.gfx.entities_png.toTile());
        sbBack = new CustomSpriteBatch(hxd.Res.gfx.entities_png.toTile());
        frontLayers.add(sbFront, frontLayer);
        midLayers.add(sbMid, midLayer);
        backLayers.add(sbBack, backLayer);
        sbFront.hasUpdate = sbFront.hasRotationScale = true;
        sbMid.hasUpdate = sbMid.hasRotationScale = true;
        sbBack.hasUpdate = sbBack.hasRotationScale = true;
        sbFront.blendMode = sbMid.blendMode = sbBack.blendMode = Add;
    }

    public function delete() {
        clear();
    }

    public function clear() {
        sbFront.clear();
        sbMid.clear();
        sbBack.clear();
        Particle.clearAll();
        stopShake();
    }

    public function update(dt:Float) {
        sbFront.update(dt);
        sbMid.update(dt);
        sbBack.update(dt);
    }

    public function updateConstantRate(dt:Float) {
        if(shakeTimer > 0) {
            shakeTimer -= dt;
            if(shakeTimer < 0) {
                shakeX = shakeY = 0;
            } else {
                shakeSOD.update(dt, 0);
                if(shakeType == Noise) {
                    var ra = Math.random() * Util.TAU;
                    var dist = shakeSOD.pos;
                    shakeX = Math.cos(ra) * dist * shakeDX;
                    shakeY = Math.sin(ra) * dist * shakeDY;
                } else {
                    shakeX = shakeDX * shakeSOD.pos;
                    shakeY = shakeDY * shakeSOD.pos;
                }
            }
        }
        if(flashTimer > 0) {
            flashBitmap.x = -flashLayers.x;
            flashBitmap.y = -flashLayers.y;
            flashTimer -= dt;
            if(flashTimer < 0) {
                flashBitmap.remove();
                flashBitmap = null;
            } else {
                flashSOD.update(dt, 0);
                flashBitmap.alpha = flashSOD.pos;
            }
        }
    }

    public function screenBounce(dx:Float, dy:Float, f:Float, z:Float, r:Float) {
        var mult = 1.;
        f /= mult;
        shakeSOD = new SecondOrderDynamics(f, z, r, 1., Fast);
        shakeTimer = 4. / f;
        shakeDX = dx * mult;
        shakeDY = dy * mult;
        shakeType = ScreenShakeType.Bounce;
    }
    public function screenShake(dx:Float, dy:Float, f:Float, z:Float, r:Float, ?maxTime:Float=null) {
        var mult = 1.;
        f /= mult;
        shakeSOD = new SecondOrderDynamics(f, z, r, 1., Fast);
        shakeTimer = maxTime == null ? 4. / f : maxTime;
        shakeDX = dx * mult;
        shakeDY = dy * mult;
        shakeType = ScreenShakeType.Noise;
    }
    public function stopShake() {
        if(shakeSOD != null) {
            shakeSOD.reset(0);
        }
        shakeDX = shakeDY = shakeX = shakeY = shakeTimer = 0.;
    }
    public function screenFlash(layers:Layers, color:Int, alpha:Float, f:Float) {
        if(flashBitmap != null) {
            flashBitmap.remove();
        }
        flashBitmap = new Bitmap(Tile.fromColor(0xFF000000 | color, Main.WIDTH, Main.HEIGHT), layers);
        flashBitmap.blendMode = Add;
        flashSOD = new SecondOrderDynamics(f, 1, 0, alpha, Fast);
        flashTimer = 4. / f;
        flashLayers = layers;
    }
    public function setFlashEnabled(v:Bool) {
        if(flashBitmap != null) {
            flashBitmap.visible = v;
        }
    }
    public function rumble(strength:Float, seconds:Float) {
        var mult = 1.;
        strength *= mult;
        seconds *= Math.sqrt(mult);
        Main.inst.controller.rumble(strength, seconds);
    }

    public function footStep(x:Float, y:Float, dir:Int, isFront:Bool) {
        if(!Particle.canCreate()) return;
        var t = Util.randf(.4, .6);
        var p = Particle.create(Tile.fromColor(isFront ? 0xFFFFFF : 0xAAAAAA, 4, 4).center(), t);
        p.xx = x;
        p.yy = y;
        p.vx = -dir * 50;
        p.vy = -50;
        p.frx = .01;
        p.fry = .01;
        p.targetScaleX = p.targetScaleY = 0.;
        if(isFront) {
            sbFront.add(p, true);
        } else {
            sbMid.add(p, true);
        }
    }

    public function jump(x:Float, y:Float, dir:Int) {
        if(!Particle.canCreate()) return;
        var time = .15;
        var tile = Tile.fromColor(0xFFFFFF, 16, 5);
        tile.dy = -2.5;
        var p = Particle.create(tile, time);
        p.xx = x;
        p.yy = y;
        p.rotation = -Math.PI * .5 + (dir * Math.PI * .15);
        p.targetScaleY = 0;
        sbMid.add(p, true);
    }

    public function wallJump(x:Float, y:Float, dir:Int) {
        if(!Particle.canCreate()) return;
        var time = .15;
        var tile = Tile.fromColor(0xFFFFFF, 16, 5);
        tile.dy = -2.5;
        var p = Particle.create(tile, time);
        p.xx = x;
        p.yy = y;
        p.rotation = -Math.PI * .5 + (dir * Math.PI * .25);
        p.targetScaleY = 0;
        sbMid.add(p, true);
    }
}