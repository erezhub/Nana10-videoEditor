package com.data
{
	public class TaggerVersion
	{
		public static const VERSION:String = "1.4.20121009.1";
		
		/*
		1.1.20110906
			- segments' color are saved
			- all items in default group can be offsetted together
			- added support for 'tab' button in all forms
			- added loading animation
			- fixed bug - data couldn't be saved when new item was added, and edited again after addition
			- segments can't be saved if they overlap each other
			- added support for the debugger's console
		
		1.1.20110914
			- when loading a video for the first time - segments get their color not from the data repository
		
		1.1.20110919
			- fixed bug which prevented the saving of markers (Color property is set to 0 instead of null)
			- added support for book-mark items (which is a sub-type of the marker)
			- fixed a preview bug
		
		1.1.20111205
			- added support for live stream
		
		1.1.20111206
			- when saving - making sure at least one item (group/item) has status = 1 (not hidden)
			- in live stream - disabling the timeline and all buttons on the group editor, except of the status check-box
		
		1.2.20111228
			- replaced visuals of the playhead and selected groups
			- when previewing a segment - skipping within the segment won't stop the preview
			- after adding an item - the playhead doesn't automatically jump to its beginning
			- after save - if the current segment is a new one - updating the id field in the segment editor 
		
		1.2.20120315
			- added volume-slider to the volume control
		
		1.3.20120329
			- segments' preview button on state is more stressed.
			- group preview fixed, displays CM8 adds only on non-automatic markers
			- right-click menu is available when modal messages pop
			- not allowing to save when new groups don't have name
			- if streaming video link isn't available yet - using the LQ link (and all the seek mechanism is adapted for that)
		
		1.3.20120401
			- when streaming link isn't ready - an internal error message is displayed
			- default segments' (when the default playlist URL has no segments) status is set to 1
		
		1.3.20120402
			- more progressive-download related bugs fixed:  selecting an item (and seeking to that point) and adding a new item
		
		1.4.20120524
			- removed 'keywords' field from groups' editor
			- default's group title and description are drawn from the video's title and description
		
		1.4.20120529
			- changed UI so that the 'add marker/segment' buttons are within the group's controls (and moved the 'save' and 'add group' button to the top of the tagger
			- when a new segment is added - it takes its name from the group cotaining it (so adding a new segment is not allowed untill the group is named)
		
		1.4.20120530
			- when the video is paused and then seeked - updating the video display manually, otherwise it won't get updated
			- enabling the seek buttons only after the video date is ready - cause otherwise the 'videoStreamingPathReady' of the data repository isn't set yet
		
		1.4.20120603
			- when opening a video for the first time - the default group's status is set to 1 (thus its not hidden)
			- fixed all sorts of preview-related bugs in the new player
		
		1.4.20120604
			- before preview - either a segment or a group - the video player is paused
			- when the player is removed from stage - the keyboard shortcuts manager is disabled
			- when a clip loads for the first time and it doesn't have default playlist url - setting the group's title and description from the video
			- a default segment is editable
		
		1.4.20120612
			- default-group's items aren't editable (only via group-offset control)
			- when a group is duplicated, the duplication isn't hidden by default, and all its items' names are added with '_duplication'
		
		1.4.20120614
			- added time-out (20sec) to the save oppertion
			- fixed saving procedure of a new segment, so its own id and its unique-group id won't mix up (which prevented the preview of a segment right after it was saved)
			- moreover, when a new item is added - the current-items array in the group object, is updated with the item's new id
		
		1.4.20121009
			- added new button in the segment editor, which allows adding a marker 10 miliseconds before the end of the segemnt (button is disabled if segment isn't saved, or there's already a marker at its end)
			- when selecting a different group than the current one - making sure the current item was saved
		*/
	}
}