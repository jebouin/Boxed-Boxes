package ;

import hxd.Pad;
import hxd.Key;

enum abstract PadButton(Int) {
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

enum abstract ControllerType(Int) {
    var Keyboard;
    var Gamepad;
}

enum abstract Action(Int) {
    var moveX;
    var moveY;
    var action;
}

class Controller {
    public var pad : hxd.Pad;
    public var onConnect : Void->Void;
    public var onDisconnect : Void->Void;
    var bindings : Map<Action, Array<Binding> >;
    var padButtonToId : Map<PadButton, Int>;
    var onControllerChange : Void->Void;

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
		pad.onDisconnect = onPadDisconnected;
        if(onConnect != null) {
            onConnect();
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

    public function bindPadStick(actionX:Action, actionY:Action, isLeftStick:Bool) {
        var bindingX = Binding.newFromPadAxis(this, actionX, isLeftStick, true);
        storeBinding(actionX, bindingX);
        var bindingY = Binding.newFromPadAxis(this, actionY, isLeftStick, false);
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
    }

	public function rumble(strength:Float, seconds:Float) {
		if(pad.index >= 0) {
            pad.rumble(strength, seconds);
        }
	}

    public function isDown(action:Action) {
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

    public inline function getPadButtonId(padButton:Null<PadButton>) {
        return padButton != null && padButtonToId.exists(padButton) ? padButtonToId.get(padButton) : -1; 
    }

    public function afterUpdate() {
        for(arr in bindings) {
            for(b in arr) {
                b.afterUpdate(pad);
            }
        }
    }
}

class Binding {
    public static var deadZone = 0.65;
    var controller : Controller;
    public var action : Action;
    public var padButton : Null<PadButton>;
    public var isLeftStick : Bool = false;
    public var isRightStick : Bool = false;
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

    public static inline function newFromPadAxis(controller:Controller, action:Action, isLeftStick:Bool, isX:Bool) {
        var binding = new Binding(controller, action);
        binding.isX = isX;
        binding.isLeftStick = isLeftStick;
        binding.isRightStick = !isLeftStick;
        return binding;
    }

    public static inline function newFromPadDirection(controller:Controller, action:Action, isLeftStick:Bool, isX:Bool, sign:Int) {
        var binding = new Binding(controller, action);
        binding.isX = isX;
        binding.isLeftStick = isLeftStick;
        binding.isRightStick = !isLeftStick;
        binding.sign = sign;
        return binding;
    }

	public inline function getValue(pad:hxd.Pad) {
        if(Key.isDown(keyboardPos) || pad.isDown(controller.getPadButtonId(padPos))) {
            return 1.;
        } else if(Key.isDown(keyboardNeg) || pad.isDown(controller.getPadButtonId(padNeg))) {
            return -1.;
        } else if(padPos == null && isLeftStick && isX) {
            return pad.xAxis * sign;
        } else if(padPos == null && isLeftStick && !isX) {
            return pad.yAxis * sign;
        } else if(padPos == null && isRightStick && isX) {
            return pad.rxAxis * sign;
        } else if(padPos == null && isRightStick && !isX) {
            return pad.ryAxis * sign;
        } else {
            return 0.;
        }
	}

    public inline function afterUpdate(pad:hxd.Pad) {
        wasDown = isDown(pad);
    }

    public inline function isDown(pad:hxd.Pad) {
        if(isLeftStick || isRightStick) {
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