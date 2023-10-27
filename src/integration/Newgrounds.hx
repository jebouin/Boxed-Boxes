package integration;

import save.Save;
import io.newgrounds.NG;
import io.newgrounds.objects.events.ResultType;

class Newgrounds {
    public static var loggedIn : Bool;
    static var loadedCallback : Void->Void;
    public static function init(callback:Void->Void) {
        loadedCallback = callback;
        NG.createAndCheckSession(Secret.NEWGROUNDS_APP_ID);
        #if debug
        NG.core.verbose = true;
        #end
        NG.core.setupEncryption(Secret.NEWGROUNDS_ENCRYPTION_KEY, AES_128, BASE_64);
        loggedIn = false;
        if(NG.core.attemptingLogin) {
			NG.core.onLogin.add(onLogin);
		} else {
            #if test_medals
            NG.core.requestLogin(onLogin);
            #else
            callback();
            #end
        }
    }

    static function onLogin() {
        NG.core.requestMedals(function() {
            #if (test_medals && int_ng_clear_save)
            NG.core.saveSlots.loadAllFiles(function(res) {
                NG.core.saveSlots[1].clear(onFetched);
            });
            #else
            NG.core.saveSlots.loadAllFiles(onFetched);
            #end
        }, function(e) {
            loadedCallback();
        });
    }

    static function onFetched(r:ResultType) {
        switch(r) {
            case Success:
                loggedIn = true;
            case Error(e):
                Main.println("Error fetching save slots: " + e);
        }
        loadedCallback();
    }

    public static function save(data:String) {
        if(!loggedIn) {
            return;
        }
        var saveSlot = NG.core.saveSlots[1];
        saveSlot.save(data, function(r) {
			switch(r) {
				case Error(e):
                    Main.println('Error saving Newgrounds data: "$e"');
                case Success:
                    trace("SAVED TO NG: " + data);
			}
        });
    }

    public static function load(callback:String->Void, onFail:Void->Void) {
        if(!loggedIn) {
            onFail();
            return;
        }
        try {
            var saveSlot = NG.core.saveSlots[1];
            saveSlot.load(function(r) {
                switch(r) {
                    case Error(e):
                        Main.println('Error loading Newgrounds data: "#e"');
                        onFail();
                    case Success(data):
                        callback(data);
                }
            });
        } catch(e) {
            onFail();
        }
    }

    public static function checkMedals() {
        var baseMedalId = 75603;
        for(k in 0...3) {
            var allCompleted = true;
            for(l in 0...9) {
                var levelId = k * 9 + l + 1;
                if(Save.gameData.data.levelsCompleted.get(levelId) == null || !Save.gameData.data.levelsCompleted.get(levelId)) {
                    allCompleted = false;
                    break;
                }
            }
            if(allCompleted) {
                unlockMedal(baseMedalId + k);
            }
        }
    }

    public static function unlockMedal(id:Int) {
        #if !test_medals
        if(NG.core.user.name == "jebouin") return;
        #end
        var medal = NG.core.medals.get(id);
        if(medal == null) {
            Main.println("Couldn't unlock NG medal with id " + id);
        } else {
            medal.sendUnlock();
        }
    }

    public static function isMedalUnlocked(id:Int) {
        var medal = NG.core.medals.get(id);
        if(medal == null) {
            Main.println("Couldn't check NG medal with id " + id);
            return false;
        } else {
            return medal.unlocked;
        }
    }

    public static function logEvent(s:String) {
        #if !test_medals
        if(NG.core.user.name == "jebouin") return;
        #end
        var call = NG.core.calls.event.logEvent(s);
        call.send();
    }

    public static function sendScore(id:Int, score:Int) {
        #if !test_medals
        if(NG.core.user.name == "jebouin") return;
        #end
        var call = NG.core.calls.scoreBoard.postScore(id, score);
        call.send();
    }

    public static function resetEvent(s:String) {

    }
}