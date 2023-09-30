package assets;

typedef SliceBounds = {
    var x: Int;
    var y: Int;
    var w : Int;
    var h : Int;
};

typedef SlicePivot = {
    var x : Int;
    var y : Int;
}

typedef SliceKey = {
    var frame : Int;
    var bounds : SliceBounds;
    var pivot : SlicePivot;
};

typedef Slice = {
    var name : String;
    var color : String;
    var data : String;
    var keys : Array<SliceKey>;
};

typedef Meta = {
    var image : String;
    var slices : Array<Slice>;
};

typedef AsepriteJson = {
    var meta : Meta;
}