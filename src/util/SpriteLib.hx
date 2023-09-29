package util;

class SpriteLib {
    public static function getAnimFrames(tile:h2d.Tile, frameWidth:Int, frameHeight:Int, ?frameCount:Null<Int>, ?cx:Null<Float>, ?cy:Null<Float>) {
        var w = Std.int(tile.width / frameWidth);
        var h = Std.int(tile.height / frameHeight);
        if(cx == null) {
            cx = Std.int(frameWidth * .5);
            cy = Std.int(frameHeight * .5);
        }
        var frames = [];
        if(frameCount == null) {
            frameCount = w * h;
        }
        for(f in 0...frameCount) {
            var i = Std.int(f / w), j = f % w;
            var sub = tile.sub(j * frameWidth, i * frameHeight, frameWidth, frameHeight, -cx, -cy);
            frames.push(sub);
        }
        return frames;
    }
}