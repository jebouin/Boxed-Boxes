package audio;

import hxd.snd.Channel;
import hxd.snd.Manager;
import hxd.snd.ChannelGroup;

class Audio {
    public static var MUSIC_FADE_IN_TIME = .7;
    public static var MUSIC_FADE_OUT_TIME = 1.;
    static var manager : Manager;
    static var soundGroup : ChannelGroup;
    static var musicGroup : ChannelGroup;
    static var musicChannel : Channel;
    static var musicBackChannel : Channel;
    static var music : Music;
    static var musicBack : Music;

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
    public static function playMusic(name:String, ?next:String=null, ?fadeTime:Float=0.) {
        if(music != null && music.name == name) return;
        stopMusic();
        music = Assets.nameToMusic.get(name);
        if(music == null) {
            trace("Invalid music name", name);
            return;
        }
        musicChannel = music.sound.play(true, fadeTime > 0 ? 0 : 1., musicGroup);
        musicChannel.priority = 1.;
        if(fadeTime > 0) {
            musicChannel.fadeTo(1, fadeTime);
            if(musicBackChannel != null) {
                musicChannel.position = musicBackChannel.position;
            }
        }
        if(next == null && music.def.playNext != null && music.def.playNext != "") {
            next = music.def.playNext;
        }
        if(next != null) {
            musicChannel.loop = false;
            musicChannel.onEnd = function() {
                playMusic(next);
            }
        }
    }
    public static function stopMusic(?fadeTime:Float=0.) {
        if(musicChannel == null) return;
        musicBackChannel = musicChannel;
        musicBack = music;
        musicChannel = null;
        music = null;
        if(fadeTime > 0) {
            musicBackChannel.fadeTo(0., fadeTime, function() {
                musicBackChannel.stop();
                musicBackChannel = null;
                musicBack = null;
            });
        } else {
            musicBackChannel.stop();
            musicBackChannel = null;
            musicBack = null;
        }
    }
    public static function pauseMusic() {
        if(musicChannel == null) return;
        musicChannel.pause = true;
    }
    public static function resumeMusic() {
        if(musicChannel == null) return;
        musicChannel.pause = false;
    }
    public static function playSound(name:String, ?loop:Bool=false, ?vol:Float=1.) {
        var sound = Assets.nameToSound.get(name);
        if(sound == null) return null;
        return sound.play(loop, vol, soundGroup);
    }

    public static function onQuit() {
        // TODO: Stop long sounds
        stopMusic();
    }
    public static function onPause(force:Bool=false) {
        // TODO: Pause long sounds
        if(music != null && (force || !music.def.continueDuringPause) && musicChannel != null) {
            musicChannel.pause = true;
        }
    }
    public static function onResume() {
        // TODO: Resume long sounds
        if(music != null && musicChannel != null) {
            musicChannel.pause = false;
        }
    }
    public static function isMusicPlaying() {
        return musicChannel != null;
    }
}