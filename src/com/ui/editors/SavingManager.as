package com.ui.editors
{
	import com.data.Nana10DataRepository;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.events.ConfirmAlertEvent;
	import com.ui.AlertBox;
	
	import flash.display.Stage;
	
	public class SavingManager
	{
		public static var currentEditor:IItemEditor;
		private static var alertBox:AlertBox;
		private static var _saveFunction:Function;
		private static var _dontSaveFunction:Function;
		private static var _cancelFunction:Function;
		private static var _inUse:Boolean;
		
		public static function init(stage:Stage):void
		{
			alertBox = new AlertBox(stage);
			alertBox.addEventListener(ConfirmAlertEvent.YES, onSaveCurrentItem);
			alertBox.addEventListener(ConfirmAlertEvent.NO, onDontSaveCurrentItem);
			alertBox.addEventListener(ConfirmAlertEvent.CANCEL,onCancel);
		}
		
		public static function checkChangesSaved(saveFunction:Function, dontSaveFunction:Function, cancelFunction:Function = null):Boolean
		{
			if (currentEditor == null || currentEditor.saved)
			{
				_inUse = false;
				return true;
			}
			else
			{
				_inUse = true;
				_saveFunction = saveFunction;
				_dontSaveFunction = dontSaveFunction;
				_cancelFunction = cancelFunction;
				var message:String = currentEditor.newItem ? "להוסיף אייטם חדש?" : "לעדכן את האייטם הקיים?";
					//"להוסיף אייטם חדש" : "?לעדכן את האייטם הקיים?";
				alertBox.displayConfirmation(message);
				return false;
			}
		}
		
		public static function checkVisibleItems(saveFunction:Function):Boolean
		{
			var visibleItems:Boolean;
			var dr:Nana10DataRepository = Nana10DataRepository.getInstance();
			var totalGroups:int = dr.totalGroups;
			for (var i:int = 0; i < totalGroups; i++)
			{
				if (dr.getGroupByIndex(i).status == 1)
				{
					visibleItems = true;
					break;
				}
			}
			if (!visibleItems)
			{
				var totalItems:int = dr.totalItems;
				for (var j:int = 0; j < totalItems; j++)
				{
					if (dr.getItemByIndex(j).type == Nana10ItemData.SEGMENT && dr.getItemByIndex(j).status == 1)
					{
						visibleItems = true;
						break;
					}
				}
			}
			if (visibleItems)
			{
				return true;
			}
			else
			{
				_inUse = true;
				_saveFunction = saveFunction;
				_dontSaveFunction = _cancelFunction = null;
				var message:String = "כל הפריטים מוסתרים.  האם להמשיך?";
				alertBox.displayConfirmation(message,false);
				return false;
			}
		}
		
		private static function onSaveCurrentItem(event:ConfirmAlertEvent):void
		{
			_inUse = false;
			_saveFunction.call();
		}
		
		private static function onDontSaveCurrentItem(event:ConfirmAlertEvent):void
		{
			_inUse = false;
			if (_dontSaveFunction != null) _dontSaveFunction.call();
		}
		
		private static function onCancel(event:ConfirmAlertEvent):void
		{
			_inUse = false;
			if (_cancelFunction != null) _cancelFunction.call();
		}

		public static function get inUse():Boolean
		{
			return _inUse;
		}

	}
}