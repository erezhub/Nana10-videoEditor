package com.ui.items
{
	import com.data.TaggerData;
	import com.events.EditorEvent;
	import com.fxpn.util.Debugging;
	import com.ui.editors.SavingManager;
	
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import resources.items.MarkerVisuals;
	
	[Event (name="markerMoved",type ="com.events.EditorEvent")]
	public class Marker extends MarkerVisuals implements IItemType
	{
		private var _dragRect:Rectangle;
		private var _playheadPos:Number;
		private var wasSnapped:Boolean;
		private var _id:int;
		private var _selected:Boolean;
		
		public function Marker(timelineWidth:Number = NaN)
		{
			if (isNaN(timelineWidth) == false)
			{
				_dragRect = new Rectangle(0,0,timelineWidth,0);
				addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				buttonMode = true;
			}
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			if (event.target == this && TaggerData.getInstance().allowSave)
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
				stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoved);
			}
			_selected = true;
		}
		
		private function onMouseMoved(event:MouseEvent):void
		{
			if (Math.abs(x - _playheadPos) < 5 && Math.abs(parent.mouseX - x ) < 5)
			{
				x = _playheadPos;
				wasSnapped = true;
			}
			else if (wasSnapped)
			{
				x = parent.mouseX;
				wasSnapped = false;
			}
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			if (SavingManager.inUse == false)
			{
				stopDrag();
				stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoved);
				dispatchEvent(new EditorEvent(EditorEvent.MARKER_MOVED));
			}
		}
		
		public function set playheadPos(value:Number):void
		{
			_playheadPos = value;
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