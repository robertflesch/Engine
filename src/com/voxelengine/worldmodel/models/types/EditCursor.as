/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.events.AppEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.worldmodel.PermissionsBase;
import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.ui.Keyboard;
import flash.utils.Timer;
import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.AppEvent;
import com.voxelengine.events.CursorOperationEvent;
import com.voxelengine.events.CursorShapeEvent;
import com.voxelengine.events.CursorSizeEvent;
import com.voxelengine.pools.LightingPool;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.*;
import com.voxelengine.worldmodel.inventory.ObjectModel;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelCache;
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelPlacementType;
import com.voxelengine.worldmodel.models.makers.ModelMakerCursor;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.tasks.flowtasks.CylinderOperation;
import com.voxelengine.worldmodel.tasks.flowtasks.SphereOperation;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class EditCursor extends VoxelModel
{
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Static data
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static private var _s_currentInstance:EditCursor;

	static public const 		EDIT_CURSOR:String 		= "EditCursor";
	static 	private	const 		SCALE_FACTOR:Number 			= 0.01;
		
	static private const 		EDITCURSOR_SQUARE:uint				= 1000;
	static private const 		EDITCURSOR_ROUND:uint				= 1001;
	static private const 		EDITCURSOR_CYLINDER:uint			= 1002;
	static private const 		EDITCURSOR_CYLINDER_ANIMATED:uint	= 1003;
	static private const 		EDITCURSOR_INVALID:uint				= 1004;
	static private const 		EDITCURSOR_HAND_LR:uint				= 1005;
	static private const 		EDITCURSOR_HAND_UD:uint				= 1006;
	static private var 			_s_listenersAdded:Boolean;
	
	
	static private var 			_editing:Boolean;
	static public function  get editing():Boolean 					{ return _editing; }
	static public function  set editing(val:Boolean):void 			{ _editing = val; }
	
	static public function get currentInstance():EditCursor {
		if ( null == _s_currentInstance ) {
			var instanceInfo:InstanceInfo = new InstanceInfo();
			instanceInfo.modelGuid = EDIT_CURSOR
			_s_currentInstance = new EditCursor( instanceInfo );

			var metadata:ModelMetadata = new ModelMetadata( EDIT_CURSOR );
			var newObj:Object = ModelMetadata.newObject()
			metadata.fromObjectImport( newObj );
			metadata.permissions.modify = false;
			
			var modelInfo:ModelInfo = new ModelInfo( EDIT_CURSOR );
			var newECDbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_MODEL_INFO, "0", "0", 0, true, null );
			newECDbo.model = new Object();
			newECDbo.model.modelClass = EDIT_CURSOR;
			newECDbo.model.fileName = EDIT_CURSOR;
			modelInfo.fromObject( newECDbo );
			
			_s_currentInstance.init( modelInfo, metadata );
			_s_currentInstance.modelInfo.createEditCursor( EDIT_CURSOR );
		}
		return _s_currentInstance;
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// instance data
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private 			var	_repeatTime:int = 100;
	private 			var _repeatTimer:Timer;
	private  			var _count:int = 0;
	private 			var _phase:Number = 0; // used by the rainbow cursor
	private 			var _pl:PlacementLocation 						= new PlacementLocation();	
	
	private 		  	var _cursorOperation:String 					= CursorOperationEvent.NONE;
	private  function 	get cursorOperation():String 					{ return _cursorOperation; }
	private  function 	set cursorOperation(val:String):void 			{ 
		//Log.out( "EditCursor.cursorOperation", Log.WARN )
		if ( _cursorOperation == CursorOperationEvent.NONE ) {
			Log.out( "EditCursor.cursorOperation - reseting", Log.WARN )
			repeatTimerStop()
		}
		_cursorOperation = val; 
	}
	
	private 		 	var _cursorShape:String 						= CursorShapeEvent.SQUARE;		// round, square, cylinder
	private function 	get cursorShape():String 						{ return _cursorShape; }
	private function 	set cursorShape(val:String):void 				{ _cursorShape = val; }
	
	private 			var   _gciData:GrainCursorIntersection 			= null;
	public function 	get gciData():GrainCursorIntersection 			{ return _gciData; }
	public function 	set gciData(value:GrainCursorIntersection):void { _gciData = value; }
	
	
	private 			var _objectModel:VoxelModel;
	private function 	get	objectModel( ):VoxelModel { return _objectModel;}
	private function 		objectModelClear():void { _objectModel = null; }
	
	// This saves the last valid texture that was set.
	private 		  	var _oxelTextureValid:int		 				= EDITCURSOR_SQUARE;
	public function 	get oxelTextureValid():int 						{ return _oxelTextureValid; }
	public function 	set oxelTextureValid(value:int):void  			{ _oxelTextureValid = value; }
	
	private 		  	var _oxelTexture:int			 				= EDITCURSOR_SQUARE;
	private  function 	get oxelTexture():int 							{ return _oxelTexture; }
	private  function 	set oxelTexture(val:int):void 					{ _oxelTexture = val; }
	
	////////////////////////////////////////////////
	// EditCursor creation/removal
	public function EditCursor( instanceInfo:InstanceInfo ):void {
		super( instanceInfo );
	}

	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
		AppEvent.addListener( AppEvent.APP_DEACTIVATE, onDeactivate );
		AppEvent.addListener( AppEvent.APP_ACTIVATE, onActivate );
		
		addListeners();
	}
	
	override public function release():void {
		super.release();
		
		removeListeners();
		
		AppEvent.removeListener( AppEvent.APP_DEACTIVATE, onDeactivate );
		AppEvent.removeListener( AppEvent.APP_ACTIVATE, onActivate );
	}
	
	protected function onDeactivate( e:AppEvent ):void  {
		//Log.out( "onDeactivate - disabling repeat" );
		// We dont want the repeat on if app loses focus
		mouseUp( null );
		removeListeners();
		reset()
	}
	
	protected function onActivate( e:AppEvent ):void  { addListeners(); }
	
	////////////////////////////////////////////////
	// CursorSizeEvents
	private function sizeSetEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation
		  || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			if ( VoxelModel.selectedModel )
				if ( e.size <= VoxelModel.selectedModel.modelInfo.data.oxel.gc.bound && 0 <= e.size ) {
					modelInfo.data.oxel.gc.bound = e.size;
					modelInfo.data.oxel.gc.grain = e.size;
				}
				else {	
					// reseting so I have to inform others
					modelInfo.data.oxel.gc.bound = 4;
					modelInfo.data.oxel.gc.grain = 4;
					CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, modelInfo.data.oxel.gc.grain ) );
				}
			else {
				modelInfo.data.oxel.gc.bound = e.size;
				modelInfo.data.oxel.gc.grain = e.size;
			}
		}
	}
	private function sizeGrowEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			if ( modelInfo.data.oxel.gc.grain < 6 )
				modelInfo.data.oxel.gc.grain++;
			CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, modelInfo.data.oxel.gc.grain ) );
		}
	}
	private function sizeShrinkEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			if ( 0 < modelInfo.data.oxel.gc.grain )
				modelInfo.data.oxel.gc.grain--;
			CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, modelInfo.data.oxel.gc.grain ) );
		}
	}
	
	////////////////////////////////////////////////
	// CursorOperationEvents
	private function resetEvent(e:CursorOperationEvent):void { reset() }
		
	private function deactivate(e:AppEvent):void { reset() }
		
	private function reset():void {		
		//Log.out( "EditCursor.resetEvent", Log.WARN )
		_editing = false;
		cursorShape = CursorShapeEvent.SQUARE;
		// The change to NONE turns off the repeat timer
		cursorOperation = CursorOperationEvent.NONE;
	}
	private function deleteOxelEvent(e:CursorOperationEvent):void {
		_editing = true;
		cursorOperation = e.type;
		if ( CursorShapeEvent.CYLINDER == cursorShape )
			oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_CYLINDER;
		else if ( CursorShapeEvent.SPHERE == cursorShape )
			oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_ROUND;
		else if ( CursorShapeEvent.SQUARE == cursorShape )
			oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_SQUARE;
		objectModelClear();
	}
	private function insertOxelEvent(e:CursorOperationEvent):void {
		_editing = true;
		cursorOperation = e.type;
		oxelTextureValid = oxelTexture = e.oxelType;
		objectModelClear();
	}
	private function deleteModelEvent(e:CursorOperationEvent):void {
		_editing = true;
		cursorShape = CursorShapeEvent.MODEL_AUTO;
		cursorOperation = e.type;
	}
	private function insertModelEvent(e:CursorOperationEvent):void {
		Log.out( "EditCursor.insertModelEvent", Log.WARN );
		_editing = true;
		cursorShape = CursorShapeEvent.MODEL_AUTO;
		cursorOperation = e.type;
		oxelTextureValid = oxelTexture = e.oxelType;
		
		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = e.om.modelGuid;
		var mm:ModelMakerCursor = new ModelMakerCursor( ii, e.om.vmm );
	}
	
	////////////////////////////////////////////////
	// CursorShapeEvents
	private function shapeSetEvent(e:CursorShapeEvent):void { 
		_cursorShape = e.type 

		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_MODEL == cursorOperation ) {	
			if ( CursorShapeEvent.CYLINDER == cursorShape )
				oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_CYLINDER;
			else if ( CursorShapeEvent.SPHERE == cursorShape )
				oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_ROUND;
			else if ( CursorShapeEvent.SQUARE == cursorShape )
				oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_SQUARE;
		}
	}
	
	private function removeListeners():void {	
		//Log.out( "EditCursor.removeListeners", Log.WARN );
		//_s_listenersAdded = false;
		//CursorOperationEvent.removeListener( CursorOperationEvent.NONE, 		resetEvent );
		//CursorOperationEvent.removeListener( CursorOperationEvent.DELETE_OXEL, 	deleteOxelEvent );
		//CursorOperationEvent.removeListener( CursorOperationEvent.DELETE_MODEL, deleteModelEvent );
		//CursorOperationEvent.removeListener( CursorOperationEvent.INSERT_OXEL, 	insertOxelEvent );
		//CursorOperationEvent.removeListener( CursorOperationEvent.INSERT_MODEL, insertModelEvent );
		//
		//CursorShapeEvent.removeListener( CursorShapeEvent.CYLINDER, 	shapeSetEvent );
		//CursorShapeEvent.removeListener( CursorShapeEvent.MODEL_AUTO, 	shapeSetEvent );
		//CursorShapeEvent.removeListener( CursorShapeEvent.SPHERE, 		shapeSetEvent );
		//CursorShapeEvent.removeListener( CursorShapeEvent.SQUARE, 		shapeSetEvent );
		//
		//CursorSizeEvent.removeListener( CursorSizeEvent.SET, 			sizeSetEvent );
		//CursorSizeEvent.removeListener( CursorSizeEvent.GROW, 			sizeGrowEvent );
		//CursorSizeEvent.removeListener( CursorSizeEvent.SHRINK, 		sizeShrinkEvent );
//
		//Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		//Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_UP, 	mouseUp);
		//Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_DOWN, 	mouseDown);
		//Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_MOVE, 	mouseMove);
	}
	
	private function addListeners():void {
		
		if ( _s_listenersAdded )
			return;
			
		_s_listenersAdded = true;	
		CursorOperationEvent.addListener( CursorOperationEvent.NONE, 			resetEvent )
		CursorOperationEvent.addListener( CursorOperationEvent.DELETE_OXEL, 	deleteOxelEvent );
		CursorOperationEvent.addListener( CursorOperationEvent.DELETE_MODEL, 	deleteModelEvent);
		CursorOperationEvent.addListener( CursorOperationEvent.INSERT_OXEL, 	insertOxelEvent );
		CursorOperationEvent.addListener( CursorOperationEvent.INSERT_MODEL, 	insertModelEvent );
		
		CursorShapeEvent.addListener( CursorShapeEvent.CYLINDER, 		shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.MODEL_AUTO, 		shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.SPHERE, 			shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.SQUARE, 			shapeSetEvent );
		
		CursorSizeEvent.addListener( CursorSizeEvent.SET, 			sizeSetEvent );
		CursorSizeEvent.addListener( CursorSizeEvent.GROW, 			sizeGrowEvent );
		CursorSizeEvent.addListener( CursorSizeEvent.SHRINK, 		sizeShrinkEvent );
		
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_UP, 	 mouseUp);
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);			
	}

	
	////////////////////////////////////////////////
	// EditCursor positioning
	public function gciDataClear():void { gciData = null; }
	public function gciDataSet( $gciData:GrainCursorIntersection ):void {
		_gciData = $gciData;
		modelInfo.data.oxel.gc.bound = $gciData.model.modelInfo.data.oxel.gc.bound;
		//// This cleans up (int) the location of the gc
		var gct:GrainCursor = GrainCursorPool.poolGet( $gciData.model.modelInfo.data.oxel.gc.bound );
		GrainCursor.roundToInt( $gciData.point.x, $gciData.point.y, $gciData.point.z, gct );
		// we have to make the grain scale up to the size of the edit cursor
		gct.become_ancestor( modelInfo.data.oxel.gc.grain );
		_gciData.gc.copyFrom( gct );
		GrainCursorPool.poolDispose( gct );
	}
	
	
	public function objectModelSet( $om:VoxelModel ):void {
		Log.out( "EditCursor.objectModelSet - model: " + $om.toString(), Log.DEBUG );
		_objectModel = $om;
	}
	
	public function drawCursor($mvp:Matrix3D, $context:Context3D, $isChild:Boolean, $alpha:Boolean ):void	{
		// if there is a parent, adjust matrix for it first
		if ( VoxelModel.selectedModel && gciData ) { // This means type cursor
			var viewMatrixParent:Matrix3D = VoxelModel.selectedModel.instanceInfo.worldSpaceMatrix.clone();
			viewMatrixParent.append($mvp);
			$mvp = viewMatrixParent;
		}
		
		if ( objectModel && objectModel.complete ) {
			objectModel.draw( $mvp, $context, true, $alpha );
		}

		if ( gciData ) { // if no intersection dont draw
			var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
			viewMatrix.prependScale( 1 + SCALE_FACTOR, 1 + SCALE_FACTOR, 1 + SCALE_FACTOR ); 
			var positionscaled:Vector3D = viewMatrix.position;
			var t:Number = modelInfo.data.oxel.gc.size() * SCALE_FACTOR/2;
			viewMatrix.prependTranslation( -t, -t, -t)
			viewMatrix.append($mvp);
			
			modelInfo.draw( viewMatrix, this, $context, selected, $isChild, $alpha )
		}
	}
	
	override public function update($context:Context3D, elapsedTimeMS:int ):void {
		super.update( $context, elapsedTimeMS );
		
		gciData = null;
		// this puts the insert/delete location if appropriate into the gciData
		if ( cursorOperation != CursorOperationEvent.NONE )
			ModelCacheUtils.highLightEditableOxel();

		// We generate gci data for INSERT_MODEL with cursorShape == MODEL_CHILD || MODEL_AUTO
		if ( gciData ) {
			if ( cursorOperation == CursorOperationEvent.INSERT_OXEL || cursorOperation == CursorOperationEvent.INSERT_MODEL ) {
				// This gets the closest open oxel along the ray
				insertLocationCalculate( gciData.model );
				PlacementLocation.INVALID == _pl.state ?  oxelTexture = EDITCURSOR_INVALID : oxelTexture = oxelTextureValid;

				if ( cursorShape == CursorShapeEvent.MODEL_AUTO && objectModel )
					objectModel.instanceInfo.positionSetComp( _pl.gc.getModelX(), _pl.gc.getModelY(), _pl.gc.getModelZ() );

				instanceInfo.positionSetComp( _pl.gc.getModelX(), _pl.gc.getModelY(), _pl.gc.getModelZ() );
			}
			else if ( cursorOperation == CursorOperationEvent.DELETE_OXEL || cursorOperation == CursorOperationEvent.DELETE_MODEL ) {
				instanceInfo.positionSetComp( _gciData.gc.getModelX(), _gciData.gc.getModelY(), _gciData.gc.getModelZ() );
			}
			buildCursorModel();	
		} 
		
		if ( !gciData && objectModel && objectModel.complete && objectModel.modelInfo.data ) { // this is the INSERT_MODEL where its not on a parent model
			oxelTexture = oxelTextureValid;
			var vv:Vector3D = ModelCacheUtils.viewVectorNormalizedGet();
			vv.scaleBy( objectModel.modelInfo.data.oxel.gc.size() * 4 );
			vv = vv.add( VoxelModel.controlledModel.instanceInfo.positionGet );
			objectModel.instanceInfo.positionSet = vv;
		}
		
		if ( objectModel )
			objectModel.update($context, elapsedTimeMS );
	}
	
	private function buildCursorModel():void {	
		modelInfo.data.oxel.reset();
		
		if ( objectModel ) {
			modelInfo.data.oxel.gc.bound = _objectModel.grain;
			modelInfo.data.oxel.gc.grain = _objectModel.grain;
		}
		if ( CursorShapeEvent.CYLINDER == cursorShape || CursorShapeEvent.SPHERE == cursorShape ) {
			// I could use gciData.near to determine which single face to use, but seems like overkill
			if ( Globals.AXIS_X == _gciData.axis ) {
				modelInfo.data.oxel.faceSet( Globals.POSX );
				modelInfo.data.oxel.faceSet( Globals.NEGX );
			} else if ( Globals.AXIS_Y == _gciData.axis ) {
				modelInfo.data.oxel.faceSet( Globals.POSY );
				modelInfo.data.oxel.faceSet( Globals.NEGY );
			} else {
				modelInfo.data.oxel.faceSet( Globals.POSZ );
				modelInfo.data.oxel.faceSet( Globals.NEGZ );
			}
		} else {	
			modelInfo.data.oxel.faceSet( Globals.POSX );
			modelInfo.data.oxel.faceSet( Globals.NEGX );
			modelInfo.data.oxel.faceSet( Globals.POSY );
			modelInfo.data.oxel.faceSet( Globals.NEGY );
			modelInfo.data.oxel.faceSet( Globals.POSZ );
			modelInfo.data.oxel.faceSet( Globals.NEGZ );
		}
		
		if ( !modelInfo.data.oxel.lighting )
			modelInfo.data.oxel.lighting = LightingPool.poolGet( 0xff );
		var li:LightInfo = modelInfo.data.oxel.lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
		modelInfo.data.oxel.lighting.setAll( Lighting.DEFAULT_LIGHT_ID, Lighting.MAX_LIGHT_LEVEL );
		modelInfo.data.oxel.write( EDIT_CURSOR, modelInfo.data.oxel.gc, oxelTexture, true );
		
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation )
			li.color = cursorColorRainbow();
		else if ( CursorOperationEvent.INSERT_OXEL == cursorOperation && EDITCURSOR_INVALID == oxelTexture )
			li.color = 0x00ff0000; // RED for invalid
		else if ( CursorOperationEvent.INSERT_MODEL == cursorOperation && EDITCURSOR_INVALID == oxelTexture )
			li.color = 0x00ff0000; // RED for invalid
		else
			li.color = 0xffffffff;
		
		modelInfo.data.oxel.quadsBuild();

		function cursorColorRainbow():uint {
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
	}
	
	private function isAvatarInsideThisOxel( vm:VoxelModel, oxel:Oxel ):Boolean {
		var mp:Vector3D = vm.worldToModel( ModelCacheUtils.worldSpaceStartPoint );
		// check head
		var result:Boolean = modelInfo.data.oxel.gc.is_point_inside( mp );
		// and foot
		mp.y -= Globals.AVATAR_HEIGHT;
		result = result || modelInfo.data.oxel.gc.is_point_inside( mp );
		return result;
	}
	
	public function getHighlightedOxel(recurse:Boolean = false):Oxel {
		
		var foundModel:VoxelModel = VoxelModel.selectedModel;
		// placementResult - { oxel:Globals.BAD_OXEL, gci:gci, positive:posMove, negative:negMove };
		insertLocationCalculate( foundModel );
		if ( PlacementLocation.INVALID == _pl.state )
		{
			Log.out( "EditCursor.getHighlightedOxel NO PLACEMENT FOUND" );
			return Globals.BAD_OXEL;
		}
		var oxelToBeModified:Oxel = foundModel.modelInfo.data.oxel.childGetOrCreate( _pl.gc );
		if ( Globals.BAD_OXEL == oxelToBeModified )
		{
			Log.out( "EditCursor.getHighlightedOxel BAD OXEL OLD" );
			if ( recurse )
				return Globals.BAD_OXEL;
				
			if ( _pl )
				return Globals.BAD_OXEL;
				
			if ( EditCursor.currentInstance.gciData )
			{
				Log.out( "EditCursor.getHighlightedOxel BAD OXEL NEW gciData.point" + EditCursor.currentInstance.gciData.point + "  gciData.gc: " + EditCursor.currentInstance.gciData.gc );
				// What does this do?
				insertOxel( true );
				return Globals.BAD_OXEL;
			}
//					foundModel.grow( _pl );
		}
		
		return oxelToBeModified;
	}
	
	private function insertModel():void {
		if ( CursorOperationEvent.INSERT_MODEL != cursorOperation )
			return
		if ( EDITCURSOR_INVALID == oxelTexture )
			return
		if ( !objectModel )
			return
			
		var ii:InstanceInfo = objectModel.instanceInfo.clone();
		if ( VoxelModel.selectedModel && PlacementLocation.INVALID != _pl.state) {
			ii.controllingModel = VoxelModel.selectedModel;
			// This places an oxel that is invisible, but collidable at the same location as the model
			// This should lock the model to that location, otherwise the oxel is invalid.
			VoxelModel.selectedModel.write( _pl.gc, 99 );
			// This adds a link from the model to the placement location
			ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelInsertComplete );			
		}
		
		Log.out( "EditCursor.insertModel - before load" );		
		ModelMakerBase.load( ii, true );
		Log.out( "EditCursor.insertModel - after load" );		
		
		//Now we need to listen for the model to be built, then use associatedGrain to see the location on the new ModelBaseEvent
		function modelInsertComplete( $mle:ModelLoadingEvent ): void {
			if ( $mle.modelGuid == ii.modelGuid && $mle.vm.instanceInfo.instanceGuid == ii.instanceGuid ) {
				Log.out( "EditCursor.insertModel - Set associated grain here", Log.WARN );
				$mle.vm.associatedGrain = _pl.gc;
			}
		}
	}
	
	private function insertOxel(recurse:Boolean = false):void {
		if ( CursorOperationEvent.INSERT_OXEL != cursorOperation )
			return;

		var foundModel:VoxelModel = VoxelModel.selectedModel;
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
			
			if ( CursorShapeEvent.SQUARE == cursorShape )
			{
				foundModel.write( oxelToBeModified.gc, oxelTexture );
			}
			else if ( CursorShapeEvent.SPHERE == cursorShape )
			{
				sphereOperation();				 
			}
			else if ( CursorShapeEvent.CYLINDER == cursorShape )
			{
				cylinderOperation();				 
			}
		}
	}
	
	private function insertLocationCalculate( foundModel:VoxelModel ):void {
		var gci:GrainCursorIntersection = EditCursor.currentInstance.gciData;
		if ( !gci )
			return;
			
		// determines whether a block can be placed
		// calculate difference between avatar location and intersection point
		var diffPos:Vector3D = Player.player.wsPositionGet().clone();
		diffPos = diffPos.subtract( gci.wsPoint );
		
		_pl.reset();
		_pl.state = PlacementLocation.VALID;
		// copy the location of the cursor in the larger model
		// since we are testing on this, we need to use a copy
		_pl.gc.copyFrom( gci.gc );
		// test the results of the step, to see if a blocks has been sent out of bounds.
		switch ( gci.axis ) {
		case Globals.AXIS_X:
			if ( 0 < diffPos.x ) {
				if ( !_pl.gc.move_posx() ) _pl.state = PlacementLocation.INVALID;
				_pl.positive = true;
			} else {
				if ( !_pl.gc.move_negx() ) _pl.state = PlacementLocation.INVALID;
				_pl.negative = true;
			}
			break;
		case Globals.AXIS_Y:
			if ( 0 < diffPos.y ) {
				if ( !_pl.gc.move_posy() ) _pl.state = PlacementLocation.INVALID;
				_pl.positive = true;
			} else {
				if ( !_pl.gc.move_negy() ) _pl.state = PlacementLocation.INVALID;
				_pl.negative = true;
			}
			break;
		case Globals.AXIS_Z:
			if ( 0 < diffPos.z ) {
				if ( !_pl.gc.move_posz() ) _pl.state = PlacementLocation.INVALID;
				_pl.positive = true;
			} else {	
				if ( !_pl.gc.move_negz() ) _pl.state = PlacementLocation.INVALID;
				_pl.negative = true;
			}
			break;
		}
			
		return;
	}
	
	static private function getOxelFromPoint( vm:VoxelModel, gci:GrainCursorIntersection ):Oxel {
		var gcDelete:GrainCursor = GrainCursorPool.poolGet( vm.modelInfo.data.oxel.gc.bound );
		// This is where it intersects with a grain 0
		gcDelete.grainX = int( EditCursor.currentInstance.instanceInfo.positionGet.x + 0.05 );
		gcDelete.grainY = int( EditCursor.currentInstance.instanceInfo.positionGet.y + 0.05 );
		gcDelete.grainZ = int( EditCursor.currentInstance.instanceInfo.positionGet.z + 0.05 );
		// we have to make the grain scale up to the size of the edit cursor
		gcDelete.become_ancestor( EditCursor.currentInstance.modelInfo.data.oxel.gc.grain );
		var oxelToBeDeleted:Oxel = vm.modelInfo.data.oxel.childFind( gcDelete );
		GrainCursorPool.poolDispose( gcDelete );
		return oxelToBeDeleted;
	}
	
	private function deleteOxel():void {
		if ( CursorOperationEvent.DELETE_OXEL != cursorOperation )
			return;

		var foundModel:VoxelModel;
		if ( VoxelModel.selectedModel )
		{
			Player.player.stateSet( "Pick", 1 );
			Player.player.stateLock( true, 300 );
			
			foundModel = VoxelModel.selectedModel;
			var fmRoot:Oxel = foundModel.modelInfo.data.oxel;
			if ( CursorShapeEvent.SQUARE == cursorShape )
			{
				var gcDelete:GrainCursor = GrainCursorPool.poolGet(foundModel.modelInfo.data.oxel.gc.bound);
				// This is where it intersects with a grain 0
				gcDelete.grainX = int( EditCursor.currentInstance.instanceInfo.positionGet.x + 0.05 );
				gcDelete.grainY = int( EditCursor.currentInstance.instanceInfo.positionGet.y + 0.05 );
				gcDelete.grainZ = int( EditCursor.currentInstance.instanceInfo.positionGet.z + 0.05 );
				// we have to make the grain scale up to the size of the edit cursor
				gcDelete.become_ancestor( EditCursor.currentInstance.modelInfo.data.oxel.gc.grain );
				var oxelToBeDeleted:Oxel = foundModel.modelInfo.data.oxel.childGetOrCreate( gcDelete );
				if ( Globals.BAD_OXEL != oxelToBeDeleted )
					foundModel.write( gcDelete, TypeInfo.AIR );
				GrainCursorPool.poolDispose( gcDelete );
			}
			else if ( CursorShapeEvent.SPHERE == cursorShape )
			{
				var gci:GrainCursorIntersection = EditCursor.currentInstance.gciData;
				var cuttingPoint:Vector3D = new Vector3D();
				if ( Globals.AXIS_X == gci.axis ) // x
				{
					cuttingPoint.x = gci.point.x;
					cuttingPoint.y = gci.gc.getModelY() + gci.gc.size() / 2;
					cuttingPoint.z = gci.gc.getModelZ() + gci.gc.size() / 2;
				}
				else if ( Globals.AXIS_X == gci.axis )  // y
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
			else if ( CursorShapeEvent.CYLINDER == cursorShape )
			{
				cylinderOperation();				 
			}
			else
			{
				throw new Error( "EditCursor.deleteOxel - Cursor type not found" );
			}
		}
	}

	private function sphereOperation():void {
		var foundModel:VoxelModel = VoxelModel.selectedModel;
		if ( foundModel )
		{
			var gciCyl:GrainCursorIntersection = EditCursor.currentInstance.gciData;
			var where:GrainCursor = null;
			
			var radius:int = gciCyl.gc.size()/2;
			
			var what:int = oxelTexture;
			if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
			{
				insertLocationCalculate( foundModel );
				if ( PlacementLocation.INVALID == _pl.state )
					return;
				
				//where = _pl.gci.gc;
				where = _pl.gc;
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
			
			var minGrain:int = Math.max( EditCursor.currentInstance.modelInfo.data.oxel.gc.grain - 4, 0 );
			var startingGrain:int = EditCursor.currentInstance.modelInfo.data.oxel.gc.grain - 1;
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
	
	private function cylinderOperation():void {
		var foundModel:VoxelModel = VoxelModel.selectedModel;
		if ( foundModel && EditCursor.currentInstance.gciData )
		{
			var gciCyl:GrainCursorIntersection = EditCursor.currentInstance.gciData;
			var where:GrainCursor = null;
			
			var offset:int = 0;
			var radius:int = gciCyl.gc.size()/2;
			var cuttingPointCyl:Vector3D = new Vector3D();
			if ( Globals.AXIS_X == gciCyl.axis ) // x
			{
				cuttingPointCyl.x = gciCyl.point.x + offset;
				cuttingPointCyl.y = gciCyl.gc.getModelY() + radius;
				cuttingPointCyl.z = gciCyl.gc.getModelZ() + radius;
			}
			else if ( Globals.AXIS_Y == gciCyl.axis )  // y
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
			
			var what:int = oxelTexture;
			if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
			{
				offset = gciCyl.gc.size();
				insertLocationCalculate( foundModel );
				if ( PlacementLocation.INVALID == _pl.state )
					return;
				
				//where = temp.gci.gc;						
				where = _pl.gc;
			}
			else // CURSOR_OP_DELETE
			{
				where = gciCyl.gc;
				radius -= radius / 8
				//radius += radius / 16
				what = TypeInfo.AIR;
			}
				
			var minGrain:int = Math.max( EditCursor.currentInstance.modelInfo.data.oxel.gc.grain - 5, 0 );
			var startingGrain:int = EditCursor.currentInstance.modelInfo.data.oxel.gc.grain - 1;
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
	
	private function keyUp(e:KeyboardEvent):void  {
		if ( Globals.openWindowCount || !Globals.clicked )
			return;
			
		switch (e.keyCode) {
			case Keyboard.CONTROL:
				oxelTexture = oxelTextureValid
		}
	}
	
	private function keyDown(e:KeyboardEvent):void  {
		if ( Globals.openWindowCount || !Globals.clicked )
			return;

			
		var foundModel:VoxelModel;
		switch (e.keyCode) {
			case Keyboard.CONTROL:
				if ( MouseKeyboardHandler.leftMouseDown )
					oxelTexture = EDITCURSOR_HAND_UD
				else
					oxelTexture = EDITCURSOR_HAND_LR
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
					CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.GROW, 0 ) );
				break;
				
			case 34: case Keyboard.PAGE_DOWN:
					CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SHRINK, 0 ) );
				break;
		}
	}
	
	protected function onRepeat(event:TimerEvent):void {
		if ( Globals.openWindowCount )
			return;
			
		if ( 1 < _count )
		{
			if ( CursorOperationEvent.DELETE_OXEL == cursorOperation )
				deleteOxel();
			else if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
				insertOxel();
		}
		_count++;
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
			if ( 0 < dy )
				dy = 1
			else if ( dy < 0 )
				dy = -1
			_s_dy = Globals.g_app.stage.mouseY;
			var dx:Number =  Globals.g_app.stage.mouseX - _s_dx;
			if ( 0 < dx )
				dx = 1
			else if ( dx < 0 )
				dx = -1
			_s_dx = Globals.g_app.stage.mouseX
			//Log.out( "EditCursor.mouse move dx: " + dx + "  dy: " + dy + " _s_dx: " + _s_dx + "  _s_dy: " + _s_dy, Log.WARN );
			
			if ( VoxelModel.selectedModel ) {
				var t:Vector3D = VoxelModel.selectedModel.instanceInfo.positionGet;
				if ( MouseKeyboardHandler.leftMouseDown ) {
					t.y += dy;
					t.y += dx;
				} else {
					t.z += dy;
					t.x += dx;
				}
				VoxelModel.selectedModel.instanceInfo.positionSetComp( int(t.x), int(t.y), int(t.z) );
			}
		}
	}
	
	private function mouseUp(e:MouseEvent):void  {
		repeatTimerStop()
	}
	
	private function repeatTimerStop():void  {
		if ( _repeatTimer ) {
			_repeatTimer.removeEventListener( TimerEvent.TIMER, onRepeat );
			_repeatTimer.stop()
			_repeatTimer = null
			_count = 0
		}
	}
		
	private function mouseDown(e:MouseEvent):void {
		if ( Globals.openWindowCount || !Globals.clicked || e.ctrlKey || !Globals.active )
			return;
		if ( doubleMessageHack ) {
			//Log.out( "EditCursor.mouseDown", Log.WARN );	
				
			if ( null == _repeatTimer && 0 == _count) {
				_repeatTimer = new Timer( 200 );
				_repeatTimer.addEventListener(TimerEvent.TIMER, onRepeat);
				_repeatTimer.start();
			}
			
			switch (e.type) 
			{
				case "mouseDown": case Keyboard.NUMPAD_ADD:
					if ( CursorOperationEvent.DELETE_OXEL == cursorOperation )
						deleteOxel();
					else if ( CursorOperationEvent.INSERT_MODEL == cursorOperation )
						insertModel();						
					else if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
						insertOxel();
					break;
			}
		}
	}
	
	import flash.utils.getTimer;
	private static const WAITING_PERIOD:int = 100;
	private var doubleMessageHackTime:int = getTimer();
	private function get doubleMessageHack():Boolean {
		var newTime:int = getTimer();
		var result:Boolean = false;
		if ( doubleMessageHackTime + WAITING_PERIOD < newTime )
			result = true;
			
		doubleMessageHackTime = newTime;
		return result;
	}
			
	private function onMouseWheel(event:MouseEvent):void {
		
		if ( true != event.shiftKey || null == objectModel )
			return;
			
		var rot:Vector3D = objectModel.instanceInfo.rotationGet;
		if ( 0 < event.delta )
			rot.y += 90;
		 else
			rot.y -= 90;

		objectModel.instanceInfo.rotationSet = rot
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
	
	public function reset():void {
		gc.reset();
		positive = false;
		negative = false;
		state = INVALID;
	}
}