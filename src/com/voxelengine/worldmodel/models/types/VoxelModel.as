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
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.net.registerClassAlias;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.utils.getQualifiedClassName;
import flash.utils.getTimer;
import flash.utils.Timer;

import com.voxelengine.Log;
import com.voxelengine.Globals;

import com.voxelengine.events.*;

import com.voxelengine.pools.LightingPool;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.pools.OxelPool;

import com.voxelengine.renderer.shaders.*

import com.voxelengine.worldmodel.*;
import com.voxelengine.worldmodel.animation.*;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.FlowInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.GrainCursorIntersection;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.oxel.OxelData;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.makers.ModelLoader;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.tasks.flowtasks.Flow;
import com.voxelengine.worldmodel.tasks.lighting.LightAdd;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.worldmodel.weapons.Projectile;

/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class VoxelModel
{
	private 	var _data:ModelData;
	private 	var	_metadata:ModelMetadata;
	protected 	var	_modelInfo:ModelInfo; 													// INSTANCE NOT EXPORTED
	protected 	var	_instanceInfo:InstanceInfo; 											// INSTANCE NOT EXPORTED
	private 	var	_oxel:Oxel; 															// INSTANCE NOT EXPORTED
	private 	var	_editCursor:EditCursor; 												// INSTANCE NOT EXPORTED
	protected 	var	_shaders:Vector.<Shader>        			= new Vector.<Shader>;		// INSTANCE NOT EXPORTED
	protected 	var	_childrenLoaded:Boolean;
	protected 	var	_children:Vector.<VoxelModel> 				= new Vector.<VoxelModel>; 	// INSTANCE NOT EXPORTED
	private		var	_statisics:ModelStatisics 					= new ModelStatisics(); 	// INSTANCE NOT EXPORTED
	private		var	_camera:Camera								= new Camera();
	private		var	_timer:int 									= getTimer(); 				// INSTANCE NOT EXPORTED
	private		var	_version:int; 															// INSTANCE NOT EXPORTED
	
	private		var	_anim:Animation;			
	private		var	_stateLock:Boolean 														// INSTANCE NOT EXPORTED
			
	private		var	_lightIDNext:uint 							= 1024; // TODO FIX reserve space for ?
						
	private		var	_initialized:Boolean 													// INSTANCE NOT EXPORTED
	protected	var	_changed:Boolean 														// INSTANCE NOT EXPORTED
	protected	var	_complete:Boolean 														// INSTANCE NOT EXPORTED
	protected	var	_selected:Boolean 														// INSTANCE NOT EXPORTED
	protected	var	_dead:Boolean 															// INSTANCE NOT EXPORTED
					
	private		var	_usesGravity:Boolean; 														
	private		var	_visible:Boolean 							= true;  // Should be exported/ move to instance
				
	protected function get initialized():Boolean 				{ return _initialized; }
	protected function set initialized( val:Boolean ):void		{ _initialized = val; }
	public	function get data():ModelData    					{ return _data; }
	public	function set data(val:ModelData):void   			{ _data = val; }
	public	function get metadata():ModelMetadata    			{ return _metadata; }
	public	function set metadata(val:ModelMetadata):void   	{ _metadata = val; }
	public	function get usesGravity():Boolean 					{ return _usesGravity; }
	public	function set usesGravity(val:Boolean):void 			{ _usesGravity = val; }
	public	function get getPerModelLightID():uint 				{ return _lightIDNext++ }
	public	function get camera():Camera						{ return _camera; }
	public	function get anim():Animation 						{ return _anim; }
	public	function get statisics():ModelStatisics				{ return _statisics; }
	public	function get instanceInfo():InstanceInfo			{ return _instanceInfo; }
	public	function get editCursor():EditCursor 				{ return _editCursor; }
	public	function set editCursor(val:EditCursor):void 		{ _editCursor = val; }
	public	function get visible():Boolean 						{ return _visible; }
	public	function set visible(val:Boolean):void 				{ _visible = val; }
	public	function get modelInfo():ModelInfo 					{ return _modelInfo; }
	public	function set modelInfo(val:ModelInfo):void			{ _modelInfo = val; }
	public	function get children():Vector.<VoxelModel>			{ return _children; }
	public	function 	 childrenGet():Vector.<VoxelModel>		{ return _children; } // This is so the function can be passed as parameter
	public	function get changed():Boolean						{ return _changed; }
	public	function set changed( $val:Boolean):void			{ _changed = $val; }
	public	function get selected():Boolean 					{ return _selected; }
	public	function set selected(val:Boolean):void  			{ _selected = val; }
	public	function set version(value:int):void  				{ _version = value; }
	public	function get version():int  						{ return _version; }
	
	public function get dead():Boolean 							{ return _dead; }
	public function set dead(val:Boolean):void 					{ 
		_dead = val; 
		
		if (0 < instanceInfo.scripts.length)
		{
			for each (var script:Script in instanceInfo.scripts)
			{
				script.instanceGuid = instanceInfo.instanceGuid;
			}
		}
		ModelEvent.dispatch( new ModelEvent( ModelEvent.PARENT_MODEL_REMOVED, instanceInfo.instanceGuid ) );
	}

	public function get complete():Boolean						{ return _complete; }
	public function set complete(val:Boolean):void
	{
		//Log.out( "VoxelModel.complete: " + modelInfo.fileName );
		_complete = val;
		
		if ( metadata.permissions.modify && Globals.g_configManager.showEditMenu) {
			if ( null == editCursor )
				editCursor = EditCursor.create();
			//if ( null == editCursor.oxel.vm_get() )
				editCursor.oxel.vm_initialize( _statisics );
			editCursor.oxel.gc.bound = oxel.gc.bound;
		}
	}
	
	public function toString():String 				{ return metadata.toString + " ii: " + instanceInfo.toString(); }
	public function get oxel():Oxel { return _oxel; }
	public function set oxel(val:Oxel):void
	{
		// This test for someone trying to overwrite an oxel with another value
		if (null != _oxel && null != val)
			throw new Error("VoxelModel.oxel SET, old oxel not null")
		_oxel = val;
	}
	
	protected function processClassJson():void {
		//if ( _modelInfo.biomes && false == complete && 0 < _modelInfo.biomes.layers.length ) {
			//if ( _modelInfo.biomes.layers[0].functionName == "LoadModelFromBigDB" ) {
				//Log.out( "VoxelModel.processClassJson - GET RID OF THESE", Log.ERROR );
				//return;
			//}
				//
			//Log.out( "VoxelModel.processClassJson - adding task for: " + _modelInfo.biomes );
			//_modelInfo.biomes.add_to_task_controller(instanceInfo);
		//}
		
		// This unblocks the landscape task controller when all terrain tasks have been added
//			if (0 == Globals.g_landscapeTaskController.activeTaskLimit)
//				Globals.g_landscapeTaskController.activeTaskLimit = 1;
		
		// if we have no children, let this stand
		_childrenLoaded	= false;
		if ( _modelInfo.children && 0 < _modelInfo.children.length)
		{
			//Log.out( "VoxelModel.processClassJson name: " + metadata.name + " - loading child models START" );
			for each (var childInstanceInfo:InstanceInfo in _modelInfo.children)
			{
				// Add the parent model info to the child.
				childInstanceInfo.controllingModel = this;
				childInstanceInfo.baseLightLevel = instanceInfo.baseLightLevel;
				
				//Log.out( "VoxelModel.internal_initialize - create child of parent.instance: " + instanceInfo.guid + "  - child.instanceGuid: " + child.instanceGuid );					
				if ( null == childInstanceInfo.modelGuid )
					continue;
				if ( null == childInstanceInfo.instanceGuid )
					childInstanceInfo.instanceGuid = Globals.getUID();
				// now load the child, this might load from the persistance
				// or it could be an import, or it could be a model for the toolbar.
				// we never want to prompt for imported children, since this only happens in dev mode.
				// to test if we are in the bar mode, we test of instanceGuid.
				// Since this is a child object, it automatically get added to the parent.
				// So add to cache just adds it to parent instance.
				//Log.out( "VoxelModel.processClassJson - calling maker on: " + childInstanceInfo.modelGuid + " parentGuid: " + instanceInfo.modelGuid );
				ModelMakerBase.load( childInstanceInfo, true, false, instanceInfo.modelGuid );
			}
			ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childLoadingComplete );
			_modelInfo.childrenReset();
			//Log.out( "VoxelModel.processClassJson - loading child models END" );
		}
		else
			_childrenLoaded	= true;
		
		// Both instanceInfo and modelInfo can have scripts. With each being persisted in correct location.
		// Currently both are persisted to instanceInfo, which is very bad...
		if (0 < _modelInfo.scripts.length)
		{
			for each (var scriptName:String in _modelInfo.scripts)
				instanceInfo.addScript( scriptName, true );
		}
	}
