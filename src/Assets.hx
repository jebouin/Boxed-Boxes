import audio.VariedSound;
import audio.Music;
import assets.AsepriteJson.Slice;
import h2d.Font;
import h2d.HtmlText;
import h2d.Tile;
import h3d.mat.Texture;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import hxd.Res;
import hxd.res.Sound;

typedef AnimData = {
    var tiles : Array<Tile>;
    var fps : Int;
    var loops : Bool;
}

typedef SpriteSheet = {
    var tiles : StringMap<Tile>;
    var animData : StringMap<AnimData>;
}

class Assets {
    static inline var LOOPS_COL_TRUE = "#0000ffff";
    static inline var LOOPS_COL_FALSE = "#fe5b59ff";
    public static var font : Font;
    public static var fontLarge : Font;
    public static var nameToSound : StringMap<VariedSound>;
    public static var nameToMusic : StringMap<Music>;
    static var sheets : StringMap<SpriteSheet>;

    public static function init() {
        Data.load(hxd.Res.data.entry.getText());
        font = Res.fonts.cc13.toFont();
        fontLarge = Res.fonts.large.toFont();
        loadAllSpriteSheets();
        loadAudio();
    }

    static function loadAllSpriteSheets() {
        sheets = new StringMap<SpriteSheet>();
        for(res in hxd.Res.load("gfx")) {
            if(res.name.substr(-5) == ".json") {
                var name = res.name.substr(0, res.name.length - 5);
                var resPng = hxd.Res.load("gfx/" + name + ".png").toImage();
                if(resPng != null) {
                    var sheet = loadSpriteSheet(name, res, resPng);
                    sheets.set(name, sheet);
                }
            }
        }
    }

    static function loadSpriteSheet(name:String, resJson:hxd.res.Any, resPng:hxd.res.Image) {
        var sheet = {
            tiles: new StringMap<Tile>(),
            animData: new StringMap<AnimData>()
        };
        var json : assets.AsepriteJson = haxe.Json.parse(resJson.entry.getText());
        var atlas = resPng.toTile();
        atlas.getTexture().preventAutoDispose();
        for(slice in json.meta.slices) {
            addSliceToSheet(sheet, atlas, slice);
        }
        return sheet;
    }

    static function addSliceToSheet(sheet:SpriteSheet, atlas:Tile, slice:Slice) {
        var bounds = slice.keys[0].bounds;
        var pivot = slice.keys[0].pivot;
        var tile = atlas.sub(bounds.x, bounds.y, bounds.w, bounds.h);
        if(slice.data == null || slice.data == "") {
            if(pivot == null) {
                tile.dx = -tile.iwidth >> 1;
                tile.dy = -tile.iheight >> 1;
            } else {
                tile.dx = -pivot.x;
                tile.dy = -pivot.y;
            }
            sheet.tiles.set(slice.name, tile);
            sheet.animData.set(slice.name, {tiles: [tile], fps: 1, loops: false});
        } else {
            // Slice data format: [frameCount, strip frame count, fps, frame1, frame2, ...] or [frameCount, fps] for single strip animations
            var json = haxe.Json.parse("[" + slice.data + "]");
            var uniqueTiles : Array<Tile> = [], frameList : Array<Int> = [];
            var frameCount = 0, frameWidth = 0, frameHeight = 0, fps = 0, cntx = 0, cnty = 0;
            if(json.length == 2) {
                frameCount = json[0];
                fps = json[1];
                if(tile.iwidth % frameCount != 0) {
                    throw "Frame count does not divide slice width for slice " + slice.name;
                }
                frameWidth = Std.int(tile.iwidth / frameCount);
                frameHeight = tile.iheight;
                cntx = frameCount;
                cnty = 1;
            } else {
                frameCount = json[0];
                cntx = json[1];
                fps = json[2];
                if(json.length > 3) {
                    for(i in 3...json.length) {
                        frameList.push(json[i]);
                    }
                }
                if(tile.iwidth % cntx != 0) {
                    throw "Frame width does not divide strip frame count for slice " + slice.name;
                }
                frameWidth = Std.int(tile.iwidth / cntx);
                cnty = Math.ceil(frameCount / cntx);
                if(tile.iheight % cnty != 0) {
                    throw "Frame height does not divide slice height for slice " + slice.name;
                }
                frameHeight = Std.int(tile.iheight / cnty);
            }
            var centerX = pivot == null ? frameWidth >> 1 : pivot.x;
            var centerY = pivot == null ? frameHeight >> 1 : pivot.y;
            for(f in 0...frameCount) {
                var i = Std.int(f / cntx), j = f % cntx;
                var sub = tile.sub(j * frameWidth, i * frameHeight, frameWidth, frameHeight, -centerX, -centerY);
                uniqueTiles.push(sub);
            }
            var tiles = [];
            if(frameList.length > 0) {
                for(f in frameList) {
                    tiles.push(uniqueTiles[f]);
                }
            } else {
                tiles = uniqueTiles;
            }
            sheet.animData.set(slice.name, {tiles: tiles, fps: fps, loops: slice.color == LOOPS_COL_TRUE});
        }
    }

    public static function hasTile(sheetName:String, tileName:String) {
        var sheet = sheets.get(sheetName);
        if(sheet == null) {
            return false;
        }
        return sheet.tiles.exists(tileName);
    }

    public static function getTile(sheetName:String, tileName:String) {
        var sheet = sheets.get(sheetName);
        if(sheet == null) {
            trace("No sheet named " + sheetName);
            return null;
        }
        var tile = sheet.tiles.get(tileName);
        if(tile == null) {
            trace("No tile named " + tileName + " in sheet " + sheetName);
            return null;
        }
        return tile;
    }

    public static function getAnimData(sheetName:String, tileName:String) {
        var sheet = sheets.get(sheetName);
        if(sheet == null) {
            trace("No sheet named " + sheetName);
            return null;
        }
        var animData = sheet.animData.get(tileName);
        if(animData == null) {
            trace("No animData named " + tileName + " in sheet " + sheetName);
            return null;
        }
        return animData;
    }

    public static function loadAudio() {
        nameToSound = new StringMap<VariedSound>();
        for(def in Data.soundDef.all) {
            var sound = new VariedSound(def);
            nameToSound.set(def.name, sound);
        }
        nameToMusic = new StringMap<Music>();
        for(def in Data.musicDef.all) {
            var music = new Music(def);
            nameToMusic.set(def.name, music);
        }
    }
}