package com.ui.groups
{
	import com.data.Nana10DataRepository;
	import com.data.TaggerData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.tagger.Nana10GroupData;
	import com.events.ConfirmAlertEvent;
	import com.events.EditorEvent;
	import com.fxpn.display.ShapeDraw;
	import com.ui.AlertBox;
	import com.ui.editors.SavingManager;
	
	import fl.controls.Button;
	import fl.controls.ScrollBar;
	import fl.events.ScrollEvent;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	import gs.TweenLite;
	
	[Event (name="groupSelected", type="com.events.EditorEvent")]
	[Event (name="itemSelected", type="com.events.EditorEvent")]
	[Event (name="groupDuplicated", type="com.events.EditorEvent")]
	[Event (name="groupPreview", type="com.events.EditorEvent")]
	public class GroupContainer extends Sprite
	{
		private const GROUPS_GAP:int = 5;
		private var dataRepository:Nana10DataRepository;
		private var addGroupBtn:Button;
		private var currentGroup:Group;
		private var groupToSelect:Group;
		private var container:Sprite;
		private var scrollBar:ScrollBar;
		private var alertBox:AlertBox;
		private var containerOrigY:Number;
		private var shadowFilter:DropShadowFilter;
		//private var glowFilter:GlowFilter;
		
		public function GroupContainer()
		{
			dataRepository = Nana10DataRepository.getInstance();
			
			/*addGroupBtn = new Button();
			addGroupBtn.label = "הוספת קבוצה";
			addGroupBtn.addEventListener(MouseEvent.CLICK, onAddGroup);
			addChild(addGroupBtn);
			addGroupBtn.enabled = TaggerData.getInstance().allowSave;*/
			
			container = new Sprite();
			container.y = containerOrigY = 0;//addGroupBtn.height + 10;
			addChild(container);
			
			//glowFilter = new GlowFilter(0xff0000,0.8,5,5,1);
			//shadowFilter = new DropShadowFilter(2);
			
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void
		{
			scrollBar = new ScrollBar();
			scrollBar.x = stage.stageWidth - x - scrollBar.width - 2;
			scrollBar.y = container.y;
			scrollBar.height = stage.stageHeight - y - scrollBar.y - 1;
			addChild(scrollBar);
			scrollBar.addEventListener(ScrollEvent.SCROLL,onScrollGroups);
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			//addGroupBtn.x = scrollBar.x - addGroupBtn.width;
			
			var shape:Shape = ShapeDraw.drawSimpleRect(stage.stageWidth - x*2 - scrollBar.width+2, scrollBar.height + 2);
			shape.x = container.x - 2;
			shape.y = container.y - 2;
			addChild(shape);
			container.mask = shape;
			
			var topLine:Shape = new Shape();
			topLine.graphics.lineStyle(1);
			topLine.graphics.lineTo(stage.stageWidth,0);
			topLine.x = -x + 1;
			topLine.y = container.y - 2;
			addChild(topLine);
		}
		
		public function addNewGroup():void
		{
			var groupData:Nana10GroupData = new Nana10GroupData(0,false);
			groupData.status = 1;
			dataRepository.addGroup(groupData);
			selectGroup(addGroup(groupData.id));
		}
		
		private function onGroupMinimized(event:EditorEvent):void
		{
			var group:Group = event.target as Group;
			tweenGroups(group.index,-group.tweenHeightDelta);
		}
		
		private function onGroupMaximized(event:EditorEvent):void
		{
			var group:Group = event.target as Group;
			tweenGroups(group.index,group.tweenHeightDelta);
		}
		
		private function tweenGroups(fromGroup:int,tweenDelta:Number, groupDeleted:Boolean = false):void
		{
			for (var i:int = fromGroup + 1; i < container.numChildren; i++)
			{
				var group:Group = container.getChildAt(i) as Group;
				TweenLite.to(group,Group.GROUP_TWEEN_DURATION,{y: group.y + tweenDelta});
				if (groupDeleted) group.index-=1;
			}
		}
		
		private function updateScrollBarProperties(event:EditorEvent = null):void
		{
			scrollBar.setScrollProperties(container.mask.height - containerOrigY,0,containerHeight - container.mask.height);
			if (containerHeight < container.mask.height)
			{
				TweenLite.to(container,0.3,{y: containerOrigY});
			}
		}
		
		private function onScrollGroups(event:ScrollEvent):void
		{
			container.y = containerOrigY - event.position; 
		}
		
		private function onMouseWheel(event:MouseEvent):void
		{
			scrollBar.scrollPosition-=event.delta*2;
		}
		
		private function onSelectGroup(event:MouseEvent):void
		{
			selectGroup(event.currentTarget as Group);
		}
		
		private function selectGroup(group:Group):void
		{
			if (group != currentGroup)
			{
				groupToSelect = group;
				if (SavingManager.checkChangesSaved(saveCurrentItem,dontSaveCurrentItem,cancelSaveOperation))
				{
					canSelect();
				}
			}			
		}
		
		private function saveCurrentItem():void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_SAVED));
			canSelect();
		}
		
		private function dontSaveCurrentItem():void
		{
			dispatchEvent(new EditorEvent(EditorEvent.RESET_ITEM));	
			canSelect();
		}
		
		private function canSelect():void
		{
			if (currentGroup)
			{
				//currentGroup.filters = [];
				currentGroup.clearSelection();
			}
			currentGroup = groupToSelect;
			//currentGroup.filters = [glowFilter];
			currentGroup.select();
			if (container.height != groupToSelect.height)
			{
				TweenLite.to(scrollBar,0.3,{scrollPosition: scrollBar.maxScrollPosition * groupToSelect.y / (container.height - groupToSelect.height)});
			}
			dispatchEvent(new EditorEvent(EditorEvent.GROUP_SELECTED));
		}
		
		private function cancelSaveOperation():void
		{
			var event:EditorEvent = new EditorEvent(EditorEvent.RESET_ITEM);
			event.cancelSave = true;
			dispatchEvent(event);
		}
		
		private function onGroupDuplicated(event:EditorEvent):void
		{
			var groupData:Nana10GroupData = new Nana10GroupData(0,false);
			groupData.status = 1;
			groupData.title = "עותק של " + currentGroup.title_txt.text;
			dataRepository.addGroup(groupData);			
			var group:Group = addGroup(groupData.id,true);
			
			var curretnGroupItems:Array = [];
			var totalItems:int = dataRepository.totalItems
			for (var i:int = 0; i < totalItems; i++)
			{
				if (dataRepository.getItemByIndex(i).belongsToGroup(currentGroupID))
				{	
					var itemData:Nana10MarkerData = dataRepository.getItemByIndex(i).clone();
					itemData.title = itemData.title.concat("_עותק");
					curretnGroupItems.push(itemData);
					dataRepository.addItem(itemData);
					itemData.addGroup(groupData.id);
				}
			}
			selectGroup(group);
			for (var j:int = 0; j < curretnGroupItems.length; j++)
			{
				addItem(curretnGroupItems[j]);
			}
		}
		
		private function onGroupSaved(event:EditorEvent):void
		{
			
		}
		
		private function onGroupDeleted(event:EditorEvent):void
		{
			if (alertBox == null)
			{
				alertBox = new AlertBox(stage);
				alertBox.addEventListener(ConfirmAlertEvent.YES,onConfirmGroupDelete);
			}	
			alertBox.displayConfirmation("האם להסיר קבוצה זו ואת כל האייטמים המקושרים אליה?",false);
		}
		
		private function onConfirmGroupDelete(event:ConfirmAlertEvent):void
		{
			tweenGroups(currentGroup.index,-currentGroup.height - GROUPS_GAP,true);
			container.removeChild(currentGroup);
			//Nana10DataRepository.getInstance().removeGroup(currentGroupID);
			TaggerData.getInstance().groupDeleted(currentGroupID);
			updateScrollBarProperties();			
			selectGroup(container.getChildAt(currentGroup.index - 1) as Group);
			if (scrollBar.enabled)
			{
				TweenLite.to(scrollBar,Group.GROUP_TWEEN_DURATION,{scrollPosition:  currentGroup.y});
			}
			else
			{
				container.y = containerOrigY;
			}
		}
		
		private function onItemSelected(event:EditorEvent):void
		{
			selectGroup(event.currentTarget as Group);
			dispatchEvent(event);
		}
		
		private function onItemReset(event:EditorEvent):void
		{
			dispatchEvent(event);
		}
		
		private function onItemSaved(event:EditorEvent):void
		{
			trace("save container");
			//dispatchEvent(event);
		}
		
		private function get containerHeight():Number
		{
			var output:Number = 0;
			var totalGroups:int = container.numChildren;
			for (var i:int = 0;  i < totalGroups; i++)
			{
				output+=container.getChildAt(i).height + GROUPS_GAP;
			}
			//output-= GROUPS_GAP;
			return output;
		}
		
		public function addGroup(id:int = 0, duplication:Boolean = false):Group
		{	
			/*var groupTitle:String;
			if (id)
			{
				var groupData:Nana10GroupData = Nana10DataRepository.getInstance().getGroupById(id);
				groupTitle = groupData.title;
			}
			else
			{
				groupTitle = "Enter group title";
			}*/
			var group:Group = new Group(container.numChildren,id,duplication);
			group.setSize(container.mask.width - 4, 220);
			container.addChild(group);			
			group.addEventListener(EditorEvent.GROUP_MAXIMIZED, onGroupMaximized);
			group.addEventListener(EditorEvent.GROUP_MINIMIZED,onGroupMinimized);
			group.addEventListener(EditorEvent.GROUP_TWEEN_FINISHED,updateScrollBarProperties);
			group.addEventListener(EditorEvent.GROUP_SAVED, onGroupSaved);
			group.addEventListener(EditorEvent.GROUP_DELETED,onGroupDeleted);
			group.addEventListener(MouseEvent.MOUSE_DOWN, onSelectGroup);
			group.addEventListener(EditorEvent.ITEM_SELECTED,onItemSelected);
			group.addEventListener(EditorEvent.GROUP_DUPLICATED,onGroupDuplicated);
			//group.addEventListener(EditorEvent.RESET_ITEM,onItemReset);
			//group.addEventListener(EditorEvent.ITEM_SAVED,onItemSaved);
			if (container.numChildren > 1)
			{
				var previousGroup:Group = container.getChildAt(container.numChildren-2) as Group; 
				group.y = previousGroup.y + previousGroup.height + GROUPS_GAP;
			}
			updateScrollBarProperties();
			//selectGroup(group);	
			return group;
		}
		
		public function addItem(itemData:Nana10MarkerData, groupId:int = 0, isDefault:Boolean = false, selected:Boolean = false):void
		{
			if (!groupId)
			{
				currentGroup.addItem(itemData,isDefault,selected);
			}
			else
			{
				var totalGroups:int = container.numChildren;
				for (var i:int  = 0; i < totalGroups; i++)
				{
					if ((container.getChildAt(i) as Group).id == groupId)
					{
						(container.getChildAt(i) as Group).addItem(itemData,isDefault);
						break;
					}
				}	
			}
		}
		
		public function deleteItem():void
		{
			currentGroup.deleteItem();
		}
		
		public function selectGroupByIndex(index:int):void
		{
			if (dataRepository.totalGroups > index)
				selectGroup(container.getChildAt(index) as Group);
		}
		
		public function selectItem(id:int):void
		{
			currentGroup.selectItem(id);
		}
		
		public function groupSaved(newID:int, origID:int):void
		{
			var totalGroups:int = container.numChildren;
			for (var i:int  = 0; i < totalGroups; i++)
			{
				if ((container.getChildAt(i) as Group).id == origID)
				{
					(container.getChildAt(i) as Group).id = newID;
					break;
				}
			}
		}
		
		public function updateLists():void
		{
			var totalGroups:int = container.numChildren;
			for (var i:int  = 0; i < totalGroups; i++)
			{
				(container.getChildAt(i) as Group).updateList();
			}
		}
		
		public function updateNewItem(origItemID:int,newItemID:int):void
		{
			currentGroup.updateNewItem(origItemID,newItemID);
		}
		
		public function get currentGroupID():int
		{
			if (currentGroup == null) return 0;
			return currentGroup.id;
		}
		
		public function get currentGroupSelectedItem():int
		{
			return currentGroup.selectedItem;
		}
	}
}