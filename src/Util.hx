package ;

import h3d.Vector;
import haxe.Int32;
import haxe.ds.IntMap;
import h2d.col.Bounds;
import h2d.Graphics;
import h2d.col.Point;

class Util {
	public static inline var TAU = 6.28318530718;
	public static inline var SQRT2 = 1.4142135623730951;
    public static inline var ISQRT2 = 0.7071067811865475;
	public static inline var HUE_YELLOW = 1. / 6;
	public static inline var HUE_BLUE = 4. / 6;

	public static inline function wrap(x:Int, min:Int, max:Int) : Int {
		return x < min ? (x - min) + max + 1: ((x > max) ? (x - max) + min - 1: x);
	}

	public static inline function frac(x:Float) {
		return x >= 0 ? x - Std.int(x) : Std.int(x) - x;
	}

	public static inline function fmin(x:Float, y:Float) : Float {
		return x < y ? x : y;
	}
	public static inline function fmax(x:Float, y:Float) : Float {
		return x > y ? x : y;
	}
	public static inline function fclamp(x:Float, mini:Float, maxi:Float) : Float {
		return x < mini ? mini : (x > maxi ? maxi : x);
	}
	public static inline function vclamp(x:Vector, mini:Vector, maxi:Vector) : Vector {
		return new Vector(fclamp(x.x, mini.x, maxi.x), fclamp(x.y, mini.y, maxi.y), fclamp(x.z, mini.z, maxi.z));
	}
	public static inline function imin(x:Int, y:Int) : Int {
		return x < y ? x : y;
	}
	public static inline function imax(x:Int, y:Int) : Int {
		return x > y ? x : y;
	}
	public static inline function iclamp(x:Int, mini:Int, maxi:Int) : Int {
		return x < mini ? mini : (x > maxi ? maxi : x);
	}

	public static inline function fpow2(x:Float) {
		return x * x;
	}
	public static inline function fpow3(x:Float) {
		return x * x * x;
	}


