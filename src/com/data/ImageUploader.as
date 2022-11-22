package com.data
{
	import com.adobe.serialization.json.JSON;
	import com.events.UploadImageEvent;
	import com.fxpn.util.Debugging;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	
	[Event (name="uploadSuccessful", type="com.events.UploadImageEvent")]
	[Event (name="uploadFailed", type="com.events.UploadImageEvent")]
	[Event (name="uploadingImage", type="com.events.UploadImageEvent")]
	public class ImageUploader extends FileReference
	{
		private var urlRequest:URLRequest;
		
		public function ImageUploader(serverURL:String)
		{			
			urlRequest = new URLRequest(serverURL + "/uploadFile");
			addEventListener(Event.SELECT,onSelect);
			addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,onLoaded);
			addEventListener(IOErrorEvent.IO_ERROR,onError);
		}
		
		public function select():void
		{
			browse();
		}
		
		private function onSelect(event:Event):void
		{		
			dispatchEvent(new UploadImageEvent(UploadImageEvent.UPLOADING_IMAGE));
			upload(urlRequest);
		}
		
		private function onLoaded(event:DataEvent):void
		{
			var data:Object = JSON.decode(event.data);
			if (data.hasOwnProperty("ActionSucceeded"))
			{
				if (data.ErrorID == 1)
				{
					dispatchEvent(new UploadImageEvent(UploadImageEvent.UPLOAD_FAILED,"העלאת התמונה נכשלה - לא ניתן להעלות תמונות מעל 100kb"));
				}
				else 
				{
					dispatchEvent(new UploadImageEvent(UploadImageEvent.UPLOAD_FAILED,"העלאת התמונה נכשלה"));
				}
			}
			else
			{
				dispatchEvent(new UploadImageEvent(UploadImageEvent.UPLOAD_SUCCESSFUL,data.FileVirtualAbsolutePath + data.FileName));
			}
		}
		
		private function onError(event:IOErrorEvent):void
		{
			dispatchEvent(new UploadImageEvent(UploadImageEvent.UPLOAD_FAILED,"העלאת התמונה נכשלה"));
			Debugging.printToConsole("Error uploading the image",event.text);
		}
	}
}