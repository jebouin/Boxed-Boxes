package ;

import h2d.Drawable;
import h2d.Object;
import h2d.Tile;
import h2d.RenderContext;

class Anim extends Drawable {
	public var frames(default, null) : Array<Tile>;
	public var currentFrame(get, set) : Float;
	public var speed : Float;
	public var pause : Bool = false;
	public var loops : Bool = true;
	var curFrame : Float;

	public function new(?frames:Array<Tile>, speed:Float = 15, loops:Bool=true, ?parent:h2d.Object) {
		super(parent);
		this.frames = frames == null ? [] : frames;
		this.curFrame = 0;
		this.speed = speed;
		this.loops = loops;
	}

	inline function get_currentFrame() {
		return curFrame;
	}

	public function playCurrent(atFrame=0.) {
		play(frames, atFrame);
	}
	public function play(frames : Array<Tile>, atFrame = 0.) {
		this.frames = frames == null ? [] : frames;
		currentFrame = atFrame;
		pause = false;
	}
	public function playFromName(sheetName:String, name:String, atFrame = 0.) {
		var data = Assets.getAnimData(sheetName, name);
		if(data == null) return;
		play(data.tiles, atFrame);
		speed = data.fps;
		loops = data.loops;
	}

	public dynamic function onAnimEnd() {
	}

	function set_currentFrame(frame:Float) {
		curFrame = frames.length == 0 ? 0 : frame % frames.length;
		if(curFrame < 0) curFrame += frames.length;
		return curFrame;
	}

	override function getBoundsRec(relativeTo:Object, out:h2d.col.Bounds, forSize:Bool) {
		super.getBoundsRec(relativeTo, out, forSize);
		var tile = getFrame();
		if(tile != null) addBounds(relativeTo, out, tile.dx, tile.dy, tile.width, tile.height);
	}

	public function update(dt:Float) {
		var prev = curFrame;
		if(!pause) {
            curFrame += speed * dt;
        }
		if(curFrame < frames.length) {
            return;
        }
		if(loops) {
			if(frames.length == 0) {
				curFrame = 0;
            } else {
				curFrame %= frames.length;
            }
			onAnimEnd();
		} else if(curFrame >= frames.length) {
			curFrame = frames.length;
			if(curFrame != prev) {
                onAnimEnd();
            }
		}
	}

	public inline function getCurrentIFrame() {
		return Std.int(curFrame);
	}

	public function getFrame() : Tile {
		var i = getCurrentIFrame();
		if(i == frames.length) i--;
		return frames[i];
	}

	override function draw(ctx:RenderContext) {
        emitTile(ctx, getFrame());
	}
}