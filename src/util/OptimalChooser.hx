package util;

class OptimalChooser<T> {
    var values : Array<T>;
    var scores : Map<Int, Float>;
    var f : T->Float;

    public function new() {
        values = new Array<T>();
        scores = new Map<Int, Float>();
        f = null;
    }

    inline function getScore(i:Int) {
        if(!scores.exists(i)) {
            scores[i] = 0;
        }
        return scores[i];
    }

    public inline function add(v:T) {
        var n = values.push(v);
        if(f != null) {
            scores[n - 1] = f(v);
        }
    }

    public inline function setScoringFunction(f : T->Float) {
        this.f = f;
        for(i in 0...values.length) {
            scores[i] = f(values[i]);
        }
    }

    public function getBest() : Null<T> {
        var bid = -1, maxi = 0.;
        for(i in 0...values.length) {
            var cur = getScore(i);
            if(bid < 0 || cur > maxi) {
                maxi = cur;
                bid = i;
            }
        }
        if(bid < 0 || bid >= values.length) {
            return null;
        }
        return values[bid];
    }
}