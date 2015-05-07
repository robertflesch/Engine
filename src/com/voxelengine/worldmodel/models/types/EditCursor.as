/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
	import com.voxelengine.events.GUIEvent;
	import com.voxelengine.GUI.actionBars.ModelPlacementType;
	import com.voxelengine.pools.LightingPool;
	import com.voxelengine.worldmodel.inventory.ObjectModel;
	import com.voxelengine.worldmodel.models.makers.ModelMakerCursor;
	import com.voxelengine.worldmodel.models.ModelCacheUtils;
	import com.voxelengine.worldmodel.oxel.GrainCursorIntersection;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.display3D.Context3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.oxel.*;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelInfo;
	import com.voxelengine.worldmodel.models.ModelMetadata;
	import com.voxelengine.pools.GrainCursorPool;
	import com.voxelengine.worldmodel.tasks.flowtasks.CylinderOperation;
	import com.voxelengine.worldmodel.tasks.flowtasks.SphereOperation;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * 
	 */
	public class EditCursor extends VoxelModel
	{
		static private var _s_currentInstance:EditCursor;

		static public const EDIT_CURSOR:String 		= "EditCursor";
		
		static public	const CURSOR_TYPE_GRAIN:int 		= 0;
		static public	const CURSOR_TYPE_SPHERE:int 		= 1;		
		static public	const CURSOR_TYPE_MODEL:int 		= 2;		
		static public	const CURSOR_TYPE_CYLINDER:int 		= 3;		
		
		static public	const CURSOR_OP_NONE:int 			= 0;
		static public	const CURSOR_OP_INSERT:int 			= 1;
		static public 	const CURSOR_OP_DELETE:int 			= 2;

		static 	private	const SCALE_FACTOR:Number 			= 0.01;
		
		static 	private var   _s_editCursorSize:int			 = 0;			// this allows me to go from model to model with the same size cursor.
		static  private var   _s_editCursorIcon:int			 = 1000; 		// Globals.EDITCURSOR_SQUARE;
		static 	private var   _s_cursorType:int = CURSOR_TYPE_GRAIN;		// round, square, cylinder
		static 	private var   _s_cursorOperation:int = CURSOR_OP_NONE;		// none, insert, delete
		
		static public const EDITCURSOR_SQUARE:uint				= 1000;
		static public const EDITCURSOR_ROUND:uint				= 1001;
		static public const EDITCURSOR_CYLINDER:uint			= 1002;
		static public const EDITCURSOR_CYLINDER_ANIMATED:uint	= 1003;
		static public const EDITCURSOR_INVALID:uint				= 1004;
		
        static private 	var	  _repeatTime:int = 100;
		static private 	var   _repeatTimer:Timer;
		static private  var   _count:int = 0;
		
		static public function get editCursorIcon():int { return _s_editCursorIcon; }
		static public function set editCursorIcon(val:int):void { _s_editCursorIcon = val; }
		static public function get cursorType():int { return _s_cursorType; }
		static public function set cursorType(val:int):void { _s_cursorType = val; }
		static public function get cursorOperation():int { return _s_cursorOperation; }
		static public function set cursorOperation(val:int):void { _s_cursorOperation = val; }
		static public function get editCursorSize():int { return _s_editCursorSize; }
		static public function set editCursorSize(val:int):void { _s_editCursorSize = val; }
		
		private 		var   _gciData:GrainCursorIntersection = null;
		public function get gciData():GrainCursorIntersection { return _gciData; }
		public function set gciData(value:GrainCursorIntersection):void { _gciData = value; }
		
		static private 	var 	_s_editing:Boolean;
		static public function get editing():Boolean { return _s_editing; }
		static public function set editing(val:Boolean):void { _s_editing = val; }
		
		static private 	var 	_s_toolOrBlockEnabled:Boolean;
		static public function get toolOrBlockEnabled():Boolean { return _s_toolOrBlockEnabled; }
		static public function set toolOrBlockEnabled(val:Boolean):void { _s_toolOrBlockEnabled = val; }
		
		static public function get currentInstance():EditCursor {
			if ( null == _s_currentInstance ) {
				var instanceInfo:InstanceInfo = new InstanceInfo();
				instanceInfo.modelGuid = EDIT_CURSOR

				var modelInfo:ModelInfo = new ModelInfo();
				modelInfo.fileName = EDIT_CURSOR;
				modelInfo.modelClass = EDIT_CURSOR;

				_s_currentInstance = new EditCursor( instanceInfo );
				_s_currentInstance.init( modelInfo, null );
			}
			return _s_currentInstance;
		}
		
		override public function get visible():Boolean {
			GUIEvent.addListener( GUIEvent.APP_DEACTIVATE, onDeactivate );
			return super.visible;
		}
		
		override public function set visible( $val:Boolean ):void {
			GUIEvent.removeListener( GUIEvent.APP_DEACTIVATE, onDeactivate );
			super.visible = $val;
			if ( visible )
				Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
			else
				Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);	
		}
		
		
		protected function onDeactivate( e:GUIEvent ):void  {
			//Log.out( "onDeactivate - disabling repeat" );
			// We dont want the repeat on if app loses focus
			mouseUp( null );
		}
		
		public function EditCursor( instanceInfo:InstanceInfo ):void {
			super( instanceInfo );
		}

		override public function init( $mi:ModelInfo, $vmm:ModelMetadata, $initializeRoot:Boolean = true ):void {
			super.init( $mi, $vmm );
			oxel.gc.bound = 4;
			visible = false;
			oxel.vm_initialize( statisics );
		}
		
		public function clearGCIData():void {
			gciData = null;
		}
		
		public function setGCIData( $gciData:GrainCursorIntersection ):void {
			gciData = $gciData;
			visible = true;
			
			// This cleans up (int) the location of the gc
			var gct:GrainCursor = GrainCursorPool.poolGet( gciData.model.oxel.gc.bound );
			GrainCursor.getFromPoint( gciData.point.x, gciData.point.y, gciData.point.z, gct );
			// we have to make the grain scale up to the size of the edit cursor
			gct.become_ancestor( oxel.gc.grain );
			_gciData.gc.copyFrom( gct );
			GrainCursorPool.poolDispose( gct );
			
			if ( CURSOR_OP_INSERT == cursorOperation ) {
				configureInsertOxel();
			}
			else {
				configureDeleteOxel();
			}

		}
		
		static private var _objectModel:VoxelModel;
		public function objectModelGet( ):VoxelModel { return _objectModel;}
		public function objectModelClear():void { _objectModel = null; }
		
		public function objectModelSet( $cm:VoxelModel ):void {
			_objectModel = $cm;
			editCursorSize = oxel.gc.bound = $cm.oxel.gc.bound;
			if ( null == oxel.vm_get() )
				oxel.vm_initialize( statisics );
			if ( null == _objectModel.oxel.vm_get() )
				_objectModel.oxel.vm_initialize( _objectModel.statisics );
		}
		
		public function objectModelAdd( $om:ObjectModel ):void {
			var ii:InstanceInfo = new InstanceInfo();
			// How can I tell if I am adding this to parent, or it is independant?
			// when it is placed?
			// Add the parent model info to the child.
//			ii.controllingModel = this;
			ii.baseLightLevel = Lighting.MAX_LIGHT_LEVEL;
			ii.modelGuid = $om.modelGuid;
			var mm:ModelMakerCursor = new ModelMakerCursor( ii, $om.vmm );
		}
		
		private function configureInsertOxel():void {
			var pl:PlacementLocation = getPlacementLocation( gciData.model );
			if ( PlacementLocation.INVALID == pl.state ) {
				editCursorIcon = EDITCURSOR_INVALID; // ;
				instanceInfo.positionSetComp( _gciData.gc.getModelX(), _gciData.gc.getModelY(), _gciData.gc.getModelZ() );
			} else {
				instanceInfo.positionSetComp( pl.gc.getModelX(), pl.gc.getModelY(), pl.gc.getModelZ() );
			}

			oxel.quadsDeleteAll();
			oxel.faces_clear_all();
			oxel.faces_mark_all_clean();
			
			oxel.face_set( Globals.POSX );
			oxel.face_set( Globals.NEGX );
			oxel.face_set( Globals.POSY );
			oxel.face_set( Globals.NEGY );
			oxel.face_set( Globals.POSZ );
			oxel.face_set( Globals.NEGZ );
			
			if ( !oxel.lighting )
				oxel.lighting = LightingPool.poolGet( 0xff );
			var li:LightInfo = oxel.lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
			if ( EDITCURSOR_INVALID == editCursorIcon ) li.color = 0x00ff0000;
			else 										li.color = 0xffffffff;
			oxel.lighting.setAll( Lighting.DEFAULT_LIGHT_ID, Lighting.MAX_LIGHT_LEVEL );
			oxel.write( EDIT_CURSOR, oxel.gc, editCursorIcon, true );
			oxel.quadsBuild();
			
			if ( _objectModel )
				_objectModel.instanceInfo.positionSet = instanceInfo.positionGet;
		}
		
		private function configureDeleteOxel():void {
			
			instanceInfo.positionSetComp( _gciData.gc.getModelX(), _gciData.gc.getModelY(), _gciData.gc.getModelZ() );
			oxel.quadsDeleteAll();
			oxel.faces_clear_all();
			oxel.faces_mark_all_clean();
			if ( !oxel.lighting )
				oxel.lighting = LightingPool.poolGet( 0xff );
			var li:LightInfo = oxel.lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
			oxel.faces_set_all();
			oxel.write( EDIT_CURSOR, oxel.gc, editCursorIcon, true );
			li.color = cursorColorRainbow();
			oxel.quadsBuild();
		}
		
		private var _phase:Number = 0;
		private function cursorColorRainbow():uint {
			var frequency:Number = 2.4;
			var red:uint = Math.max( 0, Math.sin( frequency + 2 + _phase ) ) * 255;
			var green:uint = Math.max( 0, Math.sin( frequency + 0 + _phase ) ) * 255;
			var blue:uint = Math.max( 0, Math.sin( frequency + 4 + _phase ) ) * 255;
			var color:uint;
			color |= red << 16;
			color |= green << 8;
			color |= blue << 0;
			_phase += 0.03;
			return color;
		}
		
		
		override public function draw(mvp:Matrix3D, $context:Context3D, $isChild:Boolean ):void	{

			var t:Number = oxel.gc.size() * SCALE_FACTOR/2;
			
			var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
			viewMatrix.prependScale( 1 + SCALE_FACTOR, 1 + SCALE_FACTOR, 1 + SCALE_FACTOR ); 
			var positionscaled:Vector3D = viewMatrix.position;
			viewMatrix.prependTranslation( -t, -t, -t)
			viewMatrix.append(mvp);
			
			oxel.vertMan.drawNew( viewMatrix, this, $context, _shaders, selected, $isChild );
			
			if ( _objectModel )
				_objectModel.draw( mvp, $context, true );
		}
		
		override public function drawAlpha( mvp:Matrix3D,$context:Context3D, $isChild:Boolean ):void {
			var t:Number = oxel.gc.size() * SCALE_FACTOR/2;
			
			var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
			viewMatrix.prependScale( 1 + SCALE_FACTOR, 1 + SCALE_FACTOR, 1 + SCALE_FACTOR ); 
			var positionscaled:Vector3D = viewMatrix.position;
			viewMatrix.prependTranslation( -t, -t, -t)
			viewMatrix.append(mvp);
			
			oxel.vertMan.drawNewAlpha( viewMatrix, this, $context, _shaders, selected, $isChild );
			
			if ( _objectModel )
				_objectModel.drawAlpha( mvp, $context, true );
		}
		
		override public function update($context:Context3D, elapsedTimeMS:int ):void {
			// the grain should never be larger then the bound
			if ( oxel.gc.bound < editCursorSize )
			{
				oxel.gc.grain = oxel.gc.bound;
				editCursorSize = oxel.gc.bound;
			}
			else
			{
				oxel.gc.grain =  editCursorSize;
			}
			
			internal_update($context, elapsedTimeMS );
			
			if ( _objectModel ) {
				var newPos:Vector3D = Globals.player.instanceInfo.modelToWorld( new Vector3D( 0,0, -(_objectModel.oxel.gc.size() * 2) ) );
				_objectModel.instanceInfo.positionSet = newPos;
				_objectModel.update($context, elapsedTimeMS );
			}
		}
		
		override public function initialize($context:Context3D ):void {
			internal_initialize($context );
			visible = false;
			// these are all static calls, should only be added once.
			Log.out( "EditCursor.initialize" );
			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			Globals.g_app.stage.addEventListener(MouseEvent.CLICK, mouseClick);
			Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			// this one is not a static call
			Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);

			if ( oxel.gc.grain == editCursorSize )
				return;
			else if ( oxel.gc.grain < editCursorSize )
				growCursor();
			else if ( oxel.gc.grain > editCursorSize )
				shrinkCursor();
		}

		override public function release():void {
			if ( oxel )
				oxel.release();
				
			Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		}
		
		static private function isAvatarInsideThisOxel( vm:VoxelModel, oxel:Oxel ):Boolean {
			var mp:Vector3D = vm.worldToModel( ModelCacheUtils.worldSpaceStartPoint );
			// check head
			var result:Boolean = oxel.gc.is_point_inside( mp );
			// and foot
			mp.y -= Globals.AVATAR_HEIGHT;
			result = result || oxel.gc.is_point_inside( mp );
			return result;
		}
		
		static public function getHighlightedOxel(recurse:Boolean = false):Oxel {
			
			var foundModel:VoxelModel = Globals.selectedModel;
			// placementResult - { oxel:Globals.BAD_OXEL, gci:gci, positive:posMove, negative:negMove };
			var placementResult:PlacementLocation = getPlacementLocation( foundModel );
			if ( PlacementLocation.INVALID == placementResult.state )
			{
				Log.out( "EditCursor.getHighlightedOxel NO PLACEMENT FOUND" );
				return Globals.BAD_OXEL;
			}
			var oxelToBeModified:Oxel = foundModel.oxel.childGetOrCreate( placementResult.gc );
			if ( Globals.BAD_OXEL == oxelToBeModified )
			{
				Log.out( "EditCursor.getHighlightedOxel BAD OXEL OLD" );
				if ( recurse )
					return Globals.BAD_OXEL;
					
				if ( placementResult )
					return Globals.BAD_OXEL;
					
				if ( EditCursor.currentInstance.gciData )
				{
					Log.out( "EditCursor.getHighlightedOxel BAD OXEL NEW gciData.point" + EditCursor.currentInstance.gciData.point + "  gciData.gc: " + EditCursor.currentInstance.gciData.gc );
					// What does this do?
					insertOxel( true );
					return Globals.BAD_OXEL;
				}
//					foundModel.grow( placementResult );
			}
			
			return oxelToBeModified;
		}
		
		static private function insertModel():void {
			if ( CURSOR_OP_INSERT != _s_cursorOperation )
				return;

			var foundModel:VoxelModel = Globals.selectedModel;
			if ( foundModel )
			{
				// same model, new instance.
				var newChild:VoxelModel = _objectModel.clone();
				if ( ModelPlacementType.PLACEMENT_TYPE_CHILD == ModelPlacementType.modelPlacementTypeGet() )
					foundModel.childAdd( newChild );
				else {
					var newPos:Vector3D = Globals.player.instanceInfo.modelToWorld( new Vector3D( 0,0, -(newChild.oxel.gc.size() * 2) ) );
					newChild.instanceInfo.positionSet = newPos;
					Region.currentRegion.modelCache.add( newChild );
				}
			}
		}
		
		
		static private function insertOxel(recurse:Boolean = false):void {
			if ( CURSOR_OP_INSERT != _s_cursorOperation )
				return;

			var foundModel:VoxelModel = Globals.selectedModel;
			if ( foundModel )
			{
				var oxelToBeModified:Oxel = getHighlightedOxel( recurse );
				if ( Globals.BAD_OXEL == oxelToBeModified )
				{
					Log.out( "EditCursor.insertOxel - Invalid location" );
					return;
				}
				
				if ( isAvatarInsideThisOxel( foundModel, oxelToBeModified ) )
				{
					Log.out( "EditCursor.insertOxel - Trying to place an oxel on top of ourself" );
					return;
				}
				
				if ( CURSOR_TYPE_GRAIN == cursorType )
				{
					foundModel.write( oxelToBeModified.gc, editCursorIcon );
				}
				else if ( CURSOR_TYPE_SPHERE == cursorType )
				{
					sphereOperation();				 
				}
				else if ( CURSOR_TYPE_CYLINDER == cursorType )
				{
					cylinderOperation();				 
				}
				else if ( CURSOR_TYPE_MODEL == cursorType )
				{
					Log.out( "EditCursor.insertOxel - CURSOR_TYPE_MODEL not supported yet", Log.WARN );
				}
			}
		}
		
		static private function getPlacementLocation( foundModel:VoxelModel ):PlacementLocation {
			var gci:GrainCursorIntersection = EditCursor.currentInstance.gciData;
			var pl:PlacementLocation = new PlacementLocation();
			if ( !gci )
				return pl;
				
			// determines whether a block can be placed
			// calculate difference between avatar location and intersection point
			var diffPos:Vector3D = Globals.player.wsPositionGet().clone();
			diffPos = diffPos.subtract( gci.wsPoint );
			
			pl.state = PlacementLocation.VALID;
			// copy the location of the cursor in the larger model
			// since we are testing on this, we need to use a copy
			pl.gc.copyFrom( gci.gc );
			// test the results of the step, to see if a blocks has been sent out of bounds.
			switch ( gci.axis ) {
			case 0:
				if ( 0 < diffPos.x ) {
					if ( !pl.gc.move_posx() ) pl.state = PlacementLocation.INVALID;
					pl.positive = true;
				} else {
					if ( !pl.gc.move_negx() ) pl.state = PlacementLocation.INVALID;
					pl.negative = true;
				}
				break;
			case 1:
				if ( 0 < diffPos.y ) {
					if ( !pl.gc.move_posy() ) pl.state = PlacementLocation.INVALID;
					pl.positive = true;
				} else {
					if ( !pl.gc.move_negy() ) pl.state = PlacementLocation.INVALID;
					pl.negative = true;
				}
				break;
			case 2:
				if ( 0 < diffPos.z ) {
					if ( !pl.gc.move_posz() ) pl.state = PlacementLocation.INVALID;
					pl.positive = true;
				} else {	
					if ( !pl.gc.move_negz() ) pl.state = PlacementLocation.INVALID;
					pl.negative = true;
				}
				break;
			}
				
			return pl;
		}
		
		static private function getOxelFromPoint( vm:VoxelModel, gci:GrainCursorIntersection ):Oxel {
			var gcDelete:GrainCursor = GrainCursorPool.poolGet( vm.oxel.gc.bound );
			// This is where it intersects with a grain 0
			gcDelete.grainX = int( EditCursor.currentInstance.instanceInfo.positionGet.x + 0.05 );
			gcDelete.grainY = int( EditCursor.currentInstance.instanceInfo.positionGet.y + 0.05 );
			gcDelete.grainZ = int( EditCursor.currentInstance.instanceInfo.positionGet.z + 0.05 );
			// we have to make the grain scale up to the size of the edit cursor
			gcDelete.become_ancestor( EditCursor.currentInstance.oxel.gc.grain );
			var oxelToBeDeleted:Oxel = vm.oxel.childFind( gcDelete );
			GrainCursorPool.poolDispose( gcDelete );
			return oxelToBeDeleted;
		}
		
		static private function deleteOxel():void {
			if ( CURSOR_OP_DELETE != _s_cursorOperation )
				return;

			var foundModel:VoxelModel;
			if ( Globals.selectedModel )
			{
				if ( EditCursor.toolOrBlockEnabled )
				{
					Globals.player.stateSet( "Pick", 1 );
					Globals.player.stateLock( true, 300 );
				}
				
				
				foundModel = Globals.selectedModel;
				var fmRoot:Oxel = foundModel.oxel;
				if ( CURSOR_TYPE_GRAIN == cursorType )
				{
					var gcDelete:GrainCursor = GrainCursorPool.poolGet(foundModel.oxel.gc.bound);
					// This is where it intersects with a grain 0
					gcDelete.grainX = int( EditCursor.currentInstance.instanceInfo.positionGet.x + 0.05 );
					gcDelete.grainY = int( EditCursor.currentInstance.instanceInfo.positionGet.y + 0.05 );
					gcDelete.grainZ = int( EditCursor.currentInstance.instanceInfo.positionGet.z + 0.05 );
					// we have to make the grain scale up to the size of the edit cursor
					gcDelete.become_ancestor( EditCursor.currentInstance.oxel.gc.grain );
					var oxelToBeDeleted:Oxel = foundModel.oxel.childGetOrCreate( gcDelete );
					if ( Globals.BAD_OXEL != oxelToBeDeleted )
						foundModel.write( gcDelete, TypeInfo.AIR );
					GrainCursorPool.poolDispose( gcDelete );
				}
				else if ( CURSOR_TYPE_SPHERE == cursorType )
				{
					var gci:GrainCursorIntersection = EditCursor.currentInstance.gciData;
					var cuttingPoint:Vector3D = new Vector3D();
					if ( 0 == gci.axis ) // x
					{
						cuttingPoint.x = gci.point.x;
						cuttingPoint.y = gci.gc.getModelY() + gci.gc.size() / 2;
						cuttingPoint.z = gci.gc.getModelZ() + gci.gc.size() / 2;
					}
					else if ( 1 == gci.axis )  // y
					{
						cuttingPoint.x = gci.gc.getModelX() + gci.gc.size() / 2;
						cuttingPoint.y = gci.point.y;
						cuttingPoint.z = gci.gc.getModelZ() + gci.gc.size() / 2;
					}
					else 
					{
						cuttingPoint.x = gci.gc.getModelX() + gci.gc.size() / 2;
						cuttingPoint.y = gci.gc.getModelY() + gci.gc.size() / 2;
						cuttingPoint.z = gci.point.z;
					}
					foundModel.empty_sphere(  cuttingPoint.x
											, cuttingPoint.y
											, cuttingPoint.z
											, gci.gc.size() / 2
											, 0 );
				}
				else if ( CURSOR_TYPE_MODEL == cursorType )
				{
					Log.out( "EditCursor.delete - NOT IMPLEMENTED", Log.WARN );
					//foundModel.empty_square( int(EditCursor.currentInstance.gciData.point.x)
												//, int(EditCursor.currentInstance.gciData.point.y)
												//, int(EditCursor.currentInstance.gciData.point.z)
												//, EditCursor.currentInstance.gciData.gc.size() / 2
												//, 0 );
				}
				else if ( CURSOR_TYPE_CYLINDER == cursorType )
				{
					cylinderOperation();				 
				}
				else
				{
					throw new Error( "EditCursor.keyDown - Cursor type not found" );
				}
			}
		}

		static private function sphereOperation():void {
			var foundModel:VoxelModel = Globals.selectedModel;
			if ( foundModel )
			{
				var gciCyl:GrainCursorIntersection = EditCursor.currentInstance.gciData;
				var where:GrainCursor = null;
				
				var radius:int = gciCyl.gc.size()/2;
				
				var what:int = editCursorIcon;
				if ( CURSOR_OP_INSERT == _s_cursorOperation )
				{
					var placementResult:PlacementLocation = getPlacementLocation( foundModel );
					if ( PlacementLocation.INVALID == placementResult.state )
						return;
					
					//where = placementResult.gci.gc;
					where = placementResult.gc;
				}
				else
				{
					where = gciCyl.gc;
					radius -= radius / 8
					what = TypeInfo.AIR;
				}
				
				var cuttingPointCyl:Vector3D = new Vector3D();
				cuttingPointCyl.x = where.getModelX() + radius;
				cuttingPointCyl.y = where.getModelY() + radius
				cuttingPointCyl.z = where.getModelZ() + radius
				
				var minGrain:int = Math.max( EditCursor.currentInstance.oxel.gc.grain - 4, 0 );
				var startingGrain:int = EditCursor.currentInstance.oxel.gc.grain - 1;
				//SphereOperation( gc:GrainCursor, what:int, guid:String,	cx:int, cy:int, cz:int, radius:int, currentGrain:int, gmin:uint = 0  ):void 				
				new SphereOperation( where
									 , what
									 , foundModel.instanceInfo.instanceGuid
									 , cuttingPointCyl.x
									 , cuttingPointCyl.y
									 , cuttingPointCyl.z
									 , radius
									 , startingGrain
									 , minGrain );
			}
		}
		
		static private function cylinderOperation():void {
			var foundModel:VoxelModel = Globals.selectedModel;
			if ( foundModel && EditCursor.currentInstance.gciData )
			{
				var gciCyl:GrainCursorIntersection = EditCursor.currentInstance.gciData;
				var where:GrainCursor = null;
				
				var offset:int = 0;
				var radius:int = gciCyl.gc.size()/2;
				var cuttingPointCyl:Vector3D = new Vector3D();
				if ( 0 == gciCyl.axis ) // x
				{
					cuttingPointCyl.x = gciCyl.point.x + offset;
					cuttingPointCyl.y = gciCyl.gc.getModelY() + radius;
					cuttingPointCyl.z = gciCyl.gc.getModelZ() + radius;
				}
				else if ( 1 == gciCyl.axis )  // y
				{
					cuttingPointCyl.x = gciCyl.gc.getModelX() + radius;
					cuttingPointCyl.y = gciCyl.gc.getModelY();
					//cuttingPointCyl.y = gciCyl.point.y + offset;
					cuttingPointCyl.z = gciCyl.gc.getModelZ() + radius;
				}
				else 
				{
					cuttingPointCyl.x = gciCyl.gc.getModelX() + radius;
					cuttingPointCyl.y = gciCyl.gc.getModelY() + radius;
					cuttingPointCyl.z = gciCyl.point.z + offset;
				}
				
				var what:int = editCursorIcon;
				if ( CURSOR_OP_INSERT == _s_cursorOperation )
				{
					offset = gciCyl.gc.size();
					var pl:PlacementLocation = getPlacementLocation( foundModel );
					if ( PlacementLocation.INVALID == pl.state )
						return;
					
					//where = temp.gci.gc;						
					where = pl.gc;
				}
				else // CURSOR_OP_DELETE
				{
					where = gciCyl.gc;
					radius -= radius / 8
					//radius += radius / 16
					what = TypeInfo.AIR;
				}
					
				var minGrain:int = Math.max( EditCursor.currentInstance.oxel.gc.grain - 5, 0 );
				var startingGrain:int = EditCursor.currentInstance.oxel.gc.grain - 1;
				if ( where )
				{
					new CylinderOperation( where
										 , what
										 , foundModel.instanceInfo.instanceGuid
										 , cuttingPointCyl.x
										 , cuttingPointCyl.y
										 , cuttingPointCyl.z
										 , gciCyl.axis
										 , radius
										 , startingGrain
										 , minGrain );
				}
			}
		}
		
		static private function keyDown(e:KeyboardEvent):void  {
			if ( Globals.openWindowCount || !Globals.clicked )
				return;
				
			var foundModel:VoxelModel;
			switch (e.keyCode) 
			{
				// No idea what case F does, and since it causes a link to GUI, I am removing it.
				//case Keyboard.F:
					//if ( true == EditCursor.editing && true == EditCursor.toolOrBlockEnabled )
					//{
						//if ( 0 == QuickInventory.currentItemSelection )
							//deleteOxel();
						//else if ( 1 < QuickInventory.currentItemSelection )
							//insertOxel();
					//}
					//break;
				case 107: case Keyboard.NUMPAD_ADD:
				case 45: case Keyboard.INSERT:
						insertOxel();
					break;
				case 189: case Keyboard.MINUS: 
				case 46: case Keyboard.DELETE: 
				case 109: case Keyboard.NUMPAD_SUBTRACT: 
						deleteOxel();
					break;
				case 33: case Keyboard.PAGE_UP:
						editCursorSize = editCursorSize + 1;
						growCursor()
					break;
					
				case 34: case Keyboard.PAGE_DOWN:
						editCursorSize = editCursorSize - 1;
						shrinkCursor();
					break;
			}
		}
		
		static public function growCursor():void {
			if ( Globals.selectedModel )
			{
				EditCursor.currentInstance.oxel.gc.bound = Globals.selectedModel.oxel.gc.bound;
				var gcGrow:GrainCursor = EditCursor.currentInstance.oxel.gc;
				
				// If edit cursor wants to be larger the the size of the selected object
				// then set it to the size of the selected object
				if ( Globals.selectedModel.oxel.gc.grain < editCursorSize )
					editCursorSize = Globals.selectedModel.oxel.gc.grain;
					
				if ( gcGrow.grain < Globals.selectedModel.oxel.gc.grain )
				{
					for ( var i:int = gcGrow.grain; i < editCursorSize; i++ )
						gcGrow.grain = ++gcGrow.grain;
						
					editCursorSize = gcGrow.grain;
					EditCursor.currentInstance.oxel.faces_rebuild( EDIT_CURSOR );
				}
			}
		}
		
		static public function shrinkCursor():void {
			if ( Globals.selectedModel )
			{
				var gcShrink:GrainCursor = EditCursor.currentInstance.oxel.gc;
				if ( 0 < gcShrink.grain )
				{
					var currentSize:int = gcShrink.grain;
					for ( var i:int = editCursorSize; i < currentSize; i++ )
						gcShrink.grain = --gcShrink.grain;
					editCursorSize = gcShrink.grain;
					EditCursor.currentInstance.oxel.faces_rebuild( EDIT_CURSOR );
				}
			}	
		}
		
		static protected function onRepeat(event:TimerEvent):void {
			if ( Globals.openWindowCount )
				return;
				
			if ( 1 < _count )
			{
				if ( CURSOR_OP_DELETE == _s_cursorOperation )
					deleteOxel();
				else if ( CURSOR_OP_INSERT == _s_cursorOperation )
					insertOxel();
			}
			_count++;
		}

		static private function mouseUp(e:MouseEvent):void  {
			if ( _repeatTimer )
				_repeatTimer.removeEventListener( TimerEvent.TIMER, onRepeat );
			_count = 0;	
		}
		
		import com.voxelengine.worldmodel.MouseKeyboardHandler;
		private static var _s_dy:Number = 0;
		private static var _s_dx:Number = 0;
		private function mouseMove(e:MouseEvent):void {
			if ( MouseKeyboardHandler.ctrl ) {
				if ( 0 == _s_dx && 0 == _s_dy ) {
					_s_dy = Globals.g_app.stage.mouseY;
					_s_dx = Globals.g_app.stage.mouseX;
					return;
				}
				var dy:Number = Globals.g_app.stage.mouseY - _s_dy;
				_s_dy = Globals.g_app.stage.mouseY;
				var dx:Number =  Globals.g_app.stage.mouseX - _s_dx;
				_s_dx = Globals.g_app.stage.mouseX
//				Log.out( "EditCursor.mouse move dx: " + dx + "  dy: " + dy );
				
			// do I need to add axis models?	
			//	this.childAdd();
				var t:Vector3D = Globals.selectedModel.instanceInfo.positionGet;
				t.z += dy/4;
				t.x += dx/4;
				Globals.selectedModel.instanceInfo.positionSetComp( t.x, t.y, t.z );
			}
		}
		static private function mouseDown(e:MouseEvent):void {
			if ( Globals.openWindowCount || !Globals.clicked || e.ctrlKey )
				return;
				
			_repeatTimer = new Timer( 200 );
			_repeatTimer.addEventListener(TimerEvent.TIMER, onRepeat);
			_repeatTimer.start();
			
			switch (e.type) 
			{
				case "mouseDown": case Keyboard.NUMPAD_ADD:
					if ( CURSOR_OP_DELETE == _s_cursorOperation )
						deleteOxel();
					else if ( CURSOR_OP_INSERT == _s_cursorOperation && _objectModel )
						insertModel();						
					else if ( CURSOR_OP_INSERT == _s_cursorOperation )
						insertOxel();
					break;
			}
		}
		
		static private function mouseClick(e:MouseEvent):void  {
			//Log.out( "initialize - mouseClick mouseClick mouseClick" );
		}
		
		static public function setPickColorFromType( type:int ):void {
			switch ( type )
			{
				case CURSOR_TYPE_CYLINDER:
					editCursorIcon = EditCursor.EDITCURSOR_CYLINDER;
					break;
				case CURSOR_TYPE_SPHERE:
					editCursorIcon = EditCursor.EDITCURSOR_ROUND;
					break;
				case CURSOR_TYPE_GRAIN:
					editCursorIcon = EditCursor.EDITCURSOR_SQUARE;
					break;
			} 
		}
		
		private function onMouseWheel(event:MouseEvent):void {
			
			if ( true != event.shiftKey || null == _objectModel )
				return;
				
			var rot:Vector3D = _objectModel.instanceInfo.rotationGet;
			if ( 0 < event.delta )
				rot.y += 90;
			 else
				rot.y -= 90;

			_objectModel.instanceInfo.rotationSet = rot
		}	
		
	}
}

import com.voxelengine.worldmodel.oxel.GrainCursorIntersection;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.Globals;

internal class PlacementLocation
{
	static public const INVALID:int = 0;
	static public const VALID:int = 1;
	public var gc:GrainCursor = new GrainCursor();
	public var positive:Boolean;
	public var negative:Boolean;
	public var state:int = INVALID;
}