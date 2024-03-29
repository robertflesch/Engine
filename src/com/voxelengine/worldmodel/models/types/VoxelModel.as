/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.adobe.utils.Hex;
import com.voxelengine.GUI.voxelModels.PopupBluePrintCopy;
import com.voxelengine.renderer.lamps.BlackLamp;
import com.voxelengine.renderer.lamps.Lamp;
import com.voxelengine.renderer.lamps.LampBright;
import com.voxelengine.renderer.lamps.RainbowLight;
import com.voxelengine.renderer.lamps.ShaderLight;
import com.voxelengine.renderer.lamps.Torch;
import com.voxelengine.renderer.shaders.Shader;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.makers.ModelMakerClone;
import com.voxelengine.worldmodel.oxel.GrainCursorUtils;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.OxelBad;
import com.voxelengine.worldmodel.oxel.VisitorFunctions;

import flash.display3D.Context3D;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Vector3D;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.utils.getTimer;
import flash.utils.Timer;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.*;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.*;
import com.voxelengine.worldmodel.animation.*;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.GrainIntersection;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.scripts.Script;

import org.flashapi.swing.Alert;

/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class VoxelModel {
	//static public const MODEL_VOXEL:String = "MODEL_VOXEL";
	static public function getAnimationClass():String { return null; }

	/////////////////////////////////////////////////////////////////////////////////////////////////////
	private static var _s_controlledModel:VoxelModel = null;
	public static function get controlledModel():VoxelModel { return _s_controlledModel; }
	public static function set controlledModel( val:VoxelModel ):void { _s_controlledModel = val; }

    private static var _s_selectedModelInitialized:Boolean;
	private static var _s_selectedModel:VoxelModel = null;
	public static function get selectedModel():VoxelModel { return _s_selectedModel; }
	//public static function set selectedModel( $val:VoxelModel ):void { _s_selectedModel = $val; }
	public static function set selectedModel( $val:VoxelModel ):void { 
		if ( _s_selectedModel == $val )
			return;
		//Log.out( "VoxelModel.selectedModel: " + ( $val ? $val.toString() : "null") , Log.DEBUG );
		// un-select the old model
		if ( _s_selectedModel ) {
			_s_selectedModel.selected = false;
            _s_selectedModel.save();

			Axes.hide();
		}
		// change the static to new model
		_s_selectedModel = $val;
		// set new model as selected
		if ( _s_selectedModel ) {
			_s_selectedModel.selected = true;
			Axes.show();
		}

	}

    static private function checkLastSelectedForModelDeletion( $mie:ModelInfoEvent ):void {
        var vm:VoxelModel = selectedModel;
        if ( vm )
            if ( vm.instanceInfo )
                if ( vm.instanceInfo.modelGuid  == $mie.modelGuid )
                    selectedModel = null;
    }

	/////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// This is a reference to the data which is store in the modelInfoCache
	protected 	var	_modelInfo:ModelInfo;
	// This is a unique instance from the region data or server
	protected 	var	_instanceInfo:InstanceInfo;
	

	// state data
	private		var	_anim:Animation;
	private		var	_cameraContainer:CameraContainer								= null;
	private		var	_usesGravity:Boolean; 														
	private		var	_timer:int 									= getTimer(); 				
	private 	var _hasInventory:Boolean;
	protected	var	_stateLock:Boolean;
	protected	var	_complete:Boolean;
	protected	var	_selected:Boolean;
	protected	var	_dead:Boolean; 		 
			
	// sub classes of VoxelModel can have inventory
	public function get hasInventory():Boolean 					{ return _hasInventory; }
	public function set hasInventory(value:Boolean):void  		{ _hasInventory = value; }
				
	public	function get instanceInfo():InstanceInfo			{ return _instanceInfo; }
	public	function get modelInfo():ModelInfo 					{ return _modelInfo; }
	public	function set modelInfo(val:ModelInfo):void			{ _modelInfo = val; }

	public	function get usesGravity():Boolean 					{ return _usesGravity; }
	public	function set usesGravity(val:Boolean):void 			{ _usesGravity = val; }
	public	function get cameraContainer():CameraContainer		{ return _cameraContainer; }
	public	function get anim():Animation 						{ return _anim; }
	public	function get selected():Boolean 					{ return _selected; }
	public	function set selected(val:Boolean):void  			{ _selected = val; }
	public 	function get complete():Boolean						{ return _complete; }
	public 	function set complete(val:Boolean):void				{ _complete = val; }
	public 	function 	 toString():String 						{ return modelInfo.toString() + " ii: " + instanceInfo.toString(); }

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
        ModelEvent.create( ModelEvent.PARENT_MODEL_REMOVED, instanceInfo.instanceGuid );
	}

	public function VoxelModel( $ii:InstanceInfo ):void {
		_instanceInfo = $ii;
		_instanceInfo.owner = this; // This tells the instanceInfo that this voxel model is its owningModel.
		_cameraContainer = new CameraContainer( this );
        if ( false == _s_selectedModelInitialized ) {
            _s_selectedModelInitialized = true;
            ModelInfoEvent.addListener(ModelBaseEvent.DELETE, checkLastSelectedForModelDeletion );
        }

	}
	
	public function init( $mi:ModelInfo, $buildState:String = ModelMakerBase.MAKING ):void {
		_modelInfo = $mi;
		_modelInfo.owningModel = this;
		if ( null == _modelInfo.owningModel )
				Log.out( "ModelInfo.init = null owning object");

		if ( modelInfo.permissions.modify ) {
//			Log.out( "VoxelModel - added ImpactEvent.EXPLODE for " + _modelInfo.modelClass );
			ImpactEvent.addListener(ImpactEvent.EXPLODE, impactEventHandler);
			ImpactEvent.addListener(ImpactEvent.DFIRE, impactEventHandler);
			ImpactEvent.addListener(ImpactEvent.DICE, impactEventHandler);
			ImpactEvent.addListener(ImpactEvent.ACID, impactEventHandler);
		}
		
		cameraAddLocations();

		// I think this should be before we do the setStage
		processClassJson( $buildState );

		if (instanceInfo.state != "")
			stateSet(instanceInfo.state);

		if (instanceInfo.scripts) {
			for each ( var s:Script in instanceInfo.scripts ) {
				s.vm = this;
				s.init( instanceInfo.instanceGuid );

			}
		}
	}



	protected function processClassJson( $buildState:String ):void {
		modelInfo.childrenLoad( this, $buildState );
		modelInfo.scriptsLoad( instanceInfo );
		modelInfo.animationsLoad( $buildState );
	}
	
	// The export object is a combination of modelInfo and instanceInfo
	public function buildExportObject():void {
		//Log.out( "VoxelModel.buildExportObject" );
	}

	protected function cameraAddLocations():void
	{
		_cameraContainer.addLocation( new CameraLocation( false, 0, 0, 0) );
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

	public function rotationGetCummulative():Vector3D
	{
		var totalRotation:Vector3D = null;
		if (instanceInfo.controllingModel)
			totalRotation = instanceInfo.rotationGet.add(instanceInfo.controllingModel.rotationGetCummulative());
		else
			totalRotation = instanceInfo.rotationGet;

		return totalRotation;
	}

	// returns the location of this model in the world space
	public function wsPositionGet():Vector3D {
		return modelToWorld( msPositionGet() );
	}

	// returns the location of this model in the world space
	public function wsPositionCenterGet():Vector3D {
		var cp:Vector3D = msPositionGet().add( instanceInfo.centerNotScaled );
		return modelToWorld( cp );
	}

	public function childFindInstanceGuid( $guid:String, $recursive:Boolean = true ):VoxelModel {
		for each (var child:VoxelModel in modelInfo.childVoxelModels) {
			if (child.instanceInfo.instanceGuid == $guid)
				return child;

			else { // check its children
				var cvm:VoxelModel = child.childFindInstanceGuid( $guid );
				if ( cvm )
					return cvm;
			}
		}
		return null;
	}

	public function childFindModelGuid( $guid:String, $recursive:Boolean = true ):VoxelModel {
		for each (var child:VoxelModel in modelInfo.childVoxelModels) {
			if (child.modelInfo.guid == $guid)
				return child;

			else { // check its children
				var cvm:VoxelModel = child.childFindModelGuid( $guid );
				if ( cvm )
					return cvm;
			}
		}
		return null;
	}

	public function childFindByName($name:String, $recursive:Boolean = true ):VoxelModel {
		// Are we that model?
		if ( modelInfo.name == $name )
			return this;
		
		// check children
		for each (var child:VoxelModel in modelInfo.childVoxelModels) {
			if (child.modelInfo.name == $name)
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
			$nameList.push( child.modelInfo.name );
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
		if ( !$loc.positionGet.nearEquals(_sScratchVector, 0.01 ) ) {
			$loc.positionSet = _sScratchVector;
		}
		
		//Log.out( "VoxelModel.calculateTargetPosition - worldSpaceTargetPosition: " + worldSpaceTargetPosition );
	}
	
	private function impactEventHandler(ie:ImpactEvent):void {
		// Is the explosion event close enough to me to cause me to explode?
		if (ie.instanceGuid == instanceInfo.instanceGuid )
			return;
		
		if (modelInfo.oxelPersistence.oxel && modelInfo.oxelPersistence.oxel.gc) {
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
		// Since this is not colliding, just use the instanceInfo to do calculations
		setTargetLocation( instanceInfo );
		
		return true;
	}
	
	public function doesOxelIntersectSphere($center:Vector3D, $radius:Number):Boolean {
		var dist_squared:Number = squared($radius);
		var maxDis:int = modelInfo.oxelPersistence.oxel.size_in_world_coordinates();
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
		if ( !(modelInfo.permissions.modify & PermissionsModel.MODIFY_VOXEL) ) {
			(new Alert( "You do not have permission to modify that model").display());
            CursorOperationEvent.create( CursorOperationEvent.NONE );
		}
		else {
			//Log.out( "VoxelModel.write - going to changeOxel");
			var result:Boolean = modelInfo.changeOxel( instanceInfo.instanceGuid, $gc, $type, $onlyChangeType );
			return result;
		}
		return false
	}
	
	public function write_sphere(cx:int, cy:int, cz:int, radius:int, what:int, gmin:uint = 0):void
	{
		modelInfo.oxelPersistence.changed = true;
		modelInfo.oxelPersistence.oxel.write_sphere( instanceInfo.instanceGuid, cx, cy, cz, radius, what, gmin);
	}
	
	public function empty_square(cx:int, cy:int, cz:int, radius:int, gmin:uint = 0):void
	{
		modelInfo.oxelPersistence.changed = true;
		modelInfo.oxelPersistence.oxel.empty_square( instanceInfo.instanceGuid, cx, cy, cz, radius, gmin);
	}
	
	public function effect_sphere(cx:int, cy:int, cz:int, ie:ImpactEvent ):void {
		_timer = getTimer();
		modelInfo.oxelPersistence.changed = true;
		modelInfo.oxelPersistence.oxel.effect_sphere( instanceInfo.instanceGuid, cx, cy, cz, ie );
		//Log.out( "VoxelModel.effect_sphere - radius: " + ie.radius + " gmin: " + ie.detail + " took: " + (getTimer() - _timer) );
		//oxel.mergeRecursive(); // Causes bad things to happen since we dont regen faces!
	}
	public function empty_sphere(cx:int, cy:int, cz:int, radius:Number, gmin:uint = 0):void {
		_timer = getTimer();
		modelInfo.oxelPersistence.changed = true;
		modelInfo.oxelPersistence.oxel.write_sphere( instanceInfo.instanceGuid, cx, cy - 1, cz, radius - 1.5, TypeInfo.AIR, gmin);
		
		//Log.out( "VoxelModel.empty_sphere - radius: " + radius + " gmin: " + gmin + " took: " + (getTimer() - _timer) );
		//oxel.mergeRecursive(); // Causes bad things to happen since we dont regen faces!
	}

	
	public function getModelChain( $chain:Vector.<VoxelModel> ):void {
		$chain.push( this );
		if ( instanceInfo.controllingModel ) {
			instanceInfo.controllingModel.getModelChain( $chain )
		}
	}
	
	static public function getWorldSpacePositionInChain( $chain:Vector.<VoxelModel> ):Matrix3D {
		var len:int = $chain.length;
		Log.out( "VoxelModel.getWorldSpacePositionInChain - all these clones are BAD", Log.WARN );

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

			if ( modelInfo.oxelPersistence && controlledModel ) {
				var ppos:Vector3D = controlledModel.instanceInfo.positionGet;
				var modelPos:Vector3D = this.instanceInfo.positionGet;
				var d:int = ppos.subtract(modelPos).length;
//				Log.out("ModelInfo.draw distance to model: " + d);
/*
				if ( d > 2900 )
					modelInfo.oxelPersistence.setLOD = 5;
				else if ( d > 2800 )
					modelInfo.oxelPersistence.setLOD = 4;
				else if ( d > 2700 )
					modelInfo.oxelPersistence.setLOD = 3;
				else if ( d > 2600 )
					modelInfo.oxelPersistence.setLOD = 2;
				else if ( d > 2500 )
					modelInfo.oxelPersistence.setLOD = 1;
				else*/
					modelInfo.oxelPersistence.setLOD = 0;

				//Log.out( "VoxelModel.draw - set LOD to: " + modelInfo.oxelPersistence.lod );
			}

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
		//if ( "DragonTailFirst" == modelInfo.name )
		//	Log.out( "VoxelModel.update - name: " + modelInfo.name, Log.DEBUG );
		if ( complete && modelInfo.oxelPersistence ) {
			instanceInfo.update( $elapsedTimeMS );
			modelInfo.update( $context, $elapsedTimeMS );
			
			// Only collide parent models
			if ( null == instanceInfo.controllingModel && instanceInfo.usesCollision )
				collisionTest($elapsedTimeMS);
			// TODO this seems like extra work, dead models should add them selves to a queue to be removed
			modelInfo.bringOutYourDead();
		}
	}
	
	public function calculateCenter( $oxelCenter:Number = 0 ):void {
		if ( 0 == $oxelCenter  && modelInfo.oxelPersistence ) {
			//$oxelCenter = modelInfo.oxelPersistence.oxel.size_in_world_coordinates() / 2;
			$oxelCenter = GrainCursor.get_the_g0_size_for_grain(modelInfo.oxelPersistence.bound) / 2;
		}
		instanceInfo.centerSetComp( $oxelCenter, $oxelCenter, $oxelCenter )
	}
	
	public function print():void
	{
		Log.out("----------------------- Print VoxelModel -------------------------------");
		Log.out("----------------------- instanceInfo.instanceGuid: " + instanceInfo.instanceGuid + " -------------------------------");
		Log.out("----------------------- instanceInfo.modelGuid:       " + instanceInfo.modelGuid + " -------------------------------");
		modelInfo.oxelPersistence.oxel.print();
		Log.out("------------------------------------------------------------------------------");
	}
	
	public function release():void {
		
		if ( modelInfo.permissions.modify ) {
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
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Loading and Saving Voxel Models
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function save():void
	{
		if ( !Globals.online ) {
			//Log.out( "VoxelModel.save - NOT online, NOT SAVING name: " + modelInfo.name + "  modelInfo.modelGuid: " + modelInfo.guid + "  instanceInfo.instanceGuid: " + instanceInfo.instanceGuid  );
			return;
		}
			
		modelInfo.save();
        Region.currentRegion.save()
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
	
	public function lineIntersect( $worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, $intersections:Vector.<GrainIntersection> ):void {
		var modelSpaceStartPoint:Vector3D = worldToModel( $worldSpaceStartPoint );
		var modelSpaceEndPoint:Vector3D   = worldToModel( $worldSpaceEndPoint );
		
		// if I was inside of a large oxel, the ray would not intersect any of the planes.
		// So this does a check quick check to see if worldSpaceStart point is inside of the model
		//var gct:GrainCursor = GrainCursorPool.poolGet( modelInfo.oxelPersistence.oxel.gc.bound );
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
			if ( modelInfo.oxelPersistence ){
				modelInfo.oxelPersistence.oxel.lineIntersect( modelSpaceStartPoint, modelSpaceEndPoint, $intersections );

				for each (var gci:GrainIntersection in $intersections) {
					if ( null == gci.model ) {
						gci.wsPoint = modelToWorld(gci.point);
						gci.model = this;
					}
				}
			}
		}
		//GrainCursorPool.poolDispose( gct );
	}
	
	public function lineIntersectWithChildOxels($worldSpaceStartPoint:Vector3D, $worldSpaceEndPoint:Vector3D, $intersections:Vector.<GrainIntersection>, $ignoreType:uint, minSize:int):void {
		var msStartPoint:Vector3D = worldToModel( $worldSpaceStartPoint );
		var msEndPoint:Vector3D   = worldToModel( $worldSpaceEndPoint );
		modelInfo.oxelPersistence.oxel.lineIntersectWithChildren( msStartPoint, msEndPoint, $intersections, $ignoreType, minSize );
		// lineIntersect returns modelSpaceIntersections, convert to world space.
		for each (var gci:GrainIntersection in $intersections) {
			if ( null == gci.model ) {
				gci.wsPoint = modelToWorld(gci.point);
				gci.model = this;
			}
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// end intersection functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function isInside(x:int, y:int, z:int, gct:GrainCursor):Boolean {
		GrainCursor.getGrainFromPoint(x, y, z, gct, gct.bound);
		var fo:Oxel = modelInfo.oxelPersistence.oxel.childFind(gct);
		if (OxelBad.INVALID_OXEL == fo)
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
	}
	
	public function isPassableAvatar(x:int, y:int, z:int, gct:GrainCursor, collideAtGrain:uint, positionResult:PositionTest):Boolean {
		GrainCursor.getGrainFromPoint(x, y, z, gct, collideAtGrain);
		var fo:Oxel = modelInfo.oxelPersistence.oxel.childFind(gct);
		var result:Boolean = true;
		if (OxelBad.INVALID_OXEL == fo)
		{
			//Log.out( "Camera.isNewPositionValid - oxel is BAD, so passable")
			result = true;
		}
		//if (fo.solid)
		//{
			//if (PositionTest.FOOT == positionResult.type)
				//positionResult.footHeight = fo.gc.getModelY() + GrainCursor.get_the_g0_size_for_grain(fo.gc.grain) + Avatar.AVATAR_HEIGHT_FOOT;
			//Log.out( "Camera.isNewPositionValid - oxel is Solid")
			//result = false;
		//}
		if (fo.childrenHas())
		{
			if (PositionTest.FOOT == positionResult.type)
				positionResult.footHeight = fo.gc.getModelY() + GrainCursor.get_the_g0_size_for_grain(fo.gc.grain) + Avatar.AVATAR_HEIGHT_FOOT;
			//Log.out( "Camera.isNewPositionValid - oxel has children")
			result = false;
		}
		return result;
	}
	
	public function isPassable($x:int, $y:int, $z:int, collideAtGrain:uint):Boolean {
		if ( 0 > $x || 0 > $y || 0 > $z )
			return true;
		var gct:GrainCursor = GrainCursorPool.poolGet(modelInfo.oxelPersistence.oxel.gc.bound);
		GrainCursor.getGrainFromPoint($x, $y, $z, gct, collideAtGrain);
		var fo:Oxel = modelInfo.oxelPersistence.oxel.childFind(gct);
		var result:Boolean = true;
		if (OxelBad.INVALID_OXEL == fo)
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
		var gct:GrainCursor = GrainCursorPool.poolGet(modelInfo.oxelPersistence.oxel.gc.bound);
		var posMs:Vector3D = worldToModel($pos);
		gct.getGrainFromVector(posMs, $collideAtGrain);
		var fo:Oxel = modelInfo.oxelPersistence.oxel.childFind(gct);
		GrainCursorPool.poolDispose(gct);
		return fo;
	}

	public function getOxelAtMSPoint($posMs:Vector3D, $collideAtGrain:uint):Oxel {
		var gct:GrainCursor = GrainCursorPool.poolGet(modelInfo.oxelPersistence.oxel.gc.bound);
		gct.getGrainFromVector($posMs, $collideAtGrain);
		var fo:Oxel = modelInfo.oxelPersistence.oxel.childFind(gct);
		GrainCursorPool.poolDispose(gct);
		return fo;
	}

	public function isSolidAtWorldSpace($cp:CollisionPoint, $pos:Vector3D, $collideAtGrain:uint, $collidingModel:VoxelModel = null ):void {
		$cp.oxel = getOxelAtWSPoint($pos, $collideAtGrain);
		if (OxelBad.INVALID_OXEL == $cp.oxel)
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
			if ( $collidingModel == VoxelModel.controlledModel ) {
				controlledModel.lastCollisionModel = this;
				//Log.out( "VoxelModel.isNewPositionValid - oxel is BAD, so passable")
			}
		}
	}
	
	public function rotateCCW():void { modelInfo.oxelPersistence.oxel.rotateCCW(); }
	public function validate():void { modelInfo.oxelPersistence.oxel.validate(); }
	
	public function changeGrainSize( changeSize:int):void {
		_timer = getTimer();
		Oxel.nodes = 0;
		if ( modelInfo.oxelPersistence.oxelCount ) {
			modelInfo.oxelPersistence.oxel.changeGrainSize(changeSize, modelInfo.oxelPersistence.oxel.gc.bound + changeSize);
			//Log.out("VoxelModel.changeGrainSize - took: " + (getTimer() - _timer) + " count " + Oxel.nodes);
			modelInfo.oxelPersistence.visitor( VisitorFunctions.rebuild, "Oxel.rebuild" );
			//Log.out("VoxelModel.changeGrainSize - rebuildAll took: " + (getTimer() - _timer));
		}
	}
	
	public function breakdown(smallest:int = 2):void {
		var timer:int = getTimer();
		modelInfo.oxelPersistence.oxel.breakdown(smallest);
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
		offsetDueTomodelRotation.scaleBy(model.modelInfo.oxelPersistence.oxel.gc.size() / 2);
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
		
		var worldSpaceIntersections:Vector.<GrainIntersection> = new Vector.<GrainIntersection>();
		var worldSpaceStartPoint:Vector3D = model.instanceInfo.positionGet.add(model.instanceInfo.center);
		
		var worldSpaceEndPoint:Vector3D = model.instanceInfo.worldSpaceMatrix.transformVector(new Vector3D(0, 0, -250));
		// are parmeter here backwards?
		collisionCandidate.lineIntersectWithChildOxels(worldSpaceEndPoint, worldSpaceStartPoint, worldSpaceIntersections, TypeInfo.AIR, modelInfo.oxelPersistence.oxel.gc.bound);
		
		if (worldSpaceIntersections.length)
		{
			var gci:GrainIntersection = worldSpaceIntersections.shift();
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
	
	// Before I add a model as a child, make sure it is not the same model is not a direct parent, or anywhere up the chain.
	public function isInParentChain($possibleChildModel:VoxelModel):Boolean {
		// Dont allow your own guid to be added to your child chain
		if (this.modelInfo.guid == $possibleChildModel.modelInfo.guid)
			return true;
		if ( instanceInfo.controllingModel ) {
			if (instanceInfo.controllingModel.isInParentChain($possibleChildModel)) {
				return true;
			}
		}
		return false;
	}
	
	public function takeControl( $modelLosingControl:VoxelModel, $addAsChild:Boolean = true ):void {
		//if ( $modelLosingControl )
			//Log.out( "VoxelModel.takeControl of : " + modelInfo.fileName + " by: " + $modelLosingControl.modelInfo.fileName );
		//else	
			//Log.out( "VoxelModel.takeControl of : " + modelInfo.fileName );
		
		VVKeyboardEvent.addListener( KeyboardEvent.KEY_DOWN, nextCamera );
		
		VoxelModel.controlledModel = this;
		
		// adds the player to the child list
		if ( $modelLosingControl && !($modelLosingControl is Avatar) )
			childAdd($modelLosingControl);
		cameraContainer.index = 0;
		
		// Pass in the name of the class that is taking control.
//		var className:String = getQualifiedClassName(this)
//		ModelEvent.dispatch( new ModelEvent( ModelEvent.TAKE_CONTROL, instanceInfo.instanceGuid, null, null, className ) );
	}
	
	public function loseControl($modelDetaching:VoxelModel, $detachChild:Boolean = true):void
	{
		VVKeyboardEvent.removeListener( KeyboardEvent.KEY_DOWN, nextCamera );
		
		// remove the player to the child list
		if ( $detachChild )
			modelInfo.childDetach( $modelDetaching, this );
		cameraContainer.index = 0;
		//var className:String = getQualifiedClassName(this)
		//ModelEvent.dispatch( new ModelEvent( ModelEvent.RELEASE_CONTROL, instanceInfo.instanceGuid, null, null, className ) );
	}
	
	// handle the tab key event to move camera around, this is only for controlled model
	protected function nextCamera(e:KeyboardEvent):void {
		if (Keyboard.TAB == e.keyCode && 0 == Globals.openWindowCount ) {
			cameraContainer.next();
			// I want the camera for the controlled object, not the avatar.
			var currentCamera:CameraLocation = VoxelModel.controlledModel.cameraContainer.current;
//			trace("VoxelModel.keyDown cameraLocation: " + currentCamera.position + "  " + currentCamera.rotation);
			if ( currentCamera.toolBarVisible )
				GUIEvent.dispatch( new GUIEvent(GUIEvent.TOOLBAR_SHOW));
			else
				GUIEvent.dispatch( new GUIEvent(GUIEvent.TOOLBAR_HIDE));
		}
	}

	public function childAdd( $childModel:VoxelModel):void {
		if ( isInParentChain($childModel) ) {
			Log.out( "VoxelModel.childAdd - TRYING TO ADD MODEL THIS IS A PARENT", Log.WARN );
			return;
		}
		//if ( false == modelInfo.childrenLoaded )
		//	modelInfo.childAdd( $childModel );
        else if ( modelInfo.permissions.modify & PermissionsModel.MODIFY_CHILD_ADD )
			modelInfo.childAdd( $childModel );
		else
        	Log.out( "VoxelModel.childAdd - TRYING TO ADD MODEL THIS IS A PARENT", Log.WARN );

    }


	protected function dispatchMovementEvent():void {
        ModelEvent.create( ModelEvent.MOVED, instanceInfo.instanceGuid, instanceInfo.positionGet, instanceInfo.rotationGet );
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

	protected function onStateLockRemove(event:TimerEvent):void { _stateLock = false; }

	public function stateReset():void {
		if (_anim) {
			//Log.out( "VoxelModel.stateReset - Stopping anim: " + _anim.name );
			_anim.stop( this );
			_anim = null;
		}
	}

	public function stateSet($state:String, $scale:Number = 1):void {
		if ( this is Player )
				return;
		if ( _stateLock )
			return;
		if ( (_anim && _anim.name == $state) || 0 == modelInfo.animations.length )
			return;
			
		if ( false == modelInfo.childrenLoaded ) {
			// really need to check if children are complete, not just added
			//Log.out("VoxelModel.stateSet - children not all loaded yet: " + $state );
			return; // not all children have loaded yet
		}
		
		//Log.out( "VoxelModel.stateSet setTo: " + $state + "  current: " + (_anim ? _anim.name : "No current state") ); 
		//else
		//	Log.out( "VoxelModel.stateSet - Starting anim: " + $state );
		stateReset();
		var anim:Animation = modelInfo.animationGet( $state );
		if ( null == anim ) {
			//Log.out("VoxelModel.stateSet - no animation found for state: " + $state);
			return;
		}

		var result:Boolean = true;
		var myself:Vector.<VoxelModel> = new Vector.<VoxelModel>();
		myself.push(this);
		for each (var at:AnimationTransform in anim.transforms) {
			//result = result && addAnimationsInChildren(modelInfo.childVoxelModels, at, $scale);
			result = result && addAnimationsInChildren(myself, at, $scale);
		}

		if (true == result) {
			_anim = anim;
			//Log.out( "VoxelModel.stateSet - Playing anim: " + _anim.name );
			_anim.play(this, $scale);
		}

		// if any of the children load, then it succeeds, which is slightly problematic
		function addAnimationsInChildren($children:Vector.<VoxelModel>, $at:AnimationTransform, $scale:Number):Boolean {
			//Log.out( "VoxelModel.checkChildren - have AnimationTransform looking for child : " + $at.attachmentName );
			var resultChildren:Boolean = true;
			if ( $children && 0 != $children.length) {
				for each (var cm:VoxelModel in $children) {
					if (cm && cm.modelInfo && cm.modelInfo.childrenLoaded) {
						//Log.out( "VoxelModel.addAnimationsInChildren - is child.modelInfo.name: " + child.modelInfo.name + " equal to $at.attachmentName: " + $at.attachmentName );
						if (cm.modelInfo.name == $at.attachmentName) {
							cm.stateSetData($at, $scale);
							return resultChildren; // TODO This does not allow for multiple attachments to same parent with same name, but is faster.
						}
						else if (0 < cm.modelInfo.childVoxelModels.length) {
							//Log.out( "VoxelModel.stateSet - addAnimationsInChildren - looking in children of child for: " + $at.attachmentName );
							resultChildren = resultChildren && addAnimationsInChildren(cm.modelInfo.childVoxelModels, $at, $scale);
							//if ( false == resultChildren )
							//	Log.out("VoxelModel.addAnimationsInChildren - FALSE");
						}
					}
					else {
						//Log.out("VoxelModel.addAnimationsInChildren - FALSE");
						resultChildren = false;
					}
				}
			}
			return resultChildren;
		}
	}
	
	private function stateSetData($at:AnimationTransform, $scale:Number):void
	{
		instanceInfo.removeAllNamedTransforms();
		//Log.out( "VoxelModel.stateSet - attachment found: " + modelInfo.fileName + " initializer: " + $useInitializer + "  setting data " + $at );
		// if the object has a parent model, then use this data to reset the position within the parent model
		// We DON'T want to change the position of objects which DON'T have a parent model
		if ( instanceInfo.controllingModel ) {
			if ($at.hasPosition)
				instanceInfo.positionSet = $at.position;
			else
				instanceInfo.positionReset();

			if ($at.hasRotation)
				instanceInfo.rotationSet = $at.rotation;
			else
				instanceInfo.rotationReset();
		}

		if ($at.hasScale)
			instanceInfo.scale = $at.scale;
		else
			instanceInfo.scaleReset();
			
	
		
		if ($at.hasTransform) {
			for each (var mt:ModelTransform in $at.transforms) {
				if ($at.notNamed)
					instanceInfo.addTransformMT(mt.clone($scale));
				else
					instanceInfo.addNamedTransformMT(mt.clone($scale));
			}
		}
	}
	
	public function updateAnimations($state:String, $percentage:Number):void {

		if (null == _anim) { // No anim set
			//Log.out( "VoxelModel.updateAnimations - new anim from NO state : " + $state );
			stateSet($state, $percentage);
		}
		else if (_anim.name != $state) { // changing anim
			//Log.out( "VoxelModel.updateAnimations - change to new anim: "  + $state + "  from old anim: " + _anim.name );
			stateSet($state, $percentage);
		}
		else if (_anim.name == $state) { // updating existing anim
			//Log.out( "VoxelModel.updateAnimations - updating transform on anim: " + _anim.name + " val: " + $percentage ); 
			for each (var at:AnimationTransform in _anim.transforms)
				updateAnimationsInChildren(modelInfo.childVoxelModels, at, $percentage);
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
			if (cm.modelInfo.name == $at.attachmentName)
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
	
	import com.voxelengine.worldmodel.inventory.*;
	public function getDefaultSlotData():Vector.<ObjectInfo> {
		
		Log.out( "VoxelModel.getDefaultSlotData - Loading default data into slots" , Log.WARN );
		var slots:Vector.<ObjectInfo> = new Vector.<ObjectInfo>( Slots.ITEM_COUNT );
		for ( var i:int = 0; i < Slots.ITEM_COUNT; i++ )
			slots[i] = new ObjectInfo( null, ObjectInfo.OBJECTINFO_EMPTY, ObjectInfo.DEFAULT_OBJECT_NAME );
		
		return slots;
	}
	
	public function size():int {
		if ( _modelInfo && _modelInfo.oxelPersistence && _modelInfo.oxelPersistence.oxelCount )
			return _modelInfo.oxelPersistence.oxel.size_in_world_coordinates();
		else
			return 0;
	}
	public function get grain():int {
		if ( _modelInfo && _modelInfo.oxelPersistence && _modelInfo.oxelPersistence.oxelCount )
			return _modelInfo.oxelPersistence.oxel.gc.grain;
		else
			return 0;
	}

	public function generateAllLODs():void {
		var time:int = getTimer();
		Log.out( "VoxelModel.generalAllLODs start");
		modelInfo.oxelPersistence.generateLOD( this );
		Log.out( "VoxelModel.generalAllLODs took: " + (getTimer()-time));
	}

	public function distanceFromPlayerToModel():Number {
		if ( controlledModel && controlledModel.instanceInfo ) {
			// this takes the origin of the oxel and converts it to world space.
			// takes the resulting vector and subtracts the player position, and uses the length as the priority
			//trace( "Chunk.refreshFacesAndQuads distance: priority: " + priority + "  chunk.oxel.gc: " + _oxel.gc.getModelVector().toString()  + "  Player.player: " +  Player.player.instanceInfo.positionGet )
			return ( modelToWorld( modelInfo.oxelPersistence.oxel.gc.getModelVector() ).subtract( controlledModel.instanceInfo.positionGet ) ).length;
		}
		return 32000;
	}

	public function rebuildLightingHandler():void {
		modelInfo.oxelPersistence.visitor( VisitorFunctions.rebuildLightingRecursive, "Oxel.rebuildLightingRecursive" );
		var children:Vector.<VoxelModel> = modelInfo.childVoxelModelsGet();
		for each ( var child:VoxelModel in children ) {
			child.rebuildLightingHandler();
		}
	}

	public function applyBaseLightLevel( $applyToChildren:Boolean ):void {
		modelInfo.oxelPersistence.changed = true;
		if ( $applyToChildren ) {
			var children:Vector.<VoxelModel> = modelInfo.childVoxelModelsGet();
			for each (var child:VoxelModel in children) {
				if (!child.modelInfo.oxelPersistence.lightInfo.locked) {
					child.instanceInfo.baseLightLevel = instanceInfo.baseLightLevel;
					child.applyBaseLightLevel( $applyToChildren );
				}
			}
		}
	}

	private var _torchIndex:int;
	public function torchToggle():void {
		Shader.lightsClear();
		var sl:ShaderLight;
		switch( _torchIndex ) {
			case 0:
				sl = new Lamp();
				break;
			case 1:
				sl = new LampBright();
				break;
			case 2:
				sl = new RainbowLight();
				break;
			case 3:
				sl = new BlackLamp();
				break;
			case 4:
				sl = new Torch();
				(sl as Torch).flicker = true;
				_torchIndex = -1; // its going to get incremented
				break;
		}
		_torchIndex++;
		sl.position = instanceInfo.positionGet.clone();
		sl.position.y += 30;
		sl.position.x += 4;
		Shader.lightAdd( sl );
	}


	static public function visitor( $func:Function, $functionName:String = "" ):void {
		if ( selectedModel ) {
			selectedModel.modelInfo.oxelPersistence.visitor( $func, $functionName );
		}
	}

	public function harvestTreesOn():void {
		for each ( var tree:VoxelModel in modelInfo.childVoxelModels ) {
			if (tree)
				tree.dead = true;
		}
	}
}
}

