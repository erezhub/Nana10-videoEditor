package com.ui.editors
{
	import com.data.Nana10DataRepository;
	import com.data.TaggerData;
	import com.data.items.Nana10ItemData;
	import com.data.items.Nana10MarkerData;
	import com.events.EditorEvent;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.StringUtils;
	import com.google.ads.instream.api.AdMenuEvent;
	
	import fl.controls.NumericStepper;
	import fl.core.UIComponent;
	import fl.events.ComponentEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.sampler.getMemberNames;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import resources.editors.SegmentEditorVisuals;
		
	public class SegmentsEditor extends SegmentEditorVisuals implements IItemEditor
	{
		public static const RIGHT_SIDE:int = 0;
		public static const LEFT_SIDE:int = 1;
		
		private const MINIMUM_SEGMENT_LENGTH:int = 1; 
		
		private var topLimit:Number;
		private var _saved:Boolean;
		private var _uniqueGroupID:int;
		private var _currentGroupID:int;
	
		public function SegmentsEditor()
		{
			inHourStpr.addEventListener(Event.CHANGE, onStepperChanged);
			inMinsStpr.addEventListener(Event.CHANGE, onStepperChanged);
			inSecsStpr.addEventListener(Event.CHANGE, onStepperChanged);
			inMilsStpr.addEventListener(Event.CHANGE, onStepperChanged);
			
			outHourStpr.addEventListener(Event.CHANGE, onStepperChanged);
			outMinsStpr.addEventListener(Event.CHANGE, onStepperChanged);
			outSecsStpr.addEventListener(Event.CHANGE, onStepperChanged);
			outMilsStpr.addEventListener(Event.CHANGE, onStepperChanged);	
			
			inPlayheadBtn.addEventListener(MouseEvent.CLICK, onSetToPlayhead);
			outPlayheadBtn.addEventListener(MouseEvent.CLICK, onSetToPlayhead);
			saveBtn.addEventListener(MouseEvent.CLICK,onSave);
			deleteBtn.addEventListener(MouseEvent.CLICK,onDelete);
			//blackHoleCB.addEventListener(Event.CHANGE, onToggleBlackhole);
			name_txt.addEventListener(Event.CHANGE, onTextInputChanged);
			description_txt.addEventListener(Event.CHANGE,onTextInputChanged);
			disabledCB.addEventListener(Event.CHANGE,onToggleDisabled);
			//previewBtn.addEventListener(MouseEvent.CLICK,onPreview);
			previewBtn.addEventListener(ComponentEvent.BUTTON_DOWN,onPreview);
			previewBtn.enabled = false;
			adMarkerBtn.addEventListener(MouseEvent.CLICK,onAdMarker);
			adMarkerBtn.enabled = false;
			var fmt:TextFormat = new TextFormat("Arial");
			fmt.align = TextFormatAlign.RIGHT;
			name_txt.setStyle("textFormat",fmt);
			description_txt.setStyle("textFormat",fmt);
			
			var allowSave:Boolean = TaggerData.getInstance().allowSave;
			var components:Array = [name_txt,description_txt,inPlayheadBtn,inHourStpr,inMinsStpr,inSecsStpr,inMilsStpr,
									outPlayheadBtn,outHourStpr,outMinsStpr,outSecsStpr,outMilsStpr,
									disabledCB, previewBtn,deleteBtn,saveBtn];
			for (var i:int = 0; i < components.length; i++)
			{
				components[i].tabIndex = i+1;
			}
			/*for each (var component:UIComponent in components)
			{
				component.enabled = allowSave;
			}*/
			if (allowSave == false)
			{
				saveBtn.label = "בחירה";
				saveBtn.removeEventListener(MouseEvent.CLICK,onSave);
				saveBtn.addEventListener(MouseEvent.CLICK,onSelect);
			}			
		}
		
		public function clear():void
		{
			name_txt.text = description_txt.text = id_txt.text = "";
		}
		
		public function set saveBtnLabel(txt:String):void
		{
			if (TaggerData.getInstance().allowSave) saveBtn.label = txt;
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
			inHourStpr.value = arr[0];
			inMinsStpr.value = arr[1];
			inSecsStpr.value = arr[2];
			inMilsStpr.value = arr[3];
			saved = false;
		}
		
		public function get currentTime():Number
		{
			return inMilsStpr.value/1000 + inSecsStpr.value + inMinsStpr.value*60 + inHourStpr.value*3600;
		}
		
		public function set endTime(value:Number):void
		{
			var endTime:String = StringUtils.turnNumberToTime(value,true,false,true);
			var arr:Array = endTime.split(":");
			outHourStpr.value = arr[0];
			outMinsStpr.value = arr[1];
			outSecsStpr.value = arr[2];
			outMilsStpr.value = arr[3];
			
			if (isNaN(topLimit)) topLimit = value;
			saved = false;
		}
		
		public function get endTime():Number
		{
			return outMilsStpr.value/1000 + outSecsStpr.value + outMinsStpr.value*60 + outHourStpr.value*3600;
		}
		
		public function set duration(value:Number):void
		{
			var delta:String = StringUtils.turnNumberToTime(value,true,false,true);
			var arr:Array = delta.split(":");
			durationHours.text = arr[0];
			durationMins.text = arr[1];
			durationSecs.text = arr[2];
			durationMiliSecs.text = arr[3];
		}
		
		private function onStepperChanged(event:Event):void
		{
			var stpr:NumericStepper = event.target as NumericStepper;
			var stprName:String = stpr.name;
			var stprPrefix:String = stprName.charAt(0) == "i" ? "in" : "out";	
			if (stprName.indexOf("Hour") > -1)
			{
				checkStepper(stpr,null,3,stprPrefix);
			}
			else if (stprName.indexOf("Mins") > -1)
			{
				checkStepper(stpr,this[stprPrefix + "HourStpr"],60,stprPrefix);
			}
			else if (stprName.indexOf("Secs") > -1)
			{
				checkStepper(stpr,this[stprPrefix + "MinsStpr"],60,stprPrefix);
			}
			else if (stprName.indexOf("Mils") > -1)
			{
				checkStepper(stpr,this[stprPrefix + "SecsStpr"],1000,stprPrefix);
			}
			dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_EDITED,true));
			duration = endTime - currentTime;
			saved = false;
		}
		
		private function checkStepper(stepper:NumericStepper,nextStepper:NumericStepper,max:int,prefix:String):void
		{
			var add:int;
			var reset:int;
			var value:int = stepper.value;
			var delta:Number = endTime - currentTime;
			if (delta < MINIMUM_SEGMENT_LENGTH)
			{	// making sure minimum length of segment
				while (delta < MINIMUM_SEGMENT_LENGTH)
				{
					stepper.value+=(prefix == "in" ? -1 : 1);
					delta = endTime - currentTime;
				}
				return;
			}
			if (prefix == "out")
			{	// making sure segment doesn't overlap the entire clip
				while (endTime > topLimit)
				{
					stepper.value-=1;
				}
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
			var editorEvent:EditorEvent = new EditorEvent(EditorEvent.SEGMENT_RESIZED,true);
			editorEvent.segmentSide = event.target == inPlayheadBtn ? LEFT_SIDE : RIGHT_SIDE;
			dispatchEvent(editorEvent);
		}
		
		private function onSave(event:MouseEvent):void
		{
			var editorEvent:EditorEvent = new EditorEvent(EditorEvent.ITEM_SAVED,true);
			editorEvent.itemType = Nana10ItemData.SEGMENT;
			dispatchEvent(editorEvent);
			
		}
		
		public function set itemSavedSuccesfully(value:Boolean):void
		{
			if (value)
			{
				saved = true;
				saveBtn.label = "עדכון"
				deleteBtn.label = "מחיקה";
							
				previewBtn.enabled = adMarkerBtn.enabled = true;
			}
		}
		
		private function onDelete(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_DELETED));
		}
		
		private function onPreview(event:ComponentEvent):void
		{
			var editorEvent:EditorEvent;
			if (previewBtn.selected)
			{
				editorEvent = new EditorEvent(EditorEvent.PREVIEW_END,true);
			}
			else
			{
				editorEvent = new EditorEvent(EditorEvent.PREVIEW_START,true);
			}
			editorEvent.groupID = _uniqueGroupID;
			dispatchEvent(editorEvent);
		}
		
		private function onAdMarker(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ADD_SEGMENT_MARKER,true));
		}
		
		private function onSelect(event:MouseEvent):void
		{
			ExternalInterface.call("selectGroup",_uniqueGroupID);
		}
		
		/*private function onToggleBlackhole(event:Event):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_BLACKHOLE,true));	
			_saved = false;
		}*/
		
		private function onToggleDisabled(event:Event):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.ITEM_DISABLED,true));	
			_saved = false;	
		}
		
		private function onTextInputChanged(event:Event):void
		{
			_saved = false;
		}
		
		public function get title():String
		{
			return name_txt.text;
		}
		
		public function set title(value:String):void
		{
			name_txt.text = value;
		}
		
		public function get description():String
		{
			return description_txt.text;
		}
		
		public function set description(value:String):void
		{
			if (value) description_txt.text = value;
		}
		
		public function set id(value:int):void
		{
			if (value)
			{
				if (value > 0) id_txt.text = String(value);
				previewBtn.enabled = adMarkerBtn.enabled = true;
				_uniqueGroupID = value;
			}
		}
		
		public function set uniqueGroupID(value:int):void
		{
			_uniqueGroupID = value;
		}
		
		/*public function set blackHole(value:Boolean):void
		{
			blackHoleCB.selected = value;
		}
		
		public function get blackHole():Boolean
		{
			return blackHoleCB.selected;
		}*/
		
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
		
		public function set saved(value:Boolean):void
		{
			_saved = value;
			previewBtn.enabled = adMarkerBtn.enabled = value;
		}
		
		public function init():void
		{		
			saved = true;
			if (_currentGroupID)
			{
				var dataRepository:Nana10DataRepository = Nana10DataRepository.getInstance();
				var totalItems:int = dataRepository.totalItems;
				for (var i:int = 0; i < totalItems; i++)
				{
					var itemData:Nana10MarkerData = dataRepository.getItemByIndex(i);
					if (itemData.belongsToGroup(_currentGroupID) && itemData.type == Nana10ItemData.MARKER && itemData.timeCode == endTime - 0.01)
					{
						adMarkerBtn.enabled = false;
						break;
					}
				}
			}
		}
		
		public function get newItem():Boolean
		{
			return saveBtn.label == "הוספה";
		}
		
		public function setAddToGroupDisplay(groupID:int, itemID:int):void
		{
			// temporarily disabled.  first take care of the basics. this will be added later
			return;
			addToGroups.visible = groupID > 0;
			if (groupID > 0)
			{
				addToGroups.populateList(groupID,itemID);
			}
		}
		
		public function previewEnded():void
		{
			previewBtn.selected = false;
		}

		public function set currentGroupID(value:int):void
		{
			_currentGroupID = value;
		}

	}
}