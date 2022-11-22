package com.ui
{
	import cinabu.HebrewTextHandling;
	
	import com.events.ConfirmAlertEvent;
	import com.fxpn.display.ModalManager;
	import com.fxpn.display.ShapeDraw;
	import com.fxpn.util.Debugging;
	import com.fxpn.util.DisplayUtils;
	
	import fl.controls.Button;
	
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;
	
	import resources.AlertBoxVisuals;
	
	public class AlertBox extends AlertBoxVisuals
	{				
		//private static var _instance:AlertBox;
		
		private var btnsContainer:Sprite;
		private var okBtn:Button;
		private var yesBtn:Button;
		private var noBtn:Button;
		private var cancelBtn:Button;
		private static var _stage:Stage;
				
		public function AlertBox(stage:Stage)
		{
			/*if (_instance)
			{
				throw new Error("AlertBox can only be accessed through AlertBox.getInstance()");
			}
			else
			{*/
				btnsContainer = new Sprite();
				addChild(btnsContainer);
				okBtn = createButton("אישור",onOk);
				yesBtn = createButton("כן",onYes);
				noBtn = createButton("לא",onNo);
				cancelBtn = createButton("ביטול",onCancel);
				_stage = stage;
				_txt.autoSize = TextFieldAutoSize.CENTER;
				HebrewTextHandling.actHTML = true;
				ModalManager.allowContextMenu = true;
			//}
		}
		
		private function createButton(label:String,clickFunction:Function):Button
		{
			var button:Button = new Button();
			button.label = label;
			button.addEventListener(MouseEvent.CLICK,clickFunction);
			button.width = 50;
			return button;
		}
		
		/*public static function getInstance(stage:Stage):AlertBox
		{
			if (_instance==null)
			{
				_instance = new AlertBox();
				_stage = stage;
			}
			return _instance;
		}*/
		
		/**
		 * displays a simple alert box, with 'ok' button 
		 * @param message(String) a message to display to the user
		 * @param dissable(boolean) when true the 'ok' button is dissabled
		 * 
		 */		
		public function displayAlert(message:String, dissabled:Boolean = false):void
		{
			display(message);
			btnsContainer.addChild(okBtn);
			okBtn.mouseEnabled = okBtn.enabled = !dissabled;			
			btnsContainer.x = (bg.width - okBtn.width)/2;
			btnsContainer.y =  bg.height - 10 - okBtn.height;
		}
		
		/**
		 * displays a confirmation box, with yes/no/cancel options 
		 * @param message(String) - a message to display to the user.  default value - "Are you sure?"
		 */		
		public function displayConfirmation(message:String = "?בטוח/ה", showCancel:Boolean = true):void
		{
			display(message);
			btnsContainer.addChild(yesBtn);
			btnsContainer.addChild(noBtn);
			noBtn.x = yesBtn.x + yesBtn.width + 10;
			if (showCancel)
			{
				btnsContainer.addChild(cancelBtn);
				cancelBtn.x = noBtn.x + noBtn.width + 10;
			}
			
			var realWidth:Number = yesBtn.width * (showCancel ? 3 : 2) + 20;
			btnsContainer.x = (bg.width - realWidth)/2;
			btnsContainer.y =  bg.height - 10 - yesBtn.height;
		}
		
		private function display(message:String):void
		{
			_txt.text = HebrewTextHandling.reverseString(message,25);
			clearButtons();	
			bg.height = _txt.y + _txt.textHeight + 20 + okBtn.height + _txt.y;
			_stage.addChild(this);
			DisplayUtils.align(stage,this);
			ModalManager.setModal(this);
		}
		
		private function clearButtons():void
		{
			var totalBtns:int = btnsContainer.numChildren - 1;
			for (var i:int = totalBtns; i >=0; i--)
			{
				btnsContainer.removeChildAt(i);
			}
		}
		
		private function onOk(event:MouseEvent):void
		{
			removeMe();
			dispatchEvent(new ConfirmAlertEvent(ConfirmAlertEvent.OK));	
		}
		
		private function onYes(event:MouseEvent):void
		{
			removeMe();
			dispatchEvent(new ConfirmAlertEvent(ConfirmAlertEvent.YES));	
		}
		
		private function onNo(event:MouseEvent):void
		{
			removeMe();
			dispatchEvent(new ConfirmAlertEvent(ConfirmAlertEvent.NO));	
		}
		
		private function onCancel(event:MouseEvent):void
		{
			removeMe();
			dispatchEvent(new ConfirmAlertEvent(ConfirmAlertEvent.CANCEL));	
		}
		
		private function removeMe():void
		{
			stage.removeChild(this);
			ModalManager.clearModal();
		}
	}
}