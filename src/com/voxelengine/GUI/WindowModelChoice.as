/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.GUI
{
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
		private var _rbGroup:RadioButtonGroup = null;
		private var _cbSize:ComboBox  = new ComboBox();;
		private var _cbDetail:ComboBox  = new ComboBox();
		private var _cbType:ComboBox  = new ComboBox();;
		
		public function WindowModelChoice()
		{
			super( LanguageManager.localizedStringGet( "Model Choice" ) );

			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			populateSizeAndDetail( 0 );
			
			_rbGroup = new RadioButtonGroup( this );
			eventCollector.addEvent( _rbGroup, ButtonsGroupEvent.GROUP_CHANGED, modelTypeChanged  );
			var radioButtons:DataProvider = new DataProvider();
//            radioButtons.addAll( { label:"My Models" }, { label:"All Models" }, { label:"From Cube" }, { label:"From Model Template" }, { label:"New Model Template" } );
            radioButtons.addAll( { label:"From Cube" }, { label:"From Sphere" }, { label:"From SubSphere" } );
			_rbGroup.dataProvider = radioButtons;
			_rbGroup.index = 0;
			
			var panel:Panel = new Panel( 200, 80);
            panel.autoSize = true;
			panel.layout.orientation = LayoutOrientation.VERTICAL;
			
			var sizeContainer:Container = new Container( width, 50 );
			sizeContainer.layout.orientation = LayoutOrientation.HORIZONTAL;
			var grainContainer:Container = new Container( width/2, 50 );
			grainContainer.layout.orientation = LayoutOrientation.VERTICAL;
			grainContainer.addElement( new Label( "Size in Meters" ) );
			grainContainer.addElement( _cbSize );
			eventCollector.addEvent( _cbSize, ListEvent.LIST_CHANGED, sizeChange );
			
			var detailContainer:Container = new Container( width / 2, 50 );
			detailContainer.layout.orientation = LayoutOrientation.VERTICAL;
			detailContainer.addElement( new Label( "Smallest Block in Meters" ) );
			detailContainer.addElement( _cbDetail );
			sizeContainer.addElement( grainContainer );
			sizeContainer.addElement( detailContainer );
			panel.addElement(sizeContainer);
			
			panel.addElement( new Label( "Made of Type" ) );
			_cbType = new ComboBox();
			var item:TypeInfo;
			for ( var i:int = TypeInfo.MIN_TYPE_INFO; i < TypeInfo.MAX_TYPE_INFO; i++ )
			{
				item = TypeInfo.typeInfo[i];
				if ( null == item )
					continue;
				if ( "INVALID" != item.name && "BRAND" != item.name && -1 == item.name.indexOf( "EDIT" ) && item.placeable )
					_cbType.addItem( item.name, item.type );
//				else	
//					Log.out( "WindowModelChoice.construct - rejecting: " + item.name, Log.WARN );
			}
			
			_cbType.selectedIndex = 0;
			panel.addElement( _cbType );
			
			addElement( panel );
			
			var button:Button = new Button( "Create" );
			eventCollector.addEvent( button, UIMouseEvent.CLICK, create );
			addElement( button );
			
			display();
        }
		
		private function sizeChange(e:ListEvent):void 
		{
			updateDetail( e.target.selectedIndex );
		}
		
		private function populateSizeAndDetail( index:int ):void {
			for ( var i:int = 0; i < 12; i++ )
			{
				_cbSize.addItem( (1<<i)/16, i );
			}
			_cbSize.selectedIndex = 5;
			
			for ( var j:int = 0; j < 12; j++ )
			{
				_cbDetail.addItem( (1<<j)/16, j );
			}
			_cbDetail.selectedIndex = 0;
		}
		
		private function updateDetail( selectedIndex:int ):void {
			if ( 1 < selectedIndex )
				_cbDetail.selectedIndex = Math.max( 0 , selectedIndex - 4 );
			else	
				_cbDetail.selectedIndex = 0;
		}
		
		private function modelTypeChanged( bge:ButtonsGroupEvent ):void {
			if ( 0 == bge.target.index )
				_cbDetail.visible = false;
			else	
				_cbDetail.visible = true;
		}
		
		private function create( e:UIMouseEvent ):void
		{
			createWindow( _rbGroup.index );
			remove();
		}

		private function createWindow( id:int ):void
		{
			var ii:InstanceInfo = new InstanceInfo();
			var detailSize:int;		
			var li:ListItem;
			var miJson:Object;
			if ( -1 == _cbSize.selectedIndex ) {
				(new Alert( "Please select a size" ) ).display();
				return;
			}
			switch ( id )
			{
				case 0: // From Cube
					// This data really needs to be used to generate the whole window.
					miJson = GenerateCube.script();
					
					li = _cbSize.getItemAt(_cbSize.selectedIndex );
					miJson.model.grainSize = li.data;
					miJson.model.biomes.layers[0].offset = li.data;
					
					li = _cbType.getItemAt( _cbType.selectedIndex );
					miJson.model.biomes.layers[0].type = li.data;
					
					li = _cbDetail.getItemAt(_cbDetail.selectedIndex );
					miJson.model.biomes.layers[0].range = 0;
					
					break;
				case 1: // From Sphere
					//ii.modelGuid = "GenerateSphere";
					//li = _cbDetail.getItemAt(_cbDetail.selectedIndex );
					//detailSize = li.data;			
					//miJson = GenerateSphere.script();
					break;
				case 2: // From Sphere
					//ii.modelGuid = "GenerateSubSphere";
					//li = _cbDetail.getItemAt(_cbDetail.selectedIndex );
					//detailSize = li.data;			

					break;
			}
			
			var vv:Vector3D = ModelCacheUtils.viewVectorNormalizedGet();
			vv.scaleBy( GrainCursor.two_to_the_g( miJson.grainSize ) * 4 );
			vv = vv.add( VoxelModel.controlledModel.instanceInfo.positionGet );
			ii.positionSet = vv;
			// this needs to be key for database.
			ii.modelGuid = miJson.model.guid = Globals.getUID();
			
			new ModelMakerGenerate( ii, miJson );
		}
	}
}
