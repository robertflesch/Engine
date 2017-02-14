/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
import com.voxelengine.GUI.panels.*;
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.tasks.landscapetasks.*;
import flash.accessibility.Accessibility;
import flash.geom.Vector3D;

import org.flashapi.swing.*;
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;
import org.flashapi.swing.containers.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.GUI.voxelModels.WindowModelDetail;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class WindowModelChoice extends VVPopup
{
	private var _rbGroup:RadioButtonGroup
	private var _panelContainer:Container
	private var _name:String = "Default"
	
	public function WindowModelChoice()
	{
		super( LanguageManager.localizedStringGet( "Model Choice" ) );

		autoSize = true;
		padding = 10
		layout.orientation = LayoutOrientation.VERTICAL;
		
		_rbGroup = new RadioButtonGroup( this );
		eventCollector.addEvent( _rbGroup, ButtonsGroupEvent.GROUP_CHANGED, modelTypeChanged  );
		var radioButtons:DataProvider = new DataProvider();
//            radioButtons.addAll( { label:"My Models" }, { label:"All Models" }, { label:"From Cube" }, { label:"From Model Template" }, { label:"New Model Template" } );
		radioButtons.addAll( { label:"Cube" }, { label:"Sphere" }, { label:"Island" }); // , { label:"From SubSphere" } 
		_rbGroup.dataProvider = radioButtons;
		addElement( new Spacer( width, 15 ) );
		
		_panelContainer = new Container( width );
		_panelContainer.autoSize = true;
		_panelContainer.layout.orientation = LayoutOrientation.VERTICAL;
		addElement( _panelContainer );
		
		addElement( new Spacer( width, 15 ) );
		var button:Button = new Button( "Create" );
		eventCollector.addEvent( button, UIMouseEvent.CLICK, function ( e:UIMouseEvent ):void { createObject(); remove(); } );
		addElement( button );
		
		// Now set the default object creation method to be Cube
		_rbGroup.index = 0;
		
		display();
	}
	
	private function modelTypeChanged( bge:ButtonsGroupEvent ):void {
		if ( _panelContainer && _panelContainer.numElements ) {
			_panelContainer.removeElements()
		}
		if ( 0 == bge.target.index ) {
			panelCreateModel()
		}
		else if ( 1 == bge.target.index )
			panelCreateSphere()
		else if ( 2 == bge.target.index )
			panelGenerateIsland()
	}

	private function createObject():void {
		var ii:InstanceInfo = new InstanceInfo();
		var detailSize:int;		
		var model:Object
		switch ( _rbGroup.index ) {
			case 0: // From Cube
				model = GenerateCube.script();
				parameters( model )
				break;
			case 1: // Sphere
				model = GenerateSphere.script();
				parameters( model )
				break;
			case 2: // Island
				model = GenerateIsland.script();
				parameters( model )
				ii.modelGuid = model.name
				break;
//				case 2: // From Sphere
				//ii.modelGuid = "GenerateSubSphere";
				//li = _cbDetail.getItemAt(_cbDetail.selectedIndex );
				//detailSize = li.data;			

				break;
		}
		
		var vv:Vector3D = ModelCacheUtils.viewVectorNormalizedGet();
		vv.scaleBy( GrainCursor.two_to_the_g( model.grainSize ) + 200 );
		vv = vv.add( VoxelModel.controlledModel.instanceInfo.positionGet );
		ii.positionSet = vv;
		// this needs to be key for database.
		ii.modelGuid = Globals.getUID();
		
		new ModelMakerGenerate( ii, model );

	}
	
	private var _cbType:ComboBox  = new ComboBox()
	private function addType( $label:String ):void {
		_cbType  = new ComboBox()
		var typeContainer:Container = new Container( width/2, 50 );
		typeContainer.layout.orientation = LayoutOrientation.VERTICAL;
		typeContainer.addElement( new Label( $label ) );
		typeContainer.addElement( _cbType );
		var item:TypeInfo;
		for ( var i:int = TypeInfo.MIN_TYPE_INFO; i < TypeInfo.MAX_TYPE_INFO; i++ ) {
			item = TypeInfo.typeInfo[i];
			if ( null == item )
				continue;
			if ( "INVALID" != item.name && "BRAND" != item.name && -1 == item.name.indexOf( "EDIT" ) && item.placeable )
				_cbType.addItem( item.name, item.type );
//				else	
//					Log.out( "WindowModelChoice.construct - rejecting: " + item.name, Log.WARN );
		}
		
		_cbType.selectedIndex = 0;
		_panelContainer.addElement( typeContainer );
	}
	
	private var _cbSize:ComboBox  = new ComboBox()
	private function addSize( $label:String, $low:int, $high:int, $selectedIndex:int ):void {
		_cbSize = new ComboBox()
		var grainContainer:Container = new Container( width/2, 50 );
		grainContainer.layout.orientation = LayoutOrientation.VERTICAL;
		grainContainer.addElement( new Label( $label ) );
		grainContainer.addElement( _cbSize );
		for ( var i:int = $low; i < $high; i++ )
			_cbSize.addItem( (1 << i) / 16, i );
		//if ( $high - $low >= $selectedIndex )
			//_cbSize.selectedIndex = $selectedIndex;
		//else
			_cbSize.selectedIndex = 0
		_panelContainer.addElement( grainContainer )
	}
	
	private var _cbDetail:ComboBox  = new ComboBox()
	private function addDetail( $label:String, $low:int, $high:int, $selectedIndex:int ):void {
		_cbDetail = new ComboBox()
		var detailContainer:Container = new Container( width / 2, 50 );
		detailContainer.layout.orientation = LayoutOrientation.VERTICAL;
		detailContainer.addElement( new Label( $label ) );
		detailContainer.addElement( _cbDetail );
		for ( var i:int = $low; i <= $high; i++ )
			_cbDetail.addItem( (1<<i)/16, i );
		//if ( $high - $low >= $selectedIndex )
			//_cbDetail.selectedIndex = $selectedIndex
		//else
			_cbDetail.selectedIndex = 0
		_panelContainer.addElement( detailContainer )
	}
	
	private function reset():void	{
		if ( _cbSize ) {
			_cbSize.remove()
			_cbSize = null
		}
		if ( _cbDetail ) {
			_cbDetail.remove()
			_cbDetail = null
		}
		if ( _cbType ) {
			_cbType.remove()
			_cbType = null
		}
		_panelContainer.removeElements()
	}

	private function panelGenerateIsland():void	{
		reset()
		_name = "GenerateIsland"
		addSize("Island size in meters", 6, 13, 4 );	
		addDetail( "Smallest Block in Meters", 3, 5, 2 );	
	}
	
	private function panelCreateModel():void {
		reset()
		_name = "GenerateModel"
		addSize( "Size in meters", 4, 12, 6 )
		addType( "Made of Type" )
	}
	
	private function panelCreateSphere():void {
		reset()
		_name = "GenerateSphere"
		addSize( "Size in meters", 4, 12, 6 )
		addDetail( "Smallest Block in Meters", 3, 5, 2 );	
		addType( "Made of Type" )
	}
	
	private function parameters( $model:Object ):Object {
		$model.name = _name
		var li:ListItem
		if ( _cbSize ) {
			li = _cbSize.getItemAt(_cbSize.selectedIndex )
			$model.grainSize = li.data
			$model.biomes.layers[0].offset = li.data;
		}
		if ( _cbDetail ) {
			li = _cbDetail.getItemAt(_cbDetail.selectedIndex )
			$model.smallestGrain = li.data
			$model.biomes.layers[0].range = li.data
		}
		if ( _cbType ) {
			li = _cbType.getItemAt( _cbType.selectedIndex );
			$model.biomes.layers[0].type = li.data;
		}
		return $model
	}
	
	/*
	private function sizeChange(e:ListEvent):void  {
		updateDetail( e.target.selectedIndex );
	}
	
	private function updateDetail( selectedIndex:int ):void {
		if ( 1 < selectedIndex )
			_cbDetail.selectedIndex = Math.max( 0 , selectedIndex - 4 );
		else	
			_cbDetail.selectedIndex = 0;
	}
	*/
}
}

