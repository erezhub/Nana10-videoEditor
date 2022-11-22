package com.data
{
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.Nana10SegmentData;
	import com.fxpn.util.Debugging;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class DefaultPlaylistLoader extends EventDispatcher
	{
		private var dataRepository:Nana10DataRepository;
		private var _groupID:int;
		
		public function DefaultPlaylistLoader(groupID:int)
		{
			dataRepository = Nana10DataRepository.getInstance();
			_groupID = groupID;
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE,onDefaultPlaylistReady);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR,onDataError);
			urlLoader.load(new URLRequest(dataRepository.defaultPlaylistURL+"&curretype=1"));
		}
		
		private function onDataError(event:IOErrorEvent):void
		{
			trace(event.text);
			Debugging.alert("Error loading data");
		}
		
		private function onDefaultPlaylistReady(event:Event):void
		{
			parseData(new XML(event.target.data));
			dataRepository.getGroupByIndex(0).description = dataRepository.videoDescription;
			dataRepository.getGroupByIndex(0).keywords = dataRepository.videoKeywords;
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function parseData(input:XML):void
		{
			var entries:Array = [];
			for each (var entry:XML in input.entry)
			{
				var entryObj:Object = {};
				for each (var param:XML in entry.PARAM)
				{
					var name:String = param.@NAME;
					var value:String = param.@VALUE;
					var floatValue:Number = parseFloat(value);
					if (isNaN(floatValue) == false && floatValue.toString() == value)
					{
						entryObj[name] = floatValue;
					}
					else
					{
						entryObj[name] = value;
					}
				}
				if (entry.starttime != undefined)
				{
					entryObj.startTime = getTime(String(entry.starttime.@value));
					//entryObj.duration = getTime(String(entry.duration.@value));
					//if (entryObj.duration < duration) entryObj.duration = duration;
				}
				entries.push(entryObj);
			}
			convertData(entries);
		}
		
		public function getTime(input:String):Number
		{
			var output:Number = 0;
			var arr:Array = input.split(":");
			output+= parseInt(arr[0]) * 60 * 60;
			output+= parseInt(arr[1]) * 60;
			output+= parseFloat(arr[2]);
			
			return output;
		}
		
		private function convertData(data:Array):void
		{
			var totalEntries:int = data.length;
			var adTiming:int;
			var hasBM:Boolean;
			var entry:Object;			
			var firstEntry:Boolean = true;
			var mainEntry:Object;
			var dataRepository:Nana10DataRepository = Nana10DataRepository.getInstance();
			var lastSegmentEnd:Number;
			for (var i:int = 0; i < totalEntries; i++)
			{
				entry = data[i];
				//var videoData:Nana10VideoData = new Nana10VideoData(0,0,"");				
				var markerData:Nana10MarkerData;
				switch (String(entry.title).toLocaleLowerCase())
				{
					case "preroll":	
						var preRollTiming:Number;
						if (totalEntries > 1)
						{
							preRollTiming = data[i+1].startTime;
						}
						else
						{
							preRollTiming = 1;
						}
						markerData = new Nana10MarkerData(0,Nana10ItemData.MARKER);
						markerData.timeCode = preRollTiming;
						markerData.title = "";
						markerData.status = 1;
						markerData.addGroup(_groupID);
						dataRepository.addItem(markerData);						
						break;
					case "midroll":
						markerData = new Nana10MarkerData(0,Nana10ItemData.MARKER);
						markerData.timeCode = data[i+1].startTime;
						markerData.title = "";
						markerData.status = 1;
						markerData.addGroup(_groupID);
						dataRepository.addItem(markerData);
						break;
					case "postroll": 
						markerData = new Nana10MarkerData(0,Nana10ItemData.MARKER);
						markerData.title = "";
						markerData.status = 1;
						markerData.timeCode = isNaN(lastSegmentEnd) ? dataRepository.videoDuration : lastSegmentEnd;//(communicationLayer.videoNetDuration + communicationLayer.videoStartPoint) - 0.01;
						markerData.addGroup(_groupID);
						dataRepository.addItem(markerData);
						break;
					default:
						if (!firstEntry) continue;
						firstEntry = false;
						var segmentData:Nana10SegmentData;
						var totalItems:int = entry.BM_ITEMS;
						if (totalItems)
						{
							for (var j:int = 1; j < totalItems + 1; j++)
							{
								var segmentStartPoint:Number =  entry["BM" + j + "_POS_DURATION"];
								var segmentDuration:Number = entry["BM" + j + "_DURATION"];
								var segmentEndPoint:Number = segmentStartPoint + segmentDuration;
								segmentData = new Nana10SegmentData(0);
								segmentData.title = entry["BM" + j + "_NAME"];
								segmentData.timeCode = segmentStartPoint;
								segmentData.duration = segmentDuration;
								segmentData.endTimecode = segmentEndPoint;
								segmentData.status = 1;
								segmentData.uniqueGroup = 0;
								segmentData.addGroup(_groupID);
								dataRepository.addItem(segmentData);
								lastSegmentEnd = segmentEndPoint;
							}
						}
						else
						{
							segmentData = new Nana10SegmentData(0);
							segmentData.title = "קטע מלא";
							segmentData.timeCode = 0;
							segmentData.endTimecode = segmentData.duration = dataRepository.videoDuration;
							segmentData.status = 1;
							segmentData.addGroup(_groupID);
							dataRepository.addItem(segmentData);
						}
						break;
				}				
			}			
		}		
	}
}