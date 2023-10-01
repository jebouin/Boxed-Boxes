package ;

import h2d.Tile;
import haxe.ds.StringMap;
import hxd.Pad;
import hxd.Key;

enum abstract PadButton(Int) {
    var INVALID;
    var A;
    var B;
    var X;
    var Y;
    var START;
    var SELECT;
    var LT;
    var RT;
    var LB;
    var RB;
    var DPAD_UP;
    var DPAD_RIGHT;
    var DPAD_DOWN;
    var DPAD_LEFT;
    var LSTICK_PUSH;
    var RSTICK_PUSH;
    var LSTICK_X;
	var LSTICK_Y;
	var LSTICK_UP;
	var LSTICK_RIGHT;
	var LSTICK_DOWN;
	var LSTICK_LEFT;
    var RSTICK_X;
	var RSTICK_Y;
	var RSTICK_UP;
	var RSTICK_RIGHT;
	var RSTICK_DOWN;
	var RSTICK_LEFT;
}

enum abstract GamepadType(Int) {
    var None;
    var XBox360;
    var Switch;
}

enum abstract ControllerType(Int) {
    var Keyboard;
    var Gamepad;
}

enum abstract Action(Int) {
    var moveX;
    var moveY;
    var jump;
    var retry;
    var menuUp;
    var menuRight;
    var menuDown;
    var menuLeft;
    var menuEnter;
    var menuQuit;
}

class Controller {
    public static var actionNames = ["flipperLeft", "flipperRight", "moveUp", "moveRight", "moveDown", "moveLeft", "retry", "menuEnter", "menuExit", "pause", "mapToggle", "mapMoveX", "mapMoveY"];
    public static inline function padButtonToString(b:PadButton) {
        return switch(b) {
            case A: "A";
            case B: "B";
            case X: "X";
            case Y: "Y";
            case START: "START";
            case SELECT: "SELECT";
            case LT: "LT";
            case RT: "RT";
            case LB: "LB";
            case RB: "RB";
            case DPAD_UP: "DPAD UP";
            case DPAD_RIGHT: "DPAD RIGHT";
            case DPAD_DOWN: "DPAD DOWN";
            case DPAD_LEFT: "DPAD LEFT";
            case LSTICK_PUSH: "LSTICK PUSH";
            case RSTICK_PUSH: "RSTICK PUSH";
            case LSTICK_UP: "LSTICK UP";
            case LSTICK_RIGHT: "LSTICK RIGHT";
            case LSTICK_DOWN: "LSTICK DOWN";
            case LSTICK_LEFT: "LSTICK LEFT";
            case RSTICK_UP: "RSTICK UP";
            case RSTICK_RIGHT: "RSTICK RIGHT";
            case RSTICK_DOWN: "RSTICK DOWN";
            case RSTICK_LEFT: "RSTICK LEFT";
            default: return "UNKNOWN";
        };
    }

    public var padType : GamepadType = GamepadType.None;
    public var pad : hxd.Pad;
    public var onConnect : Void->Void;
    public var onDisconnect : Void->Void;
    public var onBindingsChange : Void->Void;
    var bindings : Map<Action, Array<Binding> >;
    public var padButtonToId : Map<PadButton, Int>;
    var onControllerChange : Void->Void;
    public var enabled : Bool = true;
    public var ignoreNextInput : Bool = false;

    public function new() {
        bindings = new Map();
        padButtonToId = new Map();
        waitForPad();
    }

    public function waitForPad() {
        pad = hxd.Pad.createDummy();
        initButtonMapping();
		hxd.Pad.wait(onPadConnected);
    }

    function onPadDisconnected() {
		waitForPad();
        if(onDisconnect != null) {
            onDisconnect();
        }
	}

	function onPadConnected(pad:hxd.Pad) {
		this.pad = pad;
        updatePadType();
		pad.onDisconnect = onPadDisconnected;
        if(onConnect != null) {
            onConnect();
        }
	}

    function updatePadType() {
        var name = pad.name.toLowerCase();
        if(name.indexOf("xbox") != -1) {
            padType = GamepadType.XBox360;
        } else if(name.indexOf("switch") != -1) {
            padType = GamepadType.Switch;
        } else {
            padType = GamepadType.None;
        }
    }

