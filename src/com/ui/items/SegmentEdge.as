package com.ui.items
{
	import com.events.EditorEvent;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.Debugging;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	[Event (name="segmentResizing", type="com.events.EditorEvent")]
	[Event (name="segmentResized", type="com.events.EditorEvent")]
	public class SegmentEdge extends Sprite
	{
		private var dragRect:Rectangle;
		private var _playheadPos:Number;
		private var wasSnapped:Boolean;
		
		public function SegmentEdge(segmentHeight:Number)
		{
			addChild(ShapeDraw.drawSimpleRect(10,segmentHeight,0,0));
			dragRect = new Rectangle(0,0,100,0);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			startDrag(false,dragRect);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoved);
		}
		
		private function onMouseMoved(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_RESIZING));			
			if (Math.abs(x + width/2 - _playheadPos) < 5 && Math.abs(parent.mouseX - x - width/2) < 5)
			{
				x = _playheadPos - width/2;
				dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_RESIZING));
				wasSnapped = true;
				//onMouseUp(null);
			}
			else if (wasSnapped)
			{
				x = parent.mouseX - width/2;
				wasSnapped = false;
				dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_RESIZING));
			}
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoved);
			dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_RESIZED));
		}
		
		private function onRollOver(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private function onRollOut(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		public function set dragRectWidth(value:Number):void
		{
			dragRect.width = value;
		}
		
		public function set dragRectX(value:Number):void
		{
			dragRect.x = value;
		}

		public function set playheadPos(value:Number):void
		{
			_playheadPos = value;
		}
		
		
	}
}