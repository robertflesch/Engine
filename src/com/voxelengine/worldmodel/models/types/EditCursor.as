/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.ui.Keyboard;
import flash.utils.Timer;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.GUIEvent;
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
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelPlacementType;
import com.voxelengine.worldmodel.models.makers.ModelMakerCursor;
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

	static public const EDIT_CURSOR:String 		= "EditCursor";
	static 	private	const SCALE_FACTOR:Number 			= 0.01;
	
	static public const EDITCURSOR_SQUARE:uint				= 1000;
	static public const EDITCURSOR_ROUND:uint				= 1001;
	static public const EDITCURSOR_CYLINDER:uint			= 1002;
	static public const EDITCURSOR_CYLINDER_ANIMATED:uint	= 1003;
	static public const EDITCURSOR_INVALID:uint				= 1004;
	
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

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// instance data
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private 			var	  _repeatTime:int = 100;
	private 			var   _repeatTimer:Timer;
	private  			var   _count:int = 0;
	
	private 			var _listenersAdded:Boolean;
	
	private 		  	var _oxelTexture:int			 				= EDITCURSOR_SQUARE;
	private  function 	get oxelTexture():int 							{ return _oxelTexture; }
	private  function 	set oxelTexture(val:int):void 					{ _oxelTexture = val; }
	
	private 		  	var _cursorOperation:String 					= CursorOperationEvent.NONE;
	private  function 	get cursorOperation():String 					{ return _cursorOperation; }
	private  function 	set cursorOperation(val:String):void 			{ _cursorOperation = val; }
	
	private 		 	var _cursorShape:String 						= CursorShapeEvent.SQUARE;		// round, square, cylinder
	private function 	get cursorShape():String 						{ return _cursorShape; }
	private function 	set cursorShape(val:String):void 				{ _cursorShape = val; }
	
	private 			var   _gciData:GrainCursorIntersection 			= null;
	public function 	get gciData():GrainCursorIntersection 			{ return _gciData; }
	public function 	set gciData(value:GrainCursorIntersection):void { _gciData = value; }
	
	private 		 	var _editing:Boolean;
	public function  	get editing():Boolean 							{ return _editing; }
	
	private 			var _objectModel:VoxelModel;
	private function 	get	objectModel( ):VoxelModel { return _objectModel;}
	private function 		objectModelClear():void { _objectModel = null; }
	
	
	override public function get visible():Boolean { return super.visible; }
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
		removeListeners();
	}
	
	protected function onActivate( e:GUIEvent ):void  { addListeners(); }
	
	////////////////////////////////////////////////
	// CursorSizeEvents
	private function sizeGetRequestEvent(e:CursorSizeEvent):void {
		CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.GET_RESPONSE, oxel.gc.grain ) );
	}
	private function sizeSetEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation
		  || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
