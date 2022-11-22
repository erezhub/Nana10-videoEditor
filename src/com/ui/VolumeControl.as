// the volume control is made of 2 elements: the mute toggle button, and the volume-level slider.  once rolling over the button the slider appears.
package com.ui
{
	import com.events.Nana10PlayerEvent;
	import com.events.VideoControlsEvent;
	import com.fxpn.display.TooltipFactory;
	import com.ui.Nana10VideoPlayer;
	
	import flash.display.MovieClip;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	
	import gs.TweenLite;
	import gs.easing.Cubic;
	
	[Event (name="volumeChanged", type="com.events.Nana10PlayerEvent")]		
	public class VolumeControl extends EventDispatcher
	{		
		private var _muteBtn:MovieClip;
		private var _volumeSlider:MovieClip;
		private var _sliderMask:MovieClip;
		private var _videoPlayer:Nana10VideoPlayer;
		private var volumeDragRect:Rectangle;
		private var volumeLevelSO:SharedObject;
		private var volumeSliderTween:TweenLite;
		private var tweenDuration:Number = 0.4;
		private var ease:Function = Cubic.easeIn;
		private var draggingVolume:Boolean;
		private var origVolumeY:Number;
		private var premuteVolumeLevel:Number;
		
		public function VolumeControl(muteBtn:MovieClip, volumeSlider:MovieClip, sliderMask:MovieClip)
		{
			_muteBtn = muteBtn;
			_volumeSlider = volumeSlider;
			_sliderMask = sliderMask;
			//_videoPlayer = videoPlayer;
			muteBtn.buttonMode = volumeSlider.knob.buttonMode = true;
			try
			{
				muteBtn.highlight.visible = false;
				muteBtn.disabled.visible = false;
			}
			catch (e:Error) {}

			muteBtn.addEventListener(MouseEvent.CLICK, onToggleMute);
			muteBtn.addEventListener(MouseEvent.ROLL_OVER, onRollOverVolume);
			muteBtn.addEventListener(MouseEvent.ROLL_OUT, onRollOutVolume);
			volumeSlider.addEventListener(MouseEvent.ROLL_OVER, onRollOverVolumeSlider);
			volumeSlider.addEventListener(MouseEvent.ROLL_OUT, onRollOutVolumeSlider);
			
			volumeDragRect = (volumeSlider.sliderRect.inner_mc as MovieClip).getRect(volumeSlider);
			volumeDragRect.width = 0;
			volumeDragRect.x+=2;
			volumeSlider.knob.addEventListener(MouseEvent.MOUSE_DOWN, onStartDragKnob);
			volumeSlider.knob.addEventListener(MouseEvent.MOUSE_UP, onStopDragKnob);

			volumeDragRect.y = origVolumeY = volumeSlider.knob.y; 
			
			volumeSlider.sliderRect.addEventListener(MouseEvent.CLICK, onClickVolumeBG);
			volumeSlider.fill.addEventListener(MouseEvent.CLICK, onClickVolumeBG);
			volumeSlider.sliderRect.buttonMode = volumeSlider.fill.buttonMode = true;
		}	
		
		public function init():void
		{
			try
			{
				volumeLevelSO = SharedObject.getLocal("vl");
			}
			catch (e:Error) {}
			if (volumeLevelSO == null || volumeLevelSO.data.l == undefined)
			{
				_volumeSlider.knob.y+= volumeDragRect.height/2;
			}
			else
			{
				_volumeSlider.knob.y+= volumeDragRect.height*(1 - volumeLevelSO.data.l);
			}
			onChangeVolume(null);
		}
		
		private function onToggleMute(event:MouseEvent):void
		{
			if (_muteBtn.currentLabel == "on")
			{   // mute
				premuteVolumeLevel = _volumeSlider.knob.y; 
				_volumeSlider.knob.y = volumeDragRect.y + volumeDragRect.height;
			}
			else
			{   // unmute				
				_volumeSlider.knob.y = isNaN(premuteVolumeLevel) ? volumeDragRect.y : premuteVolumeLevel;
			}
			onChangeVolume(null);
		}
		
		// open volume slider
		private function onRollOverVolume(event:MouseEvent):void
		{
			if (!event.buttonDown)
			{
				volumeSliderTween = new TweenLite(_volumeSlider,tweenDuration,{y: _muteBtn.y - _volumeSlider.height + 3, ease: ease, onComplete: displayVolumeTooltip});
				
			}
			try
			{
				_muteBtn.highlight.visible = true;
			}
			catch (e:Error) {};
		}
		
		// close volume slider
		private function onRollOutVolume(event:MouseEvent):void
		{
			if (!draggingVolume && volumeSliderTween)
			{
				volumeSliderTween.complete(true);
				volumeSliderTween = new TweenLite(_volumeSlider,tweenDuration,{y: _muteBtn.y + 4, ease: ease});
				TooltipFactory.getInstance().hideTooltip();
				_volumeSlider.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			try
			{
				_muteBtn.highlight.visible = false;
			}
			catch (e:Error) {};
		}
		
		// once over the video slider - ignore the 'roll-out' of the mute button and display the tooltip
		private function onRollOverVolumeSlider(event:MouseEvent):void
		{
			TweenLite.killTweensOf(_volumeSlider);
			TweenLite.to(_volumeSlider,tweenDuration,{y: _muteBtn.y - _volumeSlider.height + 3, ease: ease});
			displayVolumeTooltip();
		}
		
		private function onRollOutVolumeSlider(event:MouseEvent):void
		{
			if (!draggingVolume)
			{
				TweenLite.to(_volumeSlider,tweenDuration,{y: _muteBtn.y + 4, ease: ease});
				TooltipFactory.getInstance().hideTooltip();
			}
		}
		
		// dragging the volume knob
		private function onStartDragKnob(event:MouseEvent):void
		{
			_volumeSlider.knob.startDrag(true,volumeDragRect);
			_volumeSlider.stage.addEventListener(MouseEvent.MOUSE_UP, onStopDragKnob);
			draggingVolume = true;
			_volumeSlider.stage.addEventListener(MouseEvent.MOUSE_MOVE, onChangeVolume);
		}
		
		private function onMouseWheel(event:MouseEvent):void
		{
			changeVolume(event.delta > 0);
		}
		
		// changing the volume (can be called from the key-board shortcuts manager - thus public)
		public function changeVolume(direction:Boolean):void
		{
			var delta:Number = volumeDragRect.height*0.1;
			if (direction) // up
			{
				if (_volumeSlider.knob.y - delta > volumeDragRect.y)
				{ 
					_volumeSlider.knob.y-=delta;
				}
				else
				{
					_volumeSlider.knob.y = volumeDragRect.y;	
				}
			}
			else // down
			{
				if (_volumeSlider.knob.y + delta < volumeDragRect.y + volumeDragRect.height)
				{
					_volumeSlider.knob.y+=delta;
				}
				else
				{
					_volumeSlider.knob.y = volumeDragRect.y + volumeDragRect.height;
				}	
			}
			onChangeVolume(null);
		}
		
		private function onChangeVolume(event:MouseEvent):void
		{
			_volumeSlider.fill.height = Math.max(_volumeSlider.fill.y - (_volumeSlider.knob.y + 0.2),0);
			if (volumeLevelSO) volumeLevelSO.data.l = /*_videoPlayer.volume =*/ _volumeSlider.fill.scaleY;
			if (_volumeSlider.fill.scaleY <=0.01)
			{	// if slider is close to the bottom - display 'mute' icon
				_muteBtn.gotoAndStop("off");
			}
			else
			{
				_muteBtn.gotoAndStop("on");
			}
			var videoControlsEvent:VideoControlsEvent = new VideoControlsEvent(VideoControlsEvent.CHANGE_VOLUME);
			videoControlsEvent.volumeLevel = volumeLevelSO ?  volumeLevelSO.data.l : _volumeSlider.fill.scaleY;
			dispatchEvent(videoControlsEvent);
		}
		
		// volume knob is released
		private function onStopDragKnob(event:MouseEvent):void
		{
			_volumeSlider.knob.stopDrag();
			_volumeSlider.stage.removeEventListener(MouseEvent.MOUSE_UP, onStopDragKnob);
			_volumeSlider.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onChangeVolume);
			origVolumeY = _volumeSlider.knob.y;
			
			draggingVolume = false;
			
			if (event.target != _volumeSlider && event.target != _volumeSlider.knob)
			{
				TweenLite.to(_volumeSlider,tweenDuration,{y: _muteBtn.y + 4, ease: ease});
			}
		}	
		
		private function onClickVolumeBG(event:MouseEvent):void
		{
			_volumeSlider.knob.y = _volumeSlider.mouseY;
			onChangeVolume(null);
		}
		
		private function displayVolumeTooltip():void
		{
			TooltipFactory.getInstance().dispalyTooltip("(עוצמת קול (מקשי החיצים למעלה/מטה",_muteBtn,new Point(0,-_volumeSlider.height));
			_volumeSlider.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		/*public function set videoPlayer(videoPlayer:Nana10VideoPlayer):void
		{
			_videoPlayer = videoPlayer;
		}*/
		
		public function set x(value:Number):void
		{
			_muteBtn.x = value;
			_volumeSlider.x = value - 2;
			_sliderMask.x = value - 5;
		}
	}
}