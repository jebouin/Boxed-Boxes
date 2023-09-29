package ;

import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;

class Macros {
    public static function buildTemplate() : Array<Field> {
        var fields : Array<Field> = Context.getBuildFields();
        var lines = File.getContent("constants.yaml").split("\n");
        inline function addField(i, name, kind) {
            fields.push({
                name:  name,
                access:  [Access.AStatic, Access.APublic, Access.AInline],
                kind: kind, 
                pos: Context.currentPos(),
                doc: "auto-generated from constants.yaml",
            });
        }
        inline function addStringField(i, name) {
            var val = lines[i].substr(lines[i].indexOf(":") + 2);
            addField(i, name, FieldType.FVar(macro:String, macro $v{val}));
        }
        addStringField(0, "GAME_NAME");
        addStringField(1, "GAME_ID");
        addStringField(2, "GAME_VERSION");
        return fields;
    }
}