/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{


import com.voxelengine.events.VVKeyboardEvent;
import com.voxelengine.events.VVMouseEvent;
import com.voxelengine.worldmodel.models.ModelPlacementType;

import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.ui.Keyboard;
import flash.utils.Timer;
import flash.utils.getTimer;

import org.flashapi.swing.UIManager

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.CursorOperationEvent;
import com.voxelengine.events.CursorShapeEvent;
import com.voxelengine.events.CursorSizeEvent;
import com.voxelengine.events.ObjectHierarchyData;
import com.voxelengine.GUI.voxelModels.WindowBluePrintCopy;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.MouseKeyboardHandler;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.*;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.makers.ModelMakerCursor;
import com.voxelengine.worldmodel.tasks.flowtasks.CylinderOperation;
import com.voxelengine.worldmodel.tasks.flowtasks.SphereOperation;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube;

public class EditCursor extends VoxelModel
{
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Static data
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static private var _s_currentInstance:EditCursor;

	static public const 		EDIT_CURSOR:String 					= "EditCursor";
	static private	const 		SCALE_FACTOR:Number 				= 0.01;
		
	static private const 		EDITCURSOR_SQUARE:uint				= 1000;
	static private const 		EDITCURSOR_ROUND:uint				= 1001;
	static private const 		EDITCURSOR_CYLINDER:uint			= 1002;
	//static private const 		EDITCURSOR_CYLINDER_ANIMATED:uint	= 1003;
	static private const 		EDITCURSOR_INVALID:uint				= 1004;
	static private const 		EDITCURSOR_HAND_LR:uint				= 1005;
	static private const 		EDITCURSOR_HAND_UD:uint				= 1006;

	static private var 			_editing:Boolean;
	static private function  get editing():Boolean 					{ return _editing; }
	static private function  set editing(val:Boolean):void 			{ _editing = val; }
	static public function   get isEditing():Boolean 				{ return _editing; }

	static private var _lastSize:int;
	static private function set lastSize(val:int):void 				{ _lastSize = val; }
	static private function get lastSize():int 						{ return _lastSize; }

	
	static public function get currentInstance():EditCursor { return _s_currentInstance; }

	static public function createCursor():void {
		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = EDIT_CURSOR;
		var creationInfo:Object = GenerateCube.script( 4, TypeInfo.BLUE );
		creationInfo.modelClass = EDIT_CURSOR;
		creationInfo.name = EDIT_CURSOR;
		ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, buildComplete );
		new ModelMakerGenerate( ii, creationInfo, true, false );

		function buildComplete( $mle:ModelLoadingEvent ):void {
			var ohd:ObjectHierarchyData = $mle.data;
			if ( EDIT_CURSOR == ohd.modelGuid ) {
				_s_currentInstance = $mle.vm as EditCursor;
				ModelLoadingEvent.removeListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, buildComplete );
			}
		}
	}


	override public function set dead(val:Boolean):void {
		Log.out( "EditCursor.dead - THIS MODEL IS IMMORTAL", Log.WARN );
		// Do nothing for this object, since you dont want to have to recreate each time you change regions.
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// instance data
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private 			var _repeatTimer:Timer;
	private  			var _count:int = 0;
	private 			var _phase:Number = 0; // used by the rainbow cursor
	private 			var _pl:PlacementLocation 						= new PlacementLocation();	
	
	private 		  	var _cursorOperation:String 					= CursorOperationEvent.NONE;
	private  function 	get cursorOperation():String 					{ return _cursorOperation; }
	private  function 	set cursorOperation(val:String):void 			{
		_cursorOperation = val;
		if ( _cursorOperation == CursorOperationEvent.NONE ) {
			editing = false;
			repeatTimerStop()
		}
		else
			editing = true;
	}
	
	private 		 	var _cursorShape:String 						= CursorShapeEvent.SQUARE;		// round, square, cylinder
	private function 	get cursorShape():String 						{ return _cursorShape; }
	private function 	set cursorShape(val:String):void 				{ _cursorShape = val; }
	
	private 			var   _gciData:GrainIntersection 			= null;
	public function 	get gciData():GrainIntersection 			{ return _gciData; }
	public function 	set gciData(value:GrainIntersection):void { _gciData = value; }
	
	
	private 			var _objectModel:VoxelModel;
	public function 	get	objectModel( ):VoxelModel { return _objectModel;}
	public function 		objectModelClear():void { _objectModel = null; }
	
	// This saves the last valid texture that was set.
	private 		  	var _oxelTextureValid:int		 				= EDITCURSOR_SQUARE;
	private function 	get oxelTextureValid():int 						{ return _oxelTextureValid; }
	private function 	set oxelTextureValid(value:int):void  			{ _oxelTextureValid = value; }
	
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
		addListeners();
	}

	private function addListeners():void {
		CursorOperationEvent.addListener( CursorOperationEvent.NONE, 			resetEvent );
		CursorOperationEvent.addListener( CursorOperationEvent.DELETE_OXEL, 	deleteOxelEvent );
		//CursorOperationEvent.addListener( CursorOperationEvent.DELETE_MODEL, 	deleteModelEvent);
		CursorOperationEvent.addListener( CursorOperationEvent.INSERT_OXEL, 	insertOxelEvent );
		CursorOperationEvent.addListener( CursorOperationEvent.INSERT_MODEL, 	insertModelEvent );

		CursorShapeEvent.addListener( CursorShapeEvent.CYLINDER, 		shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.MODEL_AUTO, 		shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.SPHERE, 			shapeSetEvent );
		CursorShapeEvent.addListener( CursorShapeEvent.SQUARE, 			shapeSetEvent );

		CursorSizeEvent.addListener( CursorSizeEvent.SET, 			sizeSetEvent );
		CursorSizeEvent.addListener( CursorSizeEvent.GROW, 			sizeGrowEvent );
		CursorSizeEvent.addListener( CursorSizeEvent.SHRINK, 		sizeShrinkEvent );

		VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, keyDown);
		VVKeyboardEvent.addListener( KeyboardEvent.KEY_UP, keyUp);

		VVMouseEvent.addListener( MouseEvent.MOUSE_UP, 	  mouseUp );
		VVMouseEvent.addListener( MouseEvent.MOUSE_MOVE,  mouseMove );
		VVMouseEvent.addListener( MouseEvent.MOUSE_DOWN,  mouseDown );
		VVMouseEvent.addListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
	}
	
	////////////////////////////////////////////////
	// CursorSizeEvents
	////////////////////////////////////////////////
	private function sizeSetEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation
		  || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			if ( VoxelModel.selectedModel ) {
				var vmBound:int = VoxelModel.selectedModel.modelInfo.oxelPersistence.bound;
				if (e.size <= vmBound && 0 <= e.size) {
					lastSize = e.size;
				}
				else {
					// too big or too small
					lastSize = vmBound;
					//CursorSizeEvent.dispatch(new CursorSizeEvent(CursorSizeEvent.SET, modelInfo.oxelPersistence.bound));
				}
			} else {
				if ( modelInfo && modelInfo.oxelPersistence && modelInfo.oxelPersistence.oxelCount ) {
					lastSize = e.size;
				}
			}
		}
	}
	private function sizeGrowEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			var maxCursorSize:int = 6;
			if ( Globals.isDebug ){
				maxCursorSize = 31;
			}
			if ( modelInfo.oxelPersistence.oxel.gc.grain < maxCursorSize ) {
				modelInfo.oxelPersistence.oxel.gc.bound++;
				modelInfo.oxelPersistence.oxel.gc.grain++;
			}
			CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, modelInfo.oxelPersistence.oxel.gc.grain ) );
		}
	}
	private function sizeShrinkEvent(e:CursorSizeEvent):void {
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_OXEL == cursorOperation ) {
			if ( 0 < modelInfo.oxelPersistence.oxel.gc.grain )
				modelInfo.oxelPersistence.oxel.gc.grain--;
			CursorSizeEvent.dispatch( new CursorSizeEvent( CursorSizeEvent.SET, modelInfo.oxelPersistence.oxel.gc.grain ) );
		}
	}
	
	////////////////////////////////////////////////
	// CursorOperationEvents
	static private function resetEvent(e:CursorOperationEvent):void {
		editing = false
	}
	private function deleteOxelEvent(e:CursorOperationEvent):void {
		editing = true;
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
		editing = true;
		cursorOperation = e.type;
		oxelTextureValid = oxelTexture = e.oxelType;
		objectModelClear();
	}
