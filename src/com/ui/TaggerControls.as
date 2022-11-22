package com.ui
{
	import com.data.TaggerVersion;
	import com.events.EditorEvent;
	import com.fxpn.util.DisplayUtils;
	
	import fl.controls.Button;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	public class TaggerControls extends Sprite
	{
		private var saveBtn:Button;
		private var groupBtn:Button;
		//private var markerBtn:Button;
		//private var segmentBtn:Button;
		private var title:TextField;
		
		public function TaggerControls()
		{
			/*addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void
		{*/
			title = new TextField();
			var fmt:TextFormat = new TextFormat("Arial",14);			
			fmt.align = TextFormatAlign.RIGHT;
			title.defaultTextFormat = fmt;
			title.text = "V" + TaggerVersion.VERSION  + " (C) עורך הוידיאו של נענע10";
			title.autoSize = TextFieldAutoSize.CENTER;	
			addChild(title);
			
			saveBtn = new Button();
			saveBtn.label = "שמירה"; 
			var saveFmt:TextFormat = new TextFormat("Verdana",16,0xff0000,true);
			saveBtn.setStyle("textFormat",saveFmt);
			addChild(saveBtn);
			saveBtn.addEventListener(MouseEvent.CLICK,onSave);
			
			groupBtn = new Button();
			groupBtn.label = "הוספת קבוצה";
			groupBtn.addEventListener(MouseEvent.CLICK, onAddGroup);
			addChild(groupBtn);
			
			DisplayUtils.align(saveBtn,title,false);
			//DisplayUtils.spacialAlign(stage,groupBtn,DisplayUtils.RIGHT,30);			
			
			/*segmentBtn = new Button();
			segmentBtn.label = "הוספת מקטע";
			segmentBtn.addEventListener(MouseEvent.CLICK, onAddSegment);
			segmentBtn.x = groupBtn.x - segmentBtn.width - 5;
			addChild(segmentBtn);
			
			markerBtn = new Button();
			markerBtn.label = "הוספת סמן";
			markerBtn.addEventListener(MouseEvent.CLICK,onAddMarker);
			markerBtn.x = segmentBtn.x - markerBtn.width - 5;
			addChild(markerBtn);*/
			
		}	
		
		private function onSave(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.MAIN_SAVE));
		}
		
		private function onAddGroup(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.GROUP_ADDED));
		}
		
		
		private function onAddMarker(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.MARKER_ADDED));	
		}
		
		private function onAddSegment(event:MouseEvent):void
		{
			dispatchEvent(new EditorEvent(EditorEvent.SEGMENT_ADDED));
		}
		
		override public function get height():Number
		{
			return saveBtn.height;
		}
		
		override public function set mouseChildren(enable:Boolean):void
		{
			groupBtn.enabled = /*segmentBtn.enabled = markerBtn.enabled =*/ false;
		}
		
		override public function set width(value:Number):void
		{
			groupBtn.x = saveBtn.width + 10;
			title.x = value - title.width;
		}
	}
}