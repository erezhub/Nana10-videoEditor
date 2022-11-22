package
{
	import com.events.VideoPlayerEvent;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.DisplayUtils;
	import com.fxpn.util.StringUtils;
	import com.ui.MediandVideoPlayer;
	
	import fl.controls.Button;
	import fl.controls.TextInput;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	[SWF (width="800", height="600")]
	public class SeekTest extends Sprite
	{
		private var vp:MediandVideoPlayer;
		private var input:TextInput;
		private var output:TextField;
		private var seekSize:TextInput;
		private var frame:Number;
		private var duration:TextField;
		
		public function SeekTest()
		{
			vp = new MediandVideoPlayer();
			vp.addEventListener(VideoPlayerEvent.NOT_FOUND,onVideoEvent);
			vp.addEventListener(VideoPlayerEvent.VIDEO_DATA_READY,onVideoEvent);
			vp.addEventListener(VideoPlayerEvent.START,onVideoEvent);
			vp.addEventListener(VideoPlayerEvent.FAILED, onVideoFailed);
			addChild(vp);
			DisplayUtils.spacialAlign(stage,vp,DisplayUtils.CENTER,NaN,DisplayUtils.TOP,10);
			vp.volume = 0;
			
			var toggleBtn:Button = new Button();
			toggleBtn.label = "play/pause";
			toggleBtn.x = vp.x;
			toggleBtn.y = vp.y + vp.height + 5;
			toggleBtn.addEventListener(MouseEvent.CLICK,onToggle);
			addChild(toggleBtn);
			
			var seekBtn:Button = new Button();
			seekBtn.label = "seek";
			seekBtn.x = toggleBtn.x + toggleBtn.width + 10;
			seekBtn.y = toggleBtn.y;
			seekBtn.addEventListener(MouseEvent.CLICK,onSeek);
			addChild(seekBtn);
			
			seekSize = new TextInput();
			seekSize.width = 50;
			seekSize.x = seekBtn.x + seekBtn.width + 10;
			seekSize.y = seekBtn.y;
			addChild(seekSize);
			
			duration = new TextField();
			duration.text = "duration: ";
			//duration.autoSize = TextFieldAutoSize.LEFT;
			duration.x = seekSize.x + seekSize.width + 5;
			duration.y = seekSize.y;
			addChild(duration);
			
			input = new TextInput();
			input.text = "rtmpt://s0mfl.castup.net:1935/vod/server12/206/925/92522974-136.mp4?ct=IL&rg=NV&aid=206&ts=0&cu=386D413E-032A-4E83-979F-02D072DDFB46";
			input.width = 400;
			addChild(input);
			DisplayUtils.align(stage,input,true,false);
			input.y = vp.y + vp.height + 30;
			
			var sourceBtn:Button = new Button();
			sourceBtn.label = "set source";
			sourceBtn.addEventListener(MouseEvent.CLICK,onSetSource);
			addChild(sourceBtn);
			sourceBtn.y = input.y;
			sourceBtn.x = input.x + input.width + 5;
			
			output = new TextField();
			output.width = 400;
			output.height = 200;
			addChild(output);
			output.x = input.x;
			output.y = input.y + input.height + 10;
			output.border = true;
		}
		
		private function onVideoEvent(event:VideoPlayerEvent):void
		{
			output.appendText(event.type + "," + vp.playheadTime + "\n");
			output.scrollV = output.maxScrollV;
			if (event.type == VideoPlayerEvent.VIDEO_DATA_READY)
			{
				frame = 1/vp.fps;
				seekSize.text = String(frame);
				duration.appendText(StringUtils.turnNumberToTime(vp.duration,true,true,true));				
			}
		}
		
		private function onVideoFailed(event:VideoPlayerEvent):void
		{
			Debugging.alert("failed loading");
		}
		
		private function onSetSource(event:MouseEvent):void
		{
			output.text = seekSize.text = "";
			vp.source = input.text;
			duration.text = "duration: ";
		}
		
		private function onToggle(event:MouseEvent):void
		{
			if (vp.isPlaying)
			{
				vp.pause();
			}
			else
			{
				vp.play();
			}
		}
		
		private function onSeek(event:MouseEvent):void
		{
			vp.playheadTime+=parseFloat(seekSize.text);
		}
	}
}