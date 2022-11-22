package com.ui.editors
{
	public interface IItemEditor
	{
		function set currentTime(value:Number):void
		function get currentTime():Number
		function set endTime(value:Number):void
		function get title():String;
		function set title(value:String):void;
		function get saved():Boolean;
		function set dissabled(value:Boolean):void
		function get dissabled():Boolean;
		function clear():void;
		function set saveBtnLabel(txt:String):void
		function init():void
		function get newItem():Boolean
		function set itemSavedSuccesfully(value:Boolean):void
		function set currentGroupID(value:int):void
	}
}