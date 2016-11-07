
package com.voxelengine.GUI 
{
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.RegionManager;
import flash.geom.Vector3D;
import flash.events.Event;
import flash.display.Bitmap;
import playerio.DatabaseObject;

import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;
import org.flashapi.swing.containers.*;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.GUI.components.*;

public class WindowRegionDetail extends VVPopup
{
	private static const PADDING:int = 15;
	private static const WIDTH:int = 350;
	private static const BORDER_WIDTH:int = 4;
	private static const BORDER_WIDTH_2:int = BORDER_WIDTH * 2;
	private static const BORDER_WIDTH_4:int = BORDER_WIDTH * 4;
	
	private var _region:Region;
	private var _rbGroup:RadioButtonGroup;
	private var _rbPPGroup:RadioButtonGroup;
	private var _create:Boolean;
	private var _callBack:Class;
	private var _params:String;
	
	// Null for RegionId causes a new region to be created
	public function WindowRegionDetail( $regionID:String, $callBack:Class, $params:String = null )
	{
		_callBack = $callBack;
		_params = $params;
		
		// have to break this into 2 step for the super to work.
		var title:String;
		if ( $regionID )
			title = "Edit Region";	
		else
			title = "New Region";
		super( title );	

		autoWidth = false;
		width = WIDTH;

		if ( $regionID ) {	
			RegionEvent.addListener( ModelBaseEvent.ADDED, collectRegionInfo );
			RegionEvent.addListener( ModelBaseEvent.RESULT, collectRegionInfo );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.REQUEST, 0, $regionID ) );
		}
		else {			
			_create = true;
			_region = new Region( Globals.getUID() );
			_region.createEmptyRegion();
			_region.owner = Network.PUBLIC;
			_region.name = Network.userId + "-" + int( Math.random() * 1000 );
			_region.desc = "Please enter something meaningful here";
			markDirty();

			collectRegionInfo( new RegionEvent( ModelBaseEvent.ADDED, 0, _region.guid, _region ) );
		}
		
	}
	
	private function collectRegionInfo( $re:RegionEvent ):void 
	{
		RegionEvent.removeListener( ModelBaseEvent.ADDED, collectRegionInfo );
		RegionEvent.removeListener( ModelBaseEvent.RESULT, collectRegionInfo );
		_region =  $re.region;

		//_background = (new _backgroundImage() as Bitmap);
		//texture = _background;
		//backgroundTexture = _background;

		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		//closeButtonEnabled = false; // this show it enabled, but doesnt allow it to be clicked
		//closeButtonActive = false;  // this greys it out, and doesnt allow it to be clicked
		showCloseButton = true;
		
		addElement( new Spacer( WIDTH, 10 ) );
		addElement( new ComponentTextInput( "Name", changeNameHandler, _region.name, WIDTH ) );
		addElement( new ComponentTextArea( "Desc", changeDescHandler, _region.desc ? _region.desc : "No Description", WIDTH ) );
		
		var ownerArray:Array = [ { label:Globals.MODE_PUBLIC }, { label:Globals.MODE_PRIVATE } ];
		addElement( new ComponentRadioButtonGroup( "Owner", ownerArray, ownerChange, Network.PUBLIC == _region.owner ? 0 : 1, WIDTH ) );
		var gravArray:Array = [ { label:"Use Gravity" }, { label:"NO Gravity. " } ];
		addElement( new ComponentRadioButtonGroup( "Gravity", gravArray, gravChange,  _region.gravity ? 0 : 1, WIDTH ) );
		
		var playerPosition:Vector3D = new Vector3D( _region.playerPosition.x, _region.playerPosition.y, _region.playerPosition.z );
		addElement( new ComponentVector3DToObject( setChanged, _region.setPlayerPosition, "Player Loc", "X: ", "Y: ", "Z: ",  playerPosition, WIDTH, updateVal ) );		
		
		var playerRotation:Vector3D = new Vector3D( _region.playerRotation.x, _region.playerRotation.y, _region.playerRotation.z );
		addElement( new ComponentVector3DToObject( setChanged, _region.setPlayerRotation, "Player Rot", "X: ", "Y: ", "Z: ",  playerRotation, WIDTH, updateVal ) );		
		
		addElement( new ComponentVector3DToObject( setChanged, _region.setSkyColor, "SkyColor", "R: ", "G: ", "B: ",  _region.getSkyColor(), WIDTH, updateVal ) );		
		
		/// Buttons /////////////////////////////////////////////
		var buttonPanel:Container = new Container( WIDTH, 40 );
		buttonPanel.padding = 2;

		var _createRegionButton:Button;
		if ( _create )
			_createRegionButton = new Button( "Create", WIDTH - 10, 50 );
		else
			_createRegionButton = new Button( "Save", WIDTH - 10 );
		eventCollector.addEvent( _createRegionButton , UIMouseEvent.CLICK ,save );
		buttonPanel.layout.horizontalAlignment = LayoutHorizontalAlignment.CENTER;
		buttonPanel.addElement( _createRegionButton );

//		var cancelRegionButton:Button = new Button( "Cancel" );
//		eventCollector.addEvent( cancelRegionButton , UIMouseEvent.CLICK, cancel );
//		buttonPanel.addElement( cancelRegionButton );
		addElement( new Spacer( WIDTH, 10 ) );
		addElement( buttonPanel );
		addElement( new Spacer( WIDTH, 10 ) );
		/// Buttons /////////////////////////////////////////////
		//defaultCloseOperation = ClosableProperties.DO_NOTHING_ON_CLOSE;
		
		Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		
		defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
		// calls the close function when window shuts down, which closes the splash screen in debug.
		onCloseFunction = closeFunction;

		// This auto centers
		//_modalObj.display();
		// this does not...
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
		//display();
	}
	
	private function setChanged():void {
		_region.changed = true
	}
	
	
	private function updateVal( $e:SpinButtonEvent ):int {
		var ival:int = int( $e.target.data.text );
		if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival--;
		else 											ival++;
		$e.target.data.text = ival.toString();
		markDirty();
		return ival;
	}
	
	private function markDirty():void {
		_region.changed = true;
	}
	
	private function save( e:UIMouseEvent ):void {
		
		if ( _create ) {
//			var dboTemp:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_REGIONS, "0", "0", 0, true, null );
//			_region.dbo = dboTemp;
//			_region.toObject();
			// remove the event listeners on this temporary object
//			_region.release();
			//
			var pe:PersistanceEvent = new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, 0, Globals.BIGDB_TABLE_REGIONS, _region.guid, _region.dbo, true )
			RegionManager.instance.regionAdd( pe, _region );
			// This tell the region manager to add it to the region list
			//PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, 0, Globals.BIGDB_TABLE_REGIONS, _region.guid, _region.dbo, true ) );			
			// This tell the region to save itself!
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, 0, _region.guid ) );
		}
		else {
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.CHANGED, 0, _region.guid ) );
			// This is not the active region, so we have to save it.
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, 0, _region.guid ) );
		}
			
		closeFunction();
	}
	
	private function closeFunction():void {
		
		if ( _callBack ) {
			if ( _params )
				new _callBack( _params );
			else	
				new _callBack();
		}
		remove();
	}
	
	private function gravChange(event:ButtonsGroupEvent):void {  
		_region.gravity = (0 == event.target.index ?  true : false );
		markDirty();
	} 
	
	private function ownerChange(event:ButtonsGroupEvent):void {  
		_region.owner = (0 == event.target.index ?  Network.PUBLIC : Network.userId );
		markDirty();
	} 
	
	private function changeNameHandler(event:TextEvent):void
	{
		_region.name = event.target.text;
		markDirty();
	}
	
	private function changeDescHandler(event:TextEvent):void
	{
		_region.desc = event.target.text;
		markDirty();
	}
	

}
}