package save;

import haxe.io.Bytes;
import hxbit.Serializable;
import hxbit.Serializer;
#if sys
import sys.io.File;
#end
import Game;

class SaveHeader implements Serializable {
    @:s public var version : String = null;
    @:s public var timestamp : Null<Float> = null;

    public function new() {
        version = Main.GAME_VERSION;
        timestamp = Date.now().getTime();
    }
}

class GameSaveData implements Serializable {
    @:s public var header : SaveHeader = null;
    @:s public var data : GameData = null;

    public function new(?header, ?data) {
        if(header == null) {
            header = new SaveHeader();
        }
        if(data == null) {
            data = new GameData();
        }
        this.header = header;
        this.data = data;
    }

    public function init() {
        data.init();
    }
}

class Save {
    static var gameFileName : String;
    public static var gameData : GameSaveData;

    public static function init(callback:Bool->Void) {
        gameFileName = Main.GAME_ID + "Save";
        gameData = new GameSaveData();
        loadGame(callback);
    }

    public static function saveGame() {
        var s = new Serializer();
        s.beginSave();
        s.addDynamic(gameData);
        var bytes = s.endSave();
        #if sys
        File.saveBytes(gameFileName + ".sav", bytes);
        #elseif js
        try {
            js.Browser.window.localStorage.setItem(gameFileName, bytesToString(bytes));
        } catch(e) {
            trace("Error saving game: " + e);
        }
        #end
    }

    public static function loadGame(callback:Bool->Void) {
        var bytes = null;
        var success = false;
        #if sys
        try {
            bytes = File.getBytes(gameFileName + ".sav");
            success = true;
        } catch(e) {}
        #elseif js
        try {
            bytes = stringToBytes(js.Browser.window.localStorage.getItem(gameFileName));
            success = true;
        } catch(e) {
        }
        #end
        if(!success) {
            gameData = new GameSaveData();
            callback(false);
            return;
        }
        if(bytes == null) {
            gameData = new GameSaveData();
        } else {
            try {
                var s = new Serializer();
                s.beginLoad(bytes);
                gameData = s.getDynamic();
                s.endLoad();
                //gameData.init();
            } catch(e) {
                gameData = new GameSaveData();
            }
        }
        callback(true);
    }
    static function bytesToString(bytes:haxe.io.Bytes) {
        var str = "";
        for(i in 0...bytes.length) {
            str += String.fromCharCode(bytes.get(i));
        }
        return str;
    }
    static function stringToBytes(str:String) {
        var bytes = Bytes.alloc(str.length);
        for(i in 0...str.length) {
            bytes.set(i, str.charCodeAt(i));
        }
        return bytes;
    }
}