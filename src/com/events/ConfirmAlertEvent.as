/**
* events dispatched from the alert-confirm box 
*/
package com.events
{
	import flash.events.Event;

	public class ConfirmAlertEvent extends Event
	{
		//public static const REQUEST_CONFIRMATION:String = "requestConfirmation";
		public static const YES:String = "yes";
		public static const NO:String = "no";
		public static const OK:String = "ok";
		public static const CANCEL:String = "cancel";
		
		public var callbackFunction:Function;
		
		public function ConfirmAlertEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			var event:ConfirmAlertEvent = new ConfirmAlertEvent(type,bubbles,cancelable);
			event.callbackFunction = callbackFunction;
			return event;
		}
		
	}
}