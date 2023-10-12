package audio;

import hxd.snd.ChannelGroup;
import hxd.Res;
import hxd.res.Sound;
import Data;

class VariedSound {
    public var sounds : Array<Sound>;
    public var def : Data.SoundDef;

    public function new(def:Data.SoundDef) {
        this.def = def;
        sounds = [];
        if(def.variationCount > 1) {
            for(i in 1...def.variationCount + 1) {
                loadSound(def.name + i);
            }
        } else {
            loadSound(def.name);
        }
    }

    inline function loadSound(name:String) {
        var sound = Res.load("sfx/" + name + ".wav").toSound();
        sound.getData();
        sounds.push(sound);
    }

    function getSound(vol:Float) {
        if(sounds.length == 0) throw "No sounds loaded!";
        if(sounds.length == 1) return sounds[0];
        if(def.scaleVolume) {
            var i = Std.int(vol * sounds.length);
            if(i > sounds.length - 1) i = sounds.length - 1;
            return sounds[i];
        }
        return sounds[Std.random(sounds.length)];
    }

    public function play(loop:Bool, volumeMult:Float, group:ChannelGroup) {
        var sound = getSound(volumeMult);
        if(def.scaleVolume) {
            volumeMult = 1.;
        }
        return sound.play(loop, volumeMult * def.volume, group);
    }
}