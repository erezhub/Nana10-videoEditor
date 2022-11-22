package com.ui.groups
{
	import com.data.ImageUploader;
	import com.data.Nana10DataRepository;
	import com.data.TaggerData;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.Nana10SegmentData;
	import com.data.items.tagger.Nana10GroupData;
	import com.events.ConfirmAlertEvent;
	import com.events.EditorEvent;
	import com.events.UploadImageEvent;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.Dispatcher;
	import com.fxpn.util.DisplayUtils;
	import com.fxpn.util.StringUtils;
	import com.ui.AlertBox;
	import com.ui.editors.ItemsEditor;
	import com.ui.items.Marker;
	import com.ui.items.Segment;
	
	import fl.controls.TextInput;
	import fl.events.ComponentEvent;
	
	import flash.display.Shader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	import flash.ui.MouseCursor;
	
	import gs.TweenLite;
	import gs.plugins.VolumePlugin;
	
	import resources.GroupVisuals;
	
	[Event (name="minimizeGroup", type="com.events.EditorEvent")]
	[Event (name="maximizeGroup", type="com.events.EditorEvent")]
	[Event (name="groupTweenFinished", type="com.events.EditorEvent")]
	[Event (name="groupDeleted", type="com.events.EditorEvent")]
	[Event (name="groupSaved", type="com.events.EditorEvent")]
	[Event (name="itemSelected", type="com.events.EditorEvent")]
	[Event (name="groupDuplicated", type="com.events.EditorEvent")]
	public class Group extends GroupVisuals
	{
		public static var GROUP_TWEEN_DURATION:Number = 0.3;
		public static var TOTAL_VIDEO_DURATION:Number;
		
		private var dataRepository:Nana10DataRepository;
		private var _itemsList:ItemsList;
		private var origHeight:Number;
		private var dataGridMask:Shape;
		private var _index:int;
		private var _id:int;
		public var tweenHeightDelta:Number;
		private var currentItems:Array;
		private var currentMarkers:Array;
		private var currentSegments:Array;
		private var title_orig:String;
		private var description_orig:String;
		//private var keywords_orig:String;
		private var markersContainer:Sprite;
		private var segmentsContainer:Sprite;
		private var imageUploader:ImageUploader;
		private var alertBox:AlertBox;
		
		public function Group(index:int, id:int = 0, duplication:Boolean = false)
		{
			_index = index;
			_id = id;
			dataRepository = Nana10DataRepository.getInstance();
			var groupData:Nana10GroupData = dataRepository.getGroupById(id);
			var title:String = (id > 0 || duplication) ? groupData.title : "(שם רשימת הניגון (חובה להחליף";
			if (id < 0 && !duplication)
			{
				title_txt.addEventListener(FocusEvent.FOCUS_IN,onClickTitle);
			}
			else if (id > 0)
			{
				id_txt.text = String(id);
			}
			title_orig = setTextInput(title_txt,title,"title");
			if (groupData)
			{
				description_orig = setTextInput(description_txt,groupData.description,"description");
				//keywords_orig = setTextInput(keywords_txt,groupData.keywords,"keywords");
			}
			
			_itemsList = new ItemsList(dataGrid);
			_itemsList.addEventListener(EditorEvent.ITEM_SELECTED,onItemSelected);
			_itemsList.addEventListener(EditorEvent.RESET_ITEM,onItemReset);
			_itemsList.addEventListener(EditorEvent.ITEM_SAVED,onItemSaved);
			dataGridMask = ShapeDraw.drawSimpleRect(dataGrid.width,dataGrid.height);
			dataGrid.mask = dataGridMask;
			dataGridMask.x = dataGrid.x;
			dataGridMask.y = dataGrid.y;			
			addChild(dataGridMask);
			
			segmentsContainer = new Sprite();
			addChild(segmentsContainer);
			
			markersContainer = new Sprite();
			addChild(markersContainer);
			var timelineMask:Shape = ShapeDraw.drawSimpleRect(timeline.width-2,timeline.height);
			markersContainer.mask = timelineMask;
			timelineMask.x = timeline.x + 1;
			timelineMask.y = timeline.y;
			addChild(timelineMask);
									
			if (isNaN(Segment.SAVED_SEGMENT_HEIGHT)) Segment.SAVED_SEGMENT_HEIGHT = timeline.height - 1;
			
			openCloseBtn.addEventListener(MouseEvent.CLICK,onMinMaxGroup);
			//saveBtn.addEventListener(MouseEvent.CLICK, onSave);
			segmentBtn.addEventListener(MouseEvent.CLICK, onAddSegment);
			markerBtn.addEventListener(MouseEvent.CLICK,onAddMarker);
			previewBtn.addEventListener(MouseEvent.CLICK,onPreview);
			previewBtn.enabled = false;
			duplicateBtn.addEventListener(MouseEvent.CLICK,onDuplicate);
			duplicateBtn.enabled = TaggerData.getInstance().allowSave && TaggerData.getInstance().isLive == false;
			hideCB.selected = groupData.status == 0;//false;
			hideCB.addEventListener(MouseEvent.CLICK,onToggleDissabled);
			groupOffset.updateBtn.addEventListener(MouseEvent.CLICK,onOffsetGroup);
			groupOffsetEnabled = false;
			//desktopBtn.addEventListener(MouseEvent.CLICK,onUploadImage); TEMP
			if (index == 0 && TaggerData.getInstance().allowSave)
			{
				deleteBtn.enabled = false;
				addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
			}
			else if (TaggerData.getInstance().allowSave)
			{
				deleteBtn.addEventListener(MouseEvent.CLICK, onDelete);
				groupOffset.visible = false;
			}
			else 
			{
				deleteBtn.label = "בחירה";
				deleteBtn.addEventListener(MouseEvent.CLICK,onSelect);
			}
			//if (groupData == null || StringUtils.isStringEmpty(groupData.stillImageURL))
			//{
				//removeImgBtn.mouseEnabled = removeImgBtn.enabled = displayImgBtn.mouseEnabled = displayImgBtn.enabled = false;
			/*}
			else
			{
				removeImgBtn.addEventListener(MouseEvent.CLICK,onRemoveImage);
				displayImgBtn.addEventListener(MouseEvent.CLICK,onImagePreview);
			}*/
			currentItems = [];
			currentMarkers = [];
			currentSegments = [];
			
			var tf:TextFormat = new TextFormat("Arial");
			tf.align = TextFormatAlign.RIGHT;
			title_txt.setStyle("textFormat",tf);
			description_txt.setStyle("textFormat",tf);
			//keywords_txt.setStyle("textFormat",tf);
			id_txt.setStyle("textFormat",tf);
			
			var components:Array = [title_txt,description_txt,hideCB,duplicateBtn,previewBtn,deleteBtn];
			for (var i:int = 0; i < components.length; i++)
			{
				components[i].tabIndex = i+1;
			}
		}		
		
		private function onAddedToStage(event:Event):void
		{
			groupOffset.rightOffset.selected = true;	
		}		
		
		private function setTextInput(textInput:TextInput,text:String,name:String):String
		{
			textInput.text = text;
			textInput.textField.name = name;
			textInput.addEventListener(KeyboardEvent.KEY_UP,onResetTextInput);
			textInput.addEventListener(FocusEvent.FOCUS_OUT,onTextInputFocusOut);
			return text;
		}
		
		private function onClickTitle(event:Event):void
		{
			title_txt.text = "";
			title_txt.removeEventListener(FocusEvent.FOCUS_IN,onClickTitle);
		}
		
		private function onResetTextInput(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.ESCAPE) (event.target as TextField).text = this[event.target.name+"_orig"];
		}
		
		private function onTextInputFocusOut(event:FocusEvent):void
		{
			if (_id)
			{
				var groupData:Nana10GroupData = dataRepository.getGroupById(_id); 
				groupData[event.target.name] = this[event.target.name + "_orig"] = event.currentTarget.text;
			}
		}
		
		private function onOffsetGroup(event:MouseEvent):void
		{
			var offset:Number = groupOffset.milsStpr.value/1000 + groupOffset.secsStpr.value + groupOffset.minsStpr.value*60;
			if (groupOffset.leftOffset.selected) offset*= -1;
			var totalItems:int = dataRepository.totalItems;
			var changedItems:Array = [];
			var failed:Boolean;
			for (var i:int = 0; i < totalItems; i++)
			{
				var itemData:Nana10MarkerData = dataRepository.getItemByIndex(i);
				if (itemData.belongsToGroup(_id))
				{
					itemData.timeCode+= offset;
					if (itemData is Nana10SegmentData) (itemData as Nana10SegmentData).endTimecode+= offset;
					changedItems.push(itemData);
					if (itemData.timeCode < 0 || (itemData.type == Nana10ItemData.SEGMENT && (itemData as Nana10SegmentData).endTimecode > TOTAL_VIDEO_DURATION))
					{
						failed = true;
						break;
					}
				}
			}
			if (failed)
			{
				for (var j:int = 0; j < changedItems.length; j++)
				{
					changedItems[j].timeCode-= offset;
					if (changedItems[j] is Nana10SegmentData) changedItems[j].endTimecode-= offset;
				}
				if (alertBox == null)
				{
					alertBox = new AlertBox(stage);
				}
				alertBox.displayAlert("לא ניתן לבצע את השינוי - אחד המקטעים יחרוג מגבולות הקליפ");
			}
			else
			{
				_itemsList.updateList();
				var editorEvent:EditorEvent = new EditorEvent(EditorEvent.GROUP_OFFSET,true);
				editorEvent.offset = offset;
				dispatchEvent(editorEvent);
			}
		}
		
		private function onMinMaxGroup(event:MouseEvent):void
		{
			if (openCloseBtn.rotation == 0)
			{
				tweenHeightDelta = origHeight - (dataGrid.y - 2);
				TweenLite.to(openCloseBtn,GROUP_TWEEN_DURATION,{rotation: 180,onComplete: rotationFinised});
				TweenLite.to(bg,GROUP_TWEEN_DURATION,{height: dataGrid.y - 2});
				TweenLite.to(dataGridMask,GROUP_TWEEN_DURATION,{height: 0});
				dispatchEvent(new EditorEvent(EditorEvent.GROUP_MINIMIZED));				
			}
			else
			{
				tweenHeightDelta = origHeight - bg.height;
				TweenLite.to(openCloseBtn,GROUP_TWEEN_DURATION,{rotation: 0,onComplete: rotationFinised});
				TweenLite.to(bg,GROUP_TWEEN_DURATION,{height: origHeight});
				TweenLite.to(dataGridMask,GROUP_TWEEN_DURATION,{height: dataGrid.height});
				dispatchEvent(new EditorEvent(EditorEvent.GROUP_MAXIMIZED));
			}
			openCloseBtn.mouseEnabled = false;
		}
		
		private function rotationFinised():void
		{
			openCloseBtn.mouseEnabled = true;
			dispatchEvent(new EditorEvent(EditorEvent.GROUP_TWEEN_FINISHED));
		}
		
		private function addItemToTimeline(item:Nana10MarkerData):void
		{
			if (item.type == Nana10ItemData.MARKER)
			{
				var marker:Marker = new Marker();
				marker.x = timeline.x + timeline.width * item.timeCode / TOTAL_VIDEO_DURATION;
				marker.y = timeline.y + 1;
				marker.height = timeline.height - 3;
				marker.id = item.id;
				if (item.markerType) DisplayUtils.setTintColor(marker,0x999999);
				markersContainer.addChild(marker);
				currentMarkers.push(marker);
			}
			else
			{
				var segmentData:Nana10SegmentData = item as Nana10SegmentData; 
				//var color:int = segmentData.color;
				var segment:Segment = new Segment(segmentData.color);
				segment.x = timeline.x + timeline.width * segmentData.timeCode / TOTAL_VIDEO_DURATION;
				segment.y = timeline.y;
				segment.width = timeline.width * (segmentData.endTimecode - segmentData.timeCode) / TOTAL_VIDEO_DURATION;
				segment.id = item.id;				
				segmentsContainer.addChild(segment);
				currentSegments.push(segment);
				previewBtn.enabled = true;
			}
			groupOffsetEnabled = true;
		}
		
		private function updateItemOnTimeline(item:Nana10MarkerData):void
		{
			if (item.type == Nana10ItemData.MARKER)
			{
				for (var i:int = 0; i < currentMarkers.length; i++)
				{
					if (currentMarkers[i].id == item.id)
					{
						currentMarkers[i].x = timeline.x + timeline.width * item.timeCode / TOTAL_VIDEO_DURATION;
						break;
					}
				}
			}
			else
			{	
				var segmentData:Nana10SegmentData = item as Nana10SegmentData;
				for (var j:int = 0; j < currentSegments.length; j++)
				{
					if (currentSegments[j].id == item.id)
					{
						currentSegments[j].x = timeline.x + timeline.width * segmentData.timeCode / TOTAL_VIDEO_DURATION;
						currentSegments[j].width = timeline.width * (segmentData.endTimecode - segmentData.timeCode) / TOTAL_VIDEO_DURATION;
						break;
					}
				}
			}
		}
				
		private function onSave(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.GROUP_SAVED));
		}
		
		private function onDelete(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.GROUP_DELETED));	
		}
		
		private function onAddMarker(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.MARKER_ADDED,true));	
		}
		
		private function onAddSegment(event:MouseEvent):void
		{
			if (title_txt.text == "(שם רשימת הניגון (חובה להחליף")
			{
				if (alertBox == null)
				{
					alertBox = new AlertBox(stage);
				}
				alertBox.displayAlert("יש לתת שם לקבוצה לפני הוספת מקטע חדש");
				return;
			}
			dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_ADDED,true));
		}
		
		private function onPreview(event:MouseEvent):void
		{
			var editorEvent:EditorEvent = new EditorEvent(EditorEvent.PREVIEW_START,true);
			editorEvent.groupID = _id;
			dispatchEvent(editorEvent);
		}
		
		private function onDuplicate(event:MouseEvent):void
		{
			var editorEvent:EditorEvent = new EditorEvent(EditorEvent.GROUP_DUPLICATED);
			editorEvent.groupID = _id;
			dispatchEvent(editorEvent);
		}
		
		private function onSelect(event:MouseEvent):void
		{
			ExternalInterface.call("selectGroup",_id);
		}
			
		private function onToggleDissabled(event:MouseEvent):void
		{
			var groupData:Nana10GroupData = dataRepository.getGroupById(_id);
			groupData.status = hideCB.selected ? 0 : 1;
			// in live stream the default item isn't accessible, so chaning the group's status also reflects on the item
			if (TaggerData.getInstance().isLive) dataRepository.getItemByIndex(0).status = groupData.status;
		}			
		
		private function onUploadImage(event:MouseEvent):void
		{
			if (imageUploader == null)
			{
				var serverURL:String = (stage.loaderInfo.url.indexOf("localhost") == -1) ? stage.loaderInfo.parameters.WSURL : "http://localhost:4027/WS/Tagger/Method.asmx";
				imageUploader = new ImageUploader(serverURL);
				imageUploader.addEventListener(UploadImageEvent.UPLOAD_SUCCESSFUL,onImageUploaded);
				imageUploader.addEventListener(UploadImageEvent.UPLOAD_FAILED,onImageUploadFailed);
				imageUploader.addEventListener(UploadImageEvent.UPLOADING_IMAGE,onUploadingImage);
			}
			imageUploader.select();
		}
		
		private function onUploadingImage(event:UploadImageEvent):void
		{
			if (alertBox == null)
			{
				alertBox = new AlertBox(stage);
			}
			alertBox.displayAlert("מעלה תמונה",true);
		}
		
		private function onImageUploaded(event:UploadImageEvent):void
		{
			alertBox.displayAlert("התמונה עלתה בהצלחה");
			dataRepository.getGroupById(_id).stillImageURL = loaderInfo.parameters.uploadsPath + event.filePath;
		}
		
		private function onImageUploadFailed(event:UploadImageEvent):void
		{
			alertBox.displayAlert(event.errorMessage);
		}
		
		private function onRemoveImage(event:MouseEvent):void
		{
			dataRepository.getGroupById(_id).stillImageURL == "";
		}
		
		private function onImagePreview(event:MouseEvent):void
		{
			var editorEvent:EditorEvent = new EditorEvent(EditorEvent.PREVIEW_START,true);
			editorEvent.stillImage = true;
			dispatchEvent(editorEvent);
		}
		
		private function onItemSelected(event:EditorEvent):void
		{
			dispatchEvent(event);
		}
		
		private function onItemReset(event:EditorEvent):void
		{
			dispatchEvent(event);
		}
		
		private function onItemSaved(event:EditorEvent):void
		{
			dispatchEvent(event);
		}
		
		private function set groupOffsetEnabled(value:Boolean):void
		{
			with (groupOffset)
			{
				milsStpr.enabled = secsStpr.enabled = minsStpr.enabled = leftOffset.enabled = rightOffset.enabled = updateBtn.enabled = value;
			}
		}
		
		public function addItem(item:Nana10MarkerData, isDefault:Boolean = false, selected: Boolean = false):void
		{
			if (currentItems.indexOf(item.id) == -1)
			{
				_itemsList.addItem(item,isDefault);
				if (selected) _itemsList.selectItem(item.id);
				/*if (!isDefault)*/ addItemToTimeline(item);			
				currentItems.push(item.id);
			}
			else
			{
				updateList();
				updateItemOnTimeline(item);
			}
		}
		
		public function updateList():void
		{
			_itemsList.updateList();
		}
		
		public function updateNewItem(origItemID:int,newItemID:int):void
		{
			for (var i:int = 0; i < currentItems.length; i++)
			{
				if (currentItems[i] == origItemID)
				{
					currentItems[i] = newItemID;
					break;
				}
			}
		}
		
		public function selectItem(id:int):void
		{
			_itemsList.selectItem(id);
		}
		
		public function deleteItem():void
		{
			//var deletedItemID:int = _itemsList.deleteItem();
			var deletedItem:Nana10MarkerData = _itemsList.deleteItem();//Nana10DataRepository.getInstance().getItemById(deletedItemID);
			if (deletedItem == null) return;
			if (deletedItem.type == Nana10ItemData.MARKER)
			{
				for (var i:int = 0; i < markersContainer.numChildren; i++)
				{
					if ((markersContainer.getChildAt(i) as Marker).id == deletedItem.id)
					{
						markersContainer.removeChildAt(i);
						currentMarkers.splice(currentMarkers.indexOf(deletedItem.id),1);
						break;
					}
				}
			}
			else if (deletedItem.type == Nana10ItemData.SEGMENT)
			{
				for (var j:int = 0; j < segmentsContainer.numChildren; j++)
				{
					if ((segmentsContainer.getChildAt(j) as Segment).id == deletedItem.id)
					{
						segmentsContainer.removeChildAt(j);
						currentSegments.splice(currentSegments.indexOf(deletedItem.id),1);
						break;
					}
				}
				previewBtn.enabled = currentSegments.length > 0;
			}
				
			/*for (var i:int = 0; i < numChildren; i++)
			{
				if (getChildAt(i) is Marker)
				{
					var marker:Marker = getChildAt(i) as Marker;
					if (marker.id == deletedItemID)
					{
						removeChild(marker);
						currentMarkers.splice(currentMarkers.indexOf(deletedItemID),1);
						break;
					}
				}
				else if (getChildAt(i) is Segment)
				{
					var segment:Segment = getChildAt(i) as Segment;
					if (segment.id == deletedItemID)
					{
						removeChild(segment);
						currentSegments.splice(currentSegments.indexOf(deletedItemID),1);
						break;
					}
				}
			}*/
			currentItems.splice(currentItems.indexOf(deletedItem.id),1);
			groupOffsetEnabled = currentItems.length > 0;
		}
		
		public function clearSelection():void
		{
			_itemsList.clearSelection();
			bg.gotoAndStop("off");
		}
		
		public function select():void
		{
			bg.gotoAndStop("on");
		}
		
		public function setSize(w:Number, h:Number):void
		{
			bg.width = w;
			bg.height = h;
			//openCloseBtn.x = w - openCloseBtn.width - 10;
			//deleteBtn.x = openCloseBtn.x - deleteBtn.width - 10;
			//previewBtn.x = deleteBtn.x - previewBtn.width - 5;
			DisplayUtils.spacialAlign(bg,headline_txt,DisplayUtils.RIGHT,10);
			//title_txt.x = headline_txt.x - title_txt.width - 5;
			//id_label.x = title_txt.x - 10 - id_label.width;
			//id_txt.x = id_label.x - 5 - id_txt.width;
			description_txt.width = (w - 40 - headline_txt.width)/2;
			description_txt.x = id_txt.x = headline_txt.x - description_txt.width - 5;
			id_label.x = id_txt.x + id_txt.width + 10;
			title_txt.x = id_label.x + id_label.width + 30;
			title_txt.width = headline_txt.x - title_txt.x - 10;
			//keywods_label.x = description_txt.x - keywods_label.width - 10;
			//keywords_txt.x = keywods_label.x - keywords_txt.width - 5;
			
			timeline.width = w - 2*timeline.x;
			markersContainer.mask.width = timeline.width - 2;
						
			dataGrid.width = dataGridMask.width = w - 2*dataGrid.x;
			dataGrid.height = dataGridMask.height = h - dataGrid.y - dataGrid.x;
			
			if (isNaN(origHeight)) origHeight = h;
		}
		
		override public function get height():Number
		{
			return bg.height;
		}

		public function get index():int
		{
			return _index;
		}
		
		public function set index(value:int):void
		{
			_index = value;
		}

		public function get id():int
		{
			return _id;
		}

		public function set id(value:int):void
		{
			_id =  value;
			id_txt.text = String(value);
		}
		
		public function get selectedItem():int
		{
			return _itemsList.selectedItem;
		}
	}
}