	public static inline function clampAngle(x:Float, mini:Float, maxi:Float) : Float {
		if(x < mini) {
			x += floor((mini - x) / TAU) * TAU;
		}
		if(x > maxi) {
			x -= floor((x - maxi) / TAU) * TAU;
		}
		return fclamp(x, mini, maxi);
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
	// Only works for angles not too far apart
	public static inline function radClosestTo(curAng:Float, target:Float) {
		if(Math.abs(curAng - target) <= Math.PI) {
			return curAng;
		}
		return curAng > target ? curAng - Math.PI * 2 : curAng + Math.PI * 2;
	}

	public static inline function radSubstract(a:Float, b:Float) {
		a = normalizeRad(a);
		b = normalizeRad(b);
		return normalizeRad(a - b);
	}

    public static inline function normalizeRad(a:Float) {
		while(a < -Math.PI) a += TAU;
		while(a > Math.PI) a -= TAU;
		return a;
	}

    public static inline function normalizeRad2(a:Float) {
		return (a % TAU + TAU) % TAU;
	}

	public static inline function randi(lo:Int, hi:Int) {
		return lo + Std.random(hi - lo + 1);
	}

	public static inline function randf(lo:Float, hi:Float) {
		return lo + Math.random() * (hi - lo);
	}

	public static inline function randCircle(rmin:Float, rmax:Float) {
		var d = randf(rmin, rmax);
		var a = Math.random() * TAU;
		return new Point(d * Math.cos(a), d * Math.sin(a));
	}

	public static inline function randSphere(rmin:Float, rmax:Float) {
		var z = randf(-1, 1);
		var rxy = Math.sqrt(1 - z * z);
		var phi = randf(0, TAU);
		var x = rxy * Math.cos(phi);
		var y = rxy * Math.sin(phi);
		return new h3d.col.Point(x, y, z);
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

	public static inline function colorFromRGB(r:Int, g:Int, b:Int) {
		return (r << 16) + (g << 8) + b;
	}

	public static function formatFloat(x:Float, precision:Int){
		if(precision <= 0) {
			return "" + Math.round(x);
		}
		var neg = false;
		if(x < 0) {
			neg = true;
			x *= -1;
		}
		x = Math.round(x * Math.pow(10, precision));
		var s = "" + x;
		if(s.length <= precision) {
			while(s.length < precision) {
				s = "0" + s;
			}
			s = "0." + s;
		} else {
			s = s.substr(0, s.length - precision) + '.' + s.substr(s.length - precision);
		}
		if(neg) {
			s = "-" + s;
		}
		return s;
	}
	public inline static function quantize(x:Float, step:Float) {
		return step == 0 ? x : Math.round(x / step) * step;
	}
	public inline static function smoothStepK(x:Float, k=0.) {
		return 2*(k - 1)*x*x*x + 3*(1 - k)*x*x + k*x;
	}
	public inline static function smoothStepsK(x:Float, step:Float, k=0.) {
		return steps(x, step, x -> smoothStepK(x, k));
	}
	public inline static function smoothStep(x:Float) {
		return smoothStepK(x);
	}
	public inline static function smoothSteps(x:Float, step:Float) {
		return steps(x, step, smoothStep);
	}
	public inline static function smootherStep(x:Float) {
		return 6 * x * x * x * x * x - 15 * x * x * x * x + 10 * x * x * x;
	}
	public inline static function smootherSteps(x:Float, step:Float) {
		return steps(x, step, smootherStep);
	}
	public inline static function steps(x:Float, step:Float, f:Float->Float) {
		var fx = floor(x / step);
		return step * f(x / step - fx) + step * fx;
	}
	public static function bresenham(x1:Int, y1:Int, x2:Int, y2:Int) {
		var dx = iabs(x2 - x1);
		var sx = x1 < x2 ? 1 : -1;
		var dy = -iabs(y2 - y1);
		var sy = y1 < y2 ? 1 : -1;
		var error = dx + dy;
		var ans = [];
		while(true) {
			ans.push({x:x1, y:y1});
			if(x1 == x2 && y1 == y2) break;
			var e2 = 2 * error;
			if(e2 >= dy) {
				if(x1 == x2) break;
				error += dy;
				x1 += sx;
			}
			if(e2 <= dx) {
				if(y1 == y2) break;
				error += dx;
				y1 += sy;
			}
		}
		return ans;
	}
	public static function rasterPolygon(points:Array<{x:Int, y:Int}>) {
		var lines : Array<{y:Int, x1:Int, x2:Int}> = [];
		var edges : Array<{x:Int, y:Int}> = [];
		for (i in 0...points.length) {
			var p1 = points[i];
			var p2 = (i == (points.length - 1)) ? points[0] : points[i + 1];
			var p1p2 = bresenham(p1.x, p1.y, p2.x, p2.y);
			edges = edges.concat(p1p2);
		}
		var yToXs:IntMap<Array<Int>> = new IntMap<Array<Int>>();
		for (point in edges) {
			var s = yToXs.get(point.y);
			if (s != null) {
				s.push(point.x);
			} else {
				yToXs.set(point.y, [point.x]);
			}
		}
		for (key in yToXs.keys()) {
			var arr = yToXs.get(key);
			var mini = arr[0], maxi = arr[0];
			for(x in arr) {
				if(x < mini) mini = x;
				if(x > maxi) maxi = x;
			}
			lines.push({y:key, x1:mini, x2:maxi});
		}
		return lines;
	}

	public static function easeOutBack(x:Float) {
		var c1 = 1.70158;
		var c3 = c1 + 1;
		return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
	}

	public static function rotateAround(pt:Point, center:Point, angle:Float) {
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		var x = pt.x - center.x;
		var y = pt.y - center.y;
		return new Point(x * c - y * s + center.x, x * s + y * c + center.y);
	}

	public static inline function sodStep(from:Float, to:Float, acc:Float, dt:Float) {
        return to + (from - to) * Math.pow(1. - acc, dt);
	}

	public static inline function boundsFromIntervals(xMin:Float, xMax:Float, yMin:Float, yMax:Float) {
		return Bounds.fromValues(xMin, yMin, xMax - xMin, yMax - yMin);
	}
	public static inline function shrinkBounds(bounds:Bounds, dx:Float, dy:Float) {
		return boundsFromIntervals(bounds.xMin + dx, bounds.xMax - dx, bounds.yMin + dy, bounds.yMax - dy);
	}

	public static inline function hslToRGB(h:Float, s:Float, l:Float) {
		if(s == 0) {
			return {r:l, g:l, b:l};
		}
		function hue2rgb(p:Float, q:Float, t:Float) {
			if(t < 0) t += 1;
			if(t > 1) t -= 1;
			if(t < 1 / 6) return p + (q - p) * 6 * t;
			if(t < 1 / 2) return q;
			if(t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
			return p;
		}
		var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
		var p = 2 * l - q;
		var r = hue2rgb(p, q, h + 1/3);
		var g = hue2rgb(p, q, h);
		var b = hue2rgb(p, q, h - 1/3);
		return {r:r, g:g, b:b};
	}
	public static inline function rgbToHSL(col:Int) {
		var r = ((col >> 16) & 0xFF) / 255;
		var g = ((col >> 8) & 0xFF) / 255;
		var b = (col & 0xFF) / 255;
		var max = Util.fmax(r, Util.fmax(g, b));
		var min = Util.fmin(r, Util.fmin(g, b));
		var h = 0.;
		var s = 0.;
		var l = (max + min) / 2;
		if(max != min) {
			var d = max - min;
			s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
			if(max == r) {
				h = (g - b) / d + (g < b ? 6 : 0);
			} else if(max == g) {
				h = (b - r) / d + 2;
			} else {
				h = (r - g) / d + 4;
			}
			h /= 6;
		}
		return {h:h, s:s, l:l};
	}
	public static inline function adjustColor(col:Int, hue:Float, hueMult:Float, lumMult:Float) {
		var alpha = (col >> 24) & 0xFF;
		var hsl = rgbToHSL(col);
		var dist = 0., add = true;
		if(hsl.h < hue) {
			if(hue - hsl.h > .5) {
				dist = 1. - (hue - hsl.h);
				add = false;
			} else {
				dist = hue - hsl.h;
				add = true;
			}
		} else {
			if(hsl.h - hue > .5) {
				dist = 1. - (hsl.h - hue);
				add = true;
			} else {
				dist = hsl.h - hue;
				add = false;
			}
		}
		hsl.h += (add ? 1 : -1) * hueMult * dist;
		while(hsl.h < 0) hsl.h += 1.;
		while(hsl.h > 1) hsl.h -= 1.;
		hsl.l = fclamp(hsl.l * lumMult, 0, 1);
		var rgb = hslToRGB(hsl.h, hsl.s, hsl.l);
		return rgbToInt(rgb, alpha);
	}
	public static inline function rgbToInt(rgb:{r:Float, g:Float, b:Float}, alpha=255) {
		return (alpha << 24) | Std.int(rgb.r * 255) << 16 | Std.int(rgb.g * 255) << 8 | Std.int(rgb.b * 255);
	}
	public static inline function interpolateColors(col1:Int, col2:Int, t:Float) {
		var alpha1 = (col1 >> 24) & 0xFF;
		var alpha2 = (col2 >> 24) & 0xFF;
		var hsl1 = rgbToHSL(col1);
		var hsl2 = rgbToHSL(col2);
		if(hsl1.h < hsl2.h && hsl2.h - hsl1.h > .5) {
			hsl1.h += 1;
		}
		if(hsl2.h < hsl1.h && hsl1.h - hsl2.h > .5) {
			hsl2.h += 1;
		}
		var h = hsl1.h * (1 - t) + hsl2.h * t;
		if(h > 1) h -= 1;
		var s = hsl1.s * (1 - t) + hsl2.s * t;
		var l = hsl1.l * (1 - t) + hsl2.l * t;
		var rgb = hslToRGB(h, s, l);
		var alpha = Std.int(alpha1 * (1 - t) + alpha2 * t);
		return (alpha << 24) | Std.int(rgb.r * 255) << 16 | Std.int(rgb.g * 255) << 8 | Std.int(rgb.b * 255);
	}

	public static inline function rotateSpherical(coords:{theta:Float, phi:Float}, axis:h3d.col.Point, alpha:Float) {
		var pos = new h3d.col.Point(Math.cos(coords.phi) * Math.cos(coords.theta), Math.cos(coords.phi) * Math.sin(coords.theta), Math.sin(coords.phi));
		var add1 = pos.clone();
		add1.scale(Math.cos(alpha));
		var add2 = axis.cross(pos);
		add2.scale(Math.sin(alpha));
		var add3 = axis.clone();
		add3.scale(axis.dot(pos) * (1. - Math.cos(alpha)));
		var resultPos = add1.add(add2).add(add3);
		coords.theta = Math.atan2(resultPos.y, resultPos.x);
		coords.phi = Math.atan2(resultPos.z, Math.sqrt(resultPos.x * resultPos.x + resultPos.y * resultPos.y));
	}
}