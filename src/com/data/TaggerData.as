package com.data
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.ArrayUtil;
	import com.data.datas.items.ItemData;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.Nana10SegmentData;
	import com.data.items.tagger.Nana10GroupData;
	import com.events.EditorEvent;
	import com.events.RequestEvents;
	import com.fxpn.data.ArrayList;
	import com.fxpn.events.XMLLoaderEvent;
	import com.fxpn.loaders.XMLLoader;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.MathUtils;
	import com.fxpn.util.StringUtils;
	import com.io.DataRequest;
	import com.ui.editors.SavingManager;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	[Event (type="com.events.EditorEvent", name="groupSaved")]
	[Event (type="com.events.EditorEvent", name="dataSavedSuccessfully")]
	[Event (type="com.events.EditorEvent", name="dataReady")]
	[Event (type="com.events.EditorEvent", name="dataSaveError")]
	public class TaggerData extends EventDispatcher
	{
		private static var _instance:TaggerData;
		public var allowSave:Boolean;
		private var dataRepository:Nana10DataRepository;
		public var serverURL:String;
		private var _videoID:int;
		private var deletedItems:Array;
		private var deletedGroups:Array;
		private var urlRequest:URLRequest;
		private var newVideo:Boolean;
		private var _streamingPath:String;
		private var alternativeStreamingPaths:Array;
		private var currentStreamingPath:int;
		private var availableColors:Array;
		private var _isLive:Boolean;
		private var saveTimer:Timer;
		
		public function TaggerData(singletonEnforcer:SingletonEnforcer)
		{
			urlRequest = new URLRequest();
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.contentType = "application/json; charset=utf-8";	
			dataRepository = Nana10DataRepository.getInstance();
			availableColors = [0xdd0000,0x00dd00,0x0000dd,0xdddd00,0xdd00dd,0x00dddd];
			
			saveTimer = new Timer(20000,1);
			saveTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onSaveTimeout);
		}
		
		public static function getInstance():TaggerData
		{
			if (_instance == null)
			{
				_instance = new TaggerData(new SingletonEnforcer());
			}
			return _instance;
		}
		
		public function loadData(videoID:int):void
		{
			Debugging.printToConsole("--TaggerData.loadData");
			_videoID = videoID;
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE,onDataLoaded);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR,onDataError);
			//var urlRequest:URLRequest = new URLRequest(serverURL + "/Get");
			//urlRequest.method = URLRequestMethod.POST;
			//urlRequest.contentType = "application/json; charset=utf-8";
			urlRequest.url = serverURL + "/Get";
			var obj:Object = {ID: videoID};
			urlRequest.data = JSON.encode(obj);
			urlLoader.load(urlRequest);
		}
		
		private function onDataLoaded(event:Event):void
		{
			Debugging.printToConsole("--TaggerData.onDataLoaded");
			var rawData:Object = JSON.decode(event.target.data).d;
			if (rawData.ActionSucceeded == false)
			{
				Debugging.alert("Error reading data ", rawData.ErrorState);
				return;
			}
			dataRepository.parseData(rawData.Details);
			_isLive = rawData.Details.IsLive;
			deletedItems = [];
			deletedGroups = [];
			getStreamingPath();
		}
		
		private function onDataError(event:IOErrorEvent):void
		{
			Debugging.printToConsole("--TaggerData.onDataError:", event.text);
			Debugging.alert("Error loading data:\n" + event.text);
		}
		
		private function getStreamingPath():void
		{
			Debugging.printToConsole("--Taggerata.getStreamingPath");
			if (StringUtils.isStringEmpty(dataRepository.videoStreamingPath) || dataRepository.videoStreamingPathReady == false)
			{
				if (dataRepository.videoStreamingPathReady == false && StringUtils.isStringEmpty(dataRepository.videoLink) == false)
				{
					dataRepository.videoStreamingPath = dataRepository.videoLink + "&curettype=1";
					dispatchEvent(new EditorEvent(EditorEvent.STREAM_NOT_REDAY));
				}
				else
				{
					Debugging.alert("StreamingPath not available");
					return;
				}
			}
			if (dataRepository.videoStreamingPath.indexOf("rtmp://") == 0)
			{
				alternativeStreamingPaths = [dataRepository.videoStreamingPath];
				onStreamingPathReady(null);
			}
			else
			{
				alternativeStreamingPaths = [];
				var dataRequest:DataRequest = new DataRequest();
				dataRequest.addEventListener(RequestEvents.DATA_READY,onStreamingPathReady);
				dataRequest.addEventListener(RequestEvents.DATA_ERROR,onStreamingPathError);
				dataRequest.load(dataRepository.videoStreamingPath);
			}
		}
		
		private function onStreamingPathReady(event:RequestEvents):void
		{
			Debugging.printToConsole("--TaggerData.onStreamingPathReady");
			if (event)
			{
				alternativeStreamingPaths = event.textData.split(";");
			}			
			if (dataRepository.defaultPlaylistURL && dataRepository.totalItems == 0)
			{
				if (dataRepository.defaultPlaylistURL.indexOf("gmpl.aspx") > -1 || (dataRepository.defaultPlaylistURL.indexOf("gmp2.asp")>-1 && dataRepository.defaultPlaylistURL.indexOf("BMGroupID=-1")==-1))
				{
					var defaultPlaylistLoader:DefaultPlaylistLoader = new DefaultPlaylistLoader(dataRepository.getGroupByIndex(0).id);
					defaultPlaylistLoader.addEventListener(Event.COMPLETE,onDataReady);
					
					dataRepository.getGroupByIndex(0).title = dataRepository.videoTitle;
					dataRepository.getGroupByIndex(0).description = dataRepository.videoDescription;
					dataRepository.getGroupByIndex(0).status = 1;
				}
				else
				{
					Debugging.alert("לא ניתן להציג את החיתוכים בקטע\n" + dataRepository.defaultPlaylistURL);
				}
			}
			else if (dataRepository.totalItems == 0)
			{
				var groupData:Nana10GroupData;
				if (dataRepository.totalGroups == 0)
				{
					groupData = new Nana10GroupData(0,true);
					dataRepository.addGroup(groupData);
				}
				else
				{
					groupData = dataRepository.getGroupByIndex(0);
					groupData.status = 1;					
				}
				groupData.title = dataRepository.videoTitle;
				groupData.description = dataRepository.videoDescription;
				
				var segmentData:Nana10SegmentData = new Nana10SegmentData(0);
				segmentData.timeCode = 0;
				segmentData.endTimecode = dataRepository.videoDuration;
				segmentData.title = "default segment";
				segmentData.addGroup(dataRepository.getGroupByIndex(0).id);
				segmentData.uniqueGroup = Nana10ItemData.tempID;
				segmentData.status = 1;
				dataRepository.addItem(segmentData);
				
				onDataReady(null);
			}
			else				
			{
				dispatchEvent(new EditorEvent(EditorEvent.DATA_READY));
			}
		}
		
		private function onStreamingPathError(event:RequestEvents):void
		{
			Debugging.printToConsole("--TaggerData.onStreamingPathError", event.errorMessage);
			Debugging.alert("הקליפ עדיין לא מוכן לעריכה - " + dataRepository.videoStreamingPath);
		}
		
		public function get streamingPath():String
		{
			if (currentStreamingPath < alternativeStreamingPaths.length)
			{
				return alternativeStreamingPaths[currentStreamingPath++];
			}
			if (_isLive)
			{
				currentStreamingPath = 0;
				return alternativeStreamingPaths[currentStreamingPath++];
			}
			else
			{
				throw new Error("no available streaming path");
			}
		}
		
		private function onDataReady(event:Event):void
		{
			Debugging.printToConsole("--TaggerData.onDataReady");
			newVideo = true;
			canSave();
		}
				
		public function saveData():Boolean
		{
			Debugging.printToConsole("--TaggerData.saveData");
			if (SavingManager.checkChangesSaved(saveCurrentItem,dontSaveCurrentItem,cancelSaveOperation))
			{
				if (SavingManager.checkVisibleItems(canSave))
				{
					canSave();
					return true;
				}
				else
				{
					return false;
				}
			}
			return false;
		}
		
		private function saveCurrentItem():void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_SAVED));
			canSave();
		}
		
		private function dontSaveCurrentItem():void
		{
			dispatchEvent(new EditorEvent(EditorEvent.RESET_ITEM));	
			canSave();
		}
		
		private function cancelSaveOperation():void
		{
			var event:EditorEvent = new EditorEvent(EditorEvent.RESET_ITEM);
			event.cancelSave = true;
			dispatchEvent(event);
		}
		
		private function canSave():void
		{
			Debugging.printToConsole("--TaggerData.canSave");
			var output:Object = {MediaStockVideoID: _videoID};
			var groups:Array = [];
			var groupsDict:Dictionary = new Dictionary();
			var emptyGroups:ArrayList = new ArrayList();
			for (var i:int = 0; i < dataRepository.totalGroups; i++)
			{
				var groupData:Nana10GroupData = dataRepository.getGroupByIndex(i);
				if (groupData.title == null)
				{
					throw new Error("יש לתת שמות לכל הקבוצות.");
					return;
				}
				var groupObj:Object = {ID: Math.abs(groupData.id), 
										Title: groupData.title, 
										ActionType: groupData.actionType, 
										Description: groupData.description, 
										Keywords: groupData.keywords, 
										Status: groupData.status,
										SearchKeywords: groupData.title+(groupData.description.length ? ","+groupData.description : "")+(groupData.keywords.length ? ","+groupData.keywords : ""),
										StillImageURL: groupData.stillImageURL} 
				groups.push(groupObj);
				groupsDict[groupData.id] = groupObj;
				emptyGroups.push(groupData.id);
			}
			output.VideoGroups = groups;
			var items:Array = [];
			for (var j:int = 0; j < dataRepository.totalItems; j++)
			{
				var itemData:Nana10MarkerData = dataRepository.getItemByIndex(j);
				var description:String = itemData is Nana10SegmentData ? (itemData as Nana10SegmentData).description : "";
				if (description == null) description = "";				
				var itemGroups:Array = [];
				for (var k:int = 0; k < itemData.totalGroups; k++)
				{
					var groupId:int = itemData.getGroupIDByIndex(k) 
					itemGroups.push(groupId);
					if (itemData is Nana10SegmentData)
					{
						emptyGroups.removeItem(groupId);
						updateGroupsKeywords(groupsDict[groupId],itemData.title);
						updateGroupsKeywords(groupsDict[groupId],description);
					}
				}
				var uniqueGroup:int = 0;
				if (itemData is Nana10SegmentData)
				{
					uniqueGroup = (itemData as Nana10SegmentData).uniqueGroup;
					if (uniqueGroup < 0) uniqueGroup*=-1;
				}
				
				var color:int;
				if (itemData is Nana10SegmentData)
				{
					if ((itemData as Nana10SegmentData).color)
					{
						color = (itemData as Nana10SegmentData).color;
					}
					else
					{
						color = (itemData as Nana10SegmentData).color = getSegmentColor();
					}
				}
				items.push({ID: itemData.id > 0 ? itemData.id : itemData.id * -1, 
							Title: itemData.title, 
							Type: itemData.type,
							TimeCode: itemData.timeCode, 
							EndTimeCode: itemData is Nana10SegmentData ? (itemData as Nana10SegmentData).endTimecode : itemData.timeCode,
							Description: description,
							SearchKeywords: itemData.title+","+description, 
							Status: itemData.status, 
							Groups: itemGroups.toString(),
							ActionType: itemData.actionType,
							UniqueGroup: uniqueGroup,
							Color: itemData is Nana10SegmentData ? color : 0,
							IsBookmarkItem: itemData.markerType
							});	
			}
			if (emptyGroups.length && newVideo == false)
			{
				throw new Error("לא ניתן לשמור קבוצה ריקה.");
				return;
			}
			output.VideoItems = items;
			output.DeletedItems = deletedItems.length ? deletedItems.toString() : " ";
			output.DeletedGroups = deletedGroups.length ? deletedGroups.toString() : " ";
			Debugging.printToConsole("output:",JSON.encode(output));
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE,onDataSaved);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR,onSaveError);
			urlRequest.url = serverURL + "/Save";
			urlRequest.data = JSON.encode({_MSVideo: output});
			urlLoader.load(urlRequest);
			deletedItems = [];
			deletedGroups = [];
			saveTimer.start();
		}
		
		private function onDataSaved(event:Event):void
		{
			Debugging.printToConsole("--TaggerData.onDataSaved");
			var rawData:Object = JSON.decode(event.target.data).d;
			if (rawData.ActionSucceeded == false)
			{
				Debugging.printToConsole("save error. error state: " + rawData.ErrorState);				
				if (newVideo == false) dispatchEvent(new EditorEvent(EditorEvent.DATA_SAVE_ERROR));				
			}
			else
			{				
				updateSavedData(rawData.Details);
				if (newVideo == false) dispatchEvent(new EditorEvent(EditorEvent.DATA_SAVED_SUCCESSFULLY));
			}
			if (newVideo)
			{
				newVideo = false;
				dispatchEvent(new EditorEvent(EditorEvent.DATA_READY));
			}
			saveTimer.stop();
		}
		
		private function updateSavedData(insertedData:Object):void
		{
			Debugging.printToConsole("--TaggerData.updateSavedData");
			if (insertedData.InsertedGroups.length)
			{
				for each (var insertedGroup:Object in insertedData.InsertedGroups)
				{
					Debugging.printToConsole("new group",insertedGroup.OrigId, insertedGroup.NewID);
					var groupData:Nana10GroupData = dataRepository.getGroupById(insertedGroup.OrigId * -1);
					var editorEvent:EditorEvent = new EditorEvent(EditorEvent.GROUP_SAVED);
					editorEvent.groupID = insertedGroup.NewID
					editorEvent.origGroupID = groupData.id;
					dispatchEvent(editorEvent);
					groupData.id = insertedGroup.NewID;
					for (var i:int = 0; i < dataRepository.totalItems; i++)
					{
						var itemData:Nana10MarkerData = dataRepository.getItemByIndex(i);
						if (itemData.belongsToGroup(insertedGroup.OrigId * -1))
						{
							itemData.removeFromGroup(insertedGroup.OrigId * -1);
							itemData.addGroup(insertedGroup.NewID);
						}
					}
				}
			}
			if (insertedData.InsertedItems.length)
			{
				for each (var insertedItem:Object in insertedData.InsertedItems)
				{
					Debugging.printToConsole("new item",insertedItem.OrigId, insertedItem.NewID,insertedItem.UniqueGroupID);
					var newItemData:Nana10MarkerData = dataRepository.getItemById(insertedItem.OrigId * -1);
					var itemSavedEvent:EditorEvent = new EditorEvent(EditorEvent.NEW_ITEM_SAVED);
					itemSavedEvent.itemID = insertedItem.NewID;
					if (newItemData is Nana10SegmentData)
					{
						itemSavedEvent.groupID = (newItemData as Nana10SegmentData).uniqueGroup = insertedItem.UniqueGroupID;
						itemSavedEvent.itemType = Nana10ItemData.SEGMENT;
					}
					itemSavedEvent.origItemId = insertedItem.OrigId * -1;
					dispatchEvent(itemSavedEvent);
					newItemData.id = insertedItem.NewID;
				}
			}
		}
		
		private function onSaveError(event:IOErrorEvent):void
		{	
			Debugging.printToConsole("--TaggerData.onSaveError");
			Debugging.printToConsole(event.text);
			dispatchEvent(new EditorEvent(EditorEvent.DATA_SAVE_ERROR));
			saveTimer.stop();
		}
		
		private function onSaveTimeout(event:TimerEvent):void
		{
			Debugging.printToConsole("--TaggerData.onSaveTimeout");
			dispatchEvent(new EditorEvent(EditorEvent.DATA_SAVE_ERROR));
		}
		
		private function updateGroupsKeywords(groupObj:Object, keyword:String):void
		{
			if (groupObj.SearchKeywords.indexOf(keyword) == -1)
			{
				groupObj.SearchKeywords+="," + keyword;
				if (groupObj.ActionType == Nana10ItemData.ACTIONTYPE_NONE)
					groupObj.ActionType = Nana10ItemData.ACTIONTYPE_UPDATED; 
			}
		}
		
		public function itemDeleted(id:int):void
		{
			Debugging.printToConsole("--TaggerData.itemDeleted");				
			if (id > 0) deletedItems.push(id);
			dataRepository.removeItemById(id);
		}
		
		public function groupDeleted(id:int):void
		{
			Debugging.printToConsole("--TaggerData.groupDeleted");
			if (id > 0) deletedGroups.push(id);
			for (var i:int = 0; i < dataRepository.totalItems; i++)
			{
				var itemData:Nana10MarkerData = dataRepository.getItemByIndex(i);
				if (itemData.belongsToGroup(id))
				{
					if (itemData.totalGroups > 1)
					{
						itemData.removeFromGroup(id);
					}
					else
					{
						itemDeleted(itemData.id);
					}
				}
			}
			dataRepository.removeGroup(id);
		}
		
		public function checkSegmentsOverlap(currentItemId:int, currentGroupID:int, startTime:Number,endTime:Number):Boolean
		{
			var overlap:Boolean;
			var totalItems:int = dataRepository.totalItems;
			for (var i:int = 0; i < totalItems; i++)
			{
				var currentItem:Nana10MarkerData = dataRepository.getItemByIndex(i); 
				if (currentItem.type == Nana10ItemData.SEGMENT && currentItem.id != currentItemId && currentItem.belongsToGroup(currentGroupID))
				{
					var currentItemStartTime:Number = currentItem.timeCode;
					var currentItemEndTime:Number = (currentItem as Nana10SegmentData).endTimecode;
					if (startTime > currentItemEndTime || endTime < currentItemStartTime)
					{
						continue;
					}
					else
					{
						overlap = true;
						break;
					}
				}
			}
			return overlap;
		}
		
		public function getSegmentColor():int
		{
			var color:int;			
			if (availableColors.length)
			{
				var colorIndex:int = MathUtils.randomInteger(0,availableColors.length - 1);
				color = availableColors[colorIndex];	
				availableColors.splice(colorIndex,1);
			}
			else
			{
				color = MathUtils.randomInteger(1000,0xdddddd);
			}
			return color;
		}
		
		public function updateAvailableColors(colorToRemove:int):void
		{
			if (availableColors.indexOf(colorToRemove) > -1)
				ArrayUtil.removeValueFromArray(availableColors,colorToRemove);
		}

		public function get isLive():Boolean
		{
			return _isLive;
		}

	}
}

internal class SingletonEnforcer{}