//	private function deleteModelEvent(e:CursorOperationEvent):void {
//		editing = true;
//		cursorShape = CursorShapeEvent.MODEL_AUTO;
//		cursorOperation = e.type;
//	}
	private function insertModelEvent(e:CursorOperationEvent):void {
		Log.out( "EditCursor.insertModelEvent", Log.WARN );
		editing = true;
		cursorShape = CursorShapeEvent.MODEL_AUTO;
		cursorOperation = e.type;
		oxelTextureValid = oxelTexture = e.oxelType;
		
		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = e.om.modelGuid;
		new ModelMakerCursor( ii, e.om.vmm );
	}
	
	////////////////////////////////////////////////
	// CursorShapeEvents
	private function shapeSetEvent(e:CursorShapeEvent):void { 
		_cursorShape = e.type ;

		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation || CursorOperationEvent.INSERT_MODEL == cursorOperation ) {	
			if ( CursorShapeEvent.CYLINDER == cursorShape )
				oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_CYLINDER;
			else if ( CursorShapeEvent.SPHERE == cursorShape )
				oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_ROUND;
			else if ( CursorShapeEvent.SQUARE == cursorShape )
				oxelTextureValid = oxelTexture = EditCursor.EDITCURSOR_SQUARE;
		}
	}
	
	////////////////////////////////////////////////
	// EditCursor positioning
	public function gciDataClear():void { gciData = null; }
	public function gciDataSet( $gciData:GrainIntersection ):void {
		_gciData = $gciData;

		// This is to adjust the size of the cursor if it goes over a model
		// not fully function yet
		if ( ! _gciData.oxel ) {
			Log.out( "ModelCacheUtil.highLightEditableOxel - Why no oxel?")
		}
		//_gci.point = editableModel.worldToModel( _gci.point );
		// This is used to see if there is a model associated with that grain
		// if there is it has to be the size of the model
		if ( _gciData.oxel ) {
			var modelOxel:Oxel = _gciData.oxel.minimumOxelForModel();
			if ( modelOxel  ){
				//_gci.gc.copyFrom( modelOxel.gc );
				//_gci.oxel = modelOxel;
				_gciData.invalid = true;
			}
		}


		modelInfo.oxelPersistence.bound = $gciData.model.modelInfo.oxelPersistence.bound;
		if (modelInfo.oxelPersistence.oxel.gc.grain > modelInfo.oxelPersistence.bound)
			modelInfo.oxelPersistence.oxel.gc.grain = modelInfo.oxelPersistence.bound;
		//// This cleans up (int) the location of the gc
		var gct:GrainCursor = GrainCursorPool.poolGet($gciData.model.modelInfo.oxelPersistence.bound);
		GrainCursor.roundToInt($gciData.point.x, $gciData.point.y, $gciData.point.z, gct);
		// we have to make the grain scale up to the size of the edit cursor
		if ($gciData.invalid) {
			$gciData.invalid = false;
			gct.become_ancestor(gciData.oxel.gc.grain);
//			modelInfo.oxelPersistence.oxel.gc.bound = gciData.oxel.gc.bound;
//			modelInfo.oxelPersistence.oxel.gc.grain = gciData.oxel.gc.grain;
		} else {
			gct.become_ancestor(modelInfo.oxelPersistence.oxel.gc.grain);
		}
		_gciData.gc.copyFrom(gct);
		GrainCursorPool.poolDispose(gct);
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

		if ( gciData ) { // if no intersection don't draw
			var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
			viewMatrix.prependScale( 1 + SCALE_FACTOR, 1 + SCALE_FACTOR, 1 + SCALE_FACTOR ); 
			var t:Number = modelInfo.oxelPersistence.oxel.gc.size() * SCALE_FACTOR/2;
			viewMatrix.prependTranslation( -t, -t, -t);
			viewMatrix.append($mvp);
			
			modelInfo.draw( viewMatrix, this, $context, selected, $isChild, $alpha )
		}
	}
	
	override public function update($context:Context3D, elapsedTimeMS:int ):void {
		super.update( $context, elapsedTimeMS );
		
		gciData = null;
		// this puts the insert/delete location if appropriate into the gciData
		if ( cursorOperation != CursorOperationEvent.NONE )
			ModelCacheUtils.highLightEditableOxel( Globals.g_underwater ? TypeInfo.WATER : TypeInfo.AIR );

		// We generate gci data for INSERT_MODEL with cursorShape == MODEL_CHILD || MODEL_AUTO
		if ( gciData ) {
			if ( cursorOperation == CursorOperationEvent.INSERT_MODEL ) {
				insertLocationCalculate();
				// This gets the closest open oxel along the ray
				if ( ModelPlacementType.placementType == ModelPlacementType.PLACEMENT_TYPE_CHILD ) {
					PlacementLocation.INVALID == _pl.state ? oxelTexture = EDITCURSOR_INVALID : oxelTexture = oxelTextureValid;
				}
				else {
					_pl.state = PlacementLocation.VALID;
				}

				if ( objectModel && objectModel.metadata.bound < VoxelModel.selectedModel.metadata.bound )
					objectModel.instanceInfo.positionSetComp( _pl.gc.getModelX(), _pl.gc.getModelY(), _pl.gc.getModelZ() );
				else
					Log.out( "EditCursor.update - Cusror model is larger then selected model")

			} else  if ( cursorOperation == CursorOperationEvent.INSERT_OXEL ) {
				//Log.out( "EditCursor.update - CursorOperationEvent.INSERT_OXEL");
				insertLocationCalculate();
				PlacementLocation.INVALID == _pl.state ? oxelTexture = EDITCURSOR_INVALID : oxelTexture = oxelTextureValid;
				instanceInfo.positionSetComp( _pl.gc.getModelX(), _pl.gc.getModelY(), _pl.gc.getModelZ() );
			}
			else if ( cursorOperation == CursorOperationEvent.DELETE_OXEL ) {
				//Log.out( "EditCursor.update - CursorOperationEvent.DELETE_OXEL x: " + _gciData.gc.getModelX() );
				instanceInfo.positionSetComp( _gciData.gc.getModelX(), _gciData.gc.getModelY(), _gciData.gc.getModelZ() );
			}
			buildCursorModel();	
		} else { // null == gciData So the model or oxel is being placed outside of another model
			if ( objectModel && objectModel.complete && objectModel.modelInfo.oxelPersistence && objectModel.modelInfo.oxelPersistence.oxel ) { // this is the INSERT_MODEL where its not on a parent model
				oxelTexture = oxelTextureValid;
				var vv:Vector3D = ModelCacheUtils.viewVectorNormalizedGet();
				vv.scaleBy(objectModel.modelInfo.oxelPersistence.oxel.gc.size() * 4);
				vv = vv.add(VoxelModel.controlledModel.instanceInfo.positionGet);
				objectModel.instanceInfo.positionSet = vv;
				_pl.state = PlacementLocation.VALID;
			} else {
				//Log.out( "EditCursor.update - NO GCI data and no valid object model")
			}

		}
		
		if ( objectModel )
			objectModel.update($context, elapsedTimeMS );
	}
	
	private function buildCursorModel():void {	
		modelInfo.oxelPersistence.oxel.editCursorReset();

		// if the cursor is a model, set the cursor size to the model size
		if ( objectModel ) {
			modelInfo.oxelPersistence.bound = _objectModel.grain;
			modelInfo.oxelPersistence.oxel.gc.bound = _objectModel.grain;
			modelInfo.oxelPersistence.oxel.gc.grain = _objectModel.grain;
		}

		var li:LightInfo = modelInfo.oxelPersistence.oxel.lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
		if ( null == li ) {
			modelInfo.oxelPersistence.oxel.lighting.add(modelInfo.oxelPersistence.oxel.chunkGet().lightInfo);
			li = modelInfo.oxelPersistence.oxel.lighting.lightGet( Lighting.DEFAULT_LIGHT_ID );
		}
		li.setIlluminationLevel( LightInfo.MAX );

		// Set cursor color
		if ( CursorOperationEvent.DELETE_OXEL == cursorOperation )
			li.color = cursorColorRainbow();
		else if ( CursorOperationEvent.INSERT_OXEL == cursorOperation && EDITCURSOR_INVALID == oxelTexture )
			li.color = 0x00ff0000; // RED for invalid
		else
			li.color = 0xffffffff;

		// if cursor is a move cursor, that make it the size of the model
		if ( EDITCURSOR_HAND_LR == oxelTexture || EDITCURSOR_HAND_UD == oxelTexture ) {
			modelInfo.oxelPersistence.oxel.gc.bound = gciData.oxel.gc.bound;
			modelInfo.oxelPersistence.oxel.gc.grain = gciData.oxel.gc.bound;
			var gct:GrainCursor = GrainCursorPool.poolGet( gciData.oxel.gc.bound );
			gct.grain = gciData.oxel.gc.bound;
			modelInfo.oxelPersistence.oxel.change( EDIT_CURSOR, gct, oxelTexture, true);
			GrainCursorPool.poolDispose(gct);
		}
		else {
			modelInfo.oxelPersistence.bound = lastSize;
			modelInfo.oxelPersistence.oxel.gc.bound = lastSize;
			modelInfo.oxelPersistence.oxel.gc.grain = lastSize;
		}

		modelInfo.oxelPersistence.oxel.change( EDIT_CURSOR, modelInfo.oxelPersistence.oxel.gc, oxelTexture, true );

		// This decides how many sides the edit cursor has.
		if ( CursorShapeEvent.CYLINDER == cursorShape || CursorShapeEvent.SPHERE == cursorShape ) {
			// I could use gciData.near to determine which single face to use, but seems like overkill
			if ( Globals.AXIS_X == _gciData.axis ) {
				modelInfo.oxelPersistence.oxel.faceSet( Globals.POSX );
				modelInfo.oxelPersistence.oxel.faceSet( Globals.NEGX );
			} else if ( Globals.AXIS_Y == _gciData.axis ) {
				modelInfo.oxelPersistence.oxel.faceSet( Globals.POSY );
				modelInfo.oxelPersistence.oxel.faceSet( Globals.NEGY );
			} else {
				modelInfo.oxelPersistence.oxel.faceSet( Globals.POSZ );
				modelInfo.oxelPersistence.oxel.faceSet( Globals.NEGZ );
			}
		} else {
			modelInfo.oxelPersistence.oxel.faceSet( Globals.POSX );
			modelInfo.oxelPersistence.oxel.faceSet( Globals.NEGX );
			modelInfo.oxelPersistence.oxel.faceSet( Globals.POSY );
			modelInfo.oxelPersistence.oxel.faceSet( Globals.NEGY );
			modelInfo.oxelPersistence.oxel.faceSet( Globals.POSZ );
			modelInfo.oxelPersistence.oxel.faceSet( Globals.NEGZ );
		}

		modelInfo.oxelPersistence.oxel.facesBuild();
		modelInfo.oxelPersistence.oxel.quadsBuild();

		function cursorColorRainbow():uint {
			var frequency:Number = 0.6; //2.4;
			var red:uint = Math.max( 0, Math.sin( frequency + 2 + _phase ) ) * 255;
			var green:uint = Math.max( 0, Math.sin( frequency + _phase ) ) * 255;
			var blue:uint = Math.max( 0, Math.sin( frequency + 4 + _phase ) ) * 255;
			var color:uint = 0;
			color |= red << 16;
			color |= green << 8;
			color |= blue << 0;
			_phase += 0.03;
			return color;
		}
	}
	
	private function isAvatarInsideThisOxel( vm:VoxelModel ):Boolean {
		var mp:Vector3D = vm.worldToModel( ModelCacheUtils.worldSpaceStartPoint );
		// check head
		var result:Boolean = modelInfo.oxelPersistence.oxel.gc.is_point_inside( mp );
		// and foot
		mp.y -= Avatar.AVATAR_HEIGHT;
		result = result || modelInfo.oxelPersistence.oxel.gc.is_point_inside( mp );
		return result;
	}
	
	public function getHighlightedOxel(recurse:Boolean = false):Oxel {
		
		var foundModel:VoxelModel = VoxelModel.selectedModel;
		// placementResult - { oxel:OxelBad.INVALID_OXEL, gci:gci, positive:posMove, negative:negMove };
		insertLocationCalculate();
		if ( PlacementLocation.INVALID == _pl.state )
		{
			Log.out( "EditCursor.getHighlightedOxel NO PLACEMENT FOUND" );
			return OxelBad.INVALID_OXEL;
		}
		var oxelToBeModified:Oxel = foundModel.modelInfo.oxelPersistence.oxel.childGetOrCreate( _pl.gc );
		if ( OxelBad.INVALID_OXEL == oxelToBeModified )
		{
			Log.out( "EditCursor.getHighlightedOxel BAD OXEL OLD" );
			if ( recurse )
				return OxelBad.INVALID_OXEL;
				
			if ( _pl )
				return OxelBad.INVALID_OXEL;
				
			if ( EditCursor.currentInstance.gciData )
			{
				Log.out( "EditCursor.getHighlightedOxel BAD OXEL NEW gciData.point" + EditCursor.currentInstance.gciData.point + "  gciData.gc: " + EditCursor.currentInstance.gciData.gc );
				// What does this do?
				//insertOxel( true );
				return OxelBad.INVALID_OXEL;
			}
//					foundModel.grow( _pl );
		}
		
		return oxelToBeModified;
	}
	
	private function insertModel():void {
		if ( PlacementLocation.INVALID == _pl.state) {
			Log.out( "EditCursor.insertModel - placement location invalid", Log.WARN );
			return;
		}

		if ( !Globals.active ){
			Log.out( "EditCursor.insertModel - NOT ACTIVE", Log.WARN );
			return;
		}

		if ( 0 < Globals.openWindowCount ){
			Log.out( "EditCursor.insertModel - openWindowCount", Log.WARN );
			return;
		}

		var ii:InstanceInfo = objectModel.instanceInfo.clone();
		if ( VoxelModel.selectedModel && ModelPlacementType.placementType == ModelPlacementType.PLACEMENT_TYPE_CHILD ) {
			ii.controllingModel = VoxelModel.selectedModel;
			// This places an oxel that is invisible, but collidable at the same location as the model
			// This should lock the model to that location, otherwise the oxel is invalid.
			VoxelModel.selectedModel.write( _pl.gc, TypeInfo.NO_QUADS );
			// This adds a link from the model to the placement location
			ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelInsertComplete );			
		}
		
		Log.out( "EditCursor.insertModel - before load" );		
		new ModelMaker( ii );
		Log.out( "EditCursor.insertModel - after load" );
		
		//Now we need to listen for the model to be built, then use associatedGrain to see the location on the new ModelBaseEvent
		function modelInsertComplete( $mle:ModelLoadingEvent ): void {
			if ( $mle.data.modelGuid == ii.modelGuid && $mle.vm.instanceInfo.instanceGuid == ii.instanceGuid ) {
				Log.out( "EditCursor.insertModel - Set associated grain here", Log.WARN );
				$mle.vm.instanceInfo.associatedGrain = _pl.gc;
				var oxel:Oxel = VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.childFind( _pl.gc );
				if ( oxel )
					oxel.hasModel = true;
				else
					Log.out( "EditCursor.insertModel - Can't find GC to mark for model");
			}
		}
	}
	
	private function insertOxel(recurse:Boolean = false):void {
		//Log.out( "EditCursor.insertOxel", Log.WARN );
		var foundModel:VoxelModel = VoxelModel.selectedModel;
		if ( foundModel )
		{
			var oxelToBeModified:Oxel = getHighlightedOxel( recurse );
			if ( OxelBad.INVALID_OXEL == oxelToBeModified )
			{
				Log.out( "EditCursor.insertOxel - Invalid location" );
				return;
			}
	
			if ( isAvatarInsideThisOxel( foundModel ) )
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
	
	private function insertLocationCalculate():void {
		var gci:GrainIntersection = EditCursor.currentInstance.gciData;
		if ( !gci )
			return;

		_pl.reset();
		_pl.state = PlacementLocation.VALID;
		// copy the location of the cursor in the larger model
		// since we are testing on this, we need to use a copy
		_pl.gc.copyFrom( gci.gc );
		// test the results of the step, to see if a blocks has been sent out of bounds.
		switch ( gci.axis ) {
		case Globals.AXIS_X:
			if ( gci.point.x > gci.gc.getModelX() + gci.gc.size()/2 ) {
				if ( !_pl.gc.move_posx() ) _pl.state = PlacementLocation.INVALID;
				_pl.positive = true;
			} else {
				if ( !_pl.gc.move_negx() ) _pl.state = PlacementLocation.INVALID;
				_pl.negative = true;
			}
			break;
		case Globals.AXIS_Y:
			if ( gci.point.y > gci.gc.getModelY() + gci.gc.size()/2 ) {
				if ( !_pl.gc.move_posy() ) _pl.state = PlacementLocation.INVALID;
				_pl.positive = true;
			} else {
				if ( !_pl.gc.move_negy() ) _pl.state = PlacementLocation.INVALID;
				_pl.negative = true;
			}
			break;
		case Globals.AXIS_Z:
			if ( gci.point.z > gci.gc.getModelZ() + gci.gc.size()/2 ) {
				if ( !_pl.gc.move_posz() ) _pl.state = PlacementLocation.INVALID;
				_pl.positive = true;
			} else {	
				if ( !_pl.gc.move_negz() ) _pl.state = PlacementLocation.INVALID;
				_pl.negative = true;
			}
			break;
		}
	}
	
	static private function getOxelFromPoint( vm:VoxelModel, gci:GrainIntersection ):Oxel {
		var gcDelete:GrainCursor = GrainCursorPool.poolGet( vm.modelInfo.oxelPersistence.bound );
		// This is where it intersects with a grain 0
		gcDelete.grainX = int( EditCursor.currentInstance.instanceInfo.positionGet.x + 0.05 );
		gcDelete.grainY = int( EditCursor.currentInstance.instanceInfo.positionGet.y + 0.05 );
		gcDelete.grainZ = int( EditCursor.currentInstance.instanceInfo.positionGet.z + 0.05 );
		// we have to make the grain scale up to the size of the edit cursor
		gcDelete.become_ancestor( EditCursor.currentInstance.modelInfo.oxelPersistence.oxel.gc.grain );
		var oxelToBeDeleted:Oxel = vm.modelInfo.oxelPersistence.oxel.childFind( gcDelete );
		GrainCursorPool.poolDispose( gcDelete );
		return oxelToBeDeleted;
	}
	
	private function deleteOxel():void {
		if ( CursorOperationEvent.DELETE_OXEL != cursorOperation )
			return;

		var foundModel:VoxelModel;
		if ( VoxelModel.selectedModel )
		{
			VoxelModel.controlledModel.stateSet( "Pick", 1 );
			VoxelModel.controlledModel.stateLock( true, 300 );
			
			foundModel = VoxelModel.selectedModel;
			if ( CursorShapeEvent.SQUARE == cursorShape )
			{
				if ( foundModel.metadata.permissions.blueprint ) {
					if ( !WindowBluePrintCopy.exists() )
						new WindowBluePrintCopy( this)
				}

				var gcDelete:GrainCursor = GrainCursorPool.poolGet(foundModel.modelInfo.oxelPersistence.bound);
				// This is where it intersects with a grain 0
				gcDelete.grainX = int( EditCursor.currentInstance.instanceInfo.positionGet.x + 0.05 );
				gcDelete.grainY = int( EditCursor.currentInstance.instanceInfo.positionGet.y + 0.05 );
				gcDelete.grainZ = int( EditCursor.currentInstance.instanceInfo.positionGet.z + 0.05 );
				// we have to make the grain scale up to the size of the edit cursor
				gcDelete.become_ancestor( EditCursor.currentInstance.modelInfo.oxelPersistence.oxel.gc.grain );
				var oxelToBeDeleted:Oxel = foundModel.modelInfo.oxelPersistence.oxel.childGetOrCreate( gcDelete );
				if ( OxelBad.INVALID_OXEL != oxelToBeDeleted ) {
					//Log.out( "EditCursor - found oxel to be deleted");
					foundModel.write(gcDelete, TypeInfo.AIR);
				}
				else {
					// I didnt find grain cursor, why?
					Log.out( "EditCursor - DIDN'T find oxel to be deleted", Log.WARN);
				}
				GrainCursorPool.poolDispose( gcDelete );
			}
			else if ( CursorShapeEvent.SPHERE == cursorShape )
			{
				var gci:GrainIntersection = EditCursor.currentInstance.gciData;
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
			var gciCyl:GrainIntersection = EditCursor.currentInstance.gciData;
			var where:GrainCursor = null;
			
			var radius:int = gciCyl.gc.size()/2;
			
			var what:int = oxelTexture;
			if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
			{
				insertLocationCalculate();
				if ( PlacementLocation.INVALID == _pl.state )
					return;
				
				//where = _pl.gci.gc;
				where = _pl.gc;
			}
			else
			{
				where = gciCyl.gc;
				radius -= radius / 8;
				what = TypeInfo.AIR;
			}
			
			var cuttingPointCyl:Vector3D = new Vector3D();
			cuttingPointCyl.x = where.getModelX() + radius;
			cuttingPointCyl.y = where.getModelY() + radius;
			cuttingPointCyl.z = where.getModelZ() + radius;
			
			var minGrain:int = Math.max( EditCursor.currentInstance.modelInfo.oxelPersistence.oxel.gc.grain - 4, 0 );
			var startingGrain:int = EditCursor.currentInstance.modelInfo.oxelPersistence.oxel.gc.grain - 1;
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
			var gciCyl:GrainIntersection = EditCursor.currentInstance.gciData;
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
				insertLocationCalculate();
				if ( PlacementLocation.INVALID == _pl.state )
					return;
				
				where = _pl.gc;
			}
			else // CURSOR_OP_DELETE
			{
				where = gciCyl.gc;
				radius -= radius / 8;
				//radius += radius / 16
				what = TypeInfo.AIR;
			}
				
			var minGrain:int = Math.max( EditCursor.currentInstance.modelInfo.oxelPersistence.oxel.gc.grain - 5, 0 );
			var startingGrain:int = EditCursor.currentInstance.modelInfo.oxelPersistence.oxel.gc.grain - 1;
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
		if ( Globals.openWindowCount )
			return;
			
		switch (e.keyCode) {
			case Keyboard.CONTROL:
				oxelTexture = oxelTextureValid
		}
	}
	
	private function keyDown(e:KeyboardEvent):void  {
		if ( Globals.openWindowCount || !Globals.active || !editing ) // removed || e.ctrlKey
			return;

		switch (e.keyCode) {
			case Keyboard.CONTROL:
				if ( MouseKeyboardHandler.isLeftMouseDown )
					oxelTexture = EDITCURSOR_HAND_UD;
				else
					oxelTexture = EDITCURSOR_HAND_LR;
				break;
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
	
	private static var _s_dy:Number = 0;
	private static var _s_dx:Number = 0;
	static private function mouseMove(e:MouseEvent):void {
		if ( MouseKeyboardHandler.isCtrlKeyDown ) {
			if ( 0 == _s_dx && 0 == _s_dy ) {
				_s_dy = Globals.g_app.stage.mouseY;
				_s_dx = Globals.g_app.stage.mouseX;
				return;
			}
			var dy:Number = Globals.g_app.stage.mouseY - _s_dy;
			if ( 0 < dy )
				dy = 1;
			else if ( dy < 0 )
				dy = -1;
			_s_dy = Globals.g_app.stage.mouseY;
			var dx:Number =  Globals.g_app.stage.mouseX - _s_dx;
			if ( 0 < dx )
				dx = 1;
			else if ( dx < 0 )
				dx = -1;
			_s_dx = Globals.g_app.stage.mouseX;
			//Log.out( "EditCursor.mouse move dx: " + dx + "  dy: " + dy + " _s_dx: " + _s_dx + "  _s_dy: " + _s_dy, Log.WARN );
			
			if ( VoxelModel.selectedModel ) {
				var t:Vector3D = VoxelModel.selectedModel.instanceInfo.positionGet;
				if ( MouseKeyboardHandler.isLeftMouseDown ) {
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
        //Log.out( "EditCursor.MOUSE_UP");
		repeatTimerStop();
		
		if ( Globals.openWindowCount || e.ctrlKey || !Globals.active || !editing || UIManager.dragManager.isDragging || Log.showing )
			return;
		
		//Log.out( "EditCursor.mouseUp e: " + e.toString() + "  Globals.active == true" );
		//if ( doubleMessageHack ) {
			switch (e.type) 
			{
				case "mouseUp": case Keyboard.NUMPAD_ADD:
					if ( CursorOperationEvent.DELETE_OXEL == cursorOperation ) {
						//Log.out( "EditCursor.mouseUp DELETE IT" );
						deleteOxel();
					}
					else if ( CursorOperationEvent.INSERT_MODEL == cursorOperation )
						insertModel();						
					else if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
						insertOxel();
					break;
			}
//		}
//		else {
//			Log.out( "EditCursor.mouseUp doubleMessageHack is false" );
//		}
	}
	
	private function mouseDown(e:MouseEvent):void {
        //Log.out( "EditCursor.MOUSE_DOWN");
		if ( Globals.openWindowCount  || e.ctrlKey || !Globals.active || !editing || UIManager.dragManager.isDragging || Log.showing )
			return;
			
		if ( doubleMessageHack ) {
			//Log.out( "EditCursor.mouseDown", Log.WARN );
				
			if ( null == _repeatTimer && 0 == _count) {
				_repeatTimer = new Timer( 200 );
				_repeatTimer.addEventListener(TimerEvent.TIMER, onRepeat);
				_repeatTimer.start();
			}
		}
	}
	
	private function repeatTimerStop():void  {
		if ( _repeatTimer ) {
			_repeatTimer.removeEventListener( TimerEvent.TIMER, onRepeat );
			_repeatTimer.stop();
			_repeatTimer = null;
			_count = 0
		}
	}
		
	protected function onRepeat(event:TimerEvent):void {
		if ( Globals.openWindowCount || !Globals.active || !editing ) {
			repeatTimerStop();
			return; }
			
		if ( 1 < _count )
		{
			if ( CursorOperationEvent.DELETE_OXEL == cursorOperation )
				deleteOxel();
			else if ( CursorOperationEvent.INSERT_OXEL == cursorOperation )
				insertOxel();
		}
		_count++;
	}

	private var doubleMessageHackTime:int = 0;
	private function get doubleMessageHack():Boolean {
		var newTime:int = getTimer();
		var result:Boolean = false;
		if ( doubleMessageHackTime + Globals.DOUBLE_MESSAGE_WAITING_PERIOD < newTime ) {
			doubleMessageHackTime = newTime;
			result = true;
		}
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

import com.voxelengine.worldmodel.oxel.GrainCursor;
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