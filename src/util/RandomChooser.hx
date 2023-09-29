package util;

class RandomChooser<T> {
    var values : Array<T>;
    var weights : Array<Float>;

    public function new() {
        values = new Array<T>();
        weights = new Array<Float>();
    }

    public function add(val:T, weight:Float) {
        values.push(val);
        if(weights.length > 0) {
            weight += weights[weights.length - 1];
        }
        weights.push(weight);
    }

    public function choose() {
        var n = weights.length;
        var x = Math.random() * weights[n - 1];
        var lo = 0, hi = n - 1;
        while(lo < hi) {
            var mid = lo + ((hi - lo) >> 1);
            if(x < weights[mid]) {
                hi = mid;
            } else {
                lo = mid + 1;
            }
        }
        return values[lo];
    }
}