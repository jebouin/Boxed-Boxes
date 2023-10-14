package background;

import h3d.scene.pbr.Renderer.DisplayMode;
import h2d.Tile;

class TiledParallax extends Parallax {
    var tile : Tile;
    var batch : CustomSpriteBatch;

    public function new(tile:Tile, layer:Int, speed:Float, levelWidth:Int, levelHeight:Int) {
        super(layer, speed, levelWidth, levelHeight);
        batch = new CustomSpriteBatch(tile, this);
        parallaxWidth = tile.iwidth;
        parallaxHeight = tile.iheight;
        for(i in 0...4) {
            batch.add(new CustomSpriteBatch.BatchElement(tile));
        }
    }

    override public function update(dt:Float) {
        if(!super.update(dt)) return false;
        var cameraClampedTargetX = -Game.inst.world.x + Main.WIDTH2;
        var cameraClampedTargetY = -Game.inst.world.y + Main.HEIGHT2;
        var xMin = cameraClampedTargetX - Main.WIDTH2;
        var yMin = cameraClampedTargetY - Main.HEIGHT2;
        var xOff = (cameraClampedTargetX - levelWidth * .5) * (1. - speed);
        xMin = Math.floor((xMin - xOff) / parallaxWidth) * parallaxWidth + xOff;
        var yOff = (cameraClampedTargetY - levelHeight * .5) * (1. - speed);
        yMin = Math.floor((yMin - yOff) / parallaxHeight) * parallaxHeight + yOff;
        var i = 0;
        for(e in batch.getElements()) {
            e.x = xMin + (i % 2) * (parallaxWidth - 1);
            e.y = yMin + Std.int(i / 2) * (parallaxHeight - 1);
            i++;
        }
        return true;
    }
}