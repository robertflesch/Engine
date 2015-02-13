
package com.voxelengine.GUI
{
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.ModelManager;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.accessibility.Accessibility;
	import flash.geom.Vector3D;
	import org.flashapi.swing.*;
	import org.flashapi.swing.button.RadioButtonGroup;
	import org.flashapi.swing.databinding.DataProvider;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	import org.flashapi.swing.containers.*;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.ModelInfo;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	
	public class WindowModelChoice extends VVPopup
	{
		private var _rbGroup:RadioButtonGroup = null;
		private var _cbSize:ComboBox;
		private var _cbType:ComboBox;
		
		public function WindowModelChoice()
		{
			super( "Model Choice" );

			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			_rbGroup = new RadioButtonGroup( this );
			var radioButtons:DataProvider = new DataProvider();
//            radioButtons.addAll( { label:"My Models" }, { label:"All Models" }, { label:"From Cube" }, { label:"From Model Template" }, { label:"New Model Template" } );
            radioButtons.addAll( { label:"From Cube" }, { label:"From Sphere" }, { label:"From SubSphere" } );
			_rbGroup.dataProvider = radioButtons;
			_rbGroup.index = 0;
			
			var panel:Panel = new Panel( 200, 80);
            panel.autoSize = true;
			panel.layout.orientation = LayoutOrientation.VERTICAL;
			
			var size:Label = new Label( "Size in meters" )
			size.fontSize = 14;
			panel.addElement( size );
			_cbSize = new ComboBox( "Size in meters" );
			
			for ( var j:int = 4; j < 12; j++ )
			{
				_cbSize.addItem( String(1<<(j-4)), j );
			}
			_cbSize.selectedIndex = 0;
			panel.addElement( _cbSize );
			
			var madeOfType:Label = new Label( "Made of Type" )
			madeOfType.fontSize = 14;
			panel.addElement( madeOfType );
			_cbType = new ComboBox( "Made Of" );
			
			var item:TypeInfo;
			for ( var i:int = TypeInfo.MIN_TYPE_INFO; i < TypeInfo.MAX_TYPE_INFO; i++ )
			{
				item = TypeInfo.typeInfo[i];
				if ( null == item )
					continue;
				if ( "INVALID" != item.name && "AIR" != item.name && "BRAND" != item.name && -1 == item.name.indexOf( "EDIT" ) && item.placeable )
				{
					_cbType.addItem( item.name, item.type );
				}
			}
			
			_cbType.selectedIndex = 0;
			panel.addElement( _cbType );
			
			addElement( panel );
			
			var button:Button = new Button( "Create" );
			eventCollector.addEvent( button, UIMouseEvent.CLICK, create );
			addElement( button );
			
			display();
        }
		
		private function create( e:UIMouseEvent ):void
		{
			//_modalObj.remove();
			//_modalObj = null;
			createWindow( _rbGroup.index );
			remove();
		}

		private function createWindow( id:int ):void
		{
			var ii:InstanceInfo = new InstanceInfo();
			switch ( id )
			{
				case 0: // From Cube
					ii.guid = "GenerateCube";
					//ii.name = "New Cube Object";
					// preload the modelInfo for the GenerateCube
					ModelLoader.modelInfoPreload( ii.guid );
					break;
				case 1: // From Sphere
					ii.guid = "GenerateSphere";
					//ii.name = "New Sphere Object";
					// preload the modelInfo for the GenerateCube
					ModelLoader.modelInfoPreload( ii.guid );
					break;
				case 2: // From Sphere
					ii.guid = "GenerateSubSphere";
					//ii.name = "Sphere in larger Object";
					// preload the modelInfo for the GenerateCube
					ModelLoader.modelInfoPreload( ii.guid );
					break;
			}
			
			if ( -1 == _cbSize.selectedIndex ) {
				(new Alert( "Please select a size" ) ).display();
				return;
			}
			var li:ListItem = _cbSize.getItemAt(_cbSize.selectedIndex );
			var size:int = li.data;			
			var liType:ListItem = _cbType.getItemAt( _cbType.selectedIndex );
			var type:int = liType.data;			
			ii.grainSize = size;
			ii.type = type;
			var viewDistance:Vector3D = new Vector3D(0, 0, -75 - (1<<size)/2 );
			ii.positionSet = Globals.controlledModel.instanceInfo.worldSpaceMatrix.transformVector( viewDistance );
			Globals.g_app.addEventListener( ModelEvent.MODEL_MODIFIED, modelDetailChanged );			
			var vm:VoxelModel = new VoxelModel( ii );
			vm.metadata = new VoxelModelMetadata();
			Globals.modelAdd( vm );
			new WindowModelDetail( vm );
		}
		
		private function modelDetailChanged(e:ModelEvent):void 
		{
			Globals.g_app.removeEventListener( ModelEvent.MODEL_MODIFIED, modelDetailChanged );			
			// now I want to apply the script to the oxels in the vm.
			var vm:VoxelModel = Globals.getModelInstance( e.instanceGuid );
			ModelLoader.load( vm.instanceInfo );
		}
  }
}