    function getNewBindingFromPadButton(action:Action, button:PadButton) : Binding {
        if(button == LSTICK_UP) {
            return Binding.newFromPadDirection(this, action, true, false, -1);
        } else if(button == LSTICK_RIGHT) {
            return Binding.newFromPadDirection(this, action, true, true, 1);
        } else if(button == LSTICK_DOWN) {
            return Binding.newFromPadDirection(this, action, true, false, 1);
        } else if(button == LSTICK_LEFT) {
            return Binding.newFromPadDirection(this, action, true, true, -1);
        } else if(button == RSTICK_UP) {
            return Binding.newFromPadDirection(this, action, false, false, -1);
        } else if(button == RSTICK_RIGHT) {
            return Binding.newFromPadDirection(this, action, false, true, 1);
        } else if(button == RSTICK_DOWN) {
            return Binding.newFromPadDirection(this, action, false, false, 1);
        } else if(button == RSTICK_LEFT) {
            return Binding.newFromPadDirection(this, action, false, true, -1);
        }
		return Binding.newFromPad(this, action, button);
	}

    public function isUsingGamepad() {
        return pad.index != -1;
    }

    public function bindPad(action:Action, ?button:PadButton, ?buttons:Array<PadButton>) {
		if((buttons == null && button == null) || (buttons != null && button != null)) {
            throw "Need exactly 1 button argument";
        }
		if(buttons == null) {
            buttons = [button];
        }
		for(b in buttons) {
            var binding = getNewBindingFromPadButton(action, b);
            storeBinding(action, binding);
		}
	}

    public function bindPadLStick(actionX:Action, actionY:Action) {
        var bindingX = Binding.newFromPadAxis(this, actionX, true, true);
        storeBinding(actionX, bindingX);
        var bindingY = Binding.newFromPadAxis(this, actionY, true, false);
        storeBinding(actionY, bindingY);
	}

    public function bindPadRStick(actionX:Action, actionY:Action) {
        var bindingX = Binding.newFromPadAxis(this, actionX, false, true);
        storeBinding(actionX, bindingX);
        var bindingY = Binding.newFromPadAxis(this, actionY, false, false);
        storeBinding(actionY, bindingY);
	}

    public inline function bindPadButtonsAsStickXY(actionX:Action, actionY:Action, up:PadButton, right:PadButton, down:PadButton, left:PadButton) {
		bindPadButtonsAsStick(actionX, true, left, right);
		bindPadButtonsAsStick(actionY, false, up, down);
	}

    public function bindPadButtonsAsStick(action:Action, isX:Bool, negativeButton:PadButton, positiveButton:PadButton) {
		var binding = new Binding(this, action);
		binding.isX = isX;
		binding.padNeg = negativeButton;
		binding.padPos = positiveButton;
		storeBinding(action, binding);
	}

    public function bindKey(action:Action, ?key:Int, ?keys:Array<Int>) {
        if((keys == null && key == null) || (keys != null && key != null)) {
            throw "Need exactly 1 key argument";
        }
        if(keys == null) {
            keys = [key];
        }
        for(k in keys) {
			var binding = Binding.newFromKeyboard(this, action, k);
			storeBinding(action, binding);
        }
    }

    function bindKeyAsStick(action:Action, isX:Bool, negativeKey:Int, positiveKey:Int) {
		var binding = new Binding(this, action);
		binding.isX = isX;
		binding.keyboardNeg = negativeKey;
		binding.keyboardPos = positiveKey;
		storeBinding(action, binding);
	}

    public function bindKeyAsStickXY(actionX:Action, actionY:Action, up:Int, right:Int, down:Int, left:Int) {
        bindKeyAsStick(actionX, true, left, right);
        bindKeyAsStick(actionY, false, up, down);
    }

    function storeBinding(action:Action, binding:Binding) {
        if(!bindings.exists(action)) {
            bindings.set(action, []);
        }
        bindings.get(action).push(binding);
        if(onBindingsChange != null) {
            onBindingsChange();
        }
    }

	public function rumble(strength:Float, seconds:Float) {
		if(pad.index >= 0) {
            pad.rumble(strength, seconds);
        }
	}

