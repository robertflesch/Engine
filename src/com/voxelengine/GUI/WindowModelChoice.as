
package com.voxelengine.GUI
{
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.GUI.voxelModels.WindowModelDetail;
	import com.voxelengine.worldmodel.models.ModelLoader;
	//import com.voxelengine.worldmodel.models.ModelMakerGenerated;
	import com.voxelengine.worldmodel.models.ModelManager;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.models.ModelMetadata;
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
				else	
					Log.out( "WindowModelChoice.construct - rejecting: " + item.name, Log.WARN );
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
			_cbDetail.selectedIndex = 2;
		}
		
		private function updateDetail( selectedIndex:int ):void {
			if ( 1 < selectedIndex )
				_cbDetail.selectedIndex = ( 0 <  selectedIndex - 3 ? selectedIndex - 3 : 0 );
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
			//_modalObj.remove();
			//_modalObj = null;
			createWindow( _rbGroup.index );
			remove();
		}

		private function createWindow( id:int ):void
		{
			var ii:InstanceInfo = new InstanceInfo();
			var detailSize:int;		
			var li:ListItem;
			switch ( id )
			{
				case 0: // From Cube
					ii.guid = "GenerateCube";
					ModelLoader.modelInfoPreload( ii.guid );
					break;
				case 1: // From Sphere
					ii.guid = "GenerateSphere";
					ModelLoader.modelInfoPreload( ii.guid );
					li = _cbDetail.getItemAt(_cbDetail.selectedIndex );
					detailSize = li.data;			
					break;
				case 2: // From Sphere
					ii.guid = "GenerateSubSphere";
					ModelLoader.modelInfoPreload( ii.guid );
					li = _cbDetail.getItemAt(_cbDetail.selectedIndex );
					detailSize = li.data;			
					break;
			}
			
			if ( -1 == _cbSize.selectedIndex ) {
				(new Alert( "Please select a size" ) ).display();
				return;
			}
			li = _cbSize.getItemAt(_cbSize.selectedIndex );
			var size:int = li.data;			
			li = _cbType.getItemAt( _cbType.selectedIndex );
			var type:int = li.data;			
			ii.grainSize = size;
			ii.detailSize = detailSize;
			ii.type = type;
			ii.scripts
			var viewDistance:Vector3D = new Vector3D(0, 0, -75 - (1<<size)/2 );
			ii.positionSet = Globals.controlledModel.instanceInfo.worldSpaceMatrix.transformVector( viewDistance );
			ModelEvent.addListener( ModelEvent.MODEL_MODIFIED, modelDetailChanged );			
			//var vm:VoxelModel = new VoxelModel( ii );
//			vm.metadata = new VoxelModelMetadata();
			//Globals.modelAdd( vm );
			//new ModelMakerGenerated( ii );
			//new WindowModelMetadata( ii.guid );
		}
		
		private function modelDetailChanged(e:ModelEvent):void 
		{
			ModelEvent.removeListener( ModelEvent.MODEL_MODIFIED, modelDetailChanged );			
			// now I want to apply the script to the oxels in the vm.
			var vm:VoxelModel = Globals.modelGet( e.instanceGuid );
			ModelLoader.load( vm.instanceInfo );
		}
  }
}
