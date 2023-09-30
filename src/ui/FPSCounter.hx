package ui;

import hxd.Timer;

class FPSCounter {
	public static inline var AVERAGE_COUNT = 30;
	var arr : Array<Float>;
	var tf : h2d.Text;

	public function new(font:h2d.Font) {
		arr = [];
		tf = new h2d.Text(font, Main.inst.s2d);
        tf.scale(2);
        onResize();
	}

	public function update() {
		var cur = Timer.fps();
		arr.push(cur);
		if(arr.length > AVERAGE_COUNT) {
			arr.shift();
		}
		if(arr.length == AVERAGE_COUNT) {
			var sorted = arr.copy();
			sorted.sort(function(a, b) return a > b ? 1 : (a < b ? -1 : 0));
			var med = sorted[sorted.length >> 1];
			tf.text = Std.int(med) + " FPS";
		}
	}

	public function show() {
		tf.visible = true;
	}

	public function hide() {
		tf.visible = false;
	}

    public function onResize() {
        tf.x = Main.inst.s2d.width - 80;
        tf.y = Main.inst.s2d.height - 2 * tf.font.lineHeight - 2;
    }
}