//			if ( VoxelModel.selectedModel )
//				if ( e.size < VoxelModel.selectedModel.oxel.gc.bound && 0 <= e.size )
					oxel.gc.grain = e.size;
		}
	}
	private function sizeGrowEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			if ( oxel.gc.grain < 8 )
			oxel.gc.grain++;
			CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, oxel.gc.grain ) );
		}
	}
	private function sizeShrinkEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			if ( 0 < oxel.gc.grain )
				oxel.gc.grain--;
			CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, oxel.gc.grain ) );
		}
	}
	
	////////////////////////////////////////////////
	// CursorOperationEvents
	private function resetEvent(e:CursorOperationEvent):void {
		_editing = false;
		cursorShape = CursorShapeEvent.SQUARE;
		cursorOperation = e.type;
	}
	private function deleteOxelEvent(e:CursorOperationEvent):void {
		_editing = true;
		cursorOperation = e.type;
		if ( CursorShapeEvent.CYLINDER == cursorShape )
			oxelTexture = EditCursor.EDITCURSOR_CYLINDER;
		else if ( CursorShapeEvent.SPHERE == cursorShape )
			oxelTexture = EditCursor.EDITCURSOR_ROUND;
		else if ( CursorShapeEvent.SQUARE == cursorShape )
			oxelTexture = EditCursor.EDITCURSOR_SQUARE;
		objectModelClear();
	}
	private function insertOxelEvent(e:CursorOperationEvent):void {
		_editing = true;
		cursorOperation = e.type;
		oxelTexture = e.oxelType;
		objectModelClear();
	}
	private function deleteModelEvent(e:CursorOperationEvent):void {
		_editing = true;
		cursorShape = CursorShapeEvent.MODEL_CHILD;
		cursorOperation = e.type;
	}
	private function insertModelEvent(e:CursorOperationEvent):void {
		_editing = true;
		cursorShape = CursorShapeEvent.MODEL_CHILD;
		cursorOperation = e.type;
	}
	
	////////////////////////////////////////////////
	// CursorShapeEvents
	private function shapeSetEvent(e:CursorShapeEvent):void { 
		_cursorShape = e.type 
		if ( CursorShapeEvent.MODEL_CHILD == _cursorShape )
			VoxelModel.selectedModel = objectModel;
		else if ( CursorShapeEvent.MODEL_PARENT == _cursorShape )
			VoxelModel.selectedModel = null;
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation ) {	
			if ( CursorShapeEvent.CYLINDER == cursorShape )
				oxelTexture = EditCursor.EDITCURSOR_CYLINDER;
			else if ( CursorShapeEvent.SPHERE == cursorShape )
				oxelTexture = EditCursor.EDITCURSOR_ROUND;
			else if ( CursorShapeEvent.SQUARE == cursorShape )
				oxelTexture = EditCursor.EDITCURSOR_SQUARE;
		}
	}
	
	////////////////////////////////////////////////
	// EditCursor creation/removal
	public function EditCursor( instanceInfo:InstanceInfo ):void {
		super( instanceInfo );
	}

	override public function initialize($context:Context3D ):void {
		internal_initialize($context );
		complete = true;
		Log.out( "EditCursor.initialize" );
	}
	
	override public function init( $mi:ModelInfo, $vmm:ModelMetadata, $initializeRoot:Boolean = true ):void {
		super.init( $mi, $vmm );
		oxel.gc.bound = 4;
		visible = false;
		oxel.vm_initialize( statisics );
		GUIEvent.addListener( GUIEvent.APP_DEACTIVATE, onDeactivate );
		GUIEvent.addListener( GUIEvent.APP_ACTIVATE, onActivate );
		
		addListeners();
	}
	
	override public function release():void {
		super.release();
		
		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		
		GUIEvent.removeListener( GUIEvent.APP_DEACTIVATE, onDeactivate );
		GUIEvent.removeListener( GUIEvent.APP_ACTIVATE, onActivate );
	}

	private function removeListeners():void {	
		_listenersAdded = false;
		CursorOperationEvent.removeListener( CursorOperationEvent.NONE, 		resetEvent );
		CursorOperationEvent.removeListener( CursorOperationEvent.DELETE_OXEL, 	deleteOxelEvent );
		CursorOperationEvent.removeListener( CursorOperationEvent.DELETE_MODEL, deleteModelEvent );
		CursorOperationEvent.removeListener( CursorOperationEvent.INSERT_OXEL, 	insertOxelEvent );
		CursorOperationEvent.removeListener( CursorOperationEvent.INSERT_MODEL, insertModelEvent );
		
		CursorShapeEvent.removeListener( CursorShapeEvent.CYLINDER, 	shapeSetEvent );
		CursorShapeEvent.removeListener( CursorShapeEvent.MODEL_CHILD, 	shapeSetEvent );
		CursorShapeEvent.removeListener( CursorShapeEvent.MODEL_PARENT, shapeSetEvent );
		CursorShapeEvent.removeListener( CursorShapeEvent.SPHERE, 		shapeSetEvent );
		CursorShapeEvent.removeListener( CursorShapeEvent.SQUARE, 		shapeSetEvent );
		
		CursorSizeEvent.removeListener( CursorSizeEvent.SET, 			sizeSetEvent );
		CursorSizeEvent.removeListener( CursorSizeEvent.GROW, 			sizeGrowEvent );
		CursorSizeEvent.removeListener( CursorSizeEvent.SHRINK, 		sizeShrinkEvent );
		CursorSizeEvent.removeListener( CursorSizeEvent.GET_REQUEST, 	sizeGetRequestEvent );

		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_UP, 	mouseUp);
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_DOWN, 	mouseDown);
		Globals.g_app.stage.removeEventListener(MouseEvent.MOUSE_MOVE, 	mouseMove);
	}
	
	private function addListeners():void {
		
		if ( _listenersAdded )
			return;
			
		_listenersAdded = true;	
		CursorOperationEvent.addListener( CursorOperationEvent.NONE, 			resetEvent );
		CursorOperationEvent.addListener( CursorOperationEvent.DELETE_OXEL, 	deleteOxelEvent );
		CursorOperationEvent.addListener( CursorOperationEvent.DELETE_MODEL, 	deleteModelEvent);
		CursorOperationEvent.addListener( CursorOperationEvent.INSERT_OXEL, 	insertOxelEvent );
		CursorOperationEvent.addListener( CursorOperationEvent.INSERT_MODEL, 	insertModelEvent );
		
		CursorShapeEvent.addListener( CursorShapeEvent.CYLINDER, 		shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.MODEL_CHILD, 	shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.MODEL_PARENT, 	shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.SPHERE, 			shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.SQUARE, 			shapeSetEvent );
		
		CursorSizeEvent.addListener( CursorSizeEvent.SET, 			sizeSetEvent );
		CursorSizeEvent.addListener( CursorSizeEvent.GROW, 			sizeGrowEvent );
		CursorSizeEvent.addListener( CursorSizeEvent.SHRINK, 		sizeShrinkEvent );
		CursorSizeEvent.addListener( CursorSizeEvent.GET_REQUEST, 	sizeGetRequestEvent );
		
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_UP, 	 mouseUp);
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_DOWN,  mouseDown);
		Globals.g_app.stage.addEventListener(MouseEvent.MOUSE_MOVE,  mouseMove);
	}
	
	////////////////////////////////////////////////
	// EditCursor creation/removal
	public function gciDataSet( $gciData:GrainCursorIntersection ):void {
		_gciData = $gciData;
		oxel.gc.bound = $gciData.model.oxel.gc.bound;
		//// This cleans up (int) the location of the gc
		var gct:GrainCursor = GrainCursorPool.poolGet( $gciData.model.oxel.gc.bound );
		GrainCursor.roundToInt( $gciData.point.x, $gciData.point.y, $gciData.point.z, gct );
		// we have to make the grain scale up to the size of the edit cursor
		gct.become_ancestor( oxel.gc.grain );
		_gciData.gc.copyFrom( gct );
		GrainCursorPool.poolDispose( gct );
		//
		//if ( CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			//configureInsertOxel();
		//}
		//else {
			//configureDeleteOxel();
		//}
	}
	
	public function gciDataClear():void { gciData = null; }
	