/*
	protected function addClassJson():String {
		// This is always first thing written.
		var jsonString:String = "\"model\":";
		jsonString += JSON.stringify(modelInfo);
		// now we need to replace the children in the modelInfo with the current children.
		var childList:String = getChildJSON();
		Log.out( "VoxelModel.addClassJson " + metadata.name + "  childList: " + childList );
		Log.out( "VoxelModel.addClassJson " + metadata.name + "  jsonString: " + jsonString );
		jsonString = jsonString.replace( "\"REPLACE_ME\"", childList );
		Log.out( "VoxelModel.addClassJson " + metadata.name + "  merged: " + jsonString );
		return jsonString;
	}
	*/
	public function getChildJSON():Object {
		
		// Same code that is in modelCache to build models in region
		// this is just models in models
		var oa:Vector.<Object> = new Vector.<Object>();
		for each ( var model:VoxelModel in _children ) {
			if ( model is Player )
				continue;
			oa.push( model.instanceInfo.buildExportObject() );
		}
		return oa;
		
		
		
		//var instanceData:Vector.<String> = new Vector.<String>;
		//for each ( var model:VoxelModel in _children ) {
			//instanceData.push( model.getJSON() );	
		//}
		//
		//var outString:String = "[";
		//var len:int = instanceData.length;
		//Log.out( "VoxelModel.getChildJSON ---------------------------------------------------" );
		//for ( var index:int; index < len; index++ ) {
			//outString += instanceData[index];
			//Log.out( "VoxelModel.getChildJSON - instance: " + instanceData[index] );
			//// if this is NOT the last element in the array, add a comma to it.
			//if ( index == len - 1 )
				//continue;
			//outString += ",";
		//}
		//outString += "]";
		//Log.out( "VoxelModel.getChildJSON ---------------------------------------------------" );
		//return outString;
	}
	
	public function buildExportObject( obj:Object ):Object {
		obj.model = modelInfo.buildExportObject( obj );
		if ( obj.model.children )
			obj.model.children = getChildJSON();
		//obj.model.editable = metadata.permissions.
		//obj.model.template = metadata.permissions.templateGuid
		return obj;
	}
	
	protected function cameraAddLocations():void
	{
		camera.addLocation(new CameraLocation(false, 8, Globals.AVATAR_HEIGHT, 0));
		camera.addLocation(new CameraLocation(false, 8, Globals.AVATAR_HEIGHT, 40));
		camera.addLocation(new CameraLocation(false, 8, Globals.AVATAR_HEIGHT, 100));
		//_cameras.push( new CameraLocation( true, 0, 100, 100, 45 ) );
		//_cameras.push( new CameraLocation( true, 0, 100, 0, 90 ) );
		//_cameras.push( new CameraLocation( true, 0, 0, 100) );
		//_cameras.push( new CameraLocation( false, 0, 0, 0) );
	}
	
	// returns the location of this model in the model space
	public function msPositionGet():Vector3D
	{
		var totalPosition:Vector3D = null;
		if (instanceInfo.controllingModel)
			totalPosition = instanceInfo.positionGet.add(instanceInfo.controllingModel.msPositionGet());
		else	
			totalPosition = worldToModel( instanceInfo.positionGet );
		
		return totalPosition;
	}
	
	// returns the location of this model in the model space
	public function wsPositionGet():Vector3D
	{
		if (instanceInfo.controllingModel)
			return modelToWorld( msPositionGet() );
		else	
			return instanceInfo.positionGet;
	}
	
	// returns the root model in the model space chain
	public function topmostControllingModel():VoxelModel
	{
		if (instanceInfo.controllingModel)
			return instanceInfo.controllingModel.topmostControllingModel();
		
		return this;
	}
	
	public function deltaTransformVector(val:Vector3D):Vector3D
	{
		var transformVector:Vector3D = null;
		if (instanceInfo.controllingModel)
		{
			transformVector = instanceInfo.controllingModel.deltaTransformVector(val);
			transformVector = instanceInfo.worldSpaceMatrix.deltaTransformVector(transformVector);
		}
		else
			transformVector = instanceInfo.worldSpaceMatrix.deltaTransformVector(val);
		
		return transformVector;
	}
	
	// This is where it would be if nothing interfered
	private static var _sScratchVector:Vector3D = new Vector3D();
	private static var _sScratchMatrix:Matrix3D = new Matrix3D();
	public function setTargetLocation( $loc:Location ):void 
	{
		_sScratchMatrix.identity();
		
		// If the model are are on solid ground, you cant change the angle of the avatar( or controlled object ) 
		// other then turning right and left
		if ( !usesGravity )
			_sScratchMatrix.appendRotation( -$loc.rotationGet.x, Vector3D.X_AXIS );
		_sScratchMatrix.appendRotation( -$loc.rotationGet.y,   Vector3D.Y_AXIS );
		var dvMyVelocity:Vector3D = _sScratchMatrix.transformVector( instanceInfo.velocityGet );
		_sScratchVector.setTo( $loc.positionGet.x, $loc.positionGet.y, $loc.positionGet.z );
		_sScratchVector.decrementBy( instanceInfo.velocityGet );
		$loc.positionSet = _sScratchVector;
		
		//Log.out( "VoxelModel.calculateTargetPosition - worldSpaceTargetPosition: " + worldSpaceTargetPosition );
	}
	
	public function VoxelModel( $ii:InstanceInfo ):void {
		_instanceInfo = $ii;
	}
	
	public function init( $mi:ModelInfo, $vmm:ModelMetadata, $initializeRoot:Boolean = true):void {
		_modelInfo = $mi;
		_metadata = $vmm;
		instanceInfo.owner = this; // This tells the instanceInfo that this voxel model is its owner.

		//_data = new ModelData()
		
		if ($initializeRoot)
			oxel = Oxel.initializeRoot( (0 < instanceInfo.grainSize ? instanceInfo.grainSize : modelInfo.grainSize), instanceInfo.baseLightLevel );
		
		if ( null == _metadata )
			metadata = new ModelMetadata( instanceInfo.modelGuid );
		else 
			metadata = $vmm;
		
		if ((this is EditCursor) || null != instanceInfo.controllingModel || true == instanceInfo.dynamicObject)
		{
//				trace( "VoxelModel - Not added ImpactEvent.EXPLODE for childObject " + _modelInfo.modelClass );
		}
		else
		{
			if ( metadata.permissions.modify )
			{
				//ModelEvent.addListener( ModelEvent.MODEL_MODIFIED, handleModelEvents);
				
				ImpactEvent.addListener(ImpactEvent.EXPLODE, impactEventHandler);
				ImpactEvent.addListener(ImpactEvent.DFIRE, impactEventHandler);
				ImpactEvent.addListener(ImpactEvent.DICE, impactEventHandler);
				ImpactEvent.addListener(ImpactEvent.ACID, impactEventHandler);
			}
//				trace( "VoxelModel - added ImpactEvent.EXPLODE for " + _modelInfo.modelClass );
		}
		
		if (0 < instanceInfo._repeat)
		{
			var vm:VoxelModel = this.clone();
			//childAdd( vm );
			Log.out("VoxelModel.construct - REPEAT");
		}
		
		cameraAddLocations();
		
		if (instanceInfo.state != "")
			stateSet(instanceInfo.state)
			
		processClassJson();
		
	}
	
	private function childLoadingComplete(e:ModelLoadingEvent):void {
		if ( e.modelGuid == instanceInfo.modelGuid ) {
			//Log.out("VoxelModel.childLoadingComplete - modelGuid: " + instanceInfo.modelGuid );
			ModelLoadingEvent.removeListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childLoadingComplete );
			// if we save the model, before it is complete, we put bad child data into model info
			_childrenLoaded = true;
			changed = false;
//			save();
		}
	}
	
	public function clone():VoxelModel {
		var mi:ModelInfo = modelInfo.clone();
		// Get old value since this is wiped out in the instanceInfo clone
		var repeat:int = this.instanceInfo._repeat;
		var ii:InstanceInfo = instanceInfo.clone();
		ii.modelGuid = mi.fileName;
		if (0 < repeat)
			repeat--;
		ii._repeat = repeat;
		
		var vm:VoxelModel = new VoxelModel(ii);
		vm.init( mi, null, false )
		return vm;
	}
	
	private function impactEventHandler(ie:ImpactEvent):void {
		// Is the explosion event close enough to me to cause me to explode?
		if (ie.instanceGuid == instanceInfo.instanceGuid )
			return;
		
		if (oxel)
		{
			if (oxel.gc)
			{
				var msLoc:Vector3D = worldToModel(ie.position);
				if (doesOxelIntersectSphere(msLoc, ie.radius))
				{
					if ( ImpactEvent.EXPLODE == ie.type )
						empty_sphere( msLoc.x, msLoc.y, msLoc.z, ie.radius, ie.detail );
					else if ( ImpactEvent.DFIRE == ie.type )	
						effect_sphere( msLoc.x, msLoc.y, msLoc.z, ie );
					else if ( ImpactEvent.DICE == ie.type )	
						effect_sphere( msLoc.x, msLoc.y, msLoc.z, ie );
				}
			}
		}
	}
	
	public function explode($grainRange:int):void {
		// lets assume grainRange is 1 for now.
		// so I want to break apart the top level oxel into each of its children.
		// and create a new model from that child
		
		// So that the vertex manager is clean.
		oxel.rebuildAll();
		if (!oxel.childrenHas())
			oxel.childrenCreate();
		
		for (var i:int = 0; i < 8; i++)
		{
			var coxel:Oxel = oxel.children[i];
			// dont want to clone empty air oxels
			if (TypeInfo.AIR != coxel.type || coxel.childrenHas())
			{
				// need to get this position info before we break off child.
				var dr:Vector3D = new Vector3D(coxel.gc.grainX ? Math.random() * 1 : Math.random() * -1, coxel.gc.grainY ? Math.random() * 1 : Math.random() * -1, coxel.gc.grainZ ? Math.random() * 1 : Math.random() * -1);
				
				var vm:VoxelModel = cloneFromChild(coxel);
				
				var life:Number = 2.5 + Math.random() * 2;
				vm.instanceInfo.addTransform(0, 0, 0, life, ModelTransform.LIFE);
				var velocity:Number = Math.random() * 800;
				vm.instanceInfo.addTransform(dr.x * velocity, dr.y * velocity, dr.z * velocity, life, ModelTransform.LOCATION, Projectile.PROJECTILE_VELOCITY);
				var rotation:Number = Math.random() * 50;
				vm.instanceInfo.addTransform(dr.x * rotation, dr.y * rotation, dr.z * rotation, life, ModelTransform.ROTATION);
				//vm.instanceInfo.addTransform(0, Globals.GRAVITY, 0, ModelTransform.INFINITE_TIME, ModelTransform.LOCATION, "Gravity");
			}
			else
				Log.out("VoxelModel.explode - oxel is empty");
			
			oxel.children[i] = null;
		}
		
		oxel.childrenPrune();
		oxel.neighborsInvalidate();
		oxel.dirty = false;
	}
	
	public function collisionTest($elapsedTimeMS:Number):Boolean {
		// I dont think this is needed
		if (instanceInfo.controllingModel)
			return true;
		
		// Since this is not colliding, just use the instanceInfo to do calculations
		setTargetLocation( instanceInfo );
		
		return true;
	}
	
	private function squared(v:Number):Number
	{
		return v * v;
	}
	
	public function doesOxelIntersectSphere($center:Vector3D, $radius:Number):Boolean {
		var dist_squared:Number = squared($radius);
		var maxDis:int = oxel.size_in_world_coordinates();
		// assume C1 and C2 are element-wise sorted, if not, do that now 
		if ($center.x < 0)
			dist_squared -= squared($center.x);
		else if ($center.x > maxDis)
			dist_squared -= squared($center.x - maxDis);
		if ($center.y < 0)
			dist_squared -= squared($center.y);
		else if ($center.y > maxDis)
			dist_squared -= squared($center.y - maxDis);
		if ($center.z < 0)
			dist_squared -= squared($center.z);
		else if ($center.z > maxDis)
			dist_squared -= squared($center.z - maxDis);
		return dist_squared > 0;
	}
	
	/*
	   private function doesCubeIntersectSphere( C1:Vector3D, C2:Vector3D, S:Vector3D, R:Number):Boolean
	   {
	   var dist_squared:Number = squared( R );
	   // assume C1 and C2 are element-wise sorted, if not, do that now
	   if (S.x < C1.x) dist_squared -= squared(S.x - C1.x);
	   else if (S.x > C2.x) dist_squared -= squared(S.x - C2.x);
	   if (S.y < C1.y) dist_squared -= squared(S.y - C1.y);
	   else if (S.y > C2.y) dist_squared -= squared(S.y - C2.y);
	   if (S.z < C1.z) dist_squared -= squared(S.z - C1.z);
	   else if (S.z > C2.z) dist_squared -= squared(S.z - C2.z);
	   return dist_squared > 0;
	   }
	 */
	public function grow(placementResult:Object):void {
		oxel = oxel.grow(placementResult);
		// now have to reposition this in logical space.
		var currentPosition:Vector3D = instanceInfo.positionGet.clone();
		switch (placementResult.gci.axis)
		{
			// only have to reposition with growing the in negative direction
			case 0: // x
				if (0 == placementResult.gci.gc.grainX)
				{
					currentPosition.x = currentPosition.x - oxel.gc.size() / 2
				}
				break;
			case 1: // y
				if (0 == placementResult.gci.gc.grainY) // going off neg side
				{
					currentPosition.y = currentPosition.y - oxel.gc.size() / 2
				}
				break;
			case 2: // z
				if (0 == placementResult.gci.gc.grainZ) // going off neg side
				{
					currentPosition.x = currentPosition.x - oxel.gc.size() / 2
				}
				break;
		}
		instanceInfo.positionSet = currentPosition;
		oxel.rebuildAll();
	}
	
	public function flow( $countDown:int = 8, $countOut:int = 8 ):void
	{
		oxel.flowFindCandidates( instanceInfo.instanceGuid, $countDown, $countOut );	
	}
	
	// This function writes to the root oxel, and lets the root find the correct target
	// it also add flow and lighting
	public function write( $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean
	{
		// pass in the oxel directly here?
		// requires some refactoring but not hard - RSF
		var oldOxel:Oxel = oxel.childGetOrCreate( $gc );
		var oldType:int = oldOxel.type;
		var oldTypeInfo:TypeInfo = TypeInfo.typeInfo[oldType];
		if ( oldOxel.lighting ) {
			if ( oldTypeInfo.lightInfo.lightSource )
				var oldLightID:uint = oldOxel.lighting.lightIDGet();
			if ( oldOxel.lighting.ambientOcculsionHas() ) {
				// We have to do this here before the model changes, this clears out the ambient occulusion from the removed oxel
				for ( var face:int = Globals.POSX; face <= Globals.NEGZ; face++ ) {
					if ( oldOxel.quads && oldOxel.quads[face] )
						oldOxel.lighting.evaluateAmbientOcculusion( oldOxel, face, Lighting.AMBIENT_REMOVE );
				}
			}
		}
		
		var result:Boolean;
		var changedOxel:Oxel = oxel.write( instanceInfo.instanceGuid, $gc, $type, $onlyChangeType );
		
		if ( Globals.BAD_OXEL != changedOxel )
		{
			changed = true;
			result = true;
			var typeInfo:TypeInfo = TypeInfo.typeInfo[$type];
		
			if ( typeInfo.flowable )
			{
				if ( null == changedOxel.flowInfo ) // if it doesnt have flow info, get some! This is from placement of flowable oxels
					changedOxel.flowInfo = typeInfo.flowInfo.clone();
					
				if ( Globals.autoFlow && EditCursor.EDIT_CURSOR != instanceInfo.instanceGuid )
				{
					Flow.addTask( instanceInfo.instanceGuid, changedOxel.gc, changedOxel.type, changedOxel.flowInfo, 1 );
				}
			}
			else
			{
				if ( changedOxel.flowInfo )
					changedOxel.flowInfo = null;  // If it has flow info, release it, no need to check first
			}
				
			if ( oldTypeInfo.lightInfo.lightSource )
			{
				var rle:LightEvent = new LightEvent( LightEvent.REMOVE, instanceInfo.instanceGuid, $gc, oldLightID );
				Globals.g_app.dispatchEvent( rle );
			}
			if ( typeInfo.lightInfo.lightSource )
			{
				var le:LightEvent = new LightEvent( LightEvent.ADD, instanceInfo.instanceGuid, $gc, getPerModelLightID );
				Globals.g_app.dispatchEvent( le );
			}
			
			if ( TypeInfo.isSolid( oldType ) && TypeInfo.hasAlpha( $type ) ) {
				
				// we removed a solid block, and are replacing it with air or transparent
				if ( changedOxel.lighting && changedOxel.lighting.valuesHas() )
					Globals.g_app.dispatchEvent( new LightEvent( LightEvent.SOLID_TO_ALPHA, instanceInfo.instanceGuid, changedOxel.gc ) );
			} 
			else if ( TypeInfo.isSolid( $type ) && TypeInfo.hasAlpha( oldType ) ) {
				
				// we added a solid block, and are replacing the transparent block that was there
				if ( changedOxel.lighting && changedOxel.lighting.valuesHas() )
					Globals.g_app.dispatchEvent( new LightEvent( LightEvent.ALPHA_TO_SOLID, instanceInfo.instanceGuid, changedOxel.gc ) );
			}
		}
		
		return result;
	}
	
	public function write_sphere(cx:int, cy:int, cz:int, radius:int, what:int, gmin:uint = 0):void
	{
		changed = true;
		oxel.write_sphere( instanceInfo.instanceGuid, cx, cy, cz, radius, what, gmin);
	}
	
	public function empty_square(cx:int, cy:int, cz:int, radius:int, gmin:uint = 0):void
	{
		changed = true;
		oxel.empty_square( instanceInfo.instanceGuid, cx, cy, cz, radius, gmin);
	}
	
	public function effect_sphere(cx:int, cy:int, cz:int, ie:ImpactEvent ):void {
		_timer = getTimer();
		changed = true;
		oxel.effect_sphere( instanceInfo.instanceGuid, cx, cy, cz, ie );
		//Log.out( "VoxelModel.effect_sphere - radius: " + ie.radius + " gmin: " + ie.detail + " took: " + (getTimer() - _timer) );
		//oxel.mergeRecursive(); // Causes bad things to happen since we dont regen faces!
	}
	public function empty_sphere(cx:int, cy:int, cz:int, radius:Number, gmin:uint = 0):void {
		_timer = getTimer();
		changed = true;
		oxel.write_sphere( instanceInfo.instanceGuid, cx, cy - 1, cz, radius - 1.5, TypeInfo.AIR, gmin);
		
		//Log.out( "VoxelModel.empty_sphere - radius: " + radius + " gmin: " + gmin + " took: " + (getTimer() - _timer) );
		//oxel.mergeRecursive(); // Causes bad things to happen since we dont regen faces!
	}
	
	public function draw(mvp:Matrix3D, $context:Context3D, $isChild:Boolean ):void	{
		if ( !visible )
			return;
		
		var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
		viewMatrix.append(mvp);
		
		if ( oxel )
		{
			// We have to draw all of the non alpha first, otherwise parts of the tree might get drawn after the alpha does
			var selected:Boolean = Globals.selectedModel == this ? true : false;
			//oxel.drawNew( viewMatrix, this, $context, _shaders, selected, $isChild );
			oxel.vertMan.drawNew( viewMatrix, this, $context, _shaders, selected, $isChild );
			
			//Log.out( "VoxelModel.draw - Globals.g_app.editing: " + Globals.g_app.editing + " editCursor.visible: " + (editCursor?editCursor.visible:false) );
			if (Globals.g_app.editing && editCursor && editCursor.visible)
				editCursor.draw(viewMatrix, $context, $isChild );
		}
		
		for each (var vm:VoxelModel in _children)
		{
			if (vm && vm.complete)
				vm.draw(viewMatrix, $context, true );
		}
		
//			if ( oxel.childrenHas() || oxel.quads )
//				lightingFromSun();
	}
	
	public function drawAlpha(mvp:Matrix3D, $context:Context3D, $isChild:Boolean ):void	{
		
		var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
		viewMatrix.append(mvp);
		
		if ( oxel )
		{
			// We have to draw all of the non alpha first, otherwise parts of the tree might get drawn after the alpha does
			var selected:Boolean = Globals.selectedModel == this ? true : false;
			
			//oxel.drawNewAlpha( viewMatrix, this, $context, _shaders, selected, $isChild );
			// this method is TWICE as fast in the render cycle
			oxel.vertMan.drawNewAlpha( viewMatrix, this, $context, _shaders, selected, $isChild );
			
			if (Globals.g_app.editing && editCursor && editCursor.visible)
				editCursor.drawAlpha(viewMatrix, $context, $isChild );
		}
		
		for each (var vm:VoxelModel in _children)
		{
			if (vm && vm.complete)
				vm.drawAlpha(viewMatrix, $context, true);
		}
	}
	
	public function update($context:Context3D, $elapsedTimeMS:int):void	{
		internal_update($context, $elapsedTimeMS);
		
		if (!complete)
			return;
		
		if (Globals.g_app.editing && editCursor && Globals.selectedModel == this)
			editCursor.update($context, $elapsedTimeMS);
		
		collisionTest($elapsedTimeMS);
		
		// update each child
		for each (var vm:VoxelModel in _children)
		{
			vm.update($context, $elapsedTimeMS);
		}
		
		for each (var deadCandidate:VoxelModel in _children)
		{
			if (true == deadCandidate.dead)
				childRemove(deadCandidate);
		}
		
//			changed is used internally - need a new way to determine if an event needs to be sent out when a model has moved
//			if (instanceInfo.changed && this == Globals.controlledModel)
//				dispatchMovementEvent();
	}
	
	private static const _sZERO_VEC:Vector3D = new Vector3D();
	protected function internal_update($context:Context3D, $elapsedTimeMS:int):void
	{
		if (!initialized)
			initialize($context);
		
		if (complete)
		{
			instanceInfo.update($elapsedTimeMS);
			
			if (oxel && oxel.dirty)
			{
				oxel.cleanup();
			}
		}
	}
	
	public function internal_initialize($context:Context3D):void
	{
		if (!_modelInfo)
			return;
			//throw new Error("VoxelModel.internal_initialize - modelInfo not found: " + instanceInfo.guid);
		
		initialized = true;
		visible = true;
		
		//Log.out( "VoxelModel.internal_initialize - enter - instanceGuid: " + instanceInfo.instanceGuid + " name: " + metadata.name );					
		_timer = getTimer();
		
		createShaders($context);
		
		// idea here was if I already have it loaded, why bother to load it again from disk.
		// sort of works, but I never see the model,
		//if ( 1 == _modelInfo.biomes.layers.length && "LoadModelFromIVM" == _modelInfo.biomes.layers[0].functionName && null != Globals.g_modelManager.modelByteArrays[_modelInfo.biomes.layers[0].data] )	
		//	byteArrayLoad( Globals.g_modelManager.modelByteArrays[_modelInfo.biomes.layers[0].data] );
		//else 
		//if (_modelInfo.biomes && false == complete && false == metadata.hasDataObject )
		//processClassJson();
	
		//Log.out( "VoxelModel.internal_initialize - exit - instanceGuid: " + instanceInfo.guid + " took: " + (getTimer() - _timer) );					
	}
	
	public function initialize($context:Context3D):void
	{
		internal_initialize($context);
	}
	
	private function set_camera_data():void
	{
		//var max:Number = oxel.size_in_world_coordinates() * 1.05;
		//Globals.g_renderer.viewOffsetSet( -max, -max, -max );
		//Log.out( "VoxelModel.set_camera_data - setting view offset to : " + -max + ", " + -max + ", " + -max + ", " );
	}
	
	private function createShaders($context:Context3D):void
	{
		var shader:Shader = null;
		_shaders.push( new ShaderOxel($context) ); // oxel
		
		shader = new ShaderOxel($context); // animated oxel
		shader.isAnimated = true;
		_shaders.push( shader );
		
		_shaders.push( new ShaderAlpha($context) ); // alpha oxel
		
		shader = new ShaderAlpha($context); // animated alpha oxel
		shader.isAnimated = true;
		_shaders.push( shader );
		
		shader = new ShaderFire($context); // fire
		shader.isAnimated = true;
		_shaders.push( shader );
	}
	
	public function calculateCenter( $oxelCenter:int = 0 ):void
	{
		if ( 0 == instanceInfo.center.length )
		{
			if ( 0 == $oxelCenter )
				$oxelCenter = oxel.size_in_world_coordinates() / 2;
			instanceInfo.centerSetComp( $oxelCenter, $oxelCenter, $oxelCenter ); 
		}
	}
	
	public function childAdd(vm:VoxelModel):void
	{
		changed = true;
		//Log.out(  "-------------- VoxelModel.childAdd - VM: " + vm.toString() );
		// remove parent level model
		Region.currentRegion.modelCache.changeFromParentToChild(vm);
		_children.push(vm);
		//vm.instanceInfo.baseLightLevel = instanceInfo.baseLightLevel;
		//modelInfo.childAdd(vm.instanceInfo);
	}
	
	public function childRemoveByInstanceInfo( $instanceInfo:InstanceInfo ):void {
		
		var index:int = 0;
		for each (var child:VoxelModel in _children) {
			if (child.instanceInfo.instanceGuid ==  $instanceInfo.instanceGuid ) {
				_children.splice(index, 1);
				break;
			}
			index++;
		}
		
		//modelInfo.childRemove( $instanceInfo );
		// Need a message here?
		//var me:ModelEvent = new ModelEvent( ModelEvent.REMOVE, vm.instanceInfo.guid, instanceInfo.guid );
		//Globals.g_app.dispatchEvent( me );
	}
	
	public function childRemove(vm:VoxelModel):void {
		changed = true;
		var index:int = 0;
		for each (var child:VoxelModel in _children) {
			if (child == vm) {
				Log.out(  "VoxelModel.childRemove - removing Model: " + child.toString() );
				_children.splice(index, 1);
				break;
			}
			index++;
		}
		
		//modelInfo.childRemove(vm.instanceInfo);
		// Need a message here?
		//var me:ModelEvent = new ModelEvent( ModelEvent.REMOVE, vm.instanceInfo.guid, instanceInfo.guid );
		//Globals.g_app.dispatchEvent( me );
	}
	
	// This leaves the model, but detaches it from parent.
	public function childDetach(vm:VoxelModel):void
	{
		// removethis child from the parents info
		childRemove(vm);
		
		// this make it belong to the world
		vm.instanceInfo.controllingModel = null;
		//if ( !(vm is Player) )
		Region.currentRegion.modelCache.add( vm );

		
		// now give it correct world space position and velocity
		//////////////////////////////////////////////////////
		// get the model space position of the object
		var newPosition:Vector3D = vm.instanceInfo.positionGet.clone();
		// position is based on model space, but we want to rotate around the center of the object
		newPosition = newPosition.subtract(instanceInfo.center);
		newPosition = instanceInfo.worldSpaceMatrix.deltaTransformVector(newPosition);
		// add the center back in
		newPosition = newPosition.add(instanceInfo.center);
		
		vm.instanceInfo.positionSet = newPosition.add(instanceInfo.positionGet);
		vm.instanceInfo.velocitySet = instanceInfo.velocityGet;
		
		// This model (vm.instanceInfo.guid) is detaching (ModelEvent.DETACH) from root model (instanceInfo.guid)
		var me:ModelEvent = new ModelEvent(ModelEvent.DETACH, vm.instanceInfo.instanceGuid, null, null, instanceInfo.instanceGuid);
		Globals.g_app.dispatchEvent(me);
	}
	
	public function childModelFind(guid:String):VoxelModel
	{
		for each (var child:VoxelModel in _children) {
			if (child.instanceInfo.instanceGuid == guid)
				return child;
		}
		// didnt find it at first level, lets look recurvsivly
		for each ( child in _children) {
			var cvm:VoxelModel = child.childModelFind( guid );
			if ( cvm )
				return cvm;
		}
		
		//Log.out(  "VoxelModel.childFind - not found for guid: " + guid, Log.WARN );
		return null
	}
	
	public function childFindByName($name:String):VoxelModel
	{
		for each (var child:VoxelModel in _children) {
			if (child.metadata.name == $name)
				return child;
		}
		throw new Error("VoxelModel.childFindByName - not found for name: " + $name);
	}
	
	public function print():void
	{
		Log.out("----------------------- Print VoxelModel -------------------------------");
		Log.out("----------------------- instanceInfo.instanceGuid: " + instanceInfo.instanceGuid + " -------------------------------");
		Log.out("----------------------- instanceInfo.modelGuid:       " + instanceInfo.modelGuid + " -------------------------------");
		oxel.print();
		Log.out("------------------------------------------------------------------------------");
	}
	
	public function oxelReset():void
	{
		if (oxel)
		{
			oxel.release();
			oxel = null;
		}
	}
	
	public function reinitialize( $context:Context3D ):void
	{
		//trace("VoxelModel.reinitialize - modelInfo: " + modelInfo.fileName );
		for each ( var shader:Shader in _shaders )
			shader.createProgram( $context );
			
		for each (var child:VoxelModel in _children)
		{
			child.reinitialize( $context );
		}

		if ( editCursor )
			editCursor.reinitialize( $context );
	}
	
	public function dispose():void
	{
		for each ( var shader:Shader in _shaders )
			shader.dispose();
			
		if (oxel)
			oxel.dispose();
			
		for each (var child:VoxelModel in _children)
			child.dispose();
		
		if ( editCursor )
			editCursor.dispose();
	}
	
	public function release():void
	{
		//trace("VoxelModel.release - removing listeners and deleting oxel");
		
		
		if ( metadata.permissions.modify )
		{
			//ModelEvent.removeListener(ModelEvent.MODEL_MODIFIED, handleModelEvents);
			
			ImpactEvent.removeListener( ImpactEvent.EXPLODE, impactEventHandler);
			ImpactEvent.removeListener( ImpactEvent.DFIRE, impactEventHandler);
			ImpactEvent.removeListener( ImpactEvent.DICE, impactEventHandler);
			ImpactEvent.removeListener( ImpactEvent.ACID, impactEventHandler);
		}
		
		
		//trace( "VoxelModel.release: " + instanceInfo.fileName );
		oxelReset();
		
		if (editCursor)
			editCursor.release();
			
		metadata.release();	
	}
	
	public function removePermanantly():void
	{
		/**
		 * Delete a set of DatabaseObjects from a table
		 * @param table The table to delete the DatabaseObjects from
		 * @param keys The keys of the DatabaseObjects to delete
		 * @param callback Function executed when the DatabaseObjects are successfully deleted. No arguments are passed to the the callback methoh.
		 * @param errorHandler Function executed if an error occurs while deleting the DatabaseObjects
		 *
		 */
//			MetadataManager.deleteModel( metadata.modelGuid );
		Log.out("VoxelModel.delete - delete object: " + instanceInfo.instanceGuid, Log.ERROR );
		
		changed = true;
	}
	
	// Force save is used ONLY when creating instances from templates.
	public function save():void
	{
		if ( !changed ) {
			Log.out( "VoxelModel.save - NOT changed, NOT SAVING name: " + metadata.name + "  metadata.modelGuid: " + metadata.modelGuid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
			return;
		}
		if ( !Globals.online ) {
			Log.out( "VoxelModel.save - NOT online, NOT SAVING name: " + metadata.name + "  metadata.modelGuid: " + metadata.modelGuid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
			return;
		}
		
		if (  false == _childrenLoaded ) {
			Log.out( "VoxelModel.save - children not loaded"  );
			return;
		}
			
		//Log.out("VoxelModel.save - SAVING changes name: " + metadata.name + "  metadata.modelGuid: " + metadata.modelGuid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
		//if ( null != metadata.permissions.templateGuid )
			//metadata.permissions.templateGuid = "";
				
		changed = false;
		metadata.save();
		data.save( toByteArray() );
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Loading and Saving Voxel Models
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static public function oxelAsBasicModel( $oxel:Oxel ):ByteArray {
		var ba:ByteArray = new ByteArray();
		
		writeVersionedHeader( ba );
		writeEmptyManifest( ba );
		$oxel.toByteArray( ba );
		
		return ba;
		
		function writeEmptyManifest( $ba:ByteArray ):void {
			
			// Always write the manifest into the IVM.
			/* ------------------------------------------
			   0 unsigned char model info version - 100 currently
			   next byte is size of model json
			   n+1...  is model json
			   ------------------------------------------ */
			$ba.writeByte(Globals.MANIFEST_VERSION);
			$ba.writeInt( 0 );
			//$ba.writeUTFBytes( json );
		}
	}

	private function toByteArray():ByteArray
	{
		var ba:ByteArray = new ByteArray();
		
		writeVersionedHeader( ba );
		writeManifest( ba );
		oxel.toByteArray( ba );
		
		return ba;
		
		
		function writeManifest( $ba:ByteArray ):void {
			
			// Always write the manifest into the IVM.
			/* ------------------------------------------
			   0 unsigned char model info version - 100 currently
			   next byte is size of model json
			   n+1...  is model json
			   ------------------------------------------ */
			$ba.writeByte(Globals.MANIFEST_VERSION);
			var obj:Object = new Object();
			obj = buildExportObject( obj );
			//var json:String = "{" ;
			//json += addClassJson();
			//json +=  "}"
//Log.out( "VoxelModel.writeManifest - jsonData: " + json, Log.WARN );				
			//json = encodeURI( json );
			var json:String = JSON.stringify( obj );
			$ba.writeInt( json.length );
			$ba.writeUTFBytes( json );
		}
	}
	
	static private function writeVersionedHeader( $ba:ByteArray):void
	{
		/* ------------------------------------------
		   0 char 'i'
		   1 char 'v'
		   2 char 'm'
		   3 char '0' (zero) major version
		   4 char '' (0-9) minor version
		   5 char '' (0-9) lesser version
		   ------------------------------------------ */
		$ba.writeByte('i'.charCodeAt());
		$ba.writeByte('v'.charCodeAt());
		$ba.writeByte('m'.charCodeAt());
		var outVersion:String = zeroPad( Globals.VERSION, 3 );
		$ba.writeByte(outVersion.charCodeAt(0));
		$ba.writeByte(outVersion.charCodeAt(1));
		$ba.writeByte(outVersion.charCodeAt(2));

		function zeroPad(number:int, width:int):String {
		   var ret:String = ""+number;
		   while( ret.length < width )
			   ret="0" + ret;
		   return ret;
		}
	}
		
	public function fromByteArray($ba:ByteArray):void
	{
		// Read off 1 bytes, the root size
		var rootGrainSize:int = $ba.readByte();
		var gct:GrainCursor = GrainCursorPool.poolGet(rootGrainSize);
		gct.grain = rootGrainSize;
		_statisics.gather( version, $ba, rootGrainSize);
		
//		oxel = Oxel.initializeRoot(rootGrainSize, instanceInfo.baseLightLevel);
		
		//oxelReset();
		//oxel = OxelPool.poolGet();
		//Lighting.defaultBaseLightAttn = instanceInfo.baseLightLevel;
		//oxel.lighting = LightingPool.poolGet( instanceInfo.baseLightLevel );
		
		registerClassAlias("com.voxelengine.worldmodel.oxel.FlowInfo", FlowInfo);	
		registerClassAlias("com.voxelengine.worldmodel.oxel.Brightness", Lighting);	
		if (Globals.VERSION_000 == version)
			oxel.readData( null, gct, $ba, _statisics );
		else
			oxel.readVersionedData( version, null, gct, $ba, _statisics );
		
		oxel.gc.bound = rootGrainSize;
		instanceInfo.grainSize = rootGrainSize;
		GrainCursorPool.poolDispose(gct);
		
		calculateCenter();
		set_camera_data();
		oxelLoaded();
	}
	
	// acts as stub for overloading
	protected function oxelLoaded():void
	{
		calculateCenter();
	}
	
	// This is not working correctly
	public function cloneFromChild(childOxel:Oxel):VoxelModel
	{
		var ii:InstanceInfo = instanceInfo.explosionClone();
		ii.modelGuid = "ExplosionFragment";
		var mi:ModelInfo = new ModelInfo();
		var vm:VoxelModel = new VoxelModel(ii);
		vm.init( mi, null, false )
		vm.version = Globals.VERSION;
		vm.instanceInfo.dynamicObject = true;
		vm.oxel = childOxel;
		vm.oxel.breakFromParent();
		vm.complete = true;
		//vm.instanceInfo.positionSet = positionGetWithParent;
		/*
		   var ba:ByteArray = new ByteArray();
		
		   // pad with eight bytes for header
		   ba.writeByte('i'.charCodeAt());
		   ba.writeByte('v'.charCodeAt());
		   ba.writeByte('m'.charCodeAt());
		   ba.writeByte(VERSION.charCodeAt(0));
		   ba.writeByte(VERSION.charCodeAt(1));
		   ba.writeByte(VERSION.charCodeAt(2));
		   ba.writeByte(0);
		   ba.writeByte( childOxel.gc.grain );
		
		   childOxel.writeData( ba );
		 */ /*
		   var ii:InstanceInfo = instanceInfo.explosionClone();
		   // what to do about scripts?
		   //ii.scripts
		   ii.fileName = "ExplosionFragment";
		   var mi:ModelInfo = new ModelInfo();
		   var vm:VoxelModel = new VoxelModel( ii, mi );
		   vm.version = Globals.VERSION;
		   ba.position = 0;
		   vm.IVMLoad( ba );
		   //			vm.oxel.rebuildAll();
		   vm.complete = true;
		   vm.instanceInfo.position = position;
		 */
		
		/*
		 *
		   var ii:InstanceInfo = instanceInfo.explosionClone();
		   ii.fileName = "ExplosionFragment";
		   var mi:ModelInfo = new ModelInfo();
		   var vm:VoxelModel = new VoxelModel( ii, mi, false );
		   vm.version = Globals.VERSION;
		   vm.oxel = OxelPool.oxel_get();
		   ba.position = 8;
		   vm.oxel.byteArrayLoad( null,childOxel.gc, ba, _statisics );
		   vm.complete = true;
		   vm.instanceInfo.position = position;
		 */
		Region.currentRegion.modelCache.add( vm );
		return vm;
	
		//var ms:ModelStatisics = new ModelStatisics();
		//var clonedGC:GrainCursor = GrainCursorPool.poolGet(rootGrainSize);
		//clonedGC.grain = gc.grain;
		//clonedGC.bound = gc.bound;
		//byteArrayLoad( clonedOxel, clonedGC, ba, ms );
		//GrainCursorPool.poolDispose( clonedGC );
	}
	
	// This was used to read Tox's
	private function getKeyValuePair($ba:ByteArray):Object
	{
		var byteRead:int = 0;
		byteRead = $ba.readByte();
		var keyString:String = "";
		while (String.fromCharCode(byteRead) != ' ')
		{
			keyString += String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
		}
		
		var valueString:String = "";
		byteRead = $ba.readByte();
		while (String.fromCharCode(byteRead) != '\n')
		{
			valueString += String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
		}
		
		return {key: keyString, value: valueString};
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// END - Loading and Saving Voxel Models
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// intersection functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function worldToModel(v:Vector3D):Vector3D
	{
		return instanceInfo.worldToModel(v);
	}
	
	public function modelToWorld(v:Vector3D):Vector3D
	{
		return instanceInfo.modelToWorld(v);
	}
	
	public function lineIntersect( $worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, worldSpaceIntersections:Vector.<GrainCursorIntersection>):void
	{
		var modelSpaceStartPoint:Vector3D = worldToModel( $worldSpaceStartPoint );
		var modelSpaceEndPoint:Vector3D   = worldToModel( $worldSpaceEndPoint );
		
		// if I was inside of a large oxel, the ray would not intersect any of the planes.
		// So this does a check quick check to see if worldSpaceStart point is inside of the model
		var gct:GrainCursor = GrainCursorPool.poolGet( oxel.gc.bound );
		//if ( isInside( modelSpaceStartPoint.x, modelSpaceStartPoint.y, modelSpaceStartPoint.z, gct ) )
		//{
			//oxel.lineIntersect
			///*
			//var newGci:GrainCursorIntersection = new GrainCursorIntersection();
			//newGci.point = modelSpaceStartPoint;
			//newGci.wsPoint = $worldSpaceStartPoint;
			//newGci.oxel = oxel; // This is the root oxel of the model
			//newGci.model = this;
			//newGci.gc.copyFrom( gct );
			////public var axis:int;
			////public var near:Boolean = true;
			//*/
			//
			//worldSpaceIntersections.push( newGci );
		//}
		//else
		{
			// this is returning model space intersections
			oxel.lineIntersect(modelSpaceStartPoint, modelSpaceEndPoint, worldSpaceIntersections);
		
			for each (var gci:GrainCursorIntersection in worldSpaceIntersections) {
				gci.wsPoint = modelToWorld(gci.point);
				gci.model = this;
			}
		}
		GrainCursorPool.poolDispose( gct );
	}
	
	public function lineIntersectWithChildren($worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, worldSpaceIntersections:Vector.<GrainCursorIntersection>, minSize:int):void
	{
		var msStartPoint:Vector3D = worldToModel( $worldSpaceStartPoint );
		var msEndPoint:Vector3D   = worldToModel( $worldSpaceEndPoint );
		oxel.lineIntersectWithChildren( msStartPoint, msEndPoint, worldSpaceIntersections, minSize );
		// lineIntersect returns modelSpaceIntersections, convert to world space.
		for each (var gci:GrainCursorIntersection in worldSpaceIntersections)
			gci.wsPoint = modelToWorld(gci.point);
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// end intersection functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function isInside(x:int, y:int, z:int, gct:GrainCursor):Boolean
	{
		GrainCursor.getGrainFromPoint(x, y, z, gct, gct.bound);
		var fo:Oxel = oxel.childFind(gct);
		if (Globals.BAD_OXEL == fo)
		{
			//Log.out( "Camera.isNewPositionValid - oxel is BAD, so passable")
			return false;
		}
		return true;
	
	}
	
	// This is a general case, models using different collision schemes need to override it.
	public function isPositionValid($collidingModel:VoxelModel):PositionTest
	{
		var pt:PositionTest = new PositionTest();
		pt.setValid();
		throw new Error("VoxelModel.isPositionValid - NOT IMPLEMENTED - this would be used by a generic model vs another generic model");
		return pt;
		// This sends the message back to the 
		return pt;
	}
	
	public function isPassableAvatar(x:int, y:int, z:int, gct:GrainCursor, collideAtGrain:uint, positionResult:PositionTest):Boolean
	{
		GrainCursor.getGrainFromPoint(x, y, z, gct, collideAtGrain);
		var fo:Oxel = oxel.childFind(gct);
		var result:Boolean = true;
		if (Globals.BAD_OXEL == fo)
		{
			//Log.out( "Camera.isNewPositionValid - oxel is BAD, so passable")
			result = true;
		}
		//if (fo.solid)
		//{
			//if (PositionTest.FOOT == positionResult.type)
				//positionResult.footHeight = fo.gc.getModelY() + GrainCursor.get_the_g0_size_for_grain(fo.gc.grain) + Globals.AVATAR_HEIGHT_FOOT;
			//Log.out( "Camera.isNewPositionValid - oxel is Solid")
			//result = false;
		//}
		if (fo.childrenHas())
		{
			if (PositionTest.FOOT == positionResult.type)
				positionResult.footHeight = fo.gc.getModelY() + GrainCursor.get_the_g0_size_for_grain(fo.gc.grain) + Globals.AVATAR_HEIGHT_FOOT;
			//Log.out( "Camera.isNewPositionValid - oxel has children")
			result = false;
		}
		return result;
	}
	
	public function isPassable($x:int, $y:int, $z:int, collideAtGrain:uint):Boolean
	{
		if ( 0 > $x || 0 > $y || 0 > $z )
			return true;
		var gct:GrainCursor = GrainCursorPool.poolGet(oxel.gc.bound);
		GrainCursor.getGrainFromPoint($x, $y, $z, gct, collideAtGrain);
		var fo:Oxel = oxel.childFind(gct);
		var result:Boolean = true;
		if (Globals.BAD_OXEL == fo)
		{
			//Log.out( "Camera.isNewPositionValid - oxel is BAD, so passable")
			result = true;
		}
		else if (fo.childrenHas())
		{
			result = false;
		}
		else if ( TypeInfo.isSolid( fo.type ))
		{
			result = false;
		}
		GrainCursorPool.poolDispose(gct);
		return result;
	}
	
	public function getOxelAtWSPoint($pos:Vector3D, $collideAtGrain:uint):Oxel
	{
		var gct:GrainCursor = GrainCursorPool.poolGet(oxel.gc.bound);
		var posMs:Vector3D = worldToModel($pos);
		gct.getGrainFromVector(posMs, $collideAtGrain);
		var fo:Oxel = oxel.childFind(gct);
		GrainCursorPool.poolDispose(gct);
		return fo;
	}
	
	public function isSolidAtWorldSpace($cp:CollisionPoint, $pos:Vector3D, $collideAtGrain:uint):void
	{
		$cp.oxel = getOxelAtWSPoint($pos, $collideAtGrain);
		if (Globals.BAD_OXEL == $cp.oxel)
		{
			//Log.out( "Camera.isNewPositionValid - oxel is BAD, so passable")
			$cp.collided = false;
		}
		else if ( TypeInfo.typeInfo[$cp.oxel.type].solid )
		{
			$cp.collided = true;
		}
		else if ($cp.oxel.childrenHas())
		{
			// TODO - RSF What happens if the children are passabled?
			$cp.collided = true;
		}
	}
	
	public function rotateCCW():void
	{
		oxel.rotateCCW();
	}
	
	public function validate():void
	{
		oxel.validate();
	}
	
	private function validateOxel( $ba:ByteArray, $currentGrain:int):ByteArray
	{
		var faceData:uint = $ba.readUnsignedInt();
		var type:uint;
		if ( version <= Globals.VERSION_006 )
			type = OxelData.typeFromRawDataOld(faceData);
		else {  //_version > Globals.VERSION_006
			var typeData:uint = $ba.readUnsignedInt();
			type = OxelData.type1FromData(typeData);
		}
		
		if (OxelData.data_is_parent(faceData))
		{
			$currentGrain--;
			for (var i:int = 0; i < 8; i++)
			{
				validateOxel($ba, $currentGrain);
			}
			$currentGrain++;
		}
		else
		{
			if (!TypeInfo.typeInfo[type])
			{
				trace("unknown grain of - unknown key: " + type);
				$ba.position -= 4;
				$ba.writeInt(TypeInfo.RED);
				trace("set unknown grain to RED: " + type);
			}
		}
		
		return $ba;
	}
	
	public function changeGrainSize( changeSize:int):void
	{
		_timer = getTimer();
		Oxel.nodes = 0;
		oxel.changeGrainSize(changeSize, oxel.gc.bound + changeSize);
		//Log.out("VoxelModel.changeGrainSize - took: " + (getTimer() - _timer) + " count " + Oxel.nodes);
		oxel.rebuildAll();
		//Log.out("VoxelModel.changeGrainSize - rebuildAll took: " + (getTimer() - _timer));
	}
	
	public function breakdown(smallest:int = 2):void
	{
		var timer:int = getTimer();
		oxel.breakdown(smallest);
		Log.out("Oxel.breakdown - took: " + (getTimer() - timer));
	}
	
	public function bounce(collisionCandidate:VoxelModel, model:VoxelModel):void
	{
		var toBeReflected:ModelTransform = null;
		for each (var mt:ModelTransform in model.instanceInfo.transforms)
		{
			if ("velocity" == mt.name)
			{
				trace("VoxelModel.bound - found model transform: " + mt);
				toBeReflected = mt;
				break;
			}
		}
		
		// we need to use the center of the model for the projection.
		// do I need to use 5 points of detections?
		var offsetDueTomodelRotation:Vector3D = model.instanceInfo.worldSpaceMatrix.deltaTransformVector(new Vector3D(0, 0, -1));
		offsetDueTomodelRotation.scaleBy(model.oxel.gc.size() / 2);
		var modelCenter:Vector3D = model.instanceInfo.positionGet.add(model.instanceInfo.center);
		var barrelTipModelSpaceLocation:Vector3D = modelCenter.add(offsetDueTomodelRotation);
		
		//trace( "VoxelModel.bounce toBeReflected: " + toBeReflected + "  velocity: " + model.instanceInfo.velocity );
		var startPoint:Vector3D = instanceInfo.positionGet.clone();
		if (toBeReflected && model.instanceInfo.velocityGet.length < toBeReflected.delta.length)
		{
			startPoint.x += -100 * toBeReflected.delta.x;
			startPoint.y += -100 * toBeReflected.delta.y;
			startPoint.z += -100 * toBeReflected.delta.z;
		}
		
		var worldSpaceIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
		var worldSpaceStartPoint:Vector3D = model.instanceInfo.positionGet.add(model.instanceInfo.center);
		
		var worldSpaceEndPoint:Vector3D = model.instanceInfo.worldSpaceMatrix.transformVector(new Vector3D(0, 0, -250));
		collisionCandidate.lineIntersectWithChildren(worldSpaceEndPoint, worldSpaceStartPoint, worldSpaceIntersections, oxel.gc.bound);
		
		if (worldSpaceIntersections.length)
		{
			var gci:GrainCursorIntersection = worldSpaceIntersections.shift();
			trace("VoxelModel.bounce  - worldSpaceIntersections.length: " + worldSpaceIntersections.length);
			// reverse on the plane that intersects
			switch (gci.axis)
			{
				case 0: // x
					trace("VoxelModel.bounce X PLANE velocity: " + model.instanceInfo.velocityGet);
					model.instanceInfo.velocitySetComp( model.instanceInfo.velocityGet.x, model.instanceInfo.velocityGet.y, -model.instanceInfo.velocityGet.z );
					trace("VoxelModel.bounce X PLANE velocity inverted: " + model.instanceInfo.velocityGet);
					if (toBeReflected)
						toBeReflected.delta.z = -toBeReflected.delta.z;
					break;
				case 1: 
					trace("VoxelModel.bounce Y PLANE velocity: " + model.instanceInfo.velocityGet);
					model.instanceInfo.velocitySetComp( model.instanceInfo.velocityGet.x, -model.instanceInfo.velocityGet.y, model.instanceInfo.velocityGet.z );
					trace("VoxelModel.bounce Y PLANE velocity inverted: " + model.instanceInfo.velocityGet);
					if (toBeReflected)
						toBeReflected.delta.y = -toBeReflected.delta.y;
					break;
				case 2: 
					trace("VoxelModel.bounce Z PLANE velocity: " + model.instanceInfo.velocityGet);
					model.instanceInfo.velocitySetComp( -model.instanceInfo.velocityGet.x, model.instanceInfo.velocityGet.y, model.instanceInfo.velocityGet.z );
					trace("VoxelModel.bounce Z PLANE velocity inverted: " + model.instanceInfo.velocityGet);
					if (toBeReflected)
						toBeReflected.delta.x = -toBeReflected.delta.x;
					break;
			}
		}
		//trace( "VoxelModel.bounce toBeReflected: " + toBeReflected + "  velocity: " + model.instanceInfo.velocityGet );
	}
	
	public function isInParentChain(collisionCandidate:VoxelModel):Boolean
	{
		if (this == collisionCandidate)
			return true;
		if (instanceInfo.controllingModel && instanceInfo.controllingModel.isInParentChain(collisionCandidate))
			return true;
		return false;
	}
	
	/*
	// So if you release control of any model but the player, the player is back in control
	// Now if there are multiple players (or is this not the case, is Player a special case of Avatar)
	public function handleModelEvents( $me:ModelEvent ):void {
		if ( ModelEvent.RELEASE_CONTROL == $me.type ) {
			var classCalled:String = $me.parentInstanceGuid;
Log.out( "VoxelModel.handleModelEvents - ModelEvent.RELEASE_CONTROL called on: " + classCalled, Log.DEBUG );				
			if ( classCalled != "com.voxelengine.worldmodel.models::Player" )
				Globals.player.takeControl( null, false );
				// TODO Need something here to determine which model
				//if ( $me.instanceGuid
			
		}
		else if ( ModelEvent.MODEL_MODIFIED ) {
Log.out( "VoxelModel.handleModelEvents - ModelEvent.MODEL_MODIFIED called on instance: " + $me.instanceGuid + "  my guid: " + instanceInfo.instanceGuid, Log.DEBUG );								
//				$me.instanceGuid
			if ( $me.instanceGuid == instanceInfo.instanceGuid ) 
				changed = true;
			else if ( childModelFind( $me.instanceGuid ) )
				changed = true;
		}
	}
	*/
	public function takeControl( $modelLosingControl:VoxelModel, $addAsChild:Boolean = true ):void
	{
		//if ( $modelLosingControl )
			//Log.out( "VoxelModel.takeControl of : " + modelInfo.fileName + " by: " + $modelLosingControl.modelInfo.fileName );
		//else	
			//Log.out( "VoxelModel.takeControl of : " + modelInfo.fileName );
		
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		
		Globals.controlledModel = this;
		
		// adds the player to the child list
		if ( $modelLosingControl )
			childAdd($modelLosingControl);
		camera.index = 0;
		
		// Pass in the name of the class that is taking control.
//		var className:String = getQualifiedClassName(this)
//		ModelEvent.dispatch( new ModelEvent( ModelEvent.TAKE_CONTROL, instanceInfo.instanceGuid, null, null, className ) );
	}
	
	public function loseControl($modelDetaching:VoxelModel, $detachChild:Boolean = true):void
	{
		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		
		// remove the player to the child list
		if ( $detachChild )
			childDetach($modelDetaching);
		camera.index = 0;
		//var className:String = getQualifiedClassName(this)
		//ModelEvent.dispatch( new ModelEvent( ModelEvent.RELEASE_CONTROL, instanceInfo.instanceGuid, null, null, className ) );
	}
	
	// these are overriden in subclasses to allow for custom movement
	protected function onKeyDown(e:KeyboardEvent):void
	{
		if (Keyboard.TAB == e.keyCode && 0 == Globals.openWindowCount )
		{
			camera.next();
			
			// I want the camera for the controlled object, not the avatar.
			var currentCamera:CameraLocation = Globals.controlledModel.camera.current;
			//Globals.player.visible = currentCamera.toolBarVisible;
			trace("VoxelModel.keyDown cameraLocation: " + currentCamera.position + "  " + currentCamera.rotation);
			
//				if (CameraLocation.FIRST_PERSON == camera.index && this is Player)
			if ( currentCamera.toolBarVisible )
				GUIEvent.dispatch( new GUIEvent(GUIEvent.TOOLBAR_SHOW));
			else
				GUIEvent.dispatch( new GUIEvent(GUIEvent.TOOLBAR_HIDE));
		}
	}
	
	protected function onKeyUp(e:KeyboardEvent):void
	{
	}
	
	protected function dispatchMovementEvent():void
	{
		var me:ModelEvent = new ModelEvent(ModelEvent.MOVED, instanceInfo.instanceGuid, instanceInfo.positionGet, instanceInfo.rotationGet);
		Globals.g_app.dispatchEvent(me);
	}
	
	public function getAccumulatedYRotation(rotationY:Number):Number
	{
		rotationY += instanceInfo.rotationGet.y;
		if (instanceInfo.controllingModel)
			rotationY = instanceInfo.controllingModel.getAccumulatedYRotation(rotationY);
		
		return rotationY;
	}
	
	
	public function stateLock( $val:Boolean, time:int = 0 ):void
	{
		_stateLock = $val;
		if ( time )
		{
			var pt:Timer = new Timer( time, 1 );
			pt.addEventListener(TimerEvent.TIMER, onStateLockRemove );
			pt.start();
		}
	}

	protected function onStateLockRemove(event:TimerEvent):void
	{
		_stateLock = false;
	}
	
	public function stateSet($state:String, $val:Number = 1):void
	{
		if ( _stateLock )
			return;
		if ( (_anim && _anim.metadata.name == $state) || 0 == modelInfo.animations.length )
			return;
			
		if ( _modelInfo.childCount > _children.length ) {
			// really need to check if children are complete, not just added
			Log.out("VoxelModel.stateSet - children not all loaded yet: " + $state );
			return; // not all children have loaded yet
		}
		
		//Log.out( "VoxelModel.stateSet setTo: " + $state + "  current: " + (_anim ? _anim.name : "No current state") ); 
		if (_anim)
		{
			Log.out( "VoxelModel.stateSet - Stopping anim: " + _anim.metadata.name + "  starting: " + $state ); 
			_anim.stop( this );
			_anim = null;
		}
		
		var aniVector:Vector.<Animation> = modelInfo.animations;
		var result:Boolean = false;
		const useInitializer:Boolean = true;
		for each (var anim:Animation in aniVector)
		{
			if (anim.metadata.name == $state)
			{
				if (!anim.loaded)
				{
					Log.out("VoxelModel.stateSet - ANIMATION NOT LOADED name: " + $state, Log.INFO);
					instanceInfo.state = $state;
					Globals.g_app.addEventListener(LoadingEvent.LOAD_COMPLETE, onModelLoadComplete );
					return;
				}
				
				for each (var at:AnimationTransform in anim.transforms)
				{
					//Log.out( "VoxelModel.stateSet - have AnimationTransform looking for child : " + at.attachmentName );
					if (addAnimationsInChildren(children, at, useInitializer, $val))
						result = true;
				}
				break;
			}
		}
		
		if (true == result)
		{
			_anim = anim;
			//Log.out( "VoxelModel.stateSet - Playing anim: " + _anim.name ); 
			_anim.play(this, $val);
		}
//			else
//				Log.out("VoxelModel.stateSet - addAnimationsInChildren returned false for: " + $state);
		
		// if any of the children load, then it succeeds, which is slightly problematic
		function addAnimationsInChildren($children:Vector.<VoxelModel>, $at:AnimationTransform, $useInitializer:Boolean, $val:Number):Boolean
		{
			//Log.out( "VoxelModel.checkChildren - have AnimationTransform looking for child : " + $at.attachmentName );
			var result:Boolean = false;
			for each (var child:VoxelModel in $children)
			{
				//Log.out( "VoxelModel.stateSet - addAnimationsInChildren - child: " + child.metadata.name );
				if (child.metadata.name == $at.attachmentName)
				{
					child.stateSetData($at, $useInitializer, $val);
					result = true;
				}
				else if (0 < child.children.length)
				{
					//Log.out( "VoxelModel.stateSet - addAnimationsInChildren - looking in children of child for: " + $at.attachmentName );
					if (addAnimationsInChildren(child.children, $at, $useInitializer, $val))
						result = true;
				}
			}
			return result;
		}
	}
	
	// This is currently only used by the stateSet function
	private function onModelLoadComplete( event:LoadingEvent):void
	{
		Log.out( "VoxelModel.onModelLoadComplete: " + modelInfo.fileName  );
		LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, onModelLoadComplete );
		stateSet( instanceInfo.state );
	}
	
	private function stateSetData($at:AnimationTransform, $useInitializer:Boolean, $val:Number):void
	{
		//Log.out( "VoxelModel.stateSet - attachment found: " + modelInfo.fileName + " initializer: " + $useInitializer + "  setting data " + $at );
		if ($useInitializer)
		{
			if ($at.hasPosition)
				instanceInfo.positionSet = $at.position;
			if ($at.hasRotation)
				instanceInfo.rotationSet = $at.rotation;
			if ($at.hasScale)
				instanceInfo.scale = $at.scale;
		}
		
		instanceInfo.removeAllNamedTransforms();
		if ($at.hasTransform)
		{
			for each (var mt:ModelTransform in $at.transforms)
			{
				if ($at.notNamed)
					instanceInfo.addTransformMT(mt.clone($val));
				else
					instanceInfo.addNamedTransformMT(mt.clone($val));
			}
		}
	}
	
	public function updateAnimations($state:String, $val:Number):void
	{
		// No anim set
		if (null == _anim)
		{
			stateSet($state, $val);
				//Log.out( "VoxelModel.updateAnimations - stateSet on anim: " + _anim.name ); 
		}
		// changing anim	
		else if (_anim.metadata.name != $state)
		{
			stateSet($state, $val);
				//Log.out( "VoxelModel.updateAnimations - stateSet on NEW anim: " + _anim.name ); 
		}
		// updating existing anim
		else if (_anim.metadata.name == $state)
		{
			//Log.out( "VoxelModel.updateAnimations - updating transform on anim: " + _anim.name + " val: " + $val ); 
			for each (var at:AnimationTransform in _anim.transforms)
			{
				updateAnimationsInChildren(children, at, $val);
			}
			_anim.update($val);
		}
		else
			Log.out("VoxelModel.updateAnimations - what state gets me here?: " + $state + " val: " + $val);
	}
	
	private function updateAnimationsInChildren($children:Vector.<VoxelModel>, $at:AnimationTransform, $val:Number):Boolean
	{
		//Log.out( "VoxelModel.updateAnimationsInChildren - have AnimationTransform looking for child : " + $at.attachmentName );
		var result:Boolean = false;
		for each (var child:VoxelModel in $children)
		{
			//Log.out( "VoxelModel.updateAnimationsInChildren - child: " + child.instanceInfo.name );
			// Does this child have this name? if so update the transform
			if (child.metadata.name == $at.attachmentName)
			{
				for each (var mt:ModelTransform in $at.transforms)
				{
					child.instanceInfo.updateNamedTransform(mt, $val);
				}
			}
			// If this child has children, check them also.
			else if (0 < child.children.length)
			{
				//Log.out( "VoxelModel.updateAnimationsInChildren - looking in children of child for: " + $at.attachmentName );
				if (updateAnimationsInChildren(child.children, $at, $val))
					result = true;
			}
		}
		return result;
	}
	
	public function updateVelocity( $elapsedTimeMS:int, $clipFactor:Number ):Boolean
	{
		var changed:Boolean = false;
		instanceInfo.velocityScaleBy( $clipFactor );
		instanceInfo.velocityClip();
		return changed;	
	}
	
	// This should be called from voxelModel
	public function lightSetDefault( $attn:uint ):void {
		instanceInfo.baseLightLevel = $attn;
		oxel.lightsStaticSetDefault( $attn );
	}

	
	import com.voxelengine.worldmodel.inventory.*;
	public function getDefaultSlotData():Vector.<ObjectInfo> {
		
		Log.out( "VoxelModel.getDefaultSlotData - Loading default data into slots" , Log.WARN );
		var slots:Vector.<ObjectInfo> = new Vector.<ObjectInfo>( Slots.ITEM_COUNT );
		for ( var i:int; i < Slots.ITEM_COUNT; i++ ) 
			slots[i] = new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY );
		
		return slots;
	}
}
}

