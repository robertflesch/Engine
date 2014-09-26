
package com.voxelengine.GUI
{
	import com.voxelengine.worldmodel.models.ModelLoader;
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
	
	public class WindowModelChoice extends ModalPopup
	{
		private var _rbGroup:RadioButtonGroup = null;
		
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
			_rbGroup.index = 2;
			
			var button:Button = new Button( "Create" );
			eventCollector.addEvent( button, UIMouseEvent.CLICK, create );
			addElement( button );
			
			_modalObj = new ModalObject( this );
			_modalObj.display();
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
        }
		
		private function create( e:UIMouseEvent ):void
		{
			_modalObj.remove();
			_modalObj = null;
			//createWindow( _rbGroup.index );
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
					new WindowNewModelGenerateCube( ii );
					break;
				case 1: // From Sphere
					ii.guid = "GenerateSphere";
					//ii.name = "New Sphere Object";
					// preload the modelInfo for the GenerateCube
					ModelLoader.modelInfoPreload( ii.guid );
					new WindowNewModelGenerateCube( ii );
					break;
				case 2: // From Sphere
					ii.guid = "GenerateSubSphere";
					//ii.name = "Sphere in larger Object";
					// preload the modelInfo for the GenerateCube
					ModelLoader.modelInfoPreload( ii.guid );
					new WindowNewModelGenerateCube( ii );
					break;
			}
		}

		/*
		private function createWindow( id:int ):void
		{
			var alert:Alert;
			switch ( id )
			{
				case 0: // My Models
					alert = new Alert( "Not implemented" );
					break;
				case 1: // All Models
					alert = new Alert( "Not implemented" );
					break;
				case 2: // From Cube
					var ii:InstanceInfo = new InstanceInfo();
					ii.guid = "GenerateCube";
					ii.name = "New Object";
					// preload the modelInfo for the GenerateCube
					Globals.modelInfoPreload( ii.guid );
					_modalObj.remove();
					new WindowNewModelGenerateCube( ii );
					return;
					break;
				case 3: // From Model Template
					alert = new Alert( "Not implemented" );
					break;
				case 4: // New Model Template
					new WindowModelTemplate( new ModelInfo() );
					break;
			}
			if ( alert )
				alert.display();
				
			_modalObj.remove();
		}
		*/
		override protected function onRemoved( event:UIOEvent ):void
 		{
			super.onRemoved( event );
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			if ( _modalObj ) {
				_modalObj.remove();
				_modalObj = null;
			}
		}
  }
}
