package common;


class PyxelMapImporter {
    public var scale:Int = 1;
    public var TILE_WIDTH:Int;
    public var TILE_HEIGHT:Int;
    public static var TILES_WIDE:Int;
    public static var TILES_HIGH:Int;
    private var mapDatas:Array<Map<String, String>>;
    private var xml:Xml;
    private var tilemap:haxe.xml.Fast;

    public function new(xmlDatas:String, scale:Int) {
        xml = Xml.parse(xmlDatas);
        tilemap = new haxe.xml.Fast(xml.firstElement());
        TILE_WIDTH = Std.parseInt(tilemap.att.tilewidth) * 4;
        TILE_HEIGHT = Std.parseInt(tilemap.att.tileheight) * 4;
        TILES_WIDE = Std.parseInt(tilemap.att.tileswide);
        TILES_HIGH = Std.parseInt(tilemap.att.tileshigh);
        scale = 1;
        trace("Tile width : " + TILE_WIDTH + " Tile height : " + TILE_HEIGHT);
    }

    public function getDatasFromLayer(layerName:String):Array<Map<String, String>> {
        var layers = tilemap.nodes.layer;
        mapDatas = new Array();
        for(layer in layers) {
            if(layer.att.name == layerName) {
                for(tile in layer.nodes.tile) {
                    var t:Map<String, String> = new Map();
                    t.set("x", tile.att.x);
                    t.set("y", tile.att.y);
                    t.set("index", tile.att.index);
                    t.set("rot", tile.att.rot);
                    t.set("flipX", tile.att.flipX);
                    mapDatas.push(t);
                }
            }
        }
        trace("getDatasFromLayer: " + layerName + " len: " + mapDatas.length);
        return mapDatas;
    }

    public function getTileMap(mapDatas:Array<Map<String, String>>):Array<Array<Int>> {
        var newMap:Array<Array<Int>> = [[]];
        for(posx in 0...TILES_WIDE) {
            var row = [];
            for(posy in 0...TILES_HIGH) {
                row.push(-1);
            }
            newMap.push(row);
        }

        for(tile in mapDatas) {
            var index = Std.parseInt(tile.get("index"));
            if(index != -1) {
                var posx = Std.parseInt(tile.get("x"));
                var posy = Std.parseInt(tile.get("y"));
                var id = Std.parseInt(tile.get("index"));
                newMap[posx][posy] = id;
            }
        }

        return newMap;
    }

    public function getTilesheetArray(mapDatas:Array<Map<String, String>>)
                                                            :Array<Float> {
        var tileArray:Array<Float> = new Array();
        for(tile in mapDatas) {
            var index = Std.parseInt(tile.get("index"));
            if(index != -1) {
                tileArray.push(Std.parseInt(
                                        tile.get("x")) * TILE_WIDTH);
                tileArray.push(Std.parseInt(
                                        tile.get("y")) * TILE_HEIGHT);
                tileArray.push(Std.parseInt(tile.get("index")));

                // TILE_TRANS_2x2
                // tileArray.push(1);
                // tileArray.push(0);
                // tileArray.push(0);
                // tileArray.push(1);
            }
        }
        trace("getTilesheetArray : " + tileArray.length);
        return tileArray;
    }

    public function getCollisionMapFromLayer(layerName:String)
                                                    :Array<Array<Int>>{
        var map = this.getDatasFromLayer(layerName);
        var collisionMap = new Array();

        // Generate empty collision map
        for(x in 0...TILES_WIDE) {
            var col = new Array();
            for(y in 0...TILES_HIGH) {
                col.push(-1);
            }
            collisionMap.push(col);
        }

        // Fill it
        for(tile in map) {
            var index = Std.parseInt(tile.get("index"));
            if(index != -1) {
                var x = Std.parseInt(tile.get("x"));
                var y = Std.parseInt(tile.get("y"));
                collisionMap[x][y] = index;
            }
        }

        return collisionMap;
    }
}