/*
	private function configureInsertOxel():void {
		
		var pl:PlacementLocation = getPlacementLocation( gciData.model );
		if ( PlacementLocation.INVALID == pl.state ) {
			oxelTexture = EDITCURSOR_INVALID; // ;
			instanceInfo.positionSetComp( _gciData.gc.getModelX(), _gciData.gc.getModelY(), _gciData.gc.getModelZ() );
		} else {
			instanceInfo.positionSetComp( pl.gc.getModelX(), pl.gc.getModelY(), pl.gc.getModelZ() );
		}
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
		oxel.write( EDIT_CURSOR, oxel.gc, oxelTexture, true );
		li.color = cursorColorRainbow();
		oxel.quadsBuild();
	}*/
	
	public function objectModelSet( $cm:VoxelModel ):void {
		_objectModel = $cm;
		oxel.gc.bound = oxel.gc.grain = $cm.oxel.gc.bound;
		if ( null == oxel.vm_get() )
			oxel.vm_initialize( statisics );
		if ( null == _objectModel.oxel.vm_get() )
			_objectModel.oxel.vm_initialize( _objectModel.statisics );
	}
	
	public function objectModelAdd( $om:ObjectModel ):void {
		var ii:InstanceInfo = new InstanceInfo();
		// Add the parent model info to the child.
//			ii.controllingModel = this;
		ii.baseLightLevel = Lighting.MAX_LIGHT_LEVEL;
		ii.modelGuid = $om.modelGuid;
		var mm:ModelMakerCursor = new ModelMakerCursor( ii, $om.vmm );
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
	
	
	public function drawCursor($mvp:Matrix3D, $context:Context3D, $isChild:Boolean, $alpha:Boolean ):void	{

		var viewMatrixParent:Matrix3D;
		// if we just have an object model, and no parent.
		if ( _objectModel ) {
//				Log.out( "EditCursor.drawCursor - _objectModel", Log.WARN );
			viewMatrixParent = _objectModel.instanceInfo.worldSpaceMatrix.clone();
			viewMatrixParent.append($mvp);
			$mvp = viewMatrixParent;
		} else if ( VoxelModel.selectedModel ) { // This means type cursor
//				Log.out( "EditCursor.drawCursor - selected model", Log.WARN );
			viewMatrixParent = VoxelModel.selectedModel.instanceInfo.worldSpaceMatrix.clone();
			viewMatrixParent.append($mvp);
			$mvp = viewMatrixParent;
		} else {
			//Log.out( "EditCursor.draw - no object model or selected model", Log.WARN );
			return;
		}
		
		var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
		viewMatrix.prependScale( 1 + SCALE_FACTOR, 1 + SCALE_FACTOR, 1 + SCALE_FACTOR ); 
		var positionscaled:Vector3D = viewMatrix.position;
		var t:Number = oxel.gc.size() * SCALE_FACTOR/2;
		viewMatrix.prependTranslation( -t, -t, -t)
		viewMatrix.append($mvp);
		
		if ( $alpha )
			oxel.vertMan.drawNewAlpha( viewMatrix, this, $context, _shaders, selected, $isChild );
		else	
			oxel.vertMan.drawNew( viewMatrix, this, $context, _shaders, selected, $isChild );
		
		if ( _objectModel )
			_objectModel.draw( $mvp, $context, true );
	}
	
	override public function update($context:Context3D, elapsedTimeMS:int ):void {
		
		gciData = null;
		if ( _cursorOperation == CursorOperationEvent.INSERT_OXEL || _cursorOperation == CursorOperationEvent.DELETE_OXEL )
			ModelCacheUtils.highLightEditableOxel();
		else if ( _cursorOperation == CursorOperationEvent.INSERT_MODEL || _cursorOperation == CursorOperationEvent.DELETE_MODEL )
			if ( _cursorShape == CursorShapeEvent.MODEL_CHILD )
				ModelCacheUtils.highLightEditableOxel();
		
		// We generate gci data for INSERT_MODEL with cursorShape == MODEL_CHILD
		if ( gciData ) {
			if ( _cursorOperation == CursorOperationEvent.INSERT_OXEL || _cursorOperation == CursorOperationEvent.INSERT_MODEL ) {
				// This gets the closest open oxel along the ray
				var pl:PlacementLocation = insertLocationCalculate( gciData.model );
				if ( PlacementLocation.INVALID == pl.state ) {
					oxelTexture = EDITCURSOR_INVALID; // ;
					instanceInfo.positionSetComp( _gciData.gc.getModelX(), _gciData.gc.getModelY(), _gciData.gc.getModelZ() );
				} else {
					instanceInfo.positionSetComp( pl.gc.getModelX(), pl.gc.getModelY(), pl.gc.getModelZ() );
					if ( cursorShape == CursorShapeEvent.MODEL_CHILD )
						_objectModel.instanceInfo.positionSetComp( pl.gc.getModelX(), pl.gc.getModelY(), pl.gc.getModelZ() );
				}
			}
			else if ( _cursorOperation == CursorOperationEvent.DELETE_OXEL || _cursorOperation == CursorOperationEvent.DELETE_MODEL ) {
				instanceInfo.positionSetComp( _gciData.gc.getModelX(), _gciData.gc.getModelY(), _gciData.gc.getModelZ() );
			}
		} else if ( _objectModel ) { // this is the INSERT_MODEL with cursorShape == MODEL_PARENT
			var newPos:Vector3D = Player.player.instanceInfo.modelToWorld( new Vector3D( 0,0, -(_objectModel.oxel.gc.size() * 2) ) );
			_objectModel.instanceInfo.positionSet = newPos;
			_objectModel.update($context, elapsedTimeMS );
			instanceInfo.positionSet = newPos;
		}

		buildCursorModel();	
		
		if ( _objectModel )
			_objectModel.instanceInfo.positionSet = instanceInfo.positionGet;
		
		internal_update($context, elapsedTimeMS );
		
	}
	
	override protected function internal_update($context:Context3D, $elapsedTimeMS:int):void
	{
		if (!initialized)
			initialize($context);
		
		if (oxel && oxel.dirty)
			oxel.cleanup();
	}
	
	private function buildCursorModel():void {	
		// the grain should never be larger then the bound
//		if ( oxel.gc.bound <  )
//			editCursorSize = oxel.gc.grain = oxel.gc.bound;
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
//		oxel.lighting.setAll( Lighting.DEFAULT_LIGHT_ID, Lighting.MAX_LIGHT_LEVEL );
		oxel.write( EDIT_CURSOR, oxel.gc, oxelTexture, true );
		
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation )
			li.color = cursorColorRainbow();
		else if ( CursorOperationEvent.INSERT_OXEL == cursorOperation && EDITCURSOR_INVALID == oxelTexture )
			li.color = 0x00ff0000; // RED for invalid
		else
			li.color = 0xffffffff;
		
		oxel.quadsBuild();
	}
		
	
	
	private function isAvatarInsideThisOxel( vm:VoxelModel, oxel:Oxel ):Boolean {
		var mp:Vector3D = vm.worldToModel( ModelCacheUtils.worldSpaceStartPoint );
		// check head
		var result:Boolean = oxel.gc.is_point_inside( mp );
		// and foot
		mp.y -= Globals.AVATAR_HEIGHT;
		result = result || oxel.gc.is_point_inside( mp );
		return result;
	}
	
	public function getHighlightedOxel(recurse:Boolean = false):Oxel {
		
		var foundModel:VoxelModel = VoxelModel.selectedModel;
		// placementResult - { oxel:Globals.BAD_OXEL, gci:gci, positive:posMove, negative:negMove };
		var placementResult:PlacementLocation = insertLocationCalculate( foundModel );
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
	
	private function insertModel():void {
		if ( CursorOperationEvent.INSERT_MODEL != cursorOperation )
			return;

		var newChild:VoxelModel = _objectModel.clone();
		if ( CursorShapeEvent.MODEL_CHILD == _cursorShape ) {
			var foundModel:VoxelModel = VoxelModel.selectedModel;
			if ( foundModel )
				foundModel.childAdd( newChild );
			else 
				Log.out( "EditCursor.insertModel - no parent model found", Log.WARN );
		}
		else {
			// same model, new instance.
			var newPos:Vector3D = Player.player.instanceInfo.modelToWorld( new Vector3D( 0,0, -(newChild.oxel.gc.size() * 2) ) );
			newChild.instanceInfo.positionSet = newPos;
			Region.currentRegion.modelCache.add( newChild );
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
	
	static private function insertLocationCalculate( foundModel:VoxelModel ):PlacementLocation {
		var gci:GrainCursorIntersection = EditCursor.currentInstance.gciData;
		var pl:PlacementLocation = new PlacementLocation();
		if ( !gci )
			return pl;
			
		// determines whether a block can be placed
		// calculate difference between avatar location and intersection point
		var diffPos:Vector3D = Player.player.wsPositionGet().clone();
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
	
	private function deleteOxel():void {
		if ( CursorOperationEvent.DELETE_OXEL != cursorOperation )
			return;

		var foundModel:VoxelModel;
		if ( VoxelModel.selectedModel )
		{
			Player.player.stateSet( "Pick", 1 );
			Player.player.stateLock( true, 300 );
			
			foundModel = VoxelModel.selectedModel;
			var fmRoot:Oxel = foundModel.oxel;
			if ( CursorShapeEvent.SQUARE == cursorShape )
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
			else if ( CursorShapeEvent.SPHERE == cursorShape )
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
				var placementResult:PlacementLocation = insertLocationCalculate( foundModel );
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
	
	private function cylinderOperation():void {
		var foundModel:VoxelModel = VoxelModel.selectedModel;
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
			
			var what:int = oxelTexture;
			if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
			{
				offset = gciCyl.gc.size();
				var pl:PlacementLocation = insertLocationCalculate( foundModel );
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
	
	private function keyDown(e:KeyboardEvent):void  {
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
			_s_dy = Globals.g_app.stage.mouseY;
			var dx:Number =  Globals.g_app.stage.mouseX - _s_dx;
			_s_dx = Globals.g_app.stage.mouseX
//				Log.out( "EditCursor.mouse move dx: " + dx + "  dy: " + dy );
			
		// do I need to add axis models?	
		//	this.childAdd();
			var t:Vector3D = VoxelModel.selectedModel.instanceInfo.positionGet;
			t.z += dy/4;
			t.x += dx/4;
			VoxelModel.selectedModel.instanceInfo.positionSetComp( t.x, t.y, t.z );
		}
	}
	
	private function mouseUp(e:MouseEvent):void  {
		if ( _repeatTimer )
			_repeatTimer.removeEventListener( TimerEvent.TIMER, onRepeat );
		_count = 0;	
	}
	
	private function mouseDown(e:MouseEvent):void {
		if ( Globals.openWindowCount || !Globals.clicked || e.ctrlKey )
			return;
			
		_repeatTimer = new Timer( 200 );
		_repeatTimer.addEventListener(TimerEvent.TIMER, onRepeat);
		_repeatTimer.start();
		
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