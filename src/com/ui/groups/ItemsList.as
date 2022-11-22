package com.ui.groups
{
	import com.data.Nana10DataRepository;
	import com.data.TaggerData;
	import com.data.datas.items.ItemData;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.data.items.Nana10SegmentData;
	import com.events.EditorEvent;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.StringUtils;
	import com.ui.editors.SavingManager;
	import com.ui.groups.cellRenderers.ColorCellRederer;
	
	import fl.controls.CheckBox;
	import fl.controls.DataGrid;
	import fl.controls.dataGridClasses.DataGridColumn;
	import fl.controls.listClasses.CellRenderer;
	import fl.events.ListEvent;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	[Event (name="itemSelected", type="com.events.EditorEvent")]
	public class ItemsList extends EventDispatcher
	{
		private var _dataGrid:DataGrid;
		private var defaultGroup:Boolean;
		private var previousSelectedItem:Object;
		
		public function ItemsList(dataGrid:DataGrid)
		{
			_dataGrid = dataGrid;
			
			_dataGrid.addEventListener(Event.CHANGE,onSelectItem);
			addColumnToGrid("colorDisplay","צבע",false,40,null,ColorCellRederer); // giving this column a different data name, so the color's number won't be written inside the cell
			addColumnToGrid("id","ID",true,50,getID);
			addColumnToGrid("type","סוג",true,55,getType);
			addColumnToGrid("title","שם",true);
			addColumnToGrid("timeCode","התחלה",true,100,showTimecode);
			addColumnToGrid("endTimecode","סיום",false,100,showEndTimecode);
			addColumnToGrid("duration","משך",false,100,showDuration);
			addColumnToGrid("status","מוסתר",true,60,setStatus);			
		}
		
		private function addColumnToGrid(data:String,label:String, sortable:Boolean, w:Number = NaN,labelFunction:Function = null, cellRenderer:Object = null):void
		{
			var column:DataGridColumn = new DataGridColumn(data);
			column.headerText = label;
			column.labelFunction = labelFunction;
			column.sortable = sortable;
			if (!isNaN(w)) column.width = w;			
			if (cellRenderer) column.cellRenderer = cellRenderer;
			_dataGrid.addColumn(column);
		}
		
		public function addItem(itemData:Object, isDefault:Boolean):void
		{	
			_dataGrid.addItem(itemData);
			_dataGrid.drawNow();
			//if ((itemData as Nana10MarkerData).belongsToGroup(Nana10DataRepository.getInstance().getGroupByIndex(0).id)) defaultGroup = true; 
		}
		
		public function deleteItem():Nana10MarkerData
		{
			var deletedItem:Nana10MarkerData = _dataGrid.removeItem(_dataGrid.selectedItem) as Nana10MarkerData;
			return deletedItem//.id;
		}
		
		public function updateList():void
		{
			_dataGrid.invalidateList();
		}
		
		private function getID(item:Nana10MarkerData):String
		{
			if (item.id > 0)
			{
				if (item is Nana10SegmentData && (item as Nana10SegmentData).uniqueGroup > 0)
				{
					return String((item as Nana10SegmentData).uniqueGroup);
				}
				else
				{
					return String(item.id);
				}
			}
			else
			{
				return "-";
			}
		}
		
		private function getType(item:Nana10MarkerData):String
		{
			var type:String;
			switch (item.type)
			{
				case Nana10ItemData.MARKER:
					type = item.markerType ? "תוכן" : "פרסומת";
					break;
				case Nana10ItemData.SEGMENT:
					type = "מקטע";
					break;
			}
			return type;
		}
		
		private function showTimecode(item:Nana10MarkerData):String
		{
			return StringUtils.turnNumberToTime(item.timeCode,true,true,true);
		}
		
		private function showEndTimecode(item:Nana10ItemData):String
		{
			var timecode:String = "";
			if (item is Nana10SegmentData)
			{
				timecode = StringUtils.turnNumberToTime((item as Nana10SegmentData).endTimecode,true,true,true);
			}
			return timecode;
		}
		
		private function showDuration(item:Nana10ItemData):String
		{
			var duration:String = "";
			if (item is Nana10SegmentData)
			{
				duration = StringUtils.turnNumberToTime((item as Nana10SegmentData).endTimecode - (item as Nana10MarkerData).timeCode,true,true,true);
			}
			return duration;
		}
		
		private function setStatus(item:Nana10ItemData):String
		{
			if (item.status) return "לא";
			return "כן";
		}
		
		private function onSelectItem(event:Event):void
		{
			if (defaultGroup)//(_dataGrid.selectedItem == defaultGroup || (_dataGrid.selectedItem.type == Nana10ItemData.MARKER && TaggerData.getInstance().allowSave == false))
			{
				_dataGrid.selectedItem = previousSelectedItem;					
			}
			else if (SavingManager.checkChangesSaved(saveCurrentItem,dontSaveCurrentItem,onCancelSelection))
			{
				saveCurrentItem(false);
			}
		}
		
		private function saveCurrentItem(save:Boolean = true):void
		{
			if (save) dispatchEvent(new EditorEvent(EditorEvent.ITEM_SAVED,true));
			canSelectItem();
		}
		
		private function dontSaveCurrentItem():void
		{
			dispatchEvent(new EditorEvent(EditorEvent.RESET_ITEM,true));
			canSelectItem();
		}
		
		private function canSelectItem():void
		{
			var editorEvent:EditorEvent = new EditorEvent(EditorEvent.ITEM_SELECTED);
			editorEvent.itemID = _dataGrid.selectedItem.id;
			dispatchEvent(editorEvent);
			previousSelectedItem = _dataGrid.selectedItem;
		}
		
		private function onCancelSelection():void
		{
			_dataGrid.selectedItem = previousSelectedItem;	
		}
		
		public function selectItem(id:int):void
		{
			if (id)
			{
				var totalItems:int = _dataGrid.dataProvider.length;
				for (var i:int = 0; i < totalItems; i++)
				{
					if (_dataGrid.getItemAt(i).id == id)
					{
						_dataGrid.selectedIndex = i;
						break;
					}
				}
			}
			else
			{
				_dataGrid.selectedIndex = -1;
			}
			previousSelectedItem = _dataGrid.selectedItem;
		}
		
		public function clearSelection():void
		{
			_dataGrid.selectedIndex = -1;
			previousSelectedItem = null;
		}
		
		public function get selectedItem():int
		{
			if (_dataGrid.selectedItem)
			{
				return _dataGrid.selectedItem.id;
			}
			return 0;
		}
	}	
}