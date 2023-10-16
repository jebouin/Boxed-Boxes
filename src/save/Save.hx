package save;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import hxbit.Serializable;
import hxbit.Serializer;
#if sys
import sys.io.File;
#end
#if int_ng
import integration.Newgrounds;
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
            trace("Error saving game to local storage: " + e);
        }
        #end
        #if int_ng
        if(Newgrounds.loggedIn) {
            try {
                Newgrounds.save(bytesToString(bytes));
            } catch(e) {
                trace("Error saving game to Newgrounds: " + e);
            }
        }
        #end
    }
    
    public static function loadGame(callback:Bool->Void) {
        function onBytesReceived(bytes) {
            if(bytes == null) {
                gameData = new GameSaveData();
                callback(false);
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
                callback(true);
            }
        }
        var bytes = null;
        #if sys
        try {
            bytes = File.getBytes(gameFileName + ".sav");
        } catch(e) {
        }
        onBytesReceived(bytes);
        #elseif int_ng
        if(Newgrounds.loggedIn) {
            Newgrounds.load(function(str) {
                var bytes = stringToBytes(str);
                onBytesReceived(bytes);
            }, function() {
                onBytesReceived(null);
            });
        }
        #elseif js
        try {
            bytes = stringToBytes(js.Browser.window.localStorage.getItem(gameFileName));
        } catch(e) {
        }
        onBytesReceived(bytes);
        #end
    }
    static function bytesToString(bytes:haxe.io.Bytes) {
        return Base64.encode(bytes);
    }
    static function stringToBytes(str:String) {
        var bytes = null;
        try {
            bytes = Base64.decode(str);
        } catch(e) {}
        return bytes;
    }
}