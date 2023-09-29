package util;

import h2d.Graphics;
import h2d.col.Point;

class Util {
	public static inline function wrap(x:Int, min:Int, max:Int) : Int {
		return x < min ? (x - min) + max + 1: ((x > max) ? (x - max) + min - 1: x);
	}

	public static inline function fmin(x:Float, y:Float) : Float {
		return x < y ? x : y;
	}
	public static inline function fmax(x:Float, y:Float) : Float {
		return x > y ? x : y;
	}
	public static inline function imin(x:Int, y:Int) : Int {
		return x < y ? x : y;
	}
	public static inline function imax(x:Int, y:Int) : Int {
		return x > y ? x : y;
	}

	public static inline function fpow2(x:Float) {
		return x * x;
	}
	public static inline function fpow3(x:Float) {
		return x * x * x;
	}

	public static inline function clamp(x:Float, mini:Float, maxi:Float) : Float {
		return x < mini ? mini : (x > maxi ? maxi : x);
	}

	public static inline function floor(x:Float) : Int {
		return if(x >= 0) {
			Std.int(x);
		} else {
			var i = Std.int(x);
			if(x == i) {
				i;
			} else {
				i - 1;
			}
		}
	}

	public static inline function fabs(x:Float) : Float {
		return x < 0 ? -x : x;
	}
	public static inline function iabs(x:Int) : Int {
		return x < 0 ? -x : x;
	}

	public static inline function sign(x:Float) {
		return x < 0 ? -1 : (x > 0 ? 1 : 0);
	}

	public static inline function lerp(x1:Float, x2:Float, t:Float) {
		return (1 - t) * x1 + t * x2;
	}
	public static inline function bezier(x1:Float, x2:Float, x3:Float, x4:Float, t:Float) {
		return fpow3(1 - t) * x1 + 3 * t * fpow2(1 - t) * x2 + 3 * fpow2(t) * (1 - t) * x3 + fpow3(t) * x4;
	}

    public static inline function radDistance(a:Float, b:Float) {
		return fabs(radSubstract(a,b));
	}

	public static inline function radCloseTo(curAng:Float, target:Float, maxAngDist:Float) {
		return radDistance(curAng, target) <= fabs(maxAngDist);
	}

	public static inline function radSubstract(a:Float, b:Float) {
		a = normalizeRad(a);
		b = normalizeRad(b);
		return normalizeRad(a - b);
	}

    public static inline function normalizeRad(a:Float) {
		while(a < -Math.PI) a += 2. * Math.PI;
		while(a > Math.PI) a -= 2 * Math.PI;
		return a;
	}

	public static inline function randi(lo:Int, hi:Int) {
		return lo + Std.random(hi - lo + 1);
	}

	public static inline function randf(lo:Float, hi:Float) {
		return lo + Math.random() * (hi - lo);
	}

	public static inline function randCircle(rmin:Float, rmax:Float) {
		var d = randf(rmin, rmax);
		var a = Math.random() * 2 * Math.PI;
		return new Point(d * Math.cos(a), d * Math.sin(a));
	}

	public static inline function randSign() : Int {
		return Std.random(2) * 2 - 1;
	}

	public static inline function distSq(x1:Float, y1:Float, x2:Float, y2:Float) {
		var dx = x1 - x2;
		var dy = y1 - y2;
		return dx * dx + dy * dy;
	}

	public static function drawProfilePart(g:Graphics, pts:Array<Point>, r:Float) {
		var cnt = pts.length, totalLen = 0.;
		for(i in 1...cnt) {
			totalLen += pts[i - 1].distance(pts[i]);
		}
		g.moveTo(pts[0].x, pts[0].y);
		var remLen = r * totalLen;
		for(i in 1...cnt) {
			if(remLen == 0) break;
			var dist = pts[i - 1].distance(pts[i]);
			var use = fmin(remLen, dist);
			if(dist <= remLen) {
				g.lineTo(pts[i].x, pts[i].y);
				remLen -= dist;
			} else {
				var t = remLen / dist;
				g.lineTo(lerp(pts[i - 1].x, pts[i].x, t), lerp(pts[i - 1].y, pts[i].y, t));
				remLen = 0;
			}
		}
	}
}