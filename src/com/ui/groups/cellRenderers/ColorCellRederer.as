package com.ui.groups.cellRenderers
{
	import com.fxpn.display.ShapeDraw;
	
	import fl.controls.listClasses.CellRenderer;
	
	import flash.display.Shader;
	import flash.display.Shape;
	
	public class ColorCellRederer extends CellRenderer
	{		
		private var colorBox:Shape;
		public function ColorCellRederer()
		{
			super();
		}
		
		override public function set data(arg0:Object):void
		{
			if (colorBox != null) removeChild(colorBox);
			if (arg0.hasOwnProperty("color"))
			{
				//var color:int = arg0.blackhole ? 0x444444 : arg0.color;
				colorBox = ShapeDraw.drawSimpleRectWithFrame(height/2,height/2,arg0.color);
				colorBox.y = height/4;
				colorBox.x = (width - colorBox.width)/2;
				addChild(colorBox);
			}
			else
			{
				colorBox = null;
			}
		}
	}
}