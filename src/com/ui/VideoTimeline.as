package com.ui
{
	//import com.data.DataRepository;
	import com.data.Nana10DataRepository;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.Nana10SegmentData;
	import com.events.EditorEvent;
	import com.events.VideoControlsEvent;
	import com.events.VideoPlayerEvent;
	import com.fxpn.display.AccurateShape;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.DisplayUtils;
	import com.fxpn.util.MathUtils;
	import com.ui.editors.ItemsEditor;
	import com.ui.editors.SavingManager;
	import com.ui.editors.SegmentsEditor;
	import com.ui.items.IItemType;
	import com.ui.items.Marker;
	import com.ui.items.Segment;
	import com.ui.items.SegmentEdge;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import resources.PlayheadBtn;
	
	[Event (name="pause", type="com.events.VideoControlsEvent")]
	[Event (name="playheadReleased", type="com.events.VideoPlayerEvent")]
	[Event (name="playheadMoved", type="com.events.VideoControlsEvent")]
	[Event (name="segmentMoved", type="com.events.EditorEvent")]
	[Event (name="segmentResized", type="com.events.EditorEvent")]
	[Event (name="itemSelected", type="com.events.EditorEvent")]
	[Event (name="itemReset", type="com.events.EditorEvent")]
	public class VideoTimeline extends Sprite
	{		
		private var bg:AccurateShape;
		private var playhead:PlayheadBtn;
		private var dragRect:Rectangle;
		private var timelineMask:Shape;
		private var segmentsContainer:Sprite;
		private var markersContainer:Sprite;
		private var markersMask:Shape;
		private var segmentLeftEdge:SegmentEdge;
		private var segmentRightEdge:SegmentEdge;
		private var currentSegment:Segment;
		private var currentMarker:Marker;
		private var currentItem:IItemType;
		private var selectedItem:IItemType;
		private var draggingTimer:Timer;
		//private var availableColors:Array;
		private var _currentSegmentColor:int;
		private var currentItemX:Number;
		private var wasSnapped:Boolean;
		private var currentItems:Array;
		private var itemsLocations:Array;
		
		public function VideoTimeline(timelineHeight:Number)
		{
			bg = new AccurateShape();
			var g:Graphics = bg.graphics;
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(100,timelineHeight,Math.PI/2);
			g.beginGradientFill(GradientType.LINEAR,[0xFEB626,0xFF7B00],[1,1],[127,255],matrix);
			g.lineStyle(1,0,1,true,LineScaleMode.NONE);
			g.drawRect(0,0,100,timelineHeight);
			bg.origSize(100,timelineHeight);
			addChild(bg);
			
			segmentsContainer = new Sprite();
			segmentsContainer.y = 1;
			addChild(segmentsContainer);
			
			markersContainer = new Sprite();
			markersContainer.y = 1;
			addChild(markersContainer);
			
			playhead = new PlayheadBtn();
			playhead.addEventListener(MouseEvent.MOUSE_DOWN, onStartDrag);
			playhead.buttonMode = true;
			//playhead.filters = [new GlowFilter(0xffffff)];
			addChild(playhead);
			
			segmentLeftEdge = new SegmentEdge(timelineHeight);
			segmentLeftEdge.addEventListener(EditorEvent.SEGMENT_RESIZED, onSegmentMoved);
			segmentLeftEdge.addEventListener(EditorEvent.SEGMENT_RESIZING, onSegmentResizing);
			segmentRightEdge = new SegmentEdge(timelineHeight);
			segmentRightEdge.addEventListener(EditorEvent.SEGMENT_RESIZED, onSegmentMoved);
			segmentRightEdge.addEventListener(EditorEvent.SEGMENT_RESIZING, onSegmentResizing);
			segmentLeftEdge.playheadPos = segmentRightEdge.playheadPos = playhead.x;
			
			dragRect = new Rectangle(0,playhead.y,bg.width - playhead.width,0);
			timelineMask = ShapeDraw.drawSimpleRect(bg.width,bg.height + 10);
			addChild(timelineMask);
			playhead.mask = timelineMask;
			markersMask = ShapeDraw.drawSimpleRect(bg.width-2,bg.height + 10);
			markersMask.x = 1;
			addChild(markersMask);
			markersContainer.mask = markersMask;
			
			draggingTimer = new Timer(1000);
			draggingTimer.addEventListener(TimerEvent.TIMER,onPlayheadMoved);
			currentItems = [];
			itemsLocations = [];
			//availableColors = [0xdd0000,0x00dd00,0x0000dd,0xdddd00,0xdd00dd,0x00dddd];
		}
		
		private function onStartDrag(event:MouseEvent):void
		{
			playhead.startDrag(false,dragRect);
			stage.addEventListener(MouseEvent.MOUSE_UP, onStopDrag);
			stage.addEventListener(MouseEvent.MOUSE_MOVE,onCheckPlayheadSnap);
			dispatchEvent(new VideoControlsEvent(VideoControlsEvent.PAUSE));
			draggingTimer.start();
		}
		
		private function onCheckPlayheadSnap(event:MouseEvent):void
		{
			if (Math.abs(mouseX - playhead.x) < 5)
			{
				if (currentSegment)
				{
					if (Math.abs(playhead.x - currentSegment.x) < 5)
					{
						playhead.x = currentSegment.x;
						wasSnapped = true;						
					}
					else if (Math.abs(playhead.x - (currentSegment.x + currentSegment.width)) < 5)
					{
						playhead.x = currentSegment.x + currentSegment.width;
						wasSnapped = true;
					}
				}
				else if (currentMarker && Math.abs(playhead.x - currentMarker.x) < 5)
				{
					playhead.x = currentMarker.x;
					wasSnapped = true;
				}				
			}
			else if (wasSnapped)
			{
				playhead.x = parent.mouseX - playhead.width/2;
				wasSnapped = false;
			}
		}
		
		private function onPlayheadMoved(event:TimerEvent):void
		{			
			dispatchEvent(new VideoControlsEvent(VideoControlsEvent.PLAYHEAD_MOVED));
		}
		
		private function onStopDrag(event:MouseEvent):void
		{
			playhead.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP, onStopDrag);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,onCheckPlayheadSnap);
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.PLAYHEAD_RELEASED));
			draggingTimer.stop();
			segmentLeftEdge.playheadPos = segmentRightEdge.playheadPos = playhead.x;
			if (currentMarker) currentMarker.playheadPos = playhead.x;
		}
		
		public function addNewItem(itemType:int, segmentColor:int = 0):void
		{
			switch(itemType)
			{
				case Nana10ItemData.MARKER:
					var marker:Marker = new Marker(dragRect.width);
					marker.x = playhead.x;
					markersContainer.addChild(marker);
					marker.addEventListener(EditorEvent.MARKER_MOVED,onMarkerMoved);
					marker.addEventListener(EditorEvent.ITEM_SELECTED, onSelectItem);
					currentMarker = marker;
					marker.playheadPos = playhead.x;
					currentItem = marker;
					break;
				case Nana10ItemData.SEGMENT:
					/*if (availableColors.length)
					{
						var colorIndex:int = MathUtils.randomInteger(0,availableColors.length - 1);
						_currentSegmentColor = availableColors[colorIndex];	
						availableColors.splice(colorIndex,1);
					}
					else
					{
						_currentSegmentColor = MathUtils.randomInteger(1000,0xdddddd);
					}*/
					_currentSegmentColor = segmentColor;
					var segment:Segment = new Segment(_currentSegmentColor,dragRect.width);
					segment.width = bg.width - playhead.x - 1;
					segment.x = playhead.x;
					segmentsContainer.addChild(segment);
					segment.addEventListener(EditorEvent.SEGMENT_MOVED, onSegmentMoved);
					segment.addEventListener(EditorEvent.ITEM_SELECTED,onSelectItem);
					//segment.addEventListener(MouseEvent.MOUSE_DOWN, onSelectItem);
					currentSegment = segment;
					segmentLeftEdge.x = segment.x - segmentLeftEdge.width/2;
					segmentRightEdge.x = segment.x + segment.width - segmentRightEdge.width/2;
					segmentLeftEdge.dragRectWidth = segmentRightEdge.x - 15;
					segmentLeftEdge.dragRectX = -segmentLeftEdge.width/2;
					segmentRightEdge.dragRectWidth = bg.width - segmentLeftEdge.x - 20;
					segmentRightEdge.dragRectX = segmentLeftEdge.x + 15;
					segmentsContainer.addChild(segmentLeftEdge);
					segmentsContainer.addChild(segmentRightEdge);
					
					currentItem = segment;
					break;				
			}
			currentItem.selected = true;
		}
		
		public function addExistingItem(itemData:Nana10MarkerData, itemPosition:Number, segmentWidth:Number = NaN):void
		{
			switch(itemData.type)
			{
				case Nana10ItemData.MARKER:
					if (currentItems.indexOf(itemData.id) == -1)
					{
						var marker:Marker = new Marker(dragRect.width);
						marker.x = dragRect.width * itemPosition;
						markersContainer.addChild(marker);
						marker.addEventListener(EditorEvent.MARKER_MOVED,onMarkerMoved);
						marker.addEventListener(EditorEvent.ITEM_SELECTED, onSelectItem);
						marker.id = itemData.id;
						if (itemData.markerType) DisplayUtils.setTintColor(marker,0x999999);
					}
					else
					{
						currentMarker.x = dragRect.width * itemPosition;
					}
					break;
				case Nana10ItemData.SEGMENT:
					if (currentItems.indexOf(itemData.id) == -1)
					{
						var segment:Segment = new Segment((itemData as Nana10SegmentData).color,dragRect.width);						
						segment.width = dragRect.width * segmentWidth//bg.width - playhead.x - 1;
						segment.x = dragRect.width * itemPosition;
						segmentsContainer.addChild(segment);
						segment.addEventListener(EditorEvent.SEGMENT_MOVED, onSegmentMoved);
						//segment.addEventListener(MouseEvent.MOUSE_DOWN, onSelectItem);
						segment.addEventListener(EditorEvent.ITEM_SELECTED,onSelectItem);
						segment.id = itemData.id;
						segment.alpha = itemData.status == 1 ? 1 : 0.5;
					}
					else
					{
						currentSegment.width = dragRect.width * segmentWidth;
						currentSegment.x = dragRect.width * itemPosition;
					}
					/*segmentLeftEdge.x = segment.x - segmentLeftEdge.width/2;
					segmentRightEdge.x = segment.x + segment.width - segmentRightEdge.width/2;
					segmentLeftEdge.dragRectWidth = segmentRightEdge.x - 15;
					segmentLeftEdge.dragRectX = -segmentLeftEdge.width/2;
					segmentRightEdge.dragRectWidth = bg.width - segmentLeftEdge.x - 20;
					segmentRightEdge.dragRectX = segmentLeftEdge.x + 15;
					segmentsContainer.addChild(segmentLeftEdge);
					segmentsContainer.addChild(segmentRightEdge);
					
					currentItem = segment;*/
					break;				
			}
			if (currentItems.indexOf(itemData.id) == -1)
				currentItems.push(itemData.id);
		}
		
		public function deleteItem():void
		{
			(currentItem as Sprite).removeEventListener(EditorEvent.ITEM_SELECTED,onSelectItem);
			if (currentItem is Segment)
			{
				currentSegment.removeEventListener(EditorEvent.SEGMENT_MOVED,onSegmentMoved);
				segmentsContainer.removeChild(currentSegment);
				currentSegment = null;
				segmentLeftEdge.visible = segmentRightEdge.visible = false;
			}
			else
			{
				currentMarker.removeEventListener(EditorEvent.MARKER_MOVED,onMarkerMoved);
				markersContainer.removeChild(currentMarker);
				currentMarker = null;
			}
			currentItem = null;
		}
		
		public function clearItems():void
		{
			clearContainer(segmentsContainer);
			clearContainer(markersContainer);
			currentItems = [];
		}
		
		private function clearContainer(container:Sprite):void
		{
			var totalItems:int = container.numChildren;
			for (var i:int = totalItems - 1; i >=0; i--)
			{
				container.removeChildAt(i);
			}
		}
		
		private function onSelectItem(event:EditorEvent):void
		{
			if (currentItem != event.target as IItemType)
			{
				if (currentItem) currentItem.selected = false;
				currentItem = event.target as IItemType;
				var itemData:Nana10MarkerData = Nana10DataRepository.getInstance().getItemById(currentItem.id);
				if (itemData.type == Nana10ItemData.MARKER)
				{
					currentMarker = currentItem as Marker;
					segmentLeftEdge.visible = segmentRightEdge.visible = false;
				}
				else
				{
					currentSegment = currentItem as Segment;
					_currentSegmentColor = (itemData as Nana10SegmentData).color;
					onSegmentMoved(null);
				}
				var editorEvent:EditorEvent = new EditorEvent(EditorEvent.ITEM_SELECTED);
				editorEvent.itemID = currentItem.id;
				dispatchEvent(editorEvent);
				currentItemX = currentItem.x;
				/*selectedItem = event.target as IItemType; 
				if (SavingManager.checkChangesSaved(savePrevItem,dontSavePrevItem))
				{
					selectItem();
				}*/
			}
			//segmentLeftEdge.visible = segmentRightEdge.visible = false;
		}
				
		private function onSegmentMoved(event:EditorEvent):void
		{
			if (currentItemX == currentItem.x && event != null && event.target != segmentRightEdge) return;
			if (segmentLeftEdge.parent == null) segmentsContainer.addChild(segmentLeftEdge);
			if (segmentRightEdge.parent == null) segmentsContainer.addChild(segmentRightEdge);
			segmentLeftEdge.x = currentSegment.x - segmentLeftEdge.width/2;
			segmentRightEdge.x = currentSegment.x + currentSegment.width - segmentRightEdge.width/2;
			segmentLeftEdge.dragRectWidth = segmentRightEdge.x - 15;
			segmentRightEdge.dragRectWidth = bg.width - segmentLeftEdge.x - 20;
			segmentRightEdge.dragRectX = segmentLeftEdge.x + 15;
			segmentLeftEdge.visible = segmentRightEdge.visible = true;
			if (event != null)
			{
				event.segmentSide = event.target == segmentLeftEdge ? SegmentsEditor.LEFT_SIDE : SegmentsEditor.RIGHT_SIDE
				dispatchEvent(event);
			}
		}
		
		private function onSegmentResizing(event:EditorEvent):void
		{
			if (event.currentTarget == segmentLeftEdge)
			{
				currentSegment.x = segmentLeftEdge.x + segmentLeftEdge.width/2;
			}
			currentSegment.width = segmentRightEdge.x + segmentRightEdge.width/2 - currentSegment.x;
		}
		
		private function onMarkerMoved(event:EditorEvent):void
		{
			if (currentItemX == currentItem.x) return;
			dispatchEvent(event);
		}
		
		public function removeCurrentItem(itemType:int):void
		{
			if (itemType == Nana10ItemData.MARKER)
			{
				if (currentMarker) markersContainer.removeChild(currentMarker);
			}
			else
			{
				if (currentSegment) segmentsContainer.removeChild(currentSegment);
			}
		}
		
		public function set playheadProgress(value:Number):void
		{
			playhead.x = value * dragRect.width;
		}
		
		public function get playheadProgress():Number
		{
			return playhead.x / dragRect.width;
		}
		
		override public function set width(value:Number):void
		{
			bg.width = timelineMask.width = value;
			markersMask.width = value - 2;
			dragRect.width = value// - playhead.width/2;
		}
		
		override public function get width():Number
		{
			return dragRect.width;
		}
		
		override public function get height():Number
		{
			return bg.height;
		}
		
		public function get currentSegmentPosition():Number
		{
			return currentSegment.x / bg.width;
		}
		
		public function set currentSegmentPosition(value:Number):void
		{
			currentSegment.x = value * bg.width;
		}
		
		public function get currentSegmentWidth():Number
		{
			return currentSegment.width / bg.width;
		}
		
		public function set currentSegmentWidth(value:Number):void
		{
			currentSegment.width = value * bg.width;
		}
		
		public function set currentMarkerPosition(value:Number):void
		{
			currentMarker.x = value * bg.width;
		}
		
		public function get currentMarkerPosition():Number
		{
			return currentMarker.x / bg.width;
		}
		
		public function get currentSegmentColor():int
		{
			return _currentSegmentColor;
		}
		
		public function set currentSegmentBlackhole(value:Boolean):void
		{
			if (value)
			{
				currentSegment.color = 0x444444;
			}
			else
			{
				currentSegment.color = _currentSegmentColor;
			}
		}
		
		public function set currentItemDissabled(value:Boolean):void
		{
			currentItem.alpha = value ? 0.5 : 1;
		}
		
		public function set currentItemId(value:int):void
		{
			var itemData:Nana10MarkerData = Nana10DataRepository.getInstance().getItemById(value);
			/*if (currentItem)
			{
				currentItem.id = value;
				if (itemData.type == Nana10ItemData.SEGMENT) onSegmentMoved(null);
			}
			else
			{*/
			if (currentItem) currentItem.selected = false;
			currentItem = null;
			var found:Boolean;
			if (itemData)
			{
				if (itemData.type == Nana10ItemData.SEGMENT)
				{
					var totalSegments:int = segmentsContainer.numChildren;
					for (var i:int = 0; i < totalSegments; i++)
					{
						var currSegment:Object = segmentsContainer.getChildAt(i);
						if ((currSegment is SegmentEdge) == false && 
							((currSegment as Segment).id == value || ((currSegment as Segment).id == 0 && value < 0)))
						{
							currentItem = currentSegment = (segmentsContainer.getChildAt(i) as Segment);
							_currentSegmentColor = (Nana10DataRepository.getInstance().getItemById(value) as Nana10SegmentData).color;
							onSegmentMoved(null);
							found = true;
							break;
						}
					}
				}
				else
				{
					var totalMarkers:int = markersContainer.numChildren;
					for (var j:int = 0; j < totalMarkers; j++)
					{
						if ((markersContainer.getChildAt(j) as Marker).id == value || ((markersContainer.getChildAt(j) as Marker).id == 0 && value < 0))
						{
							currentItem = currentMarker = (markersContainer.getChildAt(j) as Marker);
							found = true;
							if (itemData.markerType) DisplayUtils.setTintColor(currentMarker,0x999999);
							break;
						}
					}
					segmentLeftEdge.visible = segmentRightEdge.visible = false;
				}
			}
			if (currentItem)
			{
				/*if (!found)*/ currentItem.id = value;
				currentItemX = /*playhead.x =*/ currentItem.x;
				currentItem.selected = true;
				
			}
			else
			{
				playhead.x = 0;
				onStopDrag(null);
			}
		}
	}
}