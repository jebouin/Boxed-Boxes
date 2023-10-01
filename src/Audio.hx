package ;

import hxd.snd.Channel;
import hxd.snd.Manager;
import hxd.snd.ChannelGroup;

class Audio {
    static var manager : Manager;
    static var soundGroup : ChannelGroup;
    static var musicGroup : ChannelGroup;
    static var musicChannel : Channel;

    public static function init() {
        manager = Manager.get();
        soundGroup = new ChannelGroup("sound");
        musicGroup = new ChannelGroup("music");
        musicGroup.volume = .85;
    }
    public static function setMasterVolume(v:Float) {
        manager.masterVolume = v;
    }
    public static function setMusicVolume(v:Float) {
        musicGroup.volume = v;
    }
    public static function setSoundEffectVolume(v:Float) {
        soundGroup.volume = v;
    }
    public static function mute() {
        manager.masterVolume = 0;
    }
    public static function unmute() {
        manager.masterVolume = 1;
    }
    public static function playSound(name:String, ?loop:Bool=false, ?vol:Float=1.) {
        var sound = Assets.nameToSound.get(name);
        if(sound == null) return null;
        return sound.play(loop, vol, soundGroup);
    }
}