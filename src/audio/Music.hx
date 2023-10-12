package audio;

import hxd.snd.ChannelGroup;
import hxd.Res;
import hxd.res.Sound;
import Data;

class Music {
    public var sound : Sound;
    public var name : String;
    public var def : Data.MusicDef;

    public function new(def:Data.MusicDef) {
        this.name = def.name;
        this.def = def;
        var prefix = #if js "music/exportMP3/" #else "music/exportWAV/" #end;
        var suffix = #if js ".mp3" #else ".wav" #end;
        sound = Res.load(prefix + def.name + suffix).toSound();
        sound.getData();
    }
}