/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.GUI.voxelModels.WindowBluePrintCopy;
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
	/////////////////////////////////////////////////////////////////////////////////////////////////////
	private static var _s_controlledModel:VoxelModel = null;
	public static function get controlledModel():VoxelModel { return _s_controlledModel; }
	public static function set controlledModel( val:VoxelModel ):void { _s_controlledModel = val; }
	
	private static var _s_selectedModel:VoxelModel = null;
	public static function get selectedModel():VoxelModel { return _s_selectedModel; }
	//public static function set selectedModel( $val:VoxelModel ):void { _s_selectedModel = $val; }
	public static function set selectedModel( $val:VoxelModel ):void { 
		if ( _s_selectedModel == $val )
			return
		//Log.out( "VoxelModel.selectedModel: " + ( $val ? $val.toString() : "null") , Log.DEBUG );
		// unselect the old model
		if ( _s_selectedModel )
			_s_selectedModel.selected = false	
		// change the static to new model
		_s_selectedModel = $val
		// set new model as selected
		if ( _s_selectedModel ) {
			_s_selectedModel.selected = true	
			//Axes.show()
		}
		//if ( null == $val )
		//	Axes.hide()
			
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// This is a reference to the data which is store in the metaDataCache
	private 	var	_metadata:ModelMetadata;
	// This is a reference to the data which is store in the modelInfoCache
	protected 	var	_modelInfo:ModelInfo;
	// This is a unique instance from the region data or server
	protected 	var	_instanceInfo:InstanceInfo;
	
	// if this model is a child of a larger model
	private		var _associatedGrain:GrainCursor;											
	
	// state data
	private		var	_anim:Animation;
	private		var	_camera:Camera								= new Camera();
	private		var	_usesGravity:Boolean; 														
	private		var	_timer:int 									= getTimer(); 				
	private		var	_initialized:Boolean;
	private 	var _hasInventory:Boolean;
	protected	var	_stateLock:Boolean
	protected	var	_changed:Boolean; 
	protected	var	_complete:Boolean;
	protected	var	_selected:Boolean;
	protected	var	_dead:Boolean; 		 
			
	// sub classes of VoxelModel can have inventory
	public function get hasInventory():Boolean 					{ return _hasInventory; }
	public function set hasInventory(value:Boolean):void  		{ _hasInventory = value; }
				
	protected function get initialized():Boolean 				{ return _initialized; }
	protected function set initialized( val:Boolean ):void		{ _initialized = val; }
	
	public	function get instanceInfo():InstanceInfo			{ return _instanceInfo; }
	public	function get modelInfo():ModelInfo 					{ return _modelInfo; }
	public	function set modelInfo(val:ModelInfo):void			{ _modelInfo = val; }
	public	function get metadata():ModelMetadata    			{ return _metadata; }
	public	function set metadata(val:ModelMetadata):void   	{ _metadata = val; }
	
	public	function get usesGravity():Boolean 					{ return _usesGravity; }
	public	function set usesGravity(val:Boolean):void 			{ _usesGravity = val; }
	public	function get camera():Camera						{ return _camera; }
	public	function get anim():Animation 						{ return _anim; }
	public	function get changed():Boolean						{ return _changed; }
	public	function set changed( $val:Boolean):void			{ _changed = $val; }
	public	function get selected():Boolean 					{ return _selected; }
	public	function set selected(val:Boolean):void  			{ _selected = val; }
	public 	function get complete():Boolean						{ return _complete; }
	public 	function set complete(val:Boolean):void				{ _complete = val; }
	public 	function 	 toString():String 						{ return metadata.toString() + " ii: " + instanceInfo.toString(); }
	public  function get associatedGrain():GrainCursor			{ return _associatedGrain; }
	public  function set associatedGrain( $val:GrainCursor ):void {  
		if ( null == _associatedGrain )
			_associatedGrain = new GrainCursor();
		_associatedGrain.copyFrom( $val ); 
	}
	
	private var 			_lastCollisionModel:VoxelModel; 											// INSTANCE NOT EXPORTED
	public function get		lastCollisionModel():VoxelModel 		{ return _lastCollisionModel; }
	public function set		lastCollisionModel(val:VoxelModel):void { _lastCollisionModel = val; }
	public function 		lastCollisionModelReset():void 				{ _lastCollisionModel = null; }

	public function get dead():Boolean 							{ return _dead; }
	public function set dead(val:Boolean):void 					{ 
		_dead = val; 
		// this should really use the PARENT MODEL REMOVED event as trigger
		if (0 < instanceInfo.scripts.length) {
			for each (var script:Script in instanceInfo.scripts) 
				script.dispose()
		}
		ModelEvent.dispatch( new ModelEvent( ModelEvent.PARENT_MODEL_REMOVED, instanceInfo.instanceGuid ) );
	}

	public function VoxelModel( $ii:InstanceInfo ):void {
		_instanceInfo = $ii;
		_instanceInfo.owner = this; // This tells the instanceInfo that this voxel model is its owner.
	}
	
	public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		_modelInfo = $mi;
		_metadata = $vmm;

		OxelDataEvent.addListener( OxelDataEvent.OXEL_READY, oxelDataRetrieved );		
		
		if ( null == _metadata )
			Log.out( "VoxelModel.init - IS NULL ModelMetadata valid?", Log.ERROR );
		
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
	
	private function oxelDataRetrieved(e:OxelDataEvent):void {
		if ( e.modelGuid == modelInfo.guid ) {
			OxelDataEvent.removeListener( ModelBaseEvent.ADDED, oxelDataRetrieved )
			calculateCenter()
		}
	}
	
	protected function processClassJson():void {
		modelInfo.childrenLoad( this );
		modelInfo.scriptsLoad( instanceInfo );
		modelInfo.animationsLoad();
	}
	
	// The export object is a combination of modelInfo and instanceInfo
	static public function buildExportObject( obj:Object ):void {
		Log.out( "VoxelModel.buildExportObject" );
	}

	protected function cameraAddLocations():void
	{
		_camera.addLocation( new CameraLocation( false, 0, 0, 0) );
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
	
	// returns the location of this model in the world space
	public function wsPositionGet():Vector3D
	{
		if (instanceInfo.controllingModel)
			return modelToWorld( msPositionGet() );
		else	
			return instanceInfo.positionGet;
	}
	
	public function childFindByName($name:String, $recursive:Boolean = true ):VoxelModel {
		// Are we that model?
		if ( metadata.name == $name )
			return this
		
		// check children
		for each (var child:VoxelModel in modelInfo.childVoxelModels) {
			if (child.metadata.name == $name)
				return child;
			else { // check its children	
				var cvm:VoxelModel = child.childFindByName( $name );
				if ( cvm )
					return cvm;
			}
		}
		return null;
	}
	
	public function childNameList( $nameList:Vector.<String> ):void {
		for each (var child:VoxelModel in modelInfo.childVoxelModels) {
			$nameList.push( child.metadata.name )
			child.childNameList( $nameList );
		}
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
	
	private function impactEventHandler(ie:ImpactEvent):void {
		// Is the explosion event close enough to me to cause me to explode?
		if (ie.instanceGuid == instanceInfo.instanceGuid )
			return;
		
		if (modelInfo.data.oxel && modelInfo.data.oxel.gc) {
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
				vm.instanceInfo.addTransform(dr.x * velocity, dr.y * velocity, dr.z * velocity, life, ModelTransform.POSITION, Projectile.PROJECTILE_VELOCITY);
				var rotation:Number = Math.random() * 50;
				vm.instanceInfo.addTransform(dr.x * rotation, dr.y * rotation, dr.z * rotation, life, ModelTransform.ROTATION);
				//vm.instanceInfo.addTransform(0, Globals.GRAVITY, 0, ModelTransform.INFINITE_TIME, ModelTransform.POSITION, "Gravity");
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
	
	public function doesOxelIntersectSphere($center:Vector3D, $radius:Number):Boolean {
		var dist_squared:Number = squared($radius);
		var maxDis:int = modelInfo.data.oxel.size_in_world_coordinates();
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
		
		function squared(v:Number):Number { return v * v; }		
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
	
	// This function writes to the root oxel, and lets the root find the correct target
	// it also add flow and lighting
	public function write( $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean {
		if ( _metadata.permissions.blueprint ) {
			if ( !WindowBluePrintCopy.exists() )
				new WindowBluePrintCopy( this)
		}
		else {
			Log.out( "VoxelModel.write - going to changeOxel");
			var result:Boolean = modelInfo.changeOxel( $gc, $type, $onlyChangeType );
			if ( result )
				changed = true;
			return result;
		}
		return false
	}
	
	public function write_sphere(cx:int, cy:int, cz:int, radius:int, what:int, gmin:uint = 0):void
	{
		changed = true;
		modelInfo.data.oxel.write_sphere( instanceInfo.instanceGuid, cx, cy, cz, radius, what, gmin);
	}
	
	public function empty_square(cx:int, cy:int, cz:int, radius:int, gmin:uint = 0):void
	{
		changed = true;
		modelInfo.data.oxel.empty_square( instanceInfo.instanceGuid, cx, cy, cz, radius, gmin);
	}
	
	public function effect_sphere(cx:int, cy:int, cz:int, ie:ImpactEvent ):void {
		_timer = getTimer();
		changed = true;
		modelInfo.data.oxel.effect_sphere( instanceInfo.instanceGuid, cx, cy, cz, ie );
		//Log.out( "VoxelModel.effect_sphere - radius: " + ie.radius + " gmin: " + ie.detail + " took: " + (getTimer() - _timer) );
		//oxel.mergeRecursive(); // Causes bad things to happen since we dont regen faces!
	}
	public function empty_sphere(cx:int, cy:int, cz:int, radius:Number, gmin:uint = 0):void {
		_timer = getTimer();
		changed = true;
		modelInfo.data.oxel.write_sphere( instanceInfo.instanceGuid, cx, cy - 1, cz, radius - 1.5, TypeInfo.AIR, gmin);
		
		//Log.out( "VoxelModel.empty_sphere - radius: " + radius + " gmin: " + gmin + " took: " + (getTimer() - _timer) );
		//oxel.mergeRecursive(); // Causes bad things to happen since we dont regen faces!
	}

	
	public function getModelChain( $chain:Vector.<VoxelModel> ):void {
		$chain.push( this )
		if ( instanceInfo.controllingModel ) {
			instanceInfo.controllingModel.getModelChain( $chain )
		}
	}
	
	static public function getWorldSpacePositionInChain( $chain:Vector.<VoxelModel> ):Matrix3D {
		var len:int = $chain.length
		Log.out( "VoxelModel.getWorldSpacePositionInChain - all these clones are BAD", Log.ERROR );

		var viewMatrix:Matrix3D = $chain[len-1].instanceInfo.worldSpaceMatrix.clone();
		for ( var i:int = len - 2; 0 <= i; i-- ) {
			viewMatrix.append( $chain[i].instanceInfo.worldSpaceMatrix )
		}
		return viewMatrix
	}
	
	public function draw(mvp:Matrix3D, $context:Context3D, $isChild:Boolean, $alpha:Boolean ):void	{
		if ( !instanceInfo.visible )
			return;
		
		// This could be improved, I am doing it at least twice per model per frame.
		var viewMatrix:Matrix3D = instanceInfo.worldSpaceMatrix.clone();
		viewMatrix.append(mvp);
		
		if ( modelInfo ) {
			// We have to draw all of the non alpha first, otherwise parts of the tree might get drawn after the alpha does
			modelInfo.draw( viewMatrix, this, $context, selected, $isChild, $alpha );
		}
		/*
		if ( selected && false == $alpha ) {
			Axes.positionSet( instanceInfo.positionGet )
			Axes.rotationSet( instanceInfo.rotationGet )
			Axes.centerSet( instanceInfo.center )
			Axes.scaleSet( modelInfo.grainSize )
			Axes.display()
		}
		*/
	}
	
	public function update($context:Context3D, $elapsedTimeMS:int):void	{
		//if ( "DragonTailFirst" == metadata.name )
		//	Log.out( "VoxelModel.update - name: " + metadata.name, Log.DEBUG );
		if (!initialized) {
			initialized = true;
			//Log.out( "VoxelModel.update - loading oxel data: " + modelInfo.guid, Log.WARN );
			OxelDataEvent.addListener( ModelBaseEvent.RESULT_COMPLETE, oxelComplete );
			modelInfo.oxelLoadData();
		}
		
		if ( complete ) {
			instanceInfo.update($elapsedTimeMS);
			modelInfo.update($context,$elapsedTimeMS, this );
			
			collisionTest($elapsedTimeMS);
			modelInfo.bringOutYourDead();
		}
	}
	
	private function oxelComplete( $ode:OxelDataEvent ):void {
		//Log.out( "VoxelModel.oxelComplete evalutate - guid: " + $ode.modelGuid, Log.WARN );
		// add $ode.modelGuid == metadata.name for imported from local file system models.
		if ( $ode.modelGuid == instanceInfo.modelGuid || $ode.modelGuid == metadata.name ) {
			OxelDataEvent.removeListener( ModelBaseEvent.RESULT_COMPLETE, oxelComplete );
			//Log.out( "VoxelModel.oxelComplete guid: " + $ode.modelGuid, Log.WARN );
			complete = true;
		}
	}

	public function calculateCenter( $oxelCenter:int = 0 ):void {
		if ( 0 == instanceInfo.center.length ) {
			if ( 0 == $oxelCenter )
				if ( modelInfo.data && modelInfo.data.oxel ) {
					$oxelCenter = modelInfo.data.oxel.size_in_world_coordinates() / 2;
					instanceInfo.centerSetComp( $oxelCenter, $oxelCenter, $oxelCenter )
				}
		}
	}
	
	public function print():void
	{
		Log.out("----------------------- Print VoxelModel -------------------------------");
		Log.out("----------------------- instanceInfo.instanceGuid: " + instanceInfo.instanceGuid + " -------------------------------");
		Log.out("----------------------- instanceInfo.modelGuid:       " + instanceInfo.modelGuid + " -------------------------------");
		modelInfo.data.oxel.print();
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
		associatedGrain = null;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Loading and Saving Voxel Models
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function save():void
	{
		if ( !changed ) {
			//Log.out( "VoxelModel.save - NOT changed, NOT SAVING name: " + metadata.name + "  metadata.modelGuid: " + metadata.guid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
			return;
		}
		if ( !Globals.online ) {
			//Log.out( "VoxelModel.save - NOT online, NOT SAVING name: " + metadata.name + "  metadata.modelGuid: " + metadata.guid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
			return;
		}
			
		//Log.out("VoxelModel.save - SAVING changes name: " + metadata.name + "  metadata.modelGuid: " + metadata.guid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
		//Log.out( "VoxelModel.save - name: " + metadata.name, Log.WARN );
		changed = false;
		metadata.save();
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// END - Loading and Saving Voxel Models
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// intersection functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function worldToModel(v:Vector3D):Vector3D { return instanceInfo.worldToModel(v); }
	public function worldToModelNew(v:Vector3D,d:Vector3D):void { return instanceInfo.worldToModelNew(v,d); }
	public function modelToWorld(v:Vector3D):Vector3D { return instanceInfo.modelToWorld(v); }
	
	public function lineIntersect( $worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, worldSpaceIntersections:Vector.<GrainCursorIntersection> ):void {
		var modelSpaceStartPoint:Vector3D = worldToModel( $worldSpaceStartPoint );
		var modelSpaceEndPoint:Vector3D   = worldToModel( $worldSpaceEndPoint );
		
		// if I was inside of a large oxel, the ray would not intersect any of the planes.
		// So this does a check quick check to see if worldSpaceStart point is inside of the model
		if ( !modelInfo.data )
			return
		var gct:GrainCursor = GrainCursorPool.poolGet( modelInfo.data.oxel.gc.bound );
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
			modelInfo.data.oxel.lineIntersect(modelSpaceStartPoint, modelSpaceEndPoint, worldSpaceIntersections );
		
			for each (var gci:GrainCursorIntersection in worldSpaceIntersections) {
				gci.wsPoint = modelToWorld(gci.point);
				gci.model = this;
			}
		}
		GrainCursorPool.poolDispose( gct );
	}
	
	public function lineIntersectWithChildren($worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, worldSpaceIntersections:Vector.<GrainCursorIntersection>, $ignoreType:uint, minSize:int):void {
		var msStartPoint:Vector3D = worldToModel( $worldSpaceStartPoint );
		var msEndPoint:Vector3D   = worldToModel( $worldSpaceEndPoint );
		modelInfo.data.oxel.lineIntersectWithChildren( msStartPoint, msEndPoint, worldSpaceIntersections, $ignoreType, minSize );
		// lineIntersect returns modelSpaceIntersections, convert to world space.
		for each (var gci:GrainCursorIntersection in worldSpaceIntersections)
			gci.wsPoint = modelToWorld(gci.point);
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// end intersection functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function isInside(x:int, y:int, z:int, gct:GrainCursor):Boolean {
		GrainCursor.getGrainFromPoint(x, y, z, gct, gct.bound);
		var fo:Oxel = modelInfo.data.oxel.childFind(gct);
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
		var fo:Oxel = modelInfo.data.oxel.childFind(gct);
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
		var gct:GrainCursor = GrainCursorPool.poolGet(modelInfo.data.oxel.gc.bound);
		GrainCursor.getGrainFromPoint($x, $y, $z, gct, collideAtGrain);
		var fo:Oxel = modelInfo.data.oxel.childFind(gct);
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
		var gct:GrainCursor = GrainCursorPool.poolGet(modelInfo.data.oxel.gc.bound);
		var posMs:Vector3D = worldToModel($pos);
		gct.getGrainFromVector(posMs, $collideAtGrain);
		var fo:Oxel = modelInfo.data.oxel.childFind(gct);
		GrainCursorPool.poolDispose(gct);
		return fo;
	}
	
	public function isSolidAtWorldSpace($cp:CollisionPoint, $pos:Vector3D, $collideAtGrain:uint, $collidingModel:VoxelModel = null ):void {
		$cp.oxel = getOxelAtWSPoint($pos, $collideAtGrain);
		if (Globals.BAD_OXEL == $cp.oxel)
		{
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
		else if ( $cp.oxel.type != TypeInfo.AIR ) {
			if ( $collidingModel is Player ) {
				Player.player.lastCollisionModel = this
				//Log.out( "VoxelModel.isNewPositionValid - oxel is BAD, so passable")
			}
		}
	}
	
	public function rotateCCW():void { modelInfo.data.oxel.rotateCCW(); }
	public function validate():void { modelInfo.data.oxel.validate(); }
	
	public function changeGrainSize( changeSize:int):void {
		_timer = getTimer();
		Oxel.nodes = 0;
		if ( modelInfo.data.oxel ) {
			modelInfo.data.oxel.changeGrainSize(changeSize, modelInfo.data.oxel.gc.bound + changeSize);
			//Log.out("VoxelModel.changeGrainSize - took: " + (getTimer() - _timer) + " count " + Oxel.nodes);
			modelInfo.data.vistor( Oxel.rebuild );
			//Log.out("VoxelModel.changeGrainSize - rebuildAll took: " + (getTimer() - _timer));
		}
	}
	
	public function breakdown(smallest:int = 2):void {
		var timer:int = getTimer();
		modelInfo.data.oxel.breakdown(smallest);
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
		offsetDueTomodelRotation.scaleBy(model.modelInfo.data.oxel.gc.size() / 2);
		var modelCenter:Vector3D = model.instanceInfo.positionGet.add(model.instanceInfo.center);
		var barrelTipModelSpaceLocation:Vector3D = modelCenter.add(offsetDueTomodelRotation);
		
		//trace( "VoxelModel.bounce toBeReflected: " + toBeReflected + "  velocity: " + model.instanceInfo.velocity );
		var startPoint:Vector3D = instanceInfo.positionGet.clone();
		if (toBeReflected && model.instanceInfo.velocityGet.length < toBeReflected.originalDelta.length)
		{
			startPoint.x += -100 * toBeReflected.originalDelta.x;
			startPoint.y += -100 * toBeReflected.originalDelta.y;
			startPoint.z += -100 * toBeReflected.originalDelta.z;
		}
		
		var worldSpaceIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
		var worldSpaceStartPoint:Vector3D = model.instanceInfo.positionGet.add(model.instanceInfo.center);
		
		var worldSpaceEndPoint:Vector3D = model.instanceInfo.worldSpaceMatrix.transformVector(new Vector3D(0, 0, -250));
		// are parmeter here backwards?
		collisionCandidate.lineIntersectWithChildren(worldSpaceEndPoint, worldSpaceStartPoint, worldSpaceIntersections, TypeInfo.AIR, modelInfo.data.oxel.gc.bound);
		
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
						toBeReflected.originalDelta.z = -toBeReflected.originalDelta.z;
					break;
				case Globals.AXIS_Y: 
					trace("VoxelModel.bounce Y PLANE velocity: " + model.instanceInfo.velocityGet);
					model.instanceInfo.velocitySetComp( model.instanceInfo.velocityGet.x, -model.instanceInfo.velocityGet.y, model.instanceInfo.velocityGet.z );
					trace("VoxelModel.bounce Y PLANE velocity inverted: " + model.instanceInfo.velocityGet);
					if (toBeReflected)
						toBeReflected.originalDelta.y = -toBeReflected.originalDelta.y;
					break;
				case Globals.AXIS_Z: 
					trace("VoxelModel.bounce Z PLANE velocity: " + model.instanceInfo.velocityGet);
					model.instanceInfo.velocitySetComp( -model.instanceInfo.velocityGet.x, model.instanceInfo.velocityGet.y, model.instanceInfo.velocityGet.z );
					trace("VoxelModel.bounce Z PLANE velocity inverted: " + model.instanceInfo.velocityGet);
					if (toBeReflected)
						toBeReflected.originalDelta.x = -toBeReflected.originalDelta.x;
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
	
	public function childAdd( $childModel:VoxelModel):void {
		
		if ( false == modelInfo.childrenLoaded )
			modelInfo.childAdd( $childModel )
		else	
			if ( metadata.permissions.modify )
				modelInfo.childAdd( $childModel )
	}
	
	public function loseControl($modelDetaching:VoxelModel, $detachChild:Boolean = true):void
	{
		Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		// remove the player to the child list
		if ( $detachChild )
			modelInfo.childDetach( $modelDetaching, this );
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
		//Log.out("VoxelModel.stateLock - stateLock: " + $val );
		_stateLock = $val;
		// if $lockTime then unlock after that amount of time.
		if ( $val && $lockTime )
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
		if ( (_anim && _anim.name == $state) || 0 == modelInfo.animations.length )
			return;
			
		if ( false == modelInfo.childrenLoaded ) {
			// really need to check if children are complete, not just added
			Log.out("VoxelModel.stateSet - children not all loaded yet: " + $state );
			return; // not all children have loaded yet
		}
		
		//Log.out( "VoxelModel.stateSet setTo: " + $state + "  current: " + (_anim ? _anim.name : "No current state") ); 
		if (_anim)
		{
			Log.out( "VoxelModel.stateSet - Stopping anim: " + _anim.name + "  starting: " + $state ); 
			_anim.stop( this );
			_anim = null;
		} else 
			Log.out( "VoxelModel.stateSet - Starting anim: " + $state ); 
		
		var result:Boolean = false;
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
				if (addAnimationsInChildren(modelInfo.childVoxelModels, at, $lockTime))
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
		function addAnimationsInChildren($children:Vector.<VoxelModel>, $at:AnimationTransform, $lockTime:Number):Boolean
		{
			//Log.out( "VoxelModel.checkChildren - have AnimationTransform looking for child : " + $at.attachmentName );
			var result:Boolean = false;
			for each (var cm:VoxelModel in $children)
			{
				//Log.out( "VoxelModel.addAnimationsInChildren - is child.metadata.name: " + child.metadata.name + " equal to $at.attachmentName: " + $at.attachmentName );
				if (cm.metadata.name == $at.attachmentName)
				{
					cm.stateSetData($at, $lockTime);
					result = true;
				}
				else if (0 < cm.modelInfo.childVoxelModels.length)
				{
					//Log.out( "VoxelModel.stateSet - addAnimationsInChildren - looking in children of child for: " + $at.attachmentName );
					if (addAnimationsInChildren(cm.modelInfo.childVoxelModels, $at, $lockTime))
						result = true;
				}
			}
			return result;
		}
	}
	
	private function stateSetData($at:AnimationTransform, $lockTime:Number):void
	{
		instanceInfo.removeAllNamedTransforms();
		//Log.out( "VoxelModel.stateSet - attachment found: " + modelInfo.fileName + " initializer: " + $useInitializer + "  setting data " + $at );
		if ($at.hasPosition)
			instanceInfo.positionSet = $at.position;
		else
			instanceInfo.positionReset();
			
		if ($at.hasRotation)
			instanceInfo.rotationSet = $at.rotation;
		else
			instanceInfo.rotationReset();
			
		if ($at.hasScale)
			instanceInfo.scale = $at.scale;
		else
			instanceInfo.scaleReset();
			
	
		
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
		else if (_anim.name != $state)
		{
			stateSet($state, $percentage);
				//Log.out( "VoxelModel.updateAnimations - stateSet on NEW anim: " + _anim.name ); 
		}
		// updating existing anim
		else if (_anim.name == $state)
		{
			//Log.out( "VoxelModel.updateAnimations - updating transform on anim: " + _anim.name + " val: " + $percentage ); 
			for each (var at:AnimationTransform in _anim.transforms)
			{
				updateAnimationsInChildren(modelInfo.childVoxelModels, at, $percentage);
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
		for each (var cm:VoxelModel in $children)
		{
			//Log.out( "VoxelModel.updateAnimationsInChildren - child: " + child.instanceInfo.name );
			// Does this child have this name? if so update the transform
			if (cm.metadata.name == $at.attachmentName)
			{
				for each (var mt:ModelTransform in $at.transforms)
				{
					cm.instanceInfo.updateNamedTransform(mt, $percentage);
				}
			}
			// If this child has children, check them also.
			else if (0 < cm.modelInfo.childVoxelModels.length)
			{
				//Log.out( "VoxelModel.updateAnimationsInChildren - looking in children of child for: " + $at.attachmentName );
				if (updateAnimationsInChildren(cm.modelInfo.childVoxelModels, $at, $percentage))
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
//		instanceInfo.baseLightLevel = $attn;
		modelInfo.data.oxel.lightsStaticSetDefault( $attn );
	}

	
	import com.voxelengine.worldmodel.inventory.*;
	public function getDefaultSlotData():Vector.<ObjectInfo> {
		
		Log.out( "VoxelModel.getDefaultSlotData - Loading default data into slots" , Log.WARN );
		var slots:Vector.<ObjectInfo> = new Vector.<ObjectInfo>( Slots.ITEM_COUNT );
		for ( var i:int; i < Slots.ITEM_COUNT; i++ ) 
			slots[i] = new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY );
		
		return slots;
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

