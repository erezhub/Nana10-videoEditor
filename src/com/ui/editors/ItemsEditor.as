package com.ui.editors
{
	import com.data.Nana10DataRepository;
	import com.data.TaggerData;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.Nana10SegmentData;
	import com.events.ConfirmAlertEvent;
	import com.events.EditorEvent;
	import com.events.VideoControlsEvent;
	import com.fxpn.display.ModalManager;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.EvenGroupArray;
	import com.ui.AlertBox;
	
	import fl.controls.Button;
	import fl.controls.ComboBox;
	import fl.data.DataProvider;
	
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import mx.utils.NameUtil;
	
	[Event (name="pause", type="com.events.VideoControlsEvent")]
	[Event (name="itemAdded", type="com.events.EditorEvent")]
	[Event (name="markerEdited", type="com.events.EditorEvent")]
	[Event (name="markerMoved", type="com.events.EditorEvent")]
	[Event (name="itemSaved", type="com.events.EditorEvent")]
	[Event (name="itemDeleted", type="com.events.EditorEvent")]
	[Event (name="groupPreview", type="com.events.EditorEvent")]
	public class ItemsEditor extends Sprite
	{
		public static const MINIMUM_WIDTH:int = 400;
		private var frame:Shape;
		private var currentEditor:IItemEditor;
		private var segmentEditor:SegmentsEditor;
		private var markerEditor:MarkersEditor;
		private var alertBox:AlertBox;
		
		private var _currentTime:Number;
		private var _endTime:Number;
		private var _duration:Number;
		private var _currentItemType:int;
		private var _curentItemId:int;
		private var _videoTotalDuration:Number;
		private var itemToAdd:int;
		private var _currentGroupID:int;
		
		public function ItemsEditor()
		{
			frame = ShapeDraw.drawSimpleRectWithFrame(100,100,0,0,0.5,0,0x777777,LineScaleMode.NORMAL,2);
			addChild(frame);
			
			/*var addSegmentBtn:Button = new Button();
			addSegmentBtn.label = "מקטע חדש";
			addSegmentBtn.addEventListener(MouseEvent.CLICK, onCreateSegment);
			addSegmentBtn.x = addSegmentBtn.y = 10;
			addChild(addSegmentBtn);
			
			var addMarkerBtn:Button = new Button();
			addMarkerBtn.label = "מרקר חדש";
			addMarkerBtn.addEventListener(MouseEvent.CLICK,onCreateMarker);
			addMarkerBtn.x = addSegmentBtn.x + addSegmentBtn.width + 10;
			addMarkerBtn.y = addSegmentBtn.y;
			addChild(addMarkerBtn);
			
			addMarkerBtn.enabled = addSegmentBtn.enabled = TaggerData.getInstance().allowSave;*/
						
			segmentEditor = new SegmentsEditor();
			markerEditor = new MarkersEditor();
			segmentEditor.x = markerEditor.x = 20;
			segmentEditor.y = markerEditor.y = 30;//addSegmentBtn.y + addSegmentBtn.height + 10;
			segmentEditor.visible = markerEditor.visible = false;
			addChild(segmentEditor);
			addChild(markerEditor);
			
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void
		{
			/*alertBox = new AlertBox(stage);
			alertBox.addEventListener(ConfirmAlertEvent.YES, onSaveCurrentItem);
			alertBox.addEventListener(ConfirmAlertEvent.NO, onDontSaveCurrentItem);*/
			SavingManager.init(stage);
		}
		
		public function createNewSegment():void
		{	
			itemToAdd = Nana10ItemData.SEGMENT;
			if (SavingManager.checkChangesSaved(saveCurrentItem,dontSaveCurrentItem))
			{
				createSegment();
			}
		}
		
		private function createSegment():void
		{
			markerEditor.visible = false;
			segmentEditor.visible = true;
			SavingManager.currentEditor = currentEditor = segmentEditor;
			segmentEditor.duration = _duration;
			createItem(Nana10ItemData.SEGMENT);
		}
		
		public function createNewMarker():void
		{
			itemToAdd = Nana10ItemData.MARKER;
			if (SavingManager.checkChangesSaved(saveCurrentItem,dontSaveCurrentItem))
			{
				createMarker();
			}
		}
		
		private function createMarker():void
		{
			segmentEditor.visible = false;
			markerEditor.visible = true;
			SavingManager.currentEditor = currentEditor = markerEditor;
			createItem(Nana10ItemData.MARKER);
		}
						
		private function saveCurrentItem():void
		{
			/*var editorEvent:EditorEvent = new EditorEvent(EditorEvent.ITEM_SAVED);
			editorEvent.itemType = _currentItemType;
			dispatchEvent(editorEvent);*/
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_SAVED));
			dontSaveCurrentItem(true);
		}
		
		private function dontSaveCurrentItem(save:Boolean = false):void
		{			
			if (!save)
			{
				/*var editorEvent:EditorEvent = new EditorEvent(EditorEvent.REMOVE_ITEM);
				editorEvent.itemType = _currentItemType;
				dispatchEvent(editorEvent);*/
				dispatchEvent(new EditorEvent(EditorEvent.RESET_ITEM));
			}
			if (itemToAdd == Nana10ItemData.MARKER)
			{
				createMarker();
			}
			else
			{
				createSegment();
			}
		}
		
		private function createItem(itemType:int):void
		{			
			currentEditor.clear();
			currentEditor.endTime = _videoTotalDuration;//_endTime;
			currentEditor.saveBtnLabel = "הוספה";
			(currentEditor as Sprite).addEventListener(EditorEvent.ITEM_DELETED,onDeleteItem);
			//currentEditor.setAddToGroupDisplay(_currentGroupID,0);
			_currentItemType = itemType;
			_curentItemId = 0;
			//currentEditor.init();
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_ADDED));
		}
		
		private function onDeleteItem(event:EditorEvent):void
		{
			if (alertBox == null)
			{
				alertBox = new AlertBox(stage);
				alertBox.addEventListener(ConfirmAlertEvent.YES,onConfirmItemDelete);
			}	
			alertBox.displayConfirmation("האם למחוק?",false);
		}
		
		private function onConfirmItemDelete(event:ConfirmAlertEvent):void
		{
			clearCurrentItem();
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_DELETED));
		}
		
		public function addExistingItem(id:int,groupID:int):void
		{
			if (currentEditor) currentEditor.clear();
			var itemData:Nana10MarkerData = Nana10DataRepository.getInstance().getItemById(id);
			if (itemData.type == Nana10ItemData.MARKER)
			{
				segmentEditor.visible = false;
				markerEditor.visible = true;
				SavingManager.currentEditor = currentEditor = markerEditor;
				markerEditor.markerType = itemData.markerType;
				currentEditor.endTime = _videoTotalDuration;
			}
			else
			{
				markerEditor.visible = false;
				segmentEditor.visible = true;
				SavingManager.currentEditor = currentEditor = segmentEditor;
				currentEditor.endTime = _videoTotalDuration;
				segmentEditor.endTime = (itemData as Nana10SegmentData).endTimecode;
				segmentEditor.duration = (itemData as Nana10SegmentData).endTimecode - itemData.timeCode;
				segmentEditor.description = (itemData as Nana10SegmentData).description;
				segmentEditor.id = (itemData as Nana10SegmentData).uniqueGroup;
			}
			(currentEditor as Sprite).addEventListener(EditorEvent.ITEM_DELETED,onDeleteItem);
			currentEditor.currentTime = itemData.timeCode;
			currentEditor.title = itemData.title;
			currentEditor.dissabled = itemData.status == 0;
			currentEditor.saveBtnLabel = "עדכון";
			//currentEditor.setAddToGroupDisplay(_currentGroupID,itemData.id);
			currentEditor.currentGroupID = _currentGroupID = groupID;
			currentEditor.init();
			_currentItemType = itemData.type;
			_curentItemId = itemData.id;
		}
				
		public function set currentTime(value:Number):void
		{
			_currentTime = value;
			if (currentEditor) currentEditor.currentTime = value;
		}
		
		public function get currentTime():Number
		{
			return currentEditor.currentTime;
		}
		
		public function clearCurrentItem():void
		{
			segmentEditor.visible = markerEditor.visible = false;
			segmentEditor.init();
			markerEditor.init();
		}
		
		public function resetCurrentItem():void
		{
			addExistingItem(currentItemId,_currentGroupID);
		}
		
		public function currentItemSaved():void
		{
			currentEditor.init();
		}
		
		public function setSize(w:Number, h:Number):void
		{
			frame.width = w;
			frame.height = h;
		}
		
		public function preivewEnded():void
		{
			segmentEditor.previewEnded();
		}
		
		public function set itemSavedSuccesfully(value:Boolean):void
		{
			currentEditor.itemSavedSuccesfully = value;
		}

		public function get currentItemType():int
		{
			return _currentItemType;
		}
		
		public function get currentItemId():int
		{
			return _curentItemId;
		}
		
		public function set currentItemId(value:int):void
		{
			if (_curentItemId == 0)
			{
				currentEditor.saveBtnLabel = "עדכון";
				currentEditor.init();
				//if (currentEditor == segmentEditor) segmentEditor.id = value;
			}
			if (value > 0 && currentEditor == segmentEditor)
				segmentEditor.id = value;
			_curentItemId = value;
		}
		
		public function set uniqueGroupID(value:int):void
		{
			segmentEditor.uniqueGroupID = value;
			if (value > 0 && currentEditor == segmentEditor)
				segmentEditor.id = value;
		}
		
		public function set videoTotalDuration(value:Number):void
		{
			_videoTotalDuration = value;
		}
		
		public function set endTime(value:Number):void
		{
			_endTime = value;
			if (currentEditor) currentEditor.endTime = value;
			if (isNaN(_videoTotalDuration)) _videoTotalDuration = value;
		}
		
		public function get endTime():Number
		{
			if (currentEditor == segmentEditor) return segmentEditor.endTime;
			return 0;
		}
		
		public function set duration(value:Number):void
		{
			_duration = value;
			if (currentEditor == segmentEditor) segmentEditor.duration = value;
		}
		
		public function get itemName():String
		{
			return currentEditor.title;
		}
		
		public function set itemName(value:String):void
		{
			currentEditor.title = value;
		}
		
		public function get segmentDescription():String
		{
			if (currentEditor == segmentEditor) return segmentEditor.description;
			return "";
		}
		
		public function set itemDissabled(value:Boolean):void
		{
			currentEditor.dissabled = value;
		}
		
		public function get itemDissabled():Boolean
		{
			return currentEditor.dissabled;
		}

		/*public function set currentGroup(id:int):void
		{
			_currentGroupID = Nana10DataRepository.getInstance().totalGroups > 1 ? id : 0;
			if (currentEditor) currentEditor.currentGroupID = _currentGroupID;
		}*/
		
		public function get inUse():Boolean
		{
			return currentEditor != null;
		}
		
		public function get markerType():Boolean
		{
			if (currentEditor == markerEditor) return markerEditor.markerType;
			return false;
		}

	}
}