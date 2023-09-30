package ;

enum StableKind {
    Fast;
    Precise;
}

// https://www.youtube.com/watch?v=KPoeNZZ6H4s
class SecondOrderDynamics {
    @:s var prevTargetPos : Float;
    @:s public var pos(default, null) : Float;
    @:s public var vel(default, null) : Float;
    @:s var k1 : Float;
    @:s var k2 : Float;
    @:s var k3 : Float;
    @:s var dtCrit : Float;
    @:s var stableKind : StableKind;
    public function new(f:Float, z:Float, r:Float, initialPos:Float, stableKind:StableKind) {
        reset(initialPos);
        var ft = Util.TAU * f;
        k1 = 2 * z / ft;
        k2 = 1 / (ft * ft);
        k3 = r * z / ft;
        dtCrit = .8 * (Math.sqrt(4 * k2 + k1 * k1) - k1);
        this.stableKind = stableKind;
    }
    public function reset(initialPos:Float) {
        prevTargetPos = pos = initialPos;
        vel = 0;
    }
    public function update(dt:Float, targetPos:Float, ?targetVel:Float) {
        if(dt == 0) return;
        if(targetVel == null) {
            targetVel = (targetPos - prevTargetPos) / dt;
            prevTargetPos = targetPos;
        }
        inline function run(dt:Float, k2:Float, iterations:Int) {
            for(i in 0...iterations) {
                pos += dt * vel;
                vel += dt * (targetPos + k3 * targetVel - pos - k1 * vel) / k2;
            }
        }
        switch(stableKind) {
            case Fast:
                var k2Stable = Math.max(k2, 1.1 * (dt * dt / 4 + dt * k1 / 2));
                run(dt, k2Stable, 1);
            case Precise:
                var iterations = Math.ceil(dt / dtCrit);
                run(dt / iterations, k2, iterations);
        }
    }
    public inline function getKineticEnergy() {
        return .5 * k2 * vel * vel;
    }
    public inline function getPotentialEnergy() {
        var dpos = pos - prevTargetPos;
        return .5 * k1 * dpos * dpos;
    }
    public inline function getEnergy() {
        return getKineticEnergy() + getPotentialEnergy();
    }
}