    public function isDown(action:Action) {
        if(ignoreNextInput) return false;
        if(!bindings.exists(action)) {
            return false;
        }
        for(binding in bindings.get(action)) {
            if(binding.isDown(pad)) {
                return true;
            }
        }
		return false;
	}

    public function isPressed(action:Action) {
        if(ignoreNextInput) return false;
        if(!bindings.exists(action)) {
            return false;
        }
        for(binding in bindings.get(action)) {
            if(binding.isPressed(pad)) {
                return true;
            }
        }
		return false;
    }

    public function isReleased(action:Action) {
        if(ignoreNextInput) return false;
        if(!bindings.exists(action)) {
            return false;
        }
        for(binding in bindings.get(action)) {
            if(binding.isReleased(pad)) {
                return true;
            }
        }
		return false;
    }

    public function getAnalogValue(action:Action) {
        if(!bindings.exists(action)) {
            return 0.;
        }
        for(binding in bindings.get(action)) {
            var val = binding.getValue(pad);
            if(val != 0) {
                return val;
            }
        }
        return 0.;
    }

    public function getAnalogDistXY(actionX:Action, actionY:Action, clamp=true) {
        var dx = getAnalogValue(actionX), dy = getAnalogValue(actionY);
        var dist = Math.sqrt(dx * dx + dy * dy);
        return Math.min(dist, 1.);
	}

    public inline function getAnalogAngleXY(actionX:Action, actionY:Action) {
		return Math.atan2(getAnalogValue(actionY), getAnalogValue(actionX));
	}

    function initButtonMapping() {
        padButtonToId = new Map();
        padButtonToId.set(A, pad.config.A);
		padButtonToId.set(B, pad.config.B);
		padButtonToId.set(X, pad.config.X);
		padButtonToId.set(Y, pad.config.Y);
		padButtonToId.set(START, pad.config.start);
		padButtonToId.set(SELECT, pad.config.back);
		padButtonToId.set(LT, pad.config.LT);
		padButtonToId.set(RT, pad.config.RT);
		padButtonToId.set(LB, pad.config.LB);
		padButtonToId.set(RB, pad.config.RB);
		padButtonToId.set(DPAD_UP, pad.config.dpadUp);
		padButtonToId.set(DPAD_DOWN, pad.config.dpadDown);
		padButtonToId.set(DPAD_LEFT, pad.config.dpadLeft);
		padButtonToId.set(DPAD_RIGHT, pad.config.dpadRight);
		padButtonToId.set(LSTICK_PUSH, pad.config.analogClick);
		padButtonToId.set(RSTICK_PUSH, pad.config.ranalogClick);
    }

    public function getStickPadButton(isLeft:Bool, deadZone:Float = .7) {
        var stickX = isLeft ? pad.xAxis : pad.rxAxis;
        var stickY = isLeft ? pad.yAxis : pad.ryAxis;
        var dist = Math.sqrt(stickX * stickX + stickY * stickY);
        var angle = Math.atan2(stickY, stickX);
        if(dist > deadZone) {
            var pi2 = Math.PI / 2;
            var dirAngle = Math.round(angle / pi2) * pi2;
            if(dirAngle == 0) {
                return isLeft ? LSTICK_RIGHT : RSTICK_RIGHT;
            } else if(dirAngle == -pi2) {
                return isLeft ? LSTICK_UP : RSTICK_UP;
            } else if(dirAngle == pi2) {
                return isLeft ? LSTICK_DOWN : RSTICK_DOWN;
            } else {
                return isLeft ? LSTICK_LEFT : RSTICK_LEFT;
            }
        }
        return INVALID;
    }

    public inline function getPadButtonId(padButton:Null<PadButton>) {
        return padButton != null && padButtonToId.exists(padButton) ? padButtonToId.get(padButton) : -1; 
    }

    public function update(dt:Float) {
        
    }

    public function afterUpdate() {
        if(!enabled) return;
        for(arr in bindings) {
            for(b in arr) {
                b.afterUpdate(pad);
            }
        }
        if(ignoreNextInput) {
            ignoreNextInput = false;
        }
    }

