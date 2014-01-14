package client;
import flash.utils.ByteArray;
import flash.utils.Endian;


class CircularFrameBuffer
{
    private var buffer:ByteArray;
    public var iterationTotal:Float;
    private var iterationTimes:Int;
    private var bufferSize:Int;
    private var bufferRows:Int;
    private var bytesPerRow:Int;
    private var nextFramePointer:Int;

    public function new()
    {
        bufferRows = 256;
        bytesPerRow = 12;
        bufferSize = bytesPerRow * bufferRows;
        nextFramePointer = 0;
        resetBuffer();
    }

    public function resetBuffer()
    {
        buffer = new ByteArray();
        buffer.endian = Endian.BIG_ENDIAN;
    }

    public function getLastFrameId()
    {
        var lastPointer = nextFramePointer - bytesPerRow;
        if(lastPointer < 0) lastPointer = bufferSize - bytesPerRow;
        return lastPointer / bytesPerRow;
    }

    public function getFrame(id:Int)
    {
        var frame = new ByteArray();
        buffer.position = id * bytesPerRow;
        buffer.readBytes(frame, 0, bytesPerRow);
        return frame;
    }

    public function setIterationIndex(index:Int)
    {
        var nowIndex = index;
        if(nowIndex >= bufferRows) nowIndex = 0;

        iterationTimes = 0;
        iterationTotal = getLastFrameId() - nowIndex;

        if(iterationTotal < 0)
        {
            iterationTotal = bufferRows - nowIndex + getLastFrameId();
        }

        // Current image is not processed since current delta
        // is to reach current positions (not future positions)
        buffer.position = (nowIndex + 1) * bytesPerRow;
    }

    // NOTE : inputs from last frame to reach x,y of this very frame
    public function addFrame(x:Int, y:Int,
                             speed:Float,
                             l:Bool, r:Bool, u:Bool, d:Bool,
                             ?id:Int)
    {
        if(id != null)
        {
            buffer.position = id * bytesPerRow;
        }
        else
        {
            buffer.position = nextFramePointer;
        }

        buffer.writeShort(x);
        buffer.writeShort(y);
        buffer.writeFloat(speed);
        buffer.writeBoolean(l);
        buffer.writeBoolean(r);
        buffer.writeBoolean(u);
        buffer.writeBoolean(d);

        if(id == null)
        {
            nextFramePointer = buffer.position;
            if(nextFramePointer == bufferSize) {nextFramePointer = 0;}
        }
    }

    public function hasNext()
    {
        if(iterationTimes == iterationTotal)
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    public function next()
    {
        // NOTE : Pointer auto advance with readBytes
        iterationTimes++;
        var frame = new ByteArray();
        buffer.readBytes(frame, 0, bytesPerRow);

        if(Std.int(buffer.position) == bufferSize)
        {
            buffer.position = 0;
        }
        return frame;
    }
}