package com.ui.groups
{
	import com.data.Nana10DataRepository;
	import com.fxpn.display.ModalManager;
	import com.fxpn.gc.GarbageCollector;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.DisplayUtils;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import resources.PreviewContainerVisuals;
	
	public class PreviewContainer extends PreviewContainerVisuals
	{
		private var loader:Loader;
		private var videoPlayer:DisplayObject;
		private var dragRect:Rectangle;
		private var stillImage:Boolean;
		
		public function PreviewContainer()
		{	
			close_btn.addEventListener(MouseEvent.CLICK,onClose);
			header.addEventListener(MouseEvent.MOUSE_DOWN,onStartDrag);
			header.addEventListener(MouseEvent.ROLL_OVER,onRollOver);
			header.addEventListener(MouseEvent.ROLL_OUT,onRollOut);
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
			
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onError);
		}
		
		private function onAddedToStage(event:Event):void
		{			
			dragRect = new Rectangle(0,0,stage.stageWidth - width,stage.stageHeight - height);
		}
		
		public function init(stillImagePath:String = null):void
		{
			if (videoPlayer == null)
			{
				/*stillImage = stillImagePath != null;
				if (stillImagePath == null) stillImagePath = "../nana10player/Nana10Player.swf";//"http://localhost/nana10player/Nana10Player.swf";//"http://f.nanafiles.co.il/Common/Flash/Nana10Player.swf"; 
				var ldrContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
				loader.load(new URLRequest(stillImagePath),ldrContext);*/
				videoPlayer = new Nana10Player();
			}
			else
			{
				(videoPlayer as Nana10Player).preview();
			}
			container.addChild(videoPlayer);
		}
		
		private function onLoaded(event:Event):void
		{
			videoPlayer = loader.content;
			//var nana10Player:Class = loader.contentLoaderInfo.applicationDomain.getDefinition("Nana10Player") as Class;
			//videoPlayer = new nana10Player();
			if (stillImage)
			{
				DisplayUtils.resize(videoPlayer,container.width,container.height);
			}
			/*else
			{
				var nana10Player:Class = loader.contentLoaderInfo.applicationDomain.getDefinition("Nana10Player") as Class;
				var dataRepositoryClass:Class = loader.contentLoaderInfo.applicationDomain.getDefinition("com.data.Nana10DataRepository") as Class;
				var dataRepository:Object = Nana10DataRepository.getInstance();
				//var player:Object = videoPlayer as nana10Player;
				(videoPlayer as nana10Player).nana10DataRepository = Nana10DataRepository.getInstance();
			}*/
			container.addChild(videoPlayer);
		}
		
		private function onError(event:IOErrorEvent):void
		{
			Debugging.alert("Error loading video player");
		}
		
		private function onStartDrag(event:MouseEvent):void
		{
			startDrag(false,dragRect);
			stage.addEventListener(MouseEvent.MOUSE_UP,onStopDrag);
		}
		
		private function onStopDrag(event:MouseEvent):void
		{
			stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP,onStopDrag);
		}
		
		private function onRollOver(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private function onRollOut(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		private function onClose(event:MouseEvent):void
		{
			visible = false;
			container.removeChild(videoPlayer);
			//videoPlayer = null;
			Nana10DataRepository.getInstance().resetAfterPreview();
			ModalManager.clearModal();
		}
	}
}