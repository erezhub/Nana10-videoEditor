package com.ui.editors
{
	import com.data.items.Nana10ItemData;
	import com.events.EditorEvent;
	import com.fxpn.util.StringUtils;
	
	import fl.controls.NumericStepper;
	import fl.controls.RadioButton;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import resources.editors.MarkerEditorVisuals;
	
	public class MarkersEditor extends MarkerEditorVisuals implements IItemEditor
	{
		private var _endTime:Number;
		private var _saved:Boolean;
		
		public function MarkersEditor()
		{
			hourStpr.addEventListener(Event.CHANGE, onStepperChanged);
			minsStpr.addEventListener(Event.CHANGE, onStepperChanged);
			secsStpr.addEventListener(Event.CHANGE, onStepperChanged);
			milsStpr.addEventListener(Event.CHANGE, onStepperChanged);	
			
			playheadBtn.addEventListener(MouseEvent.CLICK, onSetToPlayhead);
			saveBtn.addEventListener(MouseEvent.CLICK,onSave);
			deleteBtn.addEventListener(MouseEvent.CLICK,onDelete);
			name_txt.addEventListener(Event.CHANGE,onNameChanged);
			disabledCB.addEventListener(Event.CHANGE,onToggleDisabled);
			adRB.addEventListener(Event.CHANGE,onToggleType);
			bookmarkRB.addEventListener(Event.CHANGE,onToggleType);
			
			var fmt:TextFormat = new TextFormat("Arial");
			fmt.align = TextFormatAlign.RIGHT;
			name_txt.setStyle("textFormat",fmt);
			
			var components:Array = [name_txt,playheadBtn,hourStpr,minsStpr,secsStpr,milsStpr,
									disabledCB,adRB,bookmarkRB, deleteBtn,saveBtn];
			for (var i:int = 0; i < components.length; i++)
			{
				components[i].tabIndex = i+1;
			}
			
			addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void
		{
			adRB.selected = true;
		}
		
		
		
		public function clear():void
		{
			name_txt.text = "";
			adRB.selected = true;
		}
		
		public function set saveBtnLabel(txt:String):void
		{
			saveBtn.label = txt;
			if (txt == "עדכון")
			{
				deleteBtn.label = "מחיקה";				
			}
			else
			{
				deleteBtn.label = "ביטול";
			}
		}
		
		public function set currentTime(value:Number):void
		{
			var currentTime:String = StringUtils.turnNumberToTime(value,true,false,true);
			var arr:Array = currentTime.split(":");
			hourStpr.value = arr[0];
			minsStpr.value = arr[1];
			secsStpr.value = arr[2];
			milsStpr.value = arr[3];
			_saved = false;
		}
		
		public function get currentTime():Number
		{
			return milsStpr.value/1000 + secsStpr.value + minsStpr.value*60 + hourStpr.value*3600;
		}
		
		public function get markerType():Boolean
		{
			return bookmarkRB.selected;
		}
		
		public function set markerType(value:Boolean):void
		{
			bookmarkRB.selected = value;
			adRB.selected = !value;
		}
		
		private function onStepperChanged(event:Event):void
		{
			var stpr:NumericStepper = event.target as NumericStepper;
			var stprName:String = stpr.name;
			switch (stpr)
			{
				case hourStpr:
					checkStepper(stpr,null,3);
					break;
				case minsStpr:
					checkStepper(stpr,hourStpr,60);
					break;
				case secsStpr:
					checkStepper(stpr,minsStpr,60);
					break;
				case milsStpr:
					checkStepper(stpr,secsStpr,1000);
					break;
			}
			dispatchEvent(new EditorEvent(EditorEvent.MARKER_EDITED,true));
			_saved = false;
		}
		
		private function checkStepper(stepper:NumericStepper,nextStepper:NumericStepper,max:int):void
		{
			var add:int;
			var reset:int;
			var value:int = stepper.value;
			if (currentTime > _endTime)
			{	// making sure segment doesn't overlap the entire clip
				stepper.value-=1;
				return;
			}
			if (value == max || value == -1)
			{				
				if (value == -1)
				{
					if (nextStepper.value > 0)
					{
						add = -1;
						reset = max-1;
					}
					else
					{
						add = 0;
						reset = 0;
					}
				}
				else
				{
					add = 1;
					reset = 0;
				}
				nextStepper.value+=add;
				stepper.value = reset;
			}			
		}

		private function onSetToPlayhead(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.MARKER_MOVED,true));
		}
		
		private function onToggleDisabled(event:Event):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_DISABLED,true));	
			_saved = false;	
		}
		
		private function onToggleType(event:Event):void
		{
			_saved = false;
		}
		
		private function onSave(event:MouseEvent):void
		{
			var editorEvent:EditorEvent = new EditorEvent(EditorEvent.ITEM_SAVED,true);
			editorEvent.itemType = Nana10ItemData.MARKER;
			dispatchEvent(editorEvent);
		}
		
		public function set itemSavedSuccesfully(value:Boolean):void
		{
			if (value)
			{
				_saved = true;
				saveBtn.label = "עדכון";
				deleteBtn.label = "מחיקה";
			}
		}
		
		private function onDelete(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_DELETED));
		}
		
		private function onNameChanged(evnet:Event):void
		{
			_saved = false;
		}
		
		public function set endTime(value:Number):void
		{
			_endTime = value;
		}
		
		public function get title():String
		{
			return name_txt.text;
		}
		
		public function set title(value:String):void
		{
			name_txt.text = value;
		}
		
		public function set dissabled(value:Boolean):void
		{
			disabledCB.selected = value;
		}
		
		public function get dissabled():Boolean
		{
			return disabledCB.selected;
		}

		public function get saved():Boolean
		{
			return _saved;
		}

		public function init():void
		{		
			_saved = true;
		}
		
		public function get newItem():Boolean
		{
			return saveBtn.label == "הוספה";
		}	
		
		public function set currentGroupID(value:int):void {}
	}
}