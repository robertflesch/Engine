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

import com.voxelengine.worldmodel.*;
import com.voxelengine.worldmodel.animation.*;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.GrainCursorIntersection;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
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
	private 	var	_metadata:ModelMetadata;
	protected 	var	_modelInfo:ModelInfo; 													// INSTANCE NOT EXPORTED
	protected 	var	_instanceInfo:InstanceInfo; 											// INSTANCE NOT EXPORTED
	
	protected 	var	_children:Vector.<VoxelModel> 				= new Vector.<VoxelModel>; 	// INSTANCE NOT EXPORTED
	
	private		var	_anim:Animation;			
	private		var	_camera:Camera								= new Camera();
	
	protected 	var	_animationsLoaded:Boolean					= true;
	protected	var	_stateLock:Boolean 														// INSTANCE NOT EXPORTED

	private		var	_initialized:Boolean 													// INSTANCE NOT EXPORTED
	protected	var	_changed:Boolean 														// INSTANCE NOT EXPORTED
	protected	var	_complete:Boolean 														// INSTANCE NOT EXPORTED
	protected	var	_selected:Boolean 														// INSTANCE NOT EXPORTED
	protected	var	_dead:Boolean 															// INSTANCE NOT EXPORTED
	private		var	_usesGravity:Boolean; 														
	private		var	_visible:Boolean 							= true;  // Should be exported/ move to instance
	
	private		var	_timer:int 									= getTimer(); 				// INSTANCE NOT EXPORTED
			
	private		var	_lightIDNext:uint 							= 1024; // TODO FIX reserve space for ?
	private var _hasInventory:Boolean;
	
	public function get hasInventory():Boolean 				{ return _hasInventory; }
	public function set hasInventory(value:Boolean):void  	{ _hasInventory = value; }
				
	protected function get initialized():Boolean 				{ return _initialized; }
	protected function set initialized( val:Boolean ):void		{ _initialized = val; }
	public	function get metadata():ModelMetadata    			{ return _metadata; }
	public	function set metadata(val:ModelMetadata):void   	{ _metadata = val; }
	public	function get usesGravity():Boolean 					{ return _usesGravity; }
	public	function set usesGravity(val:Boolean):void 			{ _usesGravity = val; }
	public	function get getPerModelLightID():uint 				{ return _lightIDNext++ }
	public	function get camera():Camera						{ return _camera; }
	public	function get anim():Animation 						{ return _anim; }
