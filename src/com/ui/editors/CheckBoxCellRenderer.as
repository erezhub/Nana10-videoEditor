package com.ui.editors
{
	import fl.controls.CheckBox;
	import fl.controls.listClasses.ICellRenderer;
	import fl.controls.listClasses.ListData;
	
	public class CheckBoxCellRenderer extends CheckBox implements ICellRenderer
	{
		private var _listData:ListData;
		private var _data:Object;

		public function CheckBoxCellRenderer()
		{
			super();
		}
		
		public function set listData(ld:ListData):void 
		{
			_listData = ld;
		}
		
		public function get listData():ListData 
		{
			return _listData;
		}
		
		public function get data():Object
		{
			return _data;
		}
		
		public function set data(d:Object):void
		{
			_data = d;
			label = d.label;

		}
	}
}