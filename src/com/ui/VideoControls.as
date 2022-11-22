package com.ui
{
	import com.data.Nana10DataRepository;
	import com.events.Nana10DataEvent;
	import com.events.VideoControlsEvent;
	import com.events.VideoPlayerEvent;
	import com.fxpn.util.StringUtils;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	import resources.videoControlsVisuals;
	
	[Event (name="play", type="com.events.VideoControlsEvent")]
	[Event (name="pause", type="com.events.VideoControlsEvent")]
	[Event (name="mute", type="com.events.VideoControlsEvent")]
	[Event (name="unmute", type="com.events.VideoControlsEvent")]
	[Event (name="fwd", type="com.events.VideoControlsEvent")]
	[Event (name="rwd", type="com.events.VideoControlsEvent")]
	public class VideoControls extends videoControlsVisuals
	{
		private var origWidth:Number;
		private var _totalTime:Number;
		private var _currentTime:Number;
		private var clickTimer:int;
		private var volumeControl:VolumeControl;
		
		public function VideoControls(pausedAtStart:Boolean)
		{
			origWidth = 320;
			playPauseBtn.addEventListener(MouseEvent.CLICK,onTogglePlay);
			//muteToggleBtn.addEventListener(MouseEvent.CLICK, onToggleMute);			
			fwdBtn.addEventListener(MouseEvent.MOUSE_UP, onFwd);
			fwdBtn.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			rwdBtn.addEventListener(MouseEvent.MOUSE_UP,onRwd);
			rwdBtn.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);			
			if (pausedAtStart)
			{
				playPauseBtn.gotoAndStop("play");				
			}
			else
			{
				enableSeekBtns = false;	
			}
			volumeControl = new VolumeControl(muteToggleBtn,volumeSlider,sliderMask);
			volumeControl.addEventListener(VideoControlsEvent.CHANGE_VOLUME, onVolumeChanged);
		}
		
		private function onAddedToStage(event:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUp);
			volumeControl.init();
		}
		 
		private function onTogglePlay(event:MouseEvent):void
		{
			if (playPauseBtn.currentLabel == "pause")
			{
				pause();
			}
			else
			{
				play();
			}
		}
		
		public function play():void
		{
			playPauseBtn.gotoAndStop("pause");
			dispatchEvent(new VideoControlsEvent(VideoControlsEvent.PLAY));
			enableSeekBtns = false;
		}
		
		public function pause():void
		{
			playPauseBtn.gotoAndStop("play");
			dispatchEvent(new VideoControlsEvent(VideoControlsEvent.PAUSE));
			if (Nana10DataRepository.getInstance().videoStreamingPathReady) enableSeekBtns = true;
		}
		
		private function onVolumeChanged(event:VideoControlsEvent):void
		{
			dispatchEvent(event.clone());
		}
				
		private function onMouseDown(event:MouseEvent):void
		{
			clickTimer = getTimer();
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			if (clickTimer == 0 && event.ctrlKey) clickTimer = getTimer();
		}
		
		private function onFwd(event:MouseEvent):void
		{
			if (_currentTime  < _totalTime || isNaN(_currentTime)) 
			{
				var timeCode:Number = getTimer() - clickTimer > 500 ? 1 : 0
				dispatchEvent(new VideoControlsEvent(VideoControlsEvent.FWD,timeCode));
			}
		}
		
		private function onRwd(event:MouseEvent):void
		{
			if (_currentTime > 0)
			{
				var timeCode:Number = getTimer() - clickTimer > 500 ? 1 : 0
				dispatchEvent(new VideoControlsEvent(VideoControlsEvent.RWD,timeCode));
			}
		}
		
		private function set enableSeekBtns(value:Boolean):void
		{
			fwdBtn.alpha = rwdBtn.alpha = value ? 1 : 0.5;
			fwdBtn.enabled = rwdBtn.enabled = fwdBtn.mouseEnabled = rwdBtn.mouseEnabled = value;
		}
		
		private function get enableSeekBtns():Boolean
		{
			return fwdBtn.enabled;
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			if (event.ctrlKey)
			{
				switch (event.keyCode)
				{
					case Keyboard.SPACE:
						onTogglePlay(null);
						break;
					case Keyboard.LEFT:
						if (enableSeekBtns) onRwd(null);
						break;
					case Keyboard.RIGHT:
						if (enableSeekBtns) onFwd(null);
						break;
				}	
			}
			clickTimer = 0;
		}
		
		public function setSeekButtons():void
		{
			if (Nana10DataRepository.getInstance().videoStreamingPathReady == false) enableSeekBtns = false;
		}
		
		public function set mute(value:Boolean):void
		{
			if (value)
			{
				muteToggleBtn.gotoAndStop("off");
				dispatchEvent(new VideoControlsEvent(VideoControlsEvent.MUTE));
			}
			else
			{
				muteToggleBtn.gotoAndStop("on");
				dispatchEvent(new VideoControlsEvent(VideoControlsEvent.UNMUTE));
			}
		}
		
		public function set totalTime(value:Number):void
		{
			timer.totalTime_txt.text = StringUtils.turnNumberToTime(value,true,false,true);
			_totalTime = value;
		}
		
		public function set currentTime(value:Number):void
		{
			if (value > _totalTime) value = _totalTime;
			timer.currentTime_txt.text = StringUtils.turnNumberToTime(value,true,false,true);
			_currentTime = value;
		}
		
		override public function set width(value:Number):void
		{
			bg.scaleX = value / origWidth;
			bg.width-= 1;
			timer.x = value - timer.width - 5;
			volumeControl.x = timer.x - muteToggleBtn.width - 5;
		}		
		
		override public function get height():Number
		{
			return bg.height;
		}
	}
}