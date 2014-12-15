
package com.voxelengine.GUI 
{
import flash.geom.Vector3D;
import flash.events.Event;
import flash.display.Bitmap;

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
import com.voxelengine.events.RegionLoadedEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.GUI.components.*;

public class WindowRegionDetail extends VVPopup
{
	private static const PADDING:int = 15;
	private static const WIDTH:int = 300;
	private static const BORDER_WIDTH:int = 4;
	private static const BORDER_WIDTH_2:int = BORDER_WIDTH * 2;
	private static const BORDER_WIDTH_4:int = BORDER_WIDTH * 4;
	
	private var _region:Region;
	private var _rbGroup:RadioButtonGroup;
	private var _rbPPGroup:RadioButtonGroup;
	private var _create:Boolean;
	
	//private var _background:Bitmap;
	//[Embed(source='../../../../../Resources/bin/assets/textures/black.jpg')]
	//private var _backgroundImage:Class;
	
	public function WindowRegionDetail( $region:Region )
	{
		var title:String;
		if ( $region ) 	title = "Edit Region";
		else			title = "New Region";
		super( title );	
		
		//_background = (new _backgroundImage() as Bitmap);
		//texture = _background;
		//backgroundTexture = _background;

		autoSize = true;
		layout.orientation = LayoutOrientation.VERTICAL;
		//closeButtonEnabled = false; // this show it enabled, but doesnt allow it to be clicked
		//closeButtonActive = false;  // this greys it out, and doesnt allow it to be clicked
		
		if ( $region ) {
			_region = $region;
		}
		else {
			_create = true
			_region = new Region( Globals.getUID() );
			_region.createEmptyRegion();
			_region.owner = Network.PUBLIC;
			_region.gravity = true;
			_region.name = Network.userId + "-" + int( Math.random() * 1000 );
			_region.desc = "Please enter something meaningful here";
			_region.changed = true;
			_region.admin.push( Network.userId );
			_region.editors.push( Network.userId );
		}

		addElement( new Spacer( WIDTH, 10 ) );
		addElement( new ComponentTextInput( "Name", changeNameHandler, _region.name, WIDTH ) );
		addElement( new ComponentTextArea( "Desc", changeDescHandler, _region.desc ? _region.desc : "No Description", WIDTH ) );
		
		var ownerArray:Array = [ { label:Globals.MODE_PUBLIC }, { label:Globals.MODE_PRIVATE } ];
		addElement( new ComponentRadioButtonGroup( "Owner", ownerArray, ownerChange, Network.PUBLIC == _region.owner ? 0 : 1, WIDTH ) );
		var gravArray:Array = [ { label:"Use Gravity" }, { label:"NO Gravity. " } ];
		addElement( new ComponentRadioButtonGroup( "Gravity", gravArray, gravChange,  _region.gravity ? 0 : 1, WIDTH ) );
		
		var playerStartingPosition:ComponentVector3D = new ComponentVector3D( "Player Starting Location", "X: ", "Y: ", "Z: ",  _region.playerPosition );
		addElement( playerStartingPosition );
		
		var playerStartingRotation:ComponentVector3D = new ComponentVector3D( "Player Starting Rotation", "X: ", "Y: ", "Z: ",  _region.playerRotation );
		addElement( playerStartingRotation );
		
		var skyColor:ComponentVector3D = new ComponentVector3D( "Sky Color", "Red: ", "Green: ", "Blue: ",  _region.getSkyColor() );
		addElement( skyColor );
		
		/// Buttons /////////////////////////////////////////////
		var buttonPanel:Container = new Container( WIDTH, 40 );
		buttonPanel.padding = 2;

		var _createRegionButton:Button;
		if ( _create )
			_createRegionButton = new Button( "Create", WIDTH - 10 );
		else
			_createRegionButton = new Button( "Save", WIDTH - 10 );
		eventCollector.addEvent( _createRegionButton , UIMouseEvent.CLICK ,create );
		buttonPanel.addElement( _createRegionButton );

//		var cancelRegionButton:Button = new Button( "Cancel" );
//		eventCollector.addEvent( cancelRegionButton , UIMouseEvent.CLICK, cancel );
//		buttonPanel.addElement( cancelRegionButton );
		addElement( buttonPanel );
		/// Buttons /////////////////////////////////////////////
		defaultCloseOperation = ClosableProperties.DO_NOTHING_ON_CLOSE;
		
		$evtColl.addEvent( this, WindowEvent.CLOSE_BUTTON_CLICKED, cancel );
		Globals.g_app.stage.addEventListener(Event.RESIZE, onResize);
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		
		// This auto centers
		//_modalObj.display();
		// this does not...
		display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
		//display();
	}
	
	private function create( e:UIMouseEvent ):void {
		
		if ( _create )
			Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_CREATED, _region ) );
		else {
			_region.saveEdit();
		}
			
		remove();
		new WindowSandboxList();
	}
	
	private function cancel( e:WindowEvent ):void {
		
		remove();
		new WindowSandboxList();
	}
	
	private function gravChange(event:ButtonsGroupEvent):void {  
		_region.gravity = (0 == event.target.index ?  true : false );
	} 
	
	private function ownerChange(event:ButtonsGroupEvent):void {  
		_region.owner = (0 == event.target.index ?  Network.PUBLIC : Network.userId );
	} 
	
	private function changeNameHandler(event:TextEvent):void
	{
		_region.name = event.target.text;
	}
	
	private function changeDescHandler(event:TextEvent):void
	{
		_region.desc = event.target.text;
	}
	

}
}