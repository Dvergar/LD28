package client;
import client.CariSprite;
import openfl.display.Tilesheet;
import flash.display.Sprite;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.geom.Rectangle;
import flash.geom.Point;
import flash.Lib;


class Tile extends MyTilesheet {
    private var tf:flash.text.TextField;

    public function new(tilesheet:Tilesheet, id) {
        super();
        this.id = id;
        this.tilesheet = tilesheet;
        updateSprite();

        // Debug
        // tf = new flash.text.TextField();
        // var font = flash.Assets.getFont("assets/Kirsty.ttf"); 
        // var format = new flash.text.TextFormat(font.fontName); 
        // format.size = 13;
        // tf.defaultTextFormat = format;
        // tf.embedFonts = true;
        // tf.textColor = 0xffffff;
        // tf.x = 4;
        // tf.y = 4;
        // tf.selectable = false;
        // tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
        // this.addChild(tf);
    }

    public function update(newId:Int, x:Int, y:Int) {
        if(newId != -1) {
            this.id = newId;
            // graphics.clear();
            // tilesheet.drawTiles(graphics, [0, 0, newId]);
            updateSprite();
            this.x = x;
            this.y = y;
        }
        else {
            this.x = -999;
            this.y = -999;
        }

        // Debug
        // var posx = Math.abs(this.x / 32);
        // var posy = Math.abs(this.y / 32);

        // tf.text = Std.string(posx) + ", " + Std.string(posy);
    }
}


class Layer extends Sprite {
    private var map:Array<Array<Int>>;
    private var tiles:Array<Tile>;
    public var tilesMap:Array<Array<Sprite>>;
    private var movingSprites:Array<DisplayObject>;
    private var mm:MapManager;

    public function new(map:Array<Array<Int>>,
                        img:BitmapData,
                        viewport:Rectangle,
                        mapManager:MapManager) {
        super();
        this.map = map;
        this.mm = mapManager;
        this.tiles = new Array();
        this.movingSprites = new Array();
        var tilesheet = makeTilesheet(img);

        // FEED TILES ARRAY
        var tilesWide = Std.int((viewport.width / mm.TILE_SIZE)) + 1;
        var tilesHigh = Std.int((viewport.height / mm.TILE_SIZE)) + 1;
        var nbTiles = tilesWide * tilesHigh;
        for(i in 0...nbTiles) {
            var tile = new Tile(tilesheet, 0);
            super.addChild(tile);
            this.tiles.push(tile);
        }

        // EMPTY TILES MAP ARRAY
        this.tilesMap = new Array();
        for(col in map) {
            var newCol = new Array();
            for(posy in col) {
                newCol.push(null);
            }
            tilesMap.push(newCol);
        }
    }

    private function makeTilesheet(bd:BitmapData) {
        var tilesheet = new Tilesheet(bd);
        var tilesWide = Std.int(bd.width / mm.TILE_SIZE);
        var tilesHigh = Std.int(bd.height / mm.TILE_SIZE);

        for(posy in 0...tilesHigh) {
            for(posx in 0...tilesWide) {
                var rect = new Rectangle(posx * mm.TILE_SIZE,
                                         posy * mm.TILE_SIZE,
                                         mm.TILE_SIZE,
                                         mm.TILE_SIZE);
                tilesheet.addTileRect(rect);
            }
        }
        return tilesheet;
    }


    public override function addChild(displayObject:DisplayObject)
                                                :DisplayObject {
        super.addChild(displayObject);
        this.movingSprites.push(displayObject);
        // if(displayObject.x < -1000) {
        //     throw "wat " + displayObject.x;
        // }
        return displayObject;
    }

    public override function removeChild(displayObject:DisplayObject)
                                                :DisplayObject {
        super.removeChild(displayObject);
        this.movingSprites.remove(displayObject);
        return null;
    }

    public function updateSprites() {
        for(sprite in movingSprites) {
            super.addChild(sprite);
        }
    }

    public function depthSortTiles(posLeft, posRight, posTop, posBottom) {
        for(sprite in movingSprites) {

            var pposLeft = Std.int((sprite.x - sprite.width / 2) / mm.TILE_SIZE);
            var pposRight = Std.int((sprite.x + sprite.width / 2) / mm.TILE_SIZE);
            var pposTop = Std.int((sprite.y - sprite.height / 2) / mm.TILE_SIZE);
            var pposBot = Std.int((sprite.y + sprite.height / 2) / mm.TILE_SIZE);

            if(pposLeft < posLeft || pposRight > posRight ||
               pposTop < posTop || pposBot > posBottom) {
                continue;
            }

            super.addChild(sprite);

            var srect = sprite.getRect(this);
            var points = [[srect.left, srect.bottom],
                          [srect.right, srect.bottom]];

            if(sprite.width > mm.TILE_SIZE) {
                points.push([sprite.x, srect.bottom]);
            } // Generate coll points in CariSprite or smth

            for(point in points) {
                var posx = Std.int(point[0] / mm.TILE_SIZE);
                var posy = Std.int(point[1] / mm.TILE_SIZE);

                try {
                    if(map[posx][posy] != -1) {
                        super.addChild(tilesMap[posx][posy]);
                    }
                }
                catch(unknown:Dynamic) {
                    // TODO : FIX THIS
                    // trace("rec " + srect);
                    // trace("spr " + sprite.x + " / " + sprite.y);
                    // trace("par " + sprite.parent.x);
                    // trace("siz " + sprite.width + " / " + sprite.height);
                    // trace("pos " + posx + " / " + posy);

                    // trace("id" + map[posx][posy]);
                    // trace("map" + tilesMap[posx][posy]);
                }
            }
        }
    }

    public function depthSortMovingSprites() {
        this.movingSprites.sort(spriteSort);
        for(sprite in movingSprites) {
            super.addChild(sprite);
        }
    }

    private inline function spriteSort(a:DisplayObject,
                                       b:DisplayObject):Int {
        var rectA = a.getRect(a.parent);
        var rectB = b.getRect(b.parent);
        if (rectA.bottom < rectB.bottom) return -1;
        if (rectA.bottom > rectB.bottom) return 1;
        return 0;
    }

    public function updateTile(posx:Int, posy:Int, i:Int) {
        var x = posx * mm.TILE_SIZE;
        var y = posy * mm.TILE_SIZE;
        var id = map[posx][posy];

        var tile = this.tiles[i];
        tile.update(id, x, y);
        super.addChild(tile);
        this.tilesMap[posx][posy] = tile;
    }
}


class MapManager extends Sprite {
    private var TILES_WIDE:Int;
    private var TILES_HIGH:Int;
    public var TILE_SIZE:Int;
    private var STAGE_WIDTH:Int;
    private var STAGE_HEIGHT:Int;
    public var bgLayer:Layer;
    public var objectsLayer:Layer;
    public var collisionMap:Array<Array<Int>>;  // Remove !?
    private var objectsSprites:Array<Sprite>;
    private var movingSprites:Array<Sprite>;
    private var viewport:Rectangle;
    private var lastPosLeft:Int;
    private var lastPosTop:Int;

    public function new(tilesWide, tilesHigh, tileSize,
                        viewport, collisionMap) {
        super();
        this.viewport = viewport;
        this.collisionMap = collisionMap;  // Remove !?
        TILES_WIDE = tilesWide;
        TILES_HIGH = tilesHigh;
        TILE_SIZE = tileSize;
        STAGE_WIDTH = Lib.current.stage.stageWidth;
        STAGE_HEIGHT = Lib.current.stage.stageHeight;
    }

    public function addBgLayer(map:Array<Array<Int>>, img:BitmapData) {
        this.bgLayer = new Layer(map, img, viewport, this);
        this.addChild(bgLayer);
    }

    public function addObjectLayer(map:Array<Array<Int>>, img:BitmapData) {
        this.objectsLayer = new Layer(map, img, viewport, this);
        this.addChild(objectsLayer);
    }

    public function getViewportPoint(x:Float, y:Float) {
        var newX = -this.x + x;
        var newY = -this.y + y;
        return new Point(newX, newY);
    }

    public function updateViewport(x:Float, y:Float) {
        this.x = Std.int(-x + STAGE_WIDTH / 2);
        this.y = Std.int(-y + STAGE_HEIGHT / 2);

        viewport.x = -this.x + STAGE_WIDTH / 2 - viewport.width / 2;
        viewport.y = -this.y + STAGE_HEIGHT / 2 - viewport.height / 2;

        var posLeft = Std.int(viewport.left / TILE_SIZE);
        var posTop = Std.int(viewport.top / TILE_SIZE);
        var posRight = Std.int(viewport.right / TILE_SIZE);
        var posBottom = Std.int(viewport.bottom / TILE_SIZE);

        if(lastPosLeft != posLeft || lastPosTop != posTop) {
            this.lastPosLeft = posLeft;
            this.lastPosTop = posTop;

            var i = 0;
            for(posx in posLeft...posRight) {
                for(posy in posTop...posBottom) {
                    if(posx < 0 || posx > TILES_WIDE ||
                       posy < 0 || posy > TILES_HIGH) {
                        continue;
                    }
                    this.objectsLayer.updateTile(posx, posy, i);
                    this.bgLayer.updateTile(posx, posy, i);
                    i++;
                }
            }
        }
        this.bgLayer.updateSprites();

        this.objectsLayer.depthSortMovingSprites();
        this.objectsLayer.depthSortTiles(posLeft, posRight,
                                         posTop, posBottom);

        graphics.clear();
        graphics.lineStyle(1);
        graphics.moveTo(viewport.x, viewport.y);
        graphics.lineTo(viewport.x + viewport.width, viewport.y);
        graphics.lineTo(viewport.x + viewport.width, viewport.y + viewport.height);
        graphics.lineTo(viewport.x, viewport.y + viewport.height);
        graphics.lineTo(viewport.x, viewport.y);
    }
}

