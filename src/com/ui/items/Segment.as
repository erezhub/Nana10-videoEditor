package com.ui.items
{
	import com.events.EditorEvent;
	import com.fxpn.display.AccurateShape;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.DisplayUtils;
	import com.ui.editors.SavingManager;
	
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	
	[Event (name="segmentMoved", type="com.events.EditorEvent")]
	[Event (name="itemSelected", type="com.events.EditorEvent")]
	public class Segment extends Sprite implements IItemType
	{
		public static var ACTIVE_SEGMENT_HEIGHT:Number;
		public static var SAVED_SEGMENT_HEIGHT:Number;
		
		private var frame:AccurateShape;
		private var bg:AccurateShape;
		private var _dragRect:Rectangle;

		private var origWidth:Number;
		private var _id:int;
		private var _selected:Boolean;
		
		public function Segment(color:int, timelineWidth:Number = NaN)
		{			
			var segmentHeight:Number = isNaN(timelineWidth) ? SAVED_SEGMENT_HEIGHT : ACTIVE_SEGMENT_HEIGHT;
			bg = new AccurateShape();
			bg.graphics.beginFill(color);
			bg.graphics.drawRect(0,0,100,segmentHeight);
			bg.origSize(100,segmentHeight);
			addChild(bg);
			
			frame = new AccurateShape();
			frame.graphics.lineStyle(0.5,0,1,true,LineScaleMode.NONE);
			frame.graphics.drawRect(0,0,100,segmentHeight);
			frame.origSize(100,segmentHeight);
			addChild(frame);
			
			if (isNaN(timelineWidth) == false)
			{
				_dragRect = new Rectangle(0,0,timelineWidth,0);
				origWidth = timelineWidth;
				
				buttonMode = true;
				addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			}
		}	
		
		private function onMouseDown(event:MouseEvent):void
		{
			if (event.target == this)
			{
				if (_selected || SavingManager.checkChangesSaved(savePrevItem,dontSavePrevItem))
				{
					selectItem(true);
				}
			}
		}
		
		private function savePrevItem():void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_SAVED,true));
			selectItem();
		}
		
		private function dontSavePrevItem():void
		{
			dispatchEvent(new EditorEvent(EditorEvent.RESET_ITEM,true));
			selectItem();
		}
		
		private function selectItem(dragSegment:Boolean = false):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_SELECTED));
			if (dragSegment)
			{
				startDrag(false,_dragRect);
				stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			}
			_selected = true;
		}
				
		private function onMouseUp(event:MouseEvent):void
		{
			if (SavingManager.inUse == false)
			{
				stopDrag();
				stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_MOVED));
			}
		}
		
		override public function set width(value:Number):void
		{
			frame.width = bg.width = value;
			if (_dragRect)
			{
				_dragRect.width = origWidth - value;
			}
		}
		
		override public function get width():Number
		{
			return bg.width;
		}
		
		public function set color(value:int):void
		{
			DisplayUtils.setTintColor(bg,value);
		}

		public function get id():int
		{
			return _id;
		}

		public function set id(value:int):void
		{
			_id = value;
		}

		public function set selected(value:Boolean):void
		{
			_selected = value;
		}


	}
}