    public function resetBindings() {
        bindings = new Map();
        if(onBindingsChange != null) {
            onBindingsChange();
        }
    }

    public function getButtonTileName(button:PadButton) : Null<String> {
        var name = padButtonToString(button);
        var defaultPrefix = "pad";
        var idealPrefix = defaultPrefix + (padType == Switch ? "Switch" : "");
        if(Assets.hasTile("inputIcons", idealPrefix + name)) {
            return idealPrefix + name;
        }
        if(Assets.hasTile("inputIcons", defaultPrefix + name)) {
            return defaultPrefix + name;
        }
        return null;
    }

    public function getPrimaryKeyForAction(action:Action) : Null<Int> {
        if(!bindings.exists(action)) {
            return null;
        }
        for(binding in bindings.get(action)) {
            if(binding.keyboardPos != -1) {
                return binding.keyboardPos;
            }
        }
        return null;
    }

    public function getPrimaryButtonForAction(action:Action) : Null<PadButton> {
        if(!bindings.exists(action)) {
            return null;
        }
        for(binding in bindings.get(action)) {
            if(binding.padButton != null) {
                return binding.padButton;
            }
        }
        return null;
    }
}

class Binding {
    public static var deadZone = 0.65;
    var controller : Controller;
    public var action : Action;
    public var padButton : Null<PadButton>;
    public var isLStick : Bool = false;
    public var isRStick : Bool = false;
    public var keyboardPos : Int = -1;
    public var keyboardNeg : Int = -1;
    public var padPos : Null<PadButton>;
    public var padNeg : Null<PadButton>;
    public var isX : Bool = false;
    public var sign : Int = 1;
    var wasDown : Bool = false;

    public function new(controller:Controller, action:Action) {
        this.controller = controller;
        this.action = action;
    }

    public static inline function newFromKeyboard(controller:Controller, action:Action, key:Int) {
        var binding = new Binding(controller, action);
        binding.keyboardPos = binding.keyboardNeg = key;
        return binding;
    }

    public static inline function newFromPad(controller:Controller, action:Action, padButton:PadButton) {
        var binding = new Binding(controller, action);
        binding.padButton = padButton;
        return binding;
    }

    public static inline function newFromPadAxis(controller:Controller, action:Action, isLStick:Bool, isX:Bool) {
        var binding = new Binding(controller, action);
        binding.isX = isX;
        binding.isLStick = isLStick;
        binding.isRStick = !isLStick;
        return binding;
    }

    public static inline function newFromPadDirection(controller:Controller, action:Action, isLStick:Bool, isX:Bool, sign:Int) {
        var binding = new Binding(controller, action);
        binding.isX = isX;
        binding.isLStick = isLStick;
        binding.isRStick = !isLStick;
        binding.sign = sign;
        return binding;
    }

	public inline function getValue(pad:hxd.Pad) {
        if(!controller.enabled) return 0.;
        if(Key.isDown(keyboardPos) || pad.isDown(controller.getPadButtonId(padPos))) {
            return 1.;
        } else if(Key.isDown(keyboardNeg) || pad.isDown(controller.getPadButtonId(padNeg))) {
            return -1.;
        } else if(padPos == null && isLStick && isX) {
            return pad.xAxis * sign;
        } else if(padPos == null && isLStick && !isX) {
            return pad.yAxis * sign;
        } else if(padPos == null && isRStick && isX) {
            return pad.rxAxis * sign;
        } else if(padPos == null && isRStick && !isX) {
            return pad.ryAxis * sign;
        } else {
            return 0.;
        }
	}

    public inline function afterUpdate(pad:hxd.Pad) {
        wasDown = isDown(pad);
    }

    public inline function isDown(pad:hxd.Pad) {
        if(!controller.enabled) return false;
        if(isLStick || isRStick) {
            return getValue(pad) > deadZone;
        }
        return pad.isDown(controller.getPadButtonId(padButton)) || Key.isDown(keyboardPos) || Key.isDown(keyboardNeg);
    }

    public inline function isPressed(pad:hxd.Pad) {
        return !wasDown && isDown(pad);
    }
    public inline function isReleased(pad:hxd.Pad) {
        return wasDown && !isDown(pad);
    }
}