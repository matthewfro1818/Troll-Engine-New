package;

#if VIDEOS_ALLOWED
import hxcodec.flixel.FlxVideo;
#end

// is this stupid or
class VideoPlayerState extends MusicBeatState
{  
    final videoPath:String;
    final isSkippable:Bool;
    final onComplete:Void -> Void;

    public function new(videoPath:String, onComplete:Void -> Void, isSkippable:Bool = true)
    {
        super();

        this.videoPath = videoPath;
        this.isSkippable = isSkippable==true;
        this.onComplete = onComplete;
    }

    var video:FlxVideo;
    override public function create(){
        FlxG.camera.bgColor = 0xFF000000;

        super.create();

        #if !VIDEOS_ALLOWED
        onComplete();
        #else
        video = new FlxVideo();
        video.onEndReached.add(onComplete);
		video.play(videoPath);
        #end
    }

    override public function update(e) {
        if (isSkippable && controls.ACCEPT){
            video.stop();
            video.dispose();
            onComplete();
        }

        super.update(e);
    }
}