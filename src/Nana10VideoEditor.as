package
{
	import com.data.Nana10DataRepository;
	import com.data.TaggerData;
	import com.data.TaggerVersion;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.Nana10SegmentData;
	import com.data.items.tagger.Nana10GroupData;
	import com.demonsters.debugger.MonsterDebugger;
	import com.events.EditorEvent;
	import com.events.VideoControlsEvent;
	import com.events.VideoPlayerEvent;
	import com.fxpn.display.ModalManager;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.ContextMenuCreator;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.DisplayUtils;
	import com.fxpn.util.FPS;
	import com.fxpn.util.MathUtils;
	import com.ui.AlertBox;
	import com.ui.MediandVideoPlayer;
	import com.ui.TaggerControls;
	import com.ui.VideoControls;
	import com.ui.VideoTimeline;
	import com.ui.editors.ItemsEditor;
	import com.ui.editors.SegmentsEditor;
	import com.ui.groups.Group;
	import com.ui.groups.GroupContainer;
	import com.ui.groups.ItemsList;
	import com.ui.groups.PreviewContainer;
	import com.ui.items.Segment;
	
	import fl.controls.Button;
	import fl.controls.DataGrid;
	import fl.controls.dataGridClasses.DataGridColumn;
	import fl.data.DataProvider;
	
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import gs.plugins.VolumePlugin;
	
	import resources.LoadingAnimation;
		
	//[SWF (backgroundColor=0xffffff, width=1000, height=800)]
	public class Nana10VideoEditor extends Sprite
	{
		private var dataRepository:Nana10DataRepository;
		private var taggerData:TaggerData;
		
		private var videoPlayer:MediandVideoPlayer;
		private var videoControls:com.ui.VideoControls;
		private var timeline:VideoTimeline;
		private var taggerControls:TaggerControls;
		private var itemsEditor:ItemsEditor;
		private var groupsContainer:GroupContainer;
		private var saveBtn:Button;
		private var alertBox:AlertBox;
		private var previewContainer:PreviewContainer;
		private var loadingAnimation:LoadingAnimation;
		
		private var progressTimer:Timer;
		private var previewTimer:Timer;
		private var previewEndTime:Number;
		private var videoPaused:Boolean = true;
		private var videoFrame:Number;
		private var previousSkip:Number = 0;
		private var availableColors:Array;
		private var strobingTimer:Timer;
		private var displaySavingMessage:Boolean;
		private var videoFile:String;
		private var afterSeek:Boolean;
		private var currentStartPoint:Number;
		
		private var videoId:int;
		
		public function Nana10VideoEditor()
		{
			Debugging.printToConsole("--Nana10VideoEditor");
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.ENTER_FRAME,onEnterFrame);
			dataRepository = Nana10DataRepository.getInstance();			
			
			progressTimer = new Timer(100);
			progressTimer.addEventListener(TimerEvent.TIMER, onProgress);	
			availableColors = [0xdd0000,0x00dd00,0x0000dd,0xdddd00,0xdd00dd,0x00dddd];
			currentStartPoint = 0;
			
			taggerData = TaggerData.getInstance();
			taggerData.addEventListener(EditorEvent.RESET_ITEM,onItemReset);
			taggerData.addEventListener(EditorEvent.ITEM_SAVED,onItemSaved);
			taggerData.addEventListener(EditorEvent.NEW_ITEM_SAVED, onNewItemSaved);
			taggerData.addEventListener(EditorEvent.DATA_SAVED_SUCCESSFULLY,onDataSaved);
			taggerData.addEventListener(EditorEvent.DATA_SAVE_ERROR,onDataSaveError);
			taggerData.addEventListener(EditorEvent.STREAM_NOT_REDAY,onStreamNotReady);
			taggerData.allowSave = (stage.loaderInfo.parameters.selectOnly != "1");
			
			contextMenu = ContextMenuCreator.setContextMenu("Nana10 Video Tagger V " + TaggerVersion.VERSION);
			var openLog:ContextMenuItem = new ContextMenuItem("Open log");
			openLog.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,onOpenLog);
			contextMenu.customItems.push(openLog);
			
			Security.allowDomain("*");
		}
		
		private function onOpenLog(event:ContextMenuEvent):void
		{
			Debugging.onScreen = true;
		}
		
		private function onAddedToStage(event:Event):void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			// adding debugging console above the stage          
			Debugging.setOnScreenDisplay(stage);
			Debugging.onScreen = false;			
		}
		
		private function onEnterFrame(event:Event):void
		{
			var frame:Shape = ShapeDraw.drawSimpleRectWithFrame(stage.stageWidth-2,stage.stageHeight-2,0,0,1,0,1,"none",5);
			frame.x = frame.y = 1;
			addChild(frame);
			
			var playerWidth:Number = Math.min(stage.stageWidth - ItemsEditor.MINIMUM_WIDTH - 20,480);
			var playerHeight:Number = playerWidth * 0.75;
			videoPlayer = new MediandVideoPlayer(playerWidth,playerHeight,true,true,-1,true,true);
			//videoPlayer.pausedAtStart = true;
			videoPlayer.addEventListener(VideoPlayerEvent.VIDEO_DATA_READY, onVideoDataReady);
			videoPlayer.addEventListener(VideoPlayerEvent.FAILED,onVideoError);
			videoPlayer.addEventListener(VideoPlayerEvent.NOT_FOUND,onVideoError);
			videoPlayer.addEventListener(VideoPlayerEvent.BUFFER_FULL,onVideoReady);
			videoPlayer.addEventListener(VideoPlayerEvent.START,onVideoReady);
			videoPlayer.x = videoPlayer.y = 5;
			addChild(videoPlayer);
			
			videoControls = new VideoControls(true);
			videoControls.addEventListener(VideoControlsEvent.PLAY, onPlay);
			videoControls.addEventListener(VideoControlsEvent.PAUSE, onPause);
			videoControls.addEventListener(VideoControlsEvent.MUTE, onMute);
			videoControls.addEventListener(VideoControlsEvent.UNMUTE, onUnMute);
			videoControls.addEventListener(VideoControlsEvent.CHANGE_VOLUME,onChangeVolume);
			videoControls.addEventListener(VideoControlsEvent.FWD, onFwd);
			videoControls.addEventListener(VideoControlsEvent.RWD, onRwd);
			addChild(videoControls);
			videoControls.y = videoPlayer.y + videoPlayer.height;
			videoControls.x = videoPlayer.x;
			videoControls.width = videoPlayer.width;
			
			timeline = new VideoTimeline(30);
			timeline.addEventListener(VideoControlsEvent.PAUSE, onPause);
			timeline.addEventListener(VideoControlsEvent.PLAYHEAD_MOVED, onPlayheadMoved);
			timeline.addEventListener(VideoPlayerEvent.PLAYHEAD_RELEASED, onPlayheadReleased);
			timeline.addEventListener(EditorEvent.SEGMENT_MOVED, onSegmentUpdated);
			timeline.addEventListener(EditorEvent.SEGMENT_RESIZED, onSegmentUpdated);
			timeline.addEventListener(EditorEvent.MARKER_MOVED, onMarkerMoved);
			timeline.addEventListener(EditorEvent.ITEM_SELECTED, onItemSelected);
			timeline.addEventListener(EditorEvent.ITEM_SAVED,onItemSaved);
			timeline.addEventListener(EditorEvent.RESET_ITEM,onItemReset);
			timeline.y = videoControls.y + videoControls.height + 10;
			timeline.x = videoPlayer.x;
			timeline.width = stage.stageWidth - timeline.x*2;
			addChild(timeline);	
			Segment.ACTIVE_SEGMENT_HEIGHT = timeline.height - 2;
			
			itemsEditor = new ItemsEditor();
			itemsEditor.addEventListener(VideoControlsEvent.PAUSE,onPause);
			itemsEditor.addEventListener(EditorEvent.ITEM_ADDED,onItemAdded);
			itemsEditor.addEventListener(EditorEvent.SEGMENT_EDITED, onSegmentEdited);
			itemsEditor.addEventListener(EditorEvent.SEGMENT_RESIZED, onSegmentResizedToPlayhead);
			itemsEditor.addEventListener(EditorEvent.MARKER_EDITED,onMarkerEdited);
			itemsEditor.addEventListener(EditorEvent.MARKER_MOVED,onMarkerMovedToPlayhead);
			itemsEditor.addEventListener(EditorEvent.ITEM_SAVED,onItemSaved);
			//itemsEditor.addEventListener(EditorEvent.SEGMENT_BLACKHOLE, onSegmentBlackholeToggle);
			itemsEditor.addEventListener(EditorEvent.ITEM_DISABLED,onItemDissabled);
			itemsEditor.addEventListener(EditorEvent.RESET_ITEM,onItemReset);
			itemsEditor.addEventListener(EditorEvent.ITEM_DELETED,onItemDeleted);
			itemsEditor.addEventListener(EditorEvent.PREVIEW_START,onStartPreview);
			itemsEditor.addEventListener(EditorEvent.PREVIEW_END,onEndPreview);
			itemsEditor.addEventListener(EditorEvent.ADD_SEGMENT_MARKER,onAddSegmentMarker);
			itemsEditor.x = videoPlayer.x + videoPlayer.width + 10;
			itemsEditor.y = 5 + videoControls.height;
			itemsEditor.setSize(timeline.width - itemsEditor.x - 7,videoPlayer.height  - 1);
			addChild(itemsEditor);
			
			taggerControls = new TaggerControls();
			taggerControls.x = itemsEditor.x;//timeline.x + 10;
			taggerControls.y = 10;//timeline.y + timeline.height + 15;
			taggerControls.width = itemsEditor.width;
			taggerControls.addEventListener(EditorEvent.MAIN_SAVE,onSave);
			taggerControls.addEventListener(EditorEvent.GROUP_ADDED,onAddNewGroup);			
			addChild(taggerControls);
						
			groupsContainer = new GroupContainer();
			groupsContainer.addEventListener(EditorEvent.GROUP_SELECTED,onGroupSelected);
			groupsContainer.addEventListener(EditorEvent.ITEM_SELECTED, onItemSelected);
			groupsContainer.addEventListener(EditorEvent.RESET_ITEM,onItemReset);
			groupsContainer.addEventListener(EditorEvent.ITEM_SAVED,onItemSaved);
			groupsContainer.addEventListener(EditorEvent.PREVIEW_START,onStartPreview);
			groupsContainer.addEventListener(EditorEvent.GROUP_OFFSET,onGroupOffset);
			groupsContainer.addEventListener(EditorEvent.MARKER_ADDED,onAddNewMarker);
			groupsContainer.addEventListener(EditorEvent.SEGMENT_ADDED,onAddNewSegment);
			groupsContainer.x = videoPlayer.x;
			groupsContainer.y = timeline.y + timeline.height + 15;//taggerControls.y + taggerControls.height + 15;			
			addChild(groupsContainer);
			
			loadingAnimation = new LoadingAnimation();
			addChild(loadingAnimation);
			DisplayUtils.align(stage,loadingAnimation);
						
			videoId = parseInt(stage.loaderInfo.parameters.videoId);
			removeEventListener(Event.ENTER_FRAME,onEnterFrame);
			var serverURL:String = (stage.loaderInfo.url.indexOf("localhost") == -1) ? stage.loaderInfo.parameters.WSURL : "http://localhost:4027/WS/Tagger/Method.asmx";
			taggerData.serverURL = serverURL;
			taggerData.loadData(videoId);
			taggerData.addEventListener(EditorEvent.DATA_READY,onDataReady);
			taggerData.addEventListener(EditorEvent.GROUP_SAVED,onGroupSaved);
			
			mouseChildren = false;
		}
		
		private function onDataReady(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onDataReady");
			if (taggerData.isLive)
			{
				mouseChildren = true;
				taggerControls.mouseChildren = timeline.mouseChildren = false;
				loadingAnimation.visible = false;
			}
			else
			{
				try
				{
					videoPlayer.source = videoFile = taggerData.streamingPath;//dataRepository.videoStreamingPath;
				}
				catch (e:Error)
				{
					onVideoError(null);
					return;
				}
			}
			addGroups();
			videoControls.setSeekButtons();
		}
		
		private function onVideoDataReady(event:VideoPlayerEvent):void
		{
			if (afterSeek)
			{
				afterSeek = false;
				currentStartPoint = Group.TOTAL_VIDEO_DURATION - videoPlayer.duration;
				if (!videoPaused) onPlay(null);				
				return;
			}
			Debugging.printToConsole("--Nana10VideoEditor.onVideoDataReady");
			videoControls.totalTime = itemsEditor.endTime = Group.TOTAL_VIDEO_DURATION = videoPlayer.duration;
			// videoFrame is the % of video's length in one frame
			videoFrame = Math.max(1/(videoPlayer.fps),0.05);//*videoPlayer.duration);
			//progressTimer.start();			
			addItems();
			groupsContainer.selectGroupByIndex(0);
			//itemsEditor.currentGroup = groupsContainer.currentGroupID;
			mouseChildren = true;	
			loadingAnimation.visible = false;
		}
		
		private function onVideoReady(event:VideoPlayerEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onVideoReady");
			loadingAnimation.visible = false;
		}
		
		private function onVideoError(event:VideoPlayerEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onVideoError");
			try
			{
				videoPlayer.source = taggerData.streamingPath;
			}
			catch (e:Error)
			{
				Debugging.alert("שגיאה בטעינת הוידיאו");
			}
		}
		
		private function addGroups():void
		{
			var totalGroups:int = dataRepository.totalGroups;
			for (var i:int = 0; i < totalGroups; i++)
			{				
				groupsContainer.addGroup(dataRepository.getGroupByIndex(i).id);	
			}
			//groupsContainer.selectGroupByIndex(0);			
		}
		
		private function addItems():void
		{
			var totalItems:int = dataRepository.totalItems;
			for (var i:int = 0; i < totalItems; i++)
			{
				var itemData:Nana10MarkerData = dataRepository.getItemByIndex(i);
				var isDefault:Boolean = false;
				if (itemData.type == Nana10ItemData.SEGMENT)
				{
					var color:int;
					if ((itemData as Nana10SegmentData).color)
					{
						color = (itemData as Nana10SegmentData).color;
						taggerData.updateAvailableColors(color);
					}
					else
					{
						color = taggerData.getSegmentColor();
					}
					(itemData as Nana10SegmentData).color =  color; 
					//if (itemData.title == "default segment") isDefault = true;
				}
				var itemTotalGroups:int = itemData.totalGroups;
				for (var j:int = 0; j < itemTotalGroups; j++)
				{
					groupsContainer.addItem(itemData,itemData.getGroupIDByIndex(j),isDefault);
				}
				//addItemToTimeline(itemData);
			}
		}
		
		private function addItemToTimeline(itemData:Nana10MarkerData):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.addItemToTimeline");
			if (itemData.belongsToGroup(groupsContainer.currentGroupID))// && itemData.title != "default segment")
			{
				var segmentWidth:Number;
				if (itemData.type == Nana10ItemData.SEGMENT)
				{
					segmentWidth = ((itemData as Nana10SegmentData).endTimecode - itemData.timeCode)/Group.TOTAL_VIDEO_DURATION;
				}
				timeline.addExistingItem(itemData,itemData.timeCode/Group.TOTAL_VIDEO_DURATION,segmentWidth);
			}
		}
		
		private function addDefaultSegment():void
		{
			Debugging.printToConsole("--Nana10VideoEditor.addDefaultSegment");
			var item:Nana10SegmentData = new Nana10SegmentData(0)
			item.endTimecode = Group.TOTAL_VIDEO_DURATION;
			item.timeCode = 0;
			item.color = 0xffffff;
			item.title = "default segment";
			//item.dissabled = false;
			item.status = 1;
			Nana10DataRepository.getInstance().addItem(item);
			//groupsContainer.addItem(item,true);
		}		
		
		
		private function onProgress(event:Event):void
		{
			videoControls.currentTime = videoPlayer.playheadTime + currentStartPoint;
			timeline.playheadProgress = (videoPlayer.playheadTime + currentStartPoint) / Group.TOTAL_VIDEO_DURATION;
			if (event is VideoPlayerEvent) Debugging.printToConsole(videoPlayer.playheadTime + currentStartPoint);
			//previousSkip = videoPlayer.playheadTime;
		}
				
		private function onPlay(event:VideoControlsEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onPlay");
			if (taggerData.isLive)
			{
				try
				{
					videoPlayer.source = taggerData.streamingPath;
					loadingAnimation.visible = true;
				}
				catch (e:Error)
				{
					onVideoError(null);
					return;
				}
			}
			else
			{
				videoPlayer.play();
				videoPaused = false;
				progressTimer.start();
			}
		}
		
		private function onPause(event:VideoControlsEvent):void
		{		
			Debugging.printToConsole("--Nana10VideoEditor.onPause");
			if (event.target == itemsEditor)
			{	// doing this work-around to toggle the 'play/pause' button
				videoControls.pause();
				return;
			}
			if (event.target == videoControls)
			{
				videoPaused = true; //!videoPlayer.isPlaying; --> not clear why i used this instead of simply 'false'
			}			
			videoPlayer.pause();
			progressTimer.stop();
			if (taggerData.isLive == false) videoControls.currentTime = videoPlayer.playheadTime + currentStartPoint;
			//if (previewTimer && previewTimer.running) previewTimer.stop();
		}
		
		private function onMute(event:VideoControlsEvent):void
		{
			videoPlayer.mute = true;
		}
		
		private function onUnMute(event:VideoControlsEvent):void
		{
			videoPlayer.mute = false;			
		}
		
		private function onChangeVolume(event:VideoControlsEvent):void
		{
			videoPlayer.volume = event.volumeLevel;
		}
		
		private function onPlayheadMoved(event:VideoControlsEvent):void
		{
			if (dataRepository.videoStreamingPathReady || currentStartPoint == 0)
			{
				videoPlayer.playheadTime = videoControls.currentTime = timeline.playheadProgress * Group.TOTAL_VIDEO_DURATION;
				//updateVideoDisplay();
			}
			else
			{
				videoControls.currentTime = timeline.playheadProgress * Group.TOTAL_VIDEO_DURATION;
			}
		}
		
		private function onPlayheadReleased(event:VideoPlayerEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onPlayheadReleased");
			loadingAnimation.visible = true;
			if (dataRepository.videoStreamingPathReady)
			{
				updateAfterRelease(false);
			}
			else
			{
				var relativeRatio:Number = (timeline.playheadProgress - (Group.TOTAL_VIDEO_DURATION - videoPlayer.duration)/Group.TOTAL_VIDEO_DURATION)/(videoPlayer.duration/Group.TOTAL_VIDEO_DURATION); 
				if (relativeRatio > videoPlayer.howMuchLoaded || relativeRatio < 0)
				{
					videoPlayer.source = videoFile + "&start=" + Math.round(timeline.playheadProgress * Group.TOTAL_VIDEO_DURATION);
					afterSeek = true;
				}
				else if (currentStartPoint > 0)
				{
					updateAfterRelease(true,relativeRatio);
				}
				else
				{
					updateAfterRelease(false);
				}
			}
		}
		
		private function updateAfterRelease(progressiveDownload:Boolean, relativeRatio:Number = NaN):void
		{
			if (progressiveDownload)
			{
				videoPlayer.playheadTime = relativeRatio * videoPlayer.duration;
				videoControls.currentTime = timeline.playheadProgress * Group.TOTAL_VIDEO_DURATION;
			}
			else
			{
				videoPlayer.playheadTime = videoControls.currentTime = timeline.playheadProgress * Group.TOTAL_VIDEO_DURATION;
			}
			if (!videoPaused && videoPlayer.playheadTime < videoPlayer.duration)
			{
				onPlay(null);
			}
			else
			{
				updateVideoDisplay();
			}
		}
		
		private function onFwd(event:VideoControlsEvent):void
		{
			if (videoPlayer.hasEventListener(VideoPlayerEvent.SEEK_COMPLETE) == false) videoPlayer.addEventListener(VideoPlayerEvent.SEEK_COMPLETE,onProgress);			
			videoPlayer.playheadTime+= event.timeCode == 0 ? videoFrame : 1 + currentStartPoint;
			updateVideoDisplay();
		}
		
		private function onRwd(event:VideoControlsEvent):void
		{
			if (videoPlayer.hasEventListener(VideoPlayerEvent.SEEK_COMPLETE) == false) videoPlayer.addEventListener(VideoPlayerEvent.SEEK_COMPLETE,onProgress);
			videoPlayer.playheadTime-= event.timeCode == 0 ? videoFrame : 1;
			updateVideoDisplay();
		}
		
		// for some unknown reasons, when the video is paused and then seek (either by the playhead or seek button) the display isn't updated
		// therefore, in such cases resuming and then pausing the video, thus its being updated
		private function updateVideoDisplay():void
		{
			if (videoPlayer.isPlaying == false)
			{
				videoPlayer.play();
				videoPlayer.pause();
			}
		}
		
		private function onStrobingTimer(event:TimerEvent):void
		{
			onProgress(null);
		}
		
		private function onAddNewGroup(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onAddNewGroup");
			groupsContainer.addNewGroup();
		}
		
		private function onAddNewMarker(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onAddNewMarker");
			itemsEditor.createNewMarker();
		}
		
		private function onAddNewSegment(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onAddNewSegment");
			itemsEditor.createNewSegment();
		}
		
		private function onItemAdded(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onItemAdded");
			var segmentColor:int;
			if (itemsEditor.currentItemType == Nana10ItemData.SEGMENT)
			{
				segmentColor = taggerData.getSegmentColor();
				itemsEditor.itemName = dataRepository.getGroupById(groupsContainer.currentGroupID).title;
			}
			timeline.addNewItem(itemsEditor.currentItemType,segmentColor);
			itemsEditor.currentTime = videoPlayer.playheadTime + currentStartPoint;
			itemsEditor.duration = itemsEditor.endTime - itemsEditor.currentTime;
			groupsContainer.selectItem(0);
		}
		
		private function onSegmentUpdated(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onSegmentUpdated");
			var currentTime:Number = timeline.currentSegmentPosition * Group.TOTAL_VIDEO_DURATION;
			var delta:Number = itemsEditor.endTime - itemsEditor.currentTime;
			if (event.type == EditorEvent.SEGMENT_MOVED)
			{	// moving all segment		
				itemsEditor.currentTime = currentTime;
				itemsEditor.endTime = currentTime + delta;
			}
			else if (event.segmentSide == SegmentsEditor.RIGHT_SIDE)
			{	// moving segment's right side
				itemsEditor.endTime = currentTime + timeline.currentSegmentWidth * Group.TOTAL_VIDEO_DURATION;
			}
			else
			{	// moving segment's left side
				itemsEditor.currentTime = currentTime;
			}
			itemsEditor.duration = itemsEditor.endTime - itemsEditor.currentTime;
		}
		
		private function onSegmentEdited(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onSegmentEdited");
			timeline.currentSegmentPosition = itemsEditor.currentTime / Group.TOTAL_VIDEO_DURATION;
			timeline.currentSegmentWidth = (itemsEditor.endTime - itemsEditor.currentTime) / Group.TOTAL_VIDEO_DURATION;
		}
		
		private function onSegmentResizedToPlayhead(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onSegmentResizedToPlayhead");
			var playheadPosition:Number = timeline.playheadProgress * Group.TOTAL_VIDEO_DURATION;
			if (event.segmentSide == SegmentsEditor.LEFT_SIDE)
			{
				if (playheadPosition < itemsEditor.endTime - 1)
				{
					itemsEditor.currentTime = playheadPosition;
				}
			}
			else
			{
				if (playheadPosition > itemsEditor.currentTime + 1)
				{
					itemsEditor.endTime = playheadPosition;
				}
			}
			itemsEditor.duration = itemsEditor.endTime - itemsEditor.currentTime;
			onSegmentEdited(null);
		}
		
		private function onItemDissabled(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onItemDisabled");
			timeline.currentItemDissabled = itemsEditor.itemDissabled;
		}
		
		private function onMarkerMoved(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onMarkerMoved");
			itemsEditor.currentTime = timeline.currentMarkerPosition * Group.TOTAL_VIDEO_DURATION;
		}
		
		private function onMarkerEdited(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onMarkerEdited");
			timeline.currentMarkerPosition = itemsEditor.currentTime / Group.TOTAL_VIDEO_DURATION;
		}
		
		private function onMarkerMovedToPlayhead(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onMarkerMovedToPlayhead");
			timeline.currentMarkerPosition = timeline.playheadProgress;
			onMarkerMoved(null);
		}
		
		private function onGroupOffset(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onGroupOffset");
			var currentItemId:int;
			if (itemsEditor.inUse)
			{
				itemsEditor.currentTime+=event.offset;
				itemsEditor.endTime+= event.offset;
				currentItemId = itemsEditor.currentItemId
			}
			for (var i:int = 0; i < dataRepository.totalItems; i++)
			{
				var currentItem:Nana10MarkerData = dataRepository.getItemByIndex(i);
				if (currentItem.belongsToGroup(groupsContainer.currentGroupID))
				{
					timeline.currentItemId = currentItem.id;
					if (currentItem.type == Nana10ItemData.SEGMENT)
					{
						timeline.currentSegmentPosition = currentItem.timeCode / Group.TOTAL_VIDEO_DURATION;
						timeline.currentSegmentWidth = ((currentItem as Nana10SegmentData).endTimecode - currentItem.timeCode) / Group.TOTAL_VIDEO_DURATION; 
					}
					else if (currentItem.type == Nana10ItemData.MARKER)
					{
						timeline.currentMarkerPosition = currentItem.timeCode / Group.TOTAL_VIDEO_DURATION;
					}
				}
			}
			timeline.currentItemId = currentItemId;
		}
				
		private function onItemSaved(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onItemSaved");
			var item:Nana10MarkerData;
			if (itemsEditor.currentItemType == Nana10ItemData.MARKER)
			{
				if (itemsEditor.currentItemId == 0)
				{
					item = new Nana10MarkerData(0,Nana10ItemData.MARKER);
					itemsEditor.currentItemId = item.id;
					item.addGroup(groupsContainer.currentGroupID);
				}
				else
				{
					item = dataRepository.getItemById(itemsEditor.currentItemId);	
				}
				item.markerType = itemsEditor.markerType;
			}
			else
			{
				if (taggerData.checkSegmentsOverlap(itemsEditor.currentItemId,groupsContainer.currentGroupID,itemsEditor.currentTime,itemsEditor.endTime))
				{
					if (alertBox == null)
					{
						alertBox = new AlertBox(stage);
					}
					alertBox.displayAlert("לא ניתן לשמור.  המקטע חופף למקטע אחר");
					itemsEditor.itemSavedSuccesfully = false;
					return;
				}
				if (itemsEditor.currentItemId == 0)
				{
					item = new Nana10SegmentData(0);
					itemsEditor.currentItemId = item.id;
					item.addGroup(groupsContainer.currentGroupID);
					(item as Nana10SegmentData).uniqueGroup = itemsEditor.uniqueGroupID = Nana10ItemData.tempID;
				}
				else
				{
					item = dataRepository.getItemById(itemsEditor.currentItemId);	
				}				
				(item as Nana10SegmentData).endTimecode = itemsEditor.endTime;
				(item as Nana10SegmentData).color = timeline.currentSegmentColor;
				(item as Nana10SegmentData).description = itemsEditor.segmentDescription;
			}
			item.timeCode = itemsEditor.currentTime;
			item.title = itemsEditor.itemName;
			item.status = itemsEditor.itemDissabled == true ? 0 : 1;
			itemsEditor.itemSavedSuccesfully = true;
			dataRepository.addItem(item);
			groupsContainer.addItem(item,0,false,true);
			timeline.currentItemId = item.id;
			if (displaySavingMessage)
				alertBox.displayAlert("מבצע שמירה",true);
			displaySavingMessage = false;
			itemsEditor.currentItemSaved();	
		}
		
		private function onNewItemSaved(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onNewItemSaved");
			if (itemsEditor.currentItemId == event.origItemId)
			{
				itemsEditor.currentItemId = event.itemID;
				if (event.itemType == Nana10ItemData.SEGMENT) itemsEditor.uniqueGroupID = event.groupID;
			}
			if (dataRepository.getItemById(event.origItemId).belongsToGroup(groupsContainer.currentGroupID))
			{
				groupsContainer.updateNewItem(event.origItemId,event.itemID);
			}
		}
		
		private function onItemSelected(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onItemSelected");
			if (event.target == timeline)
			{
				groupsContainer.selectItem(event.itemID);
			}
			//else
			//{
				timeline.currentItemId = event.itemID;
				timeline.playheadProgress = (dataRepository.getItemById(event.itemID).timeCode) / Group.TOTAL_VIDEO_DURATION;
			//}
			//itemsEditor.currentGroup = groupsContainer.currentGroupID;
			itemsEditor.addExistingItem(event.itemID,groupsContainer.currentGroupID);
			//onPlayheadMoved(null);
			onPlayheadReleased(null);
		}
		
		private function onItemReset(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onItemReset");
			if (itemsEditor.currentItemId)
			{
				addItemToTimeline(dataRepository.getItemById(itemsEditor.currentItemId));
				itemsEditor.resetCurrentItem();
			}
			else
			{
				timeline.removeCurrentItem(itemsEditor.currentItemType);//event.itemType);
				itemsEditor.clearCurrentItem();
			}
			if (displaySavingMessage && event.cancelSave == false)
				alertBox.displayAlert("מבצע שמירה",true);
			displaySavingMessage = false;
		}
		
		private function onItemDeleted(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onItemDeleted");
			taggerData.itemDeleted(groupsContainer.currentGroupSelectedItem);
			timeline.deleteItem();	
			groupsContainer.deleteItem();
		}
		
		private function onGroupSelected(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onGroupSelected");
			timeline.clearItems();			
			if (groupsContainer.currentGroupSelectedItem == 0)
			{
				itemsEditor.clearCurrentItem();
			}
			//itemsEditor.currentGroup = groupsContainer.currentGroupID;
			var totalItems:int = dataRepository.totalItems;
			for (var i:int = 0; i < totalItems; i++)
			{
				addItemToTimeline(dataRepository.getItemByIndex(i));
			}
		}
		
		private function onGroupSaved(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onGroupSaved");
			groupsContainer.groupSaved(event.groupID,event.origGroupID);
		}
		
		private function onStartPreview(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onStartPreview");
			videoControls.pause();
			if (event.target is SegmentsEditor)
			{
				previewSegment();
			}
			else
				previewGroup(event.groupID);
			
		}
		
		private function previewSegment():void
		{
			Debugging.printToConsole("--Nana10VideoEditor.previewSegment");
			var segmentData:Nana10SegmentData = dataRepository.getItemById(itemsEditor.currentItemId) as Nana10SegmentData;
			var delay:int = 1000*(segmentData.endTimecode - segmentData.timeCode);
			timeline.currentItemId = itemsEditor.currentItemId;
			timeline.playheadProgress = segmentData.timeCode / Group.TOTAL_VIDEO_DURATION;
			onPlayheadMoved(null);
			videoControls.play();
			if (previewTimer == null)
			{
				previewTimer = new Timer(100);
				previewTimer.addEventListener(TimerEvent.TIMER,onPreviewEnded);
			}
			previewTimer.reset();
			previewEndTime = segmentData.endTimecode;
			//previewTimer.delay = delay;
			previewTimer.start();
		}
		
		private function onPreviewEnded(event:TimerEvent):void
		{
			if (videoPlayer.playheadTime + currentStartPoint >= previewEndTime)
			{
				videoControls.pause();
				itemsEditor.preivewEnded();
				previewTimer.stop();
			}
		}
		
		private function onEndPreview(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onEndPreview");
			previewTimer.stop();
		}
		
		private function onAddSegmentMarker(event:EditorEvent):void
		{
			var markerTimeCode:Number = itemsEditor.endTime - 0.01;
			var markerTitle:String = itemsEditor.itemName + "_פרסומת";
			itemsEditor.createNewMarker();
			itemsEditor.currentTime = markerTimeCode;
			timeline.currentMarkerPosition = markerTimeCode / Group.TOTAL_VIDEO_DURATION;
			itemsEditor.itemName = markerTitle;
			onItemSaved(null);
		}			
		
		private function previewGroup(groupId:int):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onPreviewGroup");
			dataRepository.previewGroupID = groupId;//.target.id;
			if (previewContainer == null)
			{
				previewContainer = new PreviewContainer();
				addChild(previewContainer);
				DisplayUtils.align(stage,previewContainer);
			}
			//previewContainer.init(event.stillImage ? dataRepository.getGroupById(dataRepository.previewGroupID).stillImageURL : null);
			previewContainer.init();
			previewContainer.visible = true;
			ModalManager.setModal(previewContainer);
		}
		
		private function onSave(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onSave");
			if (alertBox == null)
			{
				alertBox = new AlertBox(stage);
			}
			try
			{
				if (taggerData.saveData())
					alertBox.displayAlert("מבצע שמירה",true);
				else
					displaySavingMessage = true;
			}
			catch (e:Error)
			{
				alertBox.displayAlert("שגיאה:  " + e.message);
			}
		}
		
		private function onDataSaved(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onDateSaved");
			groupsContainer.updateLists();
			alertBox.displayAlert("שמירה בוצעה בהצלחה");
		}
		
		private function onDataSaveError(event:EditorEvent):void
		{
			Debugging.printToConsole("--Nana10VideoEditor.onDataSaveError");
			alertBox.displayAlert("תקלה בשמירה.  נסו שוב מאוחר יותר");
		}
		
		private function onStreamNotReady(event:EditorEvent):void
		{
			if (alertBox == null)
			{
				alertBox = new AlertBox(stage);
			}
			alertBox.displayAlert("שים לב - הקישור לקובץ ה-streaming עדיין לא מוכן.  העריכה אפשרית אולם לא ניתן לעשות זאת בצורה מדויקת. %%%כדי לעבוד בצורה מדויקת מומלץ להמתין שקישור ה-streaming יהיה מוכן.");
		}
	}
}