package ;

import h2d.Scene.ScaleMode;
import h3d.Engine;

// Scene with custom viewport to fix letterboxed pixel-perfect events
class PixelPerfectScene extends h2d.Scene {
	override function screenToViewport(e : hxd.Event) {
		e.relX = (e.relX - Main.inst.screen.x) / Main.inst.scale;
		e.relY = (e.relY - Main.inst.screen.y) / Main.inst.scale;
	}
}

class Scene {
	public var onFocusGain : Void->Void;
	public var onFocusLoss : Void->Void;
	public var onDelete : Void->Void;
    public var world : PixelPerfectScene;
	public var hud : PixelPerfectScene;
	public var masking(default, null) : Bool = false;
	public var maskUpdate(default, null) : Bool = true;
	public var deleted : Bool = false;

	public function new(masking:Bool=false) {
		this.masking = masking;
		SceneManager.add(this);
        world = new PixelPerfectScene();
        world.scaleMode = ScaleMode.Stretch(Main.WIDTH, Main.HEIGHT);
        hud = new PixelPerfectScene();
        hud.scaleMode = ScaleMode.Stretch(Main.WIDTH, Main.HEIGHT);
		Main.inst.sevents.addScene(world);
		Main.inst.sevents.addScene(hud);
	}
	public function delete() {
		deleted = true;
		Main.inst.sevents.removeScene(hud);
		Main.inst.sevents.removeScene(world);
		hud.remove();
        world.remove();
		if(onDelete != null) {
			onDelete();
		}
		SceneManager.remove(this);
	}
	public function update(dt:Float) {
	}
	public function updateBack(dt:Float) {
	}
	public function updateAfter(dt:Float) {
	}
	public function updateConstantRate(dt:Float) {
	}
    public function renderWorld(e:Engine) {
        world.render(e);
    }
	public function renderHUD(e:Engine) {
		hud.render(e);
	}
}

class SceneManager {
	public static var scenes : Array<Scene>;
	static var lastMaskingId : Int;

	public static function init() {
		scenes = new Array();
		updateLastMaskingId();
	}
	public static function deleteAll() {
		while(scenes.length > 0) {
			scenes[scenes.length - 1].delete();
			scenes.pop();
		}
		updateLastMaskingId();
	}
	public static function update(dt:Float) {
		var i = scenes.length - 1;
		while(i >= 0) {
			var scene = scenes[i];
			scene.update(dt);
			if(scene.maskUpdate) break;
			i--;
		}
		checkDeletedScenes();
	}
	public static function updateBack(dt:Float) {
		for(scene in scenes) {
			scene.updateBack(dt);
		}
		checkDeletedScenes();
	}
	public static function updateConstantRate(dt:Float) {
		var i = scenes.length - 1;
		while(i >= 0) {
			var scene = scenes[i];
			scene.updateConstantRate(dt);
			if(scene.maskUpdate) break;
			i--;
		}
		checkDeletedScenes();
	}
	public static function updateAfter(dt:Float) {
		var i = scenes.length - 1;
		while(i >= 0) {
			var scene = scenes[i];
			scene.updateAfter(dt);
			if(scene.maskUpdate) break;
			i--;
		}
	}
	inline static function checkDeletedScenes() {
		var i = 0;
		while(i < scenes.length) {
			if(scenes[i].deleted) {
				remove(scenes[i]);
				scenes.splice(i, 1);
			} else {
				i++;
			}
		}
	}
	static function updateLastMaskingId() {
		if(scenes.length == 0) {
			lastMaskingId = -1;
			return;
		}
		lastMaskingId = 0;
		for(i in 0...scenes.length) {
			if(scenes[i].masking) {
				lastMaskingId = i;
			}
		}
	}
    public static function renderWorld(e:Engine) {
		if(lastMaskingId == -1) return;
		for(i in lastMaskingId...scenes.length) {
			//trace("RENDER WORLD " + scenes[i]);
			scenes[i].renderWorld(e);
		}
    }
    public static function renderHUD(e:Engine) {
		if(lastMaskingId == -1) return;
		for(i in lastMaskingId...scenes.length) {
			//trace("RENDER HUD " + scenes[i]);
			scenes[i].renderHUD(e);
		}
    }
	@:allow(Scene)
	static private function add(scene:Scene) {
		if(scenes.length > 0) {
			if(scenes[scenes.length-1].onFocusLoss != null) {
				scenes[scenes.length-1].onFocusLoss();
			}
		}
		scenes.push(scene);
		updateLastMaskingId();
	}
	@:allow(Scene)
	static private function remove(scene:Scene) {
		scenes.remove(scene);
		if(scenes.length > 0) {
			if(scenes[scenes.length-1].onFocusGain != null) {
				scenes[scenes.length-1].onFocusGain();
			}
		}
		updateLastMaskingId();
	}
}