//	public	function get statisics():ModelStatisics				{ return _statisics; }
	public	function get instanceInfo():InstanceInfo			{ return _instanceInfo; }
	public	function get visible():Boolean 						{ return _visible; }
	public	function set visible(val:Boolean):void 				{ _visible = val; }
	public	function get modelInfo():ModelInfo 					{ return _modelInfo; }
	public	function set modelInfo(val:ModelInfo):void			{ _modelInfo = val; }
	public	function get children():Vector.<VoxelModel>			{ return _children; }
	public	function 	 childrenGet():Vector.<VoxelModel>		{ return _children; } // This is so the function can be passed as parameter
	public	function get changed():Boolean						{ return _changed; }
	public	function set changed( $val:Boolean):void			
	{ 
		_changed = $val; 
		//if ( _changed )
			//Log.out( "VoxelModel.changed = TRUE - name: " + metadata.name, Log.WARN );
		//else	
			//Log.out( "VoxelModel.changed = FALSE - name: " + metadata.name, Log.WARN );
	}
	public	function get selected():Boolean 					{ return _selected; }
	public	function set selected(val:Boolean):void  			{ _selected = val; }
	
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
		Log.out( "VoxelModel.complete: " + modelInfo.guid );
		_complete = val;
	}
	
	public function toString():String 				{ return metadata.toString() + " ii: " + instanceInfo.toString(); }
	public function get animationsLoaded():Boolean { return _animationsLoaded; }
	public function set animationsLoaded(value:Boolean):void 
	{
		//Log.out( "VoxelModel.animationsLoaded - modelGuid: " + instanceInfo.modelGuid + " setting to: " + value, Log.WARN );
		_animationsLoaded = value;
	}
	
	protected function processClassJson():void {
		Log.out( "VoxelModel.processClassJson load children for model name: " + _metadata.name, Log.DEBUG ),
		modelInfo.childrenLoad( this );
		
		// Both instanceInfo and modelInfo can have scripts. With each being persisted in correct location.
		// Currently both are persisted to instanceInfo, which is very bad...
		if (0 < _modelInfo.scripts.length)
		{
			for each (var scriptName:String in _modelInfo.scripts)
				instanceInfo.addScript( scriptName, true );
		}
	}
	
	public function get oxel():Oxel { return _modelInfo.oxel; }
	
	// The export object is a combination of modelInfo and instanceInfo
	public function buildExportObject( obj:Object ):void {
		
		modelInfo.toObject();
		obj = modelInfo.obj
		obj.model.children = getChildJSON();
	}
	
	private function getChildJSON():Object {
	// Same code that is in modelCache to build models in region
	// this is just models in models
		var oa:Vector.<Object> = new Vector.<Object>();
		for each ( var vm:VoxelModel in children ) {
			if ( vm is Player )
				continue;
			//Log.out( "VoxelModel.getChildJSON - name: " + metadata.name + "  modelGuid: " + instanceInfo.modelGuid + "  child ii: " + vm.instanceInfo, Log.WARN );
			var io:Object = new Object();
			vm.instanceInfo.buildExportObject( io );
			oa.push( io );
		}
		return oa;	
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
		_instanceInfo.owner = this; // This tells the instanceInfo that this voxel model is its owner.
	}
	
	//public function init( $mi:ModelInfo, $vmm:ModelMetadata, $initializeRoot:Boolean = true):void {
	public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		_modelInfo = $mi;
		_metadata = $vmm;

		if ( null == _metadata )
			metadata = new ModelMetadata( instanceInfo.modelGuid );
		else 
			metadata = $vmm;
		
		if ( metadata.permissions.modify ) {
//			Log.out( "VoxelModel - added ImpactEvent.EXPLODE for " + _modelInfo.modelClass );
			ImpactEvent.addListener(ImpactEvent.EXPLODE, impactEventHandler);
			ImpactEvent.addListener(ImpactEvent.DFIRE, impactEventHandler);
			ImpactEvent.addListener(ImpactEvent.DICE, impactEventHandler);
			ImpactEvent.addListener(ImpactEvent.ACID, impactEventHandler);
		}
		
		cameraAddLocations();
		
		if (instanceInfo.state != "")
			stateSet(instanceInfo.state)
			
		processClassJson();
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
	
/*
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
*/
	
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
	   /*
	public function grow(placementResult:Object):void {
		oxel = oxel.grow(placementResult);
		// now have to reposition this in logical space.
		var currentPosition:Vector3D = instanceInfo.positionGet.clone();
		switch (placementResult.gci.axis)
		{
			// only have to reposition with growing the in negative direction
			case Globals.AXIS_X: // x
				if (0 == placementResult.gci.gc.grainX)
				{
					currentPosition.x = currentPosition.x - oxel.gc.size() / 2
				}
				break;
			case Globals.AXIS_Y: // y
				if (0 == placementResult.gci.gc.grainY) // going off neg side
				{
					currentPosition.y = currentPosition.y - oxel.gc.size() / 2
				}
				break;
			case Globals.AXIS_Z: // z
				if (0 == placementResult.gci.gc.grainZ) // going off neg side
				{
					currentPosition.x = currentPosition.x - oxel.gc.size() / 2
				}
				break;
		}
		instanceInfo.positionSet = currentPosition;
		oxel.rebuildAll();
	}
	*/
	public function flow( $countDown:int = 8, $countOut:int = 8 ):void
	{
		oxel.flowFindCandidates( instanceInfo.instanceGuid, $countDown, $countOut );	
	}
	
	// This function writes to the root oxel, and lets the root find the correct target
	// it also add flow and lighting
	public function write( $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean
	{
		var result:Boolean = modelInfo.data.changeOxel( instanceInfo.modelGuid, $gc, $type, $onlyChangeType );
		if ( result )
			changed = true;
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
	
	public function draw(mvp:Matrix3D, $context:Context3D, $isChild:Boolean, $alpha:Boolean ):void	{
		if ( !visible )
			return;
		
		var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
		viewMatrix.append(mvp);
		
		if ( oxel ) {
			// We have to draw all of the non alpha first, otherwise parts of the tree might get drawn after the alpha does
			var selected:Boolean = VoxelModel.selectedModel == this ? true : false;
			modelInfo.draw( viewMatrix, this, $context, selected, $isChild, $alpha );
		}
		
		for each (var vm:VoxelModel in _children) {
			if (vm && vm.complete)
				vm.draw(viewMatrix, $context, true, $alpha );
		}
	}
	
	public function update($context:Context3D, $elapsedTimeMS:int):void	{
		if (!initialized) {
			initialized = true;
			OxelDataEvent.addListener( ModelBaseEvent.RESULT_COMPLETE, oxelComplete );
			modelInfo.oxelLoadData();
		}
		
		if (complete) {
			instanceInfo.update($elapsedTimeMS);
			
			if (oxel && oxel.dirty)
				oxel.cleanup();
		}
		
		if (!complete)
			return;
		
		collisionTest($elapsedTimeMS);
		
		for each (var vm:VoxelModel in _children) {
			vm.update($context, $elapsedTimeMS);
		}
		
		for each (var deadCandidate:VoxelModel in _children) {
			if (true == deadCandidate.dead)
				childRemove(deadCandidate);
		}
	}
	
	private function oxelComplete( $ode:OxelDataEvent ):void {
		if ( $ode.modelGuid == instanceInfo.modelGuid ) {
			OxelDataEvent.removeListener( ModelBaseEvent.RESULT_COMPLETE, oxelComplete );
			Log.out( "VoxelModel.oxelComplete guid: " + $ode.modelGuid );
			complete = true;
		}
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
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Children functions
	/////////////////////////////////////////////////////////////////////////////////////////////
	public function childAdd( $child:VoxelModel):void
	{
		if ( null ==  $child.instanceInfo.instanceGuid )
			 $child.instanceInfo.instanceGuid = Globals.getUID();
		changed = true;
		//Log.out(  "-------------- VoxelModel.childAdd -  $child: " +  $child.toString() );
		// remove parent level model
		Region.currentRegion.modelCache.changeFromParentToChild( $child);
		_children.push( $child);
		$child.instanceInfo.baseLightLevel = instanceInfo.baseLightLevel;
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
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End Children functions
	/////////////////////////////////////////////////////////////////////////////////////////////
	
	public function print():void
	{
		Log.out("----------------------- Print VoxelModel -------------------------------");
		Log.out("----------------------- instanceInfo.instanceGuid: " + instanceInfo.instanceGuid + " -------------------------------");
		Log.out("----------------------- instanceInfo.modelGuid:       " + instanceInfo.modelGuid + " -------------------------------");
		oxel.print();
		Log.out("------------------------------------------------------------------------------");
	}
	
	public function release():void {
		
		if ( metadata.permissions.modify ) {
			//ModelEvent.removeListener(ModelEvent.MODEL_MODIFIED, handleModelEvents);
			ImpactEvent.removeListener( ImpactEvent.EXPLODE, impactEventHandler);
			ImpactEvent.removeListener( ImpactEvent.DFIRE, impactEventHandler);
			ImpactEvent.removeListener( ImpactEvent.DICE, impactEventHandler);
			ImpactEvent.removeListener( ImpactEvent.ACID, impactEventHandler);
		}
		
		//trace( "VoxelModel.release: " + instanceInfo.fileName );
		//oxelReset();
		
		modelInfo.release();
		instanceInfo.release();
		metadata.release();	
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Loading and Saving Voxel Models
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function save():void
	{
		for ( var i:int; i < _children.length; i++ ) {
			var child:VoxelModel = _children[i];
			child.save();
		}
		
		if ( !changed ) {
			Log.out( "VoxelModel.save - NOT changed, NOT SAVING name: " + metadata.name + "  metadata.modelGuid: " + metadata.guid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
			return;
		}
		if ( !Globals.online ) {
			Log.out( "VoxelModel.save - NOT online, NOT SAVING name: " + metadata.name + "  metadata.modelGuid: " + metadata.guid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
			return;
		}
		
		if (  false == modelInfo.childrenLoaded ) {
			Log.out( "VoxelModel.save - children not loaded name: " + _metadata.name );
			return;
		}
			
		if (  false == animationsLoaded ) {
			Log.out( "VoxelModel.save - animations not loaded name: " + _metadata.name );
			return;
		}
		Log.out("VoxelModel.save - SAVING changes name: " + metadata.name + "  metadata.modelGuid: " + metadata.guid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
		//if ( null != metadata.permissions.templateGuid )
			//metadata.permissions.templateGuid = "";
				
		//Log.out( "VoxelModel.save - name: " + metadata.name, Log.WARN );
		changed = false;
		metadata.save();
		modelInfo.childrenSet( getChildJSON() );
		modelInfo.save();
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// END - Loading and Saving Voxel Models
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// intersection functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function worldToModel(v:Vector3D):Vector3D { return instanceInfo.worldToModel(v); }
	public function modelToWorld(v:Vector3D):Vector3D { return instanceInfo.modelToWorld(v); }
	
	public function lineIntersect( $worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, worldSpaceIntersections:Vector.<GrainCursorIntersection>):void {
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
	
	public function lineIntersectWithChildren($worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, worldSpaceIntersections:Vector.<GrainCursorIntersection>, minSize:int):void {
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
	
	public function isInside(x:int, y:int, z:int, gct:GrainCursor):Boolean {
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
	public function isPositionValid($collidingModel:VoxelModel):PositionTest {
		var pt:PositionTest = new PositionTest();
		pt.setValid();
		throw new Error("VoxelModel.isPositionValid - NOT IMPLEMENTED - this would be used by a generic model vs another generic model");
		return pt;
		// This sends the message back to the 
		return pt;
	}
	
	public function isPassableAvatar(x:int, y:int, z:int, gct:GrainCursor, collideAtGrain:uint, positionResult:PositionTest):Boolean {
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
	
	public function isPassable($x:int, $y:int, $z:int, collideAtGrain:uint):Boolean {
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
	
	public function getOxelAtWSPoint($pos:Vector3D, $collideAtGrain:uint):Oxel {
		var gct:GrainCursor = GrainCursorPool.poolGet(oxel.gc.bound);
		var posMs:Vector3D = worldToModel($pos);
		gct.getGrainFromVector(posMs, $collideAtGrain);
		var fo:Oxel = oxel.childFind(gct);
		GrainCursorPool.poolDispose(gct);
		return fo;
	}
	
	public function isSolidAtWorldSpace($cp:CollisionPoint, $pos:Vector3D, $collideAtGrain:uint):void {
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
	
	public function rotateCCW():void { oxel.rotateCCW(); }
	public function validate():void { oxel.validate(); }
	
	public function changeGrainSize( changeSize:int):void {
		_timer = getTimer();
		Oxel.nodes = 0;
		oxel.changeGrainSize(changeSize, oxel.gc.bound + changeSize);
		//Log.out("VoxelModel.changeGrainSize - took: " + (getTimer() - _timer) + " count " + Oxel.nodes);
		oxel.rebuildAll();
		//Log.out("VoxelModel.changeGrainSize - rebuildAll took: " + (getTimer() - _timer));
	}
	
	public function breakdown(smallest:int = 2):void {
		var timer:int = getTimer();
		oxel.breakdown(smallest);
		Log.out("Oxel.breakdown - took: " + (getTimer() - timer));
	}
	
	public function bounce(collisionCandidate:VoxelModel, model:VoxelModel):void {
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
				case Globals.AXIS_X: // x
					trace("VoxelModel.bounce X PLANE velocity: " + model.instanceInfo.velocityGet);
					model.instanceInfo.velocitySetComp( model.instanceInfo.velocityGet.x, model.instanceInfo.velocityGet.y, -model.instanceInfo.velocityGet.z );
					trace("VoxelModel.bounce X PLANE velocity inverted: " + model.instanceInfo.velocityGet);
					if (toBeReflected)
						toBeReflected.delta.z = -toBeReflected.delta.z;
					break;
				case Globals.AXIS_Y: 
					trace("VoxelModel.bounce Y PLANE velocity: " + model.instanceInfo.velocityGet);
					model.instanceInfo.velocitySetComp( model.instanceInfo.velocityGet.x, -model.instanceInfo.velocityGet.y, model.instanceInfo.velocityGet.z );
					trace("VoxelModel.bounce Y PLANE velocity inverted: " + model.instanceInfo.velocityGet);
					if (toBeReflected)
						toBeReflected.delta.y = -toBeReflected.delta.y;
					break;
				case Globals.AXIS_Z: 
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
	
	public function isInParentChain(collisionCandidate:VoxelModel):Boolean {
		if (this == collisionCandidate)
			return true;
		if (instanceInfo.controllingModel && instanceInfo.controllingModel.isInParentChain(collisionCandidate))
			return true;
		return false;
	}
	
	public function takeControl( $modelLosingControl:VoxelModel, $addAsChild:Boolean = true ):void {
		//if ( $modelLosingControl )
			//Log.out( "VoxelModel.takeControl of : " + modelInfo.fileName + " by: " + $modelLosingControl.modelInfo.fileName );
		//else	
			//Log.out( "VoxelModel.takeControl of : " + modelInfo.fileName );
		
		Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		VoxelModel.controlledModel = this;
		
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
		
		// remove the player to the child list
		if ( $detachChild )
			childDetach($modelDetaching);
		camera.index = 0;
		//var className:String = getQualifiedClassName(this)
		//ModelEvent.dispatch( new ModelEvent( ModelEvent.RELEASE_CONTROL, instanceInfo.instanceGuid, null, null, className ) );
	}
	
	// handle the tab key event to move camera around, this is only for controlled model
	protected function onKeyDown(e:KeyboardEvent):void {
		if (Keyboard.TAB == e.keyCode && 0 == Globals.openWindowCount ) {
			camera.next();
			// I want the camera for the controlled object, not the avatar.
			var currentCamera:CameraLocation = VoxelModel.controlledModel.camera.current;
//			trace("VoxelModel.keyDown cameraLocation: " + currentCamera.position + "  " + currentCamera.rotation);
			if ( currentCamera.toolBarVisible )
				GUIEvent.dispatch( new GUIEvent(GUIEvent.TOOLBAR_SHOW));
			else
				GUIEvent.dispatch( new GUIEvent(GUIEvent.TOOLBAR_HIDE));
		}
	}
	
	// overridden by decendants
	protected function onKeyUp(e:KeyboardEvent):void  { }
	
	protected function dispatchMovementEvent():void {
		var me:ModelEvent = new ModelEvent(ModelEvent.MOVED, instanceInfo.instanceGuid, instanceInfo.positionGet, instanceInfo.rotationGet);
		Globals.g_app.dispatchEvent(me);
	}
	
	public function getAccumulatedYRotation(rotationY:Number):Number {
		rotationY += instanceInfo.rotationGet.y;
		if (instanceInfo.controllingModel)
			rotationY = instanceInfo.controllingModel.getAccumulatedYRotation(rotationY);
		
		return rotationY;
	}
	
	
	public function stateLock( $val:Boolean, $lockTime:int = 0 ):void {
		Log.out("VoxelModel.stateLock - stateLock: " + $val );
		_stateLock = $val;
		// if $lockTime then unlock after that amount of time.
		if ( $lockTime )
		{
			var pt:Timer = new Timer( $lockTime, 1 );
			pt.addEventListener(TimerEvent.TIMER, onStateLockRemove );
			pt.start();
		}
	}

	protected function onStateLockRemove(event:TimerEvent):void
	{
		_stateLock = false;
	}
	
	public function stateSet($state:String, $lockTime:Number = 1):void
	{
		if ( _stateLock )
			return;
		if ( (_anim && _anim.metadata.name == $state) || 0 == modelInfo.animations.length )
			return;
			
		if ( false == modelInfo.childrenLoaded ) {
			// really need to check if children are complete, not just added
			Log.out("VoxelModel.stateSet - children not all loaded yet: " + $state );
			return; // not all children have loaded yet
		}
		
		Log.out( "VoxelModel.stateSet setTo: " + $state + "  current: " + (_anim ? _anim.metadata.name : "No current state") ); 
		if (_anim)
		{
			Log.out( "VoxelModel.stateSet - Stopping anim: " + _anim.metadata.name + "  starting: " + $state ); 
			_anim.stop( this );
			_anim = null;
		}
		
		var result:Boolean = false;
		const useInitializer:Boolean = true;
		var anim:Animation = modelInfo.animationGet( $state );
		if ( anim ) {
			//if (!anim.loaded)
			//{
				//Log.out("VoxelModel.stateSet - ANIMATION NOT LOADED name: " + $state, Log.INFO);
				//instanceInfo.state = $state;
				// This should be redone as animationLoadComplete, and use an animation event
				//Globals.g_app.addEventListener(LoadingEvent.LOAD_COMPLETE, onModelLoadComplete );
				//return;
			//}
			//
			for each (var at:AnimationTransform in anim.transforms)
			{
				//Log.out( "VoxelModel.stateSet - have AnimationTransform looking for child : " + at.attachmentName );
				if (addAnimationsInChildren(children, at, useInitializer, $lockTime))
					result = true;
			}
		}

		if (true == result)
		{
			_anim = anim;
			//Log.out( "VoxelModel.stateSet - Playing anim: " + _anim.name ); 
			_anim.play(this, $lockTime);
		}
//			else
//				Log.out("VoxelModel.stateSet - addAnimationsInChildren returned false for: " + $state);
		
		// if any of the children load, then it succeeds, which is slightly problematic
		function addAnimationsInChildren($children:Vector.<VoxelModel>, $at:AnimationTransform, $useInitializer:Boolean, $lockTime:Number):Boolean
		{
			//Log.out( "VoxelModel.checkChildren - have AnimationTransform looking for child : " + $at.attachmentName );
			var result:Boolean = false;
			for each (var child:VoxelModel in $children)
			{
				//Log.out( "VoxelModel.addAnimationsInChildren - is child.metadata.name: " + child.metadata.name + " equal to $at.attachmentName: " + $at.attachmentName );
				if (child.metadata.name == $at.attachmentName)
				{
					child.stateSetData($at, $useInitializer, $lockTime);
					result = true;
				}
				else if (0 < child.children.length)
				{
					//Log.out( "VoxelModel.stateSet - addAnimationsInChildren - looking in children of child for: " + $at.attachmentName );
					if (addAnimationsInChildren(child.children, $at, $useInitializer, $lockTime))
						result = true;
				}
			}
			return result;
		}
	}
	
	private function stateSetData($at:AnimationTransform, $useInitializer:Boolean, $lockTime:Number):void
	{
		instanceInfo.removeAllNamedTransforms();
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
		
		if ($at.hasTransform)
		{
			for each (var mt:ModelTransform in $at.transforms)
			{
				if ($at.notNamed)
					instanceInfo.addTransformMT(mt.clone($lockTime));
				else
					instanceInfo.addNamedTransformMT(mt.clone($lockTime));
			}
		}
	}
	
	public function updateAnimations($state:String, $percentage:Number):void
	{
		// No anim set
		if (null == _anim)
		{
			stateSet($state, $percentage);
				//Log.out( "VoxelModel.updateAnimations - stateSet on anim: " + _anim.name ); 
		}
		// changing anim	
		else if (_anim.metadata.name != $state)
		{
			stateSet($state, $percentage);
				//Log.out( "VoxelModel.updateAnimations - stateSet on NEW anim: " + _anim.name ); 
		}
		// updating existing anim
		else if (_anim.metadata.name == $state)
		{
			//Log.out( "VoxelModel.updateAnimations - updating transform on anim: " + _anim.name + " val: " + $percentage ); 
			for each (var at:AnimationTransform in _anim.transforms)
			{
				updateAnimationsInChildren(children, at, $percentage);
			}
			_anim.update($percentage);
		}
		else
			Log.out("VoxelModel.updateAnimations - what state gets me here?: " + $state + " val: " + $percentage);
	}
	
	private function updateAnimationsInChildren($children:Vector.<VoxelModel>, $at:AnimationTransform, $percentage:Number):Boolean
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
					child.instanceInfo.updateNamedTransform(mt, $percentage);
				}
			}
			// If this child has children, check them also.
			else if (0 < child.children.length)
			{
				//Log.out( "VoxelModel.updateAnimationsInChildren - looking in children of child for: " + $at.attachmentName );
				if (updateAnimationsInChildren(child.children, $at, $percentage))
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
	
	// acts as stub for overloading
	protected function oxelLoaded():void
	{
//		calculateCenter();
	}
	
	private static var g_controlledModel:VoxelModel = null;
	public static function get controlledModel():VoxelModel { return g_controlledModel; }
	public static function set controlledModel( val:VoxelModel ):void { g_controlledModel = val; }
	
	private static var g_selectedModel:VoxelModel = null;
	public static function get selectedModel():VoxelModel { return g_selectedModel; }
	public static function set selectedModel( val:VoxelModel ):void { 
		//Log.out( "VoxelModel.selectedModel: " + ( val ? val.toString() : "null") , Log.WARN );
		g_selectedModel = val; 
	}
	
	public function size():int {
		if ( _modelInfo && _modelInfo.data && _modelInfo.data.loaded )
			return _modelInfo.data.oxel.size_in_world_coordinates();
		else
			return 0;
	}
	public function get grain():int {
		if ( _modelInfo && _modelInfo.data && _modelInfo.data.loaded )
			return _modelInfo.data.oxel.gc.grain;
		else
			return 0;
	}
}
}

