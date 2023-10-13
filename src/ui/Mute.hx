package ui;

import save.Save;
import h2d.Text;
import audio.Audio;

class Mute {
    public static inline var STAY_TIME = .5;
    public static inline var FADE_TIME = .4;
    public static var musicEnabled : Bool = true;
    public static var soundEnabled : Bool = true;
    static var text : Text;
    static var timer : Float;

    public static function init() {
        var data = Save.gameData.data;
        musicEnabled = data.musicEnabled;
        soundEnabled = data.soundEnabled;
        Audio.setMusicVolume(musicEnabled ? 1. : 0.);
        Audio.setSoundEffectVolume(soundEnabled ? 1. : 0.);
    }

    public static function mute() {
        if(text != null) {
            text.remove();
            text = null;
        }
        text = new Text(Assets.font, Main.inst.hud);
        if(musicEnabled && soundEnabled) {
            musicEnabled = false;
            text.text = "MUSIC OFF";
            Audio.setMusicVolume(0.);
        } else if(!musicEnabled && soundEnabled) {
            soundEnabled = false;
            text.text = "SOUND OFF";
            Audio.setSoundEffectVolume(0.);
        } else if(!musicEnabled && !soundEnabled) {
            musicEnabled = true;
            text.text = "MUSIC ON";
            Audio.setMusicVolume(1.);
        } else {
            soundEnabled = true;
            text.text = "SOUND ON";
            Audio.setSoundEffectVolume(1.);
        }
        text.x = Main.WIDTH2 - text.textWidth * .5;
        text.y = Main.HEIGHT - text.textHeight;
        timer = 0.;
        Save.gameData.data.setMuteState(musicEnabled, soundEnabled);
    }

    public static function update(dt:Float) {
        if(text != null) {
            timer += dt;
            if(timer > FADE_TIME + STAY_TIME) {
                text.remove();
                text = null;
            } else if(timer > STAY_TIME) {
                text.alpha = 1. - (timer - STAY_TIME) / FADE_TIME;
            } else {
                text.alpha = 1.;
            }
        }
    }
}