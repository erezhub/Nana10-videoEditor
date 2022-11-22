package com.events
{
	import flash.events.Event;
	
	public class EditorEvent extends Event
	{
		public static const ITEM_ADDED:String = "itemAdded";
		public static const ITEM_SELECTED:String = "itemSelected";
		public static const SEGMENT_MOVED:String = "segmentMoved";
		public static const SEGMENT_RESIZING:String = "segmentResizing";
		public static const SEGMENT_RESIZED:String = "segmentResized";
		public static const SEGMENT_EDITED:String = "segmentEdited";
		public static const SEGMENT_ADDED:String = "segmentAdded";
		public static const MARKER_MOVED:String = "markerMoved";
		public static const MARKER_EDITED:String = "markerEdited";
		public static const MARKER_ADDED:String = "markerAdded";
		public static const ITEM_SAVED:String = "itemSaved";
		public static const NEW_ITEM_SAVED:String = "newItemSaved";
		public static const SEGMENT_BLACKHOLE:String = "segmentBlackhole";
		public static const ITEM_DISABLED:String = "itemDisabled";
		public static const ITEM_DELETED:String = "itemDeleted";
		public static const RESET_ITEM:String = "resetItem";
		public static const GROUP_MINIMIZED:String = "minimizeGroup";
		public static const GROUP_MAXIMIZED:String = "maximizeGroup";
		public static const GROUP_TWEEN_FINISHED:String = "groupTweenFinised";
		public static const GROUP_SAVED:String = "groupSaved";
		public static const GROUP_DELETED:String = "groupDeleted";
		public static const GROUP_SELECTED:String = "groupSelected";
		public static const GROUP_DUPLICATED:String = "groupDuplicated";
		public static const GROUP_ADDED:String = "groupAdded";
		public static const DATA_READY:String = "dataReady";
		public static const DATA_SAVED_SUCCESSFULLY:String = "dataSavedSuccessfully";
		public static const DATA_SAVE_ERROR:String = "dataSaveError";
		public static const MAIN_SAVE:String = "mainSave";
		public static const GROUP_OFFSET:String = "groupOffset";
		public static const PREVIEW_START:String = "previewStart";
		public static const PREVIEW_END:String = "previewEnd";
		public static const STREAM_NOT_REDAY:String = "streamNotReady";
		public static const ADD_SEGMENT_MARKER:String = "addSegmentMarker";
		
		public var segmentSide:int;
		public var itemType:int;
		public var itemID:int;
		public var origItemId:int;
		public var groupID:int;
		public var origGroupID:int;
		public var stillImage:Boolean;
		public var cancelSave:Boolean;
		public var offset:Number;
		
		public function EditorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var event:EditorEvent = new EditorEvent(type, bubbles,cancelable);
			event.segmentSide = segmentSide;
			event.itemType = itemType;
			event.itemID = itemID;
			event.origItemId = origItemId;
			event.groupID = groupID;
			event.origGroupID = origGroupID;
			event.stillImage = stillImage;
			event.cancelSave = cancelSave;
			event.offset = offset;
			return 	event;
		}
	}
}