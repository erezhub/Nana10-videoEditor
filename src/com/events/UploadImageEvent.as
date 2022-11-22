package com.events
{
	import flash.events.Event;
	
	public class UploadImageEvent extends Event
	{
		public static const UPLOADING_IMAGE:String = "uploadingImage";
		public static const UPLOAD_SUCCESSFUL:String = "uploadSuccessful";
		public static const UPLOAD_FAILED:String = "uploadFailed";
		
		public var filePath:String;
		public var errorMessage:String
		
		public function UploadImageEvent(type:String, pathOrError:String = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			if (type == UPLOAD_SUCCESSFUL)
			{
				filePath = pathOrError;
			}
			else if (type == UPLOAD_FAILED)
			{
				errorMessage = pathOrError;
			}
		}
		
		override public function clone():Event
		{
			var event:UploadImageEvent;
			if (type == UPLOAD_SUCCESSFUL)
			{
				event = new UploadImageEvent(type, filePath, bubbles,cancelable);
			}
			else if (type == UPLOAD_FAILED)
			{
				event = new UploadImageEvent(type,errorMessage,bubbles,cancelable);
			}
			else
			{
				event = new UploadImageEvent(type,null,bubbles,cancelable);
			}
			return event;
		}
	}
}