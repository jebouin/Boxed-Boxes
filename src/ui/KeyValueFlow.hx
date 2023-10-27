package ui;

import h2d.Object;
import h2d.Flow;
import h2d.Text;

class KeyValueFlow extends Flow {
    var lines : Array<Flow> = [];

    public function new(parent:Object, minWidth:Int) {
        super(parent);
        this.minWidth = minWidth;
        layout = Vertical;
    }

    public function addLine(?keyText:String="", ?valueText:String="") {
        var flow = new Flow(this);
        flow.minWidth = minWidth;
        var key = getText(flow, Left);
        key.text = keyText;
        var value = getText(flow, Right);
        value.text = valueText;
        lines.push(flow);
        return {key: key, value: value};
    }

    function getText(parent:Flow, align:FlowAlign) {
        var text = new Text(Assets.font, parent);
        text.textColor = 0x8b9bb4;
        var props = parent.getProperties(text);
        props.horizontalAlign = align;
        return text;
    }
}