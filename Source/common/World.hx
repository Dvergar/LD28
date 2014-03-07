package common;

#if client
import openfl.Assets;
#end


class World
{
    public static var TILE_SIZE:Int;
    public static var tileSheetArray:Array<Float>;
    public static var map:Array<Array<Int>>;

    public function new()
    {
        TILE_SIZE = 16 * 4;

        #if server
        var datas = new PyxelMapImporter(
                        sys.io.File.getContent("../assets/map"), 4);
        #end

        #if client
        var datas = new PyxelMapImporter(
                        Assets.getText("assets/map"), 4);
        #end

        var worldDatas = datas.getDatasFromLayer("world");
        var worldTileArray = datas.getTilesheetArray(worldDatas);
        World.tileSheetArray = worldTileArray;
        World.map = datas.getCollisionMapFromLayer("collision");
    }
}