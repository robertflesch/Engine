
package com.voxelengine.GUI
{

	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.animation.Animation;
	import com.voxelengine.worldmodel.models.Dragon;
	import com.voxelengine.worldmodel.models.ModelInfo;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.Player;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import flash.utils.Dictionary;
	import flash.events.Event;
	import flash.net.FileReference;
	import flash.net.FileFilter;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	
	import flash.geom.Vector3D;

	public class WindowModelsForRegion extends VVPopup
	{
		private const PANEL_WIDTH:int = 200;
		private const PANEL_HEIGHT:int = 300;
		private const PANEL_BUTTON_HEIGHT:int = 200;
		private var _listParents:ListBox = new ListBox( PANEL_WIDTH, 15, PANEL_HEIGHT );
		private var _listChildModels:ListBox = new ListBox( PANEL_WIDTH, 15, PANEL_HEIGHT );
		private var _listAnimations:ListBox = new ListBox( PANEL_WIDTH, 15, PANEL_HEIGHT );
		private var _fileReference:FileReference = new FileReference();
		private var _popup:Popup = null;
		
		public function WindowModelsForRegion()
		{
			super("Voxel Models");
			autoSize = true;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			populateParentModels();
			
			var listBoxPanel:Container = new Container( PANEL_WIDTH * 3, PANEL_HEIGHT );
			listBoxPanel.layout.orientation = LayoutOrientation.HORIZONTAL;
			listBoxPanel.padding = 0;
			listBoxPanel.addElement( _listParents );
			listBoxPanel.addElement( _listChildModels );
			listBoxPanel.addElement( _listAnimations );
			_listParents.addEventListener(ListEvent.LIST_CHANGED, selectParentModel);
			_listChildModels.addEventListener(ListEvent.LIST_CHANGED, childModelDetail );
			addElement( listBoxPanel );
			
			///////// Buttons //////////////////////////////
			var panelButton:Container = new Container( PANEL_WIDTH * 3, PANEL_BUTTON_HEIGHT );
			panelButton.padding = 0;
			addElement( panelButton );

			// PARENT BUTTONS
			var panelParentButton:Container = new Container( PANEL_WIDTH, PANEL_BUTTON_HEIGHT );
			panelParentButton.layout.orientation = LayoutOrientation.VERTICAL;
			panelParentButton.padding = 0;
			panelButton.addElement( panelParentButton );

			var addModel:Button = new Button( "Add Parent Model..." );
			addModel.addEventListener(UIMouseEvent.CLICK, addParent );
			addModel.width = 150;
			panelParentButton.addElement( addModel );
			
			var deleteModel:Button = new Button("Delete Parent Model");
			deleteModel.addEventListener(UIMouseEvent.CLICK, deleteParent );
			deleteModel.width = 150;
			panelParentButton.addElement( deleteModel );
			
			var parentDetail:Button = new Button("Parent Detail");
			parentDetail.addEventListener(UIMouseEvent.CLICK, parentDetailHandler );
			parentDetail.width = 150;
			panelParentButton.addElement( parentDetail );
			
			var newModel:Button = new Button("New Model...");
			newModel.addEventListener(UIMouseEvent.CLICK, newModelHandler );
			newModel.width = 150;
			panelParentButton.addElement( newModel );

		//var editModel:Button = new Button("Edit Template");
			//editModel.addEventListener(UIMouseEvent.CLICK, editModelHandler );
			//editModel.width = 150;
			//panelParentButton.addElement( editModel );
			
//			if ( true == Globals.g_debug )
//			{
				var oxelUtils:Button = new Button( "Oxel Utils" );
				oxelUtils.addEventListener(UIMouseEvent.CLICK, oxelUtilsHandler );
				oxelUtils.width = 150;
				panelParentButton.addElement( oxelUtils );
//			}
			
			//var testB:Button = new Button("Import Model");
			//testB.addEventListener(UIMouseEvent.CLICK,  );
			//testB.width = 150;
			//panelParentButton.addElement( testB );
			
			// CHILD BUTTONS
			var panelChildButton:Container = new Container( PANEL_WIDTH, PANEL_BUTTON_HEIGHT );
			panelChildButton.layout.orientation = LayoutOrientation.VERTICAL;
			panelChildButton.padding = 0;
			panelButton.addElement( panelChildButton );
			
			var addCModel:Button = new Button( "Add Child Model..." );
			addCModel.addEventListener(UIMouseEvent.CLICK, addChildModel );
			panelChildButton.addElement( addCModel );
			
			var deleteCModel:Button = new Button("Delete Child Model...");
			deleteCModel.addEventListener(UIMouseEvent.CLICK, deleteChild );
			panelChildButton.addElement( deleteCModel );
			

			// ANIMATION BUTTONS
			var panelAnimButton:Container = new Container( PANEL_WIDTH, PANEL_BUTTON_HEIGHT );
			panelAnimButton.layout.orientation = LayoutOrientation.VERTICAL;
			panelAnimButton.padding = 0;
			panelButton.addElement( panelAnimButton );
			
			var addAminB:Button = new Button( "Add Animimation..." );
			addAminB.addEventListener(UIMouseEvent.CLICK, addAnim );
			panelAnimButton.addElement( addAminB );
			
			var deleteAminB:Button = new Button("Delete Animimation...");
			deleteAminB.addEventListener(UIMouseEvent.CLICK, deleteAnim );
			panelAnimButton.addElement( deleteAminB );
			
			var editAminB:Button = new Button("Edit Animimation...");
			editAminB.addEventListener(UIMouseEvent.CLICK, editAnim );
			panelAnimButton.addElement( editAminB );
			
			var importAminB:Button = new Button("Import Animimation...");
			importAminB.addEventListener(UIMouseEvent.CLICK, importAnim );
			panelAnimButton.addElement( importAminB );
			
			display();
			
			addEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelCreated );
        }
		
		private function noModelSelected():void
		{
			(new Alert( "No model selected" )).display();
		}
		
		
		
		public function onModelFileSelected(e:Event):void
		{
			var instance:InstanceInfo = new InstanceInfo();
			instance.guid = _fileReference.name.substr( 0, _fileReference.name.length - _fileReference.type.length )
			instance.grainSize = 6;
			instance.positionSet = Globals.controlledModel.instanceInfo.positionGet.clone();
			instance.positionSetComp( instance.positionGet.x, instance.positionGet.y - Globals.UNITS_PER_METER * 4, instance.positionGet.z );
			ModelLoader.load( instance );
		}
		
		
		
		
		//////////////////////////////////////////////////////////
		///////////////////////////// PARENT
		//////////////////////////////////////////////////////////
		private function onParentModelCreated(event:ModelEvent):void {
			var guid:String = event.instanceGuid;
			Log.out( "WindowModels.onParentModelCreated: " + guid );
			var vm:VoxelModel = Globals.getModelInstance( event.instanceGuid );
			if ( vm )
				_listParents.addItem( vm.instanceInfo.name, vm );
			
			//populateParentModels();
		}
		
		private function deleteParent(event:UIMouseEvent):void  {
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					Globals.markDead( li.data.instanceInfo.guid );
					populateParentModels()
				}
			}
			else
				noModelSelected();
		}
		
		// PARENT BUTTONS //////////////////////////////////////////////
		private function onRemoved( event:UIOEvent ):void
 		{
			removeEventListener(UIOEvent.REMOVED, onRemoved );
			Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_ADDED, onParentModelCreated );
			removeChildModels();
			Globals.selectedModel = null;
		}
		
		private function newModelHandler(event:UIMouseEvent):void 
		{
			new WindowModelChoice();
		}

		private function editModelHandler(event:UIMouseEvent):void  {
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					Globals.selectedModel = li.data;
					
					new WindowModelTemplate( Globals.selectedModel );
					
				}
			}
			else
				noModelSelected();
		}
		
		private function addParent(event:UIMouseEvent):void  {
			new WindowModelList();
		}
		
		private function parentDetailHandler(event:UIMouseEvent):void  {
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					Globals.selectedModel = li.data;
					new WindowModelDetail( li.data.instanceInfo );
				}
			}
			else
				noModelSelected();
		}
		
		private function oxelUtilsHandler(event:UIMouseEvent):void  {
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					Globals.selectedModel = li.data;
					new WindowOxelUtils( li.data );
				}
			}
			else
				noModelSelected();
		}
		/*
		private function importLocalFile(event:UIMouseEvent):void 
		{
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					Globals.selectedModel = li.data;
//					new WindowModelDetail( li.data.instanceInfo );
					// Basically works.
					//new WindowModelTemplate( li.data.modelInfo );
					_fileReference.addEventListener(Event.SELECT, onAnimationFileSelected);
					var swfTypeFilter:FileFilter = new FileFilter("Model Files","*.ajson");
					_fileReference.browse([swfTypeFilter]);
					
				}
			}
			else
				noModelSelected();
		}
		*/
		
		//////////////////////////////////////////////////////////
		///////////////////////////// END PARENT
		//////////////////////////////////////////////////////////
		
		//////////////////////////////////////////////////////////
		///////////////////////////// CHILD MODELS
		//////////////////////////////////////////////////////////
		private function onChildModelCreated(event:ModelEvent):void
		{
			var guid:String = event.instanceGuid;
			var rootGuid:String = event.parentInstanceGuid;
			Log.out( "WindowModels.onChildModelCreated: " + guid );
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
					populateChildModels( li.data );
				var vm:VoxelModel = Globals.getModelInstance( guid );
				if ( vm )
					vm.selected = true;
			}
			else
				noModelSelected();
		}
		
		private function deleteChild(event:UIMouseEvent):void 
		{
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					var parentModel:VoxelModel = li.data;
					var lic:ListItem = _listChildModels.getItemAt( _listChildModels.selectedIndex );
					if ( lic && lic.data )
					{
						parentModel.childRemove( lic.data )
					}
					populateChildModels( li.data );
				}
			}
			else
				noModelSelected();
		}
/*		
		private var _viewDistance:Vector3D = new Vector3D(0, 0, -75);
		public function onChildModelFileSelected(e:Event):void
		{
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					var parentModel:VoxelModel = li.data;
					var instance:InstanceInfo = new InstanceInfo();
					instance.guid = _fileReference.name.substr( 0, _fileReference.name.length - _fileReference.type.length )
					instance.positionSet = parentModel.worldToModel( Globals.controlledModel.instanceInfo.positionGet );

					var worldSpaceEndPoint:Vector3D = Globals.controlledModel.instanceInfo.worldSpaceMatrix.transformVector( _viewDistance );
					instance.positionSet = instance.positionGet.add( worldSpaceEndPoint );
					
					
					trace( "onChildModelFileSelected: " + instance.positionGet );
					instance.controllingModel = parentModel;
					ModelLoader.load( instance );
					Globals.g_app.addEventListener( ModelEvent.CHILD_MODEL_ADDED, onChildModelCreated );
				}
			}
		}
	*/	
		// Window events
		private function addChildModel(event:UIMouseEvent):void 
		{
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					var vm:VoxelModel = li.data as VoxelModel
					new WindowModelList( vm.instanceInfo.guid );
//
					//_fileReference.addEventListener(Event.SELECT, onChildModelFileSelected);
					//var swfTypeFilter:FileFilter = new FileFilter("Model Files","*.mjson");
					//_fileReference.browse([swfTypeFilter]);
				}
			}
			else
				noModelSelected();
		}
		
		//////////////////////////////////////////////////////////
		///////////////////////////// END CHILD MODELS
		//////////////////////////////////////////////////////////
		private function getItemData( $lb:ListBox ):* {
			
			if ( -1 < $lb.selectedIndex )
			{
				var li:ListItem = $lb.getItemAt( $lb.selectedIndex );
				if ( li && li.data )
				{
					return li.data;
				}
			}
			else
				noModelSelected();
				
			return null;	
		}
		
		
		//////////////////////////////////////////////////////////
		///////////////////////////// Animations
		//////////////////////////////////////////////////////////
		private function addAnim(event:UIMouseEvent):void 
		{
			var parent:VoxelModel = getItemData( _listParents ) as VoxelModel;
			if ( null != parent )
				new WindowAnimationMetadata( parent.instanceInfo.guid );
		}
		
		private function deleteAnim(event:UIMouseEvent):void 
		{
			var anim:Animation = getItemData( _listAnimations ) as Animation;
			if ( null != anim )
				Log.out( "WindowModels.deleteAnim", Log.ERROR );
		}
		
		private function editAnim(event:UIMouseEvent):void 
		{
			var anim:Animation = getItemData( _listAnimations ) as Animation;
			if ( null != anim )
				new WindowAnimationEdit( anim );
		}
		
		//private function importAnim(event:UIMouseEvent):void 
		//{
			//var anim:Animation = getItemData( _listAnimations ) as Animation;
			//if ( null != anim )
				//anim.importAnimation();
		//}
		
		private function importAnim(event:UIMouseEvent):void 
		{
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
				{
					Globals.selectedModel = li.data;
//					new WindowModelDetail( li.data.instanceInfo );
					// Basically works.
					//new WindowModelTemplate( li.data.modelInfo );
					_fileReference.addEventListener(Event.SELECT, onAnimationFileSelected);
					var swfTypeFilter:FileFilter = new FileFilter("Model Files","*.ajson");
					_fileReference.browse([swfTypeFilter]);
					
				}
			}
			else
				noModelSelected();
		}
		
		public function onAnimationFileSelected(e:Event):void
		{
			if ( -1 < _listParents.selectedIndex )
			{
				var li:ListItem = _listParents.getItemAt( _listParents.selectedIndex );
				if ( li && li.data )
						var vm:VoxelModel = li.data as VoxelModel;
			}
			
			if ( !vm ) 
				return;

			var animName:String = _fileReference.name.substr( 0, _fileReference.name.length - _fileReference.type.length );
			// i.e. animData = { "name": "Glide", "guid":"Glide.ajson" }
			var na:Animation = new Animation();
			na.ownerGuid = vm.modelInfo.modelClass;
			if ( Globals.selectedModel is Player )
				na.model = Animation.MODEL_BIPEDAL_10;
			else if ( Globals.selectedModel is Dragon )
				na.model = Animation.MODEL_DRAGON_9;
			else
				na.model = Animation.MODEL_UNKNOWN;
				
			na.loadForImport( _fileReference.name );
			Globals.g_app.addEventListener( LoadingEvent.ANIMATION_LOAD_COMPLETE, animationLoaded );
		}
		
		
		private function animationLoaded( le:LoadingEvent ):void {
			
		}
		
		private function populateAnimations( $vm:VoxelModel ):void
		{
			removeAnimations();
			var anims:Vector.<Animation> = $vm.modelInfo.animations;
			for each ( var anim:Animation in anims )
			{
				_listAnimations.addItem( anim.name + " - " + anim.guid, anim );
			}
		}
		
		
		//////////////////////////////////////////////////////////
		///////////////////////////// END ANIMATOINS
		//////////////////////////////////////////////////////////
		
		private function removeChildModels():void
		{
			for each ( var vm:VoxelModel in _listChildModels )
			{
				vm.selected = false;
			}
			_listChildModels.removeAll();
		}
		
		private function removeAnimations():void
		{
			_listAnimations.removeAll();
		}
		
		private function populateParentModels():void
		{
			_listParents.removeAll();
			removeChildModels();
			var models:Dictionary = Globals.modelInstancesGetDictionary();
			for each ( var vm:VoxelModel in models )
			{
				if ( vm && !vm.instanceInfo.dynamicObject && !vm.instanceInfo.dead )
				{
					// if not debug, hide the player
					if ( !Globals.g_debug ) {
						if ( vm is Player )
							continue;
					}
					_listParents.addItem( vm.instanceInfo.name, vm );
				}
			}
		}

		
		private function populateChildModels( $vm:VoxelModel ):void
		{
			removeChildModels();
			var models:Vector.<VoxelModel> = $vm.children;
			for each ( var vm:VoxelModel in models )
			{
				if ( "Default Name" != vm.instanceInfo.name )
					_listChildModels.addItem( vm.instanceInfo.name + " - " + vm.instanceInfo.guid, vm );
				else	
					_listChildModels.addItem( vm.instanceInfo.guid, vm );
			}
		}

		private function selectParentModel(event:ListEvent):void 
		{
			var selectedModel:VoxelModel = event.target.data;
			if ( selectedModel )
			{
				populateChildModels( selectedModel );
				populateAnimations( selectedModel );
			}
		}
		
		public function childModelDetail(event:ListEvent):void 
		{ 
			var vm:VoxelModel = event.target.data;
			if ( vm )
			{
				if ( null != WindowModelDetail.currentInstance )
				{
					WindowModelDetail.currentInstance.remove();
				}
				Globals.selectedModel = vm;
				new WindowModelDetail( vm.instanceInfo );
			}
			else
				Log.out( "WindowModel.childModelDetail - VoxelModelNotFound" );
		}
		
		
  }
}