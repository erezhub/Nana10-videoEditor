package com.ui.editors
{
	import com.data.Nana10DataRepository;
	import com.data.items.Nana10MarkerData;
	import com.data.items.tagger.Nana10GroupData;
	
	import fl.controls.Button;
	import fl.controls.ComboBox;
	
	import flash.display.MovieClip;
	
	public class AddToGroup extends MovieClip
	{
		private var groups_cb1:ComboBox;
		private var addBtn1:Button;
		
		public function AddToGroup()
		{
			groups_cb1 = this["groups_cb"];
			addBtn1 = this["addBtn"];
			
			groups_cb1.dropdown.allowMultipleSelection = true;
			groups_cb1.dropdown.setStyle("cellRenderer",CheckBoxCellRenderer);
		}
		
		public function populateList(currentGroupID:int, itemID:int):void
		{
			groups_cb1.removeAll();
			var dataRepository:Nana10DataRepository = Nana10DataRepository.getInstance();
			var itemData:Nana10MarkerData = dataRepository.getItemById(itemID);
			for (var i:int = 0; i < dataRepository.totalGroups; i++)
			{
				var groupData:Nana10GroupData = dataRepository.getGroupByIndex(i);
				if (groupData.id != currentGroupID && (itemData == null || itemData.belongsToGroup(groupData.id) == false))
				{
					groups_cb1.addItem({label: groupData.title, data: groupData.id});
				}
			}
		}
	}
}