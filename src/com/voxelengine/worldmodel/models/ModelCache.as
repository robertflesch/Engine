/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.utils.Dictionary;
import flash.utils.getTimer;

//import com.developmentarc.core.datastructures.utils.HashTable;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.ModelPlacementType;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.*;

public class ModelCache 
{
	// these are the active parent objects or dynamic objects
	// We do double entry here so that models can be retrived by guid
	
	// TODO replace this double entry with a hash table which has it built in.
	// Speed consideration?
	private var _instances:Vector.<VoxelModel> = new Vector.<VoxelModel>();
	private var _instanceByGuid:Dictionary = new Dictionary();
	private var _instancesDynamic:Vector.<VoxelModel> = new Vector.<VoxelModel>();
	private var _instanceByGuidDynamic:Dictionary = new Dictionary();
	private var _region:Region;
	
	public function get models():Vector.<VoxelModel> { return _instances; }
	public function modelsGet():Vector.<VoxelModel> { return _instances; }
	public function get modelsDynamic():Vector.<VoxelModel> { return _instancesDynamic; }
	
	public function ModelCache( $region:Region ) {
		_region = $region;
		ModelEvent.addListener( ModelEvent.PLAYER_MODEL_REMOVED, playerRemoved );
	}
	
	public function requestModelInfoByModelGuid( $modelGuid:String ):ModelInfo {
		for ( var i:int; i < _instances.length; i++ ) {
			var vm:VoxelModel = _instances[i];
			if ( vm )
				if ( $modelGuid == vm.modelInfo.guid )
					return vm.modelInfo
		}
		return null
	}
	
	public function getModelFromModelGuid( $modelGuid:String ):VoxelModel {
		for ( var i:int; i < _instances.length; i++ ) {
			var vm:VoxelModel = _instances[i];
			if ( vm )
				if ( $modelGuid == vm.modelInfo.guid )
					return vm
		}
		return null
	}
	
	private function playerRemoved(e:ModelEvent):void {
		var vm:VoxelModel;
		for ( var i:int; i < _instances.length; ) {
			vm = _instances[i];
			if ( vm && vm is Player ) {
				_instances.splice( i, 1 );
				_instanceByGuid[vm.instanceInfo.instanceGuid] = null;
				return;
			}
			else 
				i++
		}
	}
	
	// need to do a recurvsive search here
	public function instanceGet( $instanceGuid:String ):VoxelModel
	{ 
		return _instanceByGuid[$instanceGuid];
	}

	public function instancesOfModelGet( $modelGuid:String ):Vector.<VoxelModel>
	{ 
		var results:Vector.<VoxelModel> = new Vector.<VoxelModel>();
		for ( var i:int; i < _instances.length; i++ ) {
			var vm:VoxelModel = _instances[i];
			if ( vm && vm.metadata.guid == $modelGuid )
				results.push( vm );
		}
		return results;
	}

	static public function createPlayer():void	{
		var instanceInfo:InstanceInfo = new InstanceInfo();
		Log.out( "ModelCache.createPlayer - creating from LOCAL", Log.DEBUG );
		instanceInfo.modelGuid = "Player";
		instanceInfo.instanceGuid = "Player";
		ModelMakerBase.load( instanceInfo );
	}

	public function save():void {
		//Log.out( "ModelCache.save - Saving all models", Log.WARN );
		if ( false == Globals.online || false == Globals.inRoom )
			return;
		
		// check all models to see if they have changed, if so save them to server.
		for each ( var vm:VoxelModel in _instances )
			vm.save();
	}
	
	public function unload():void {
		var vm:VoxelModel;
		for ( var i:int = 0; i < _instances.length; i++ ) {
			vm = _instances[i];
			if ( vm is Player )
				continue;
			vm.dead = true;	
		}
		
		for ( i = 0; i < _instancesDynamic.length; i++ ) {
			vm = _instancesDynamic[i];
			vm.dead = true;
		}
	}
	
	public function add( vm:VoxelModel ):void {
		// if this is a child model, give it to parent, 
		// next check to see if its a dynamic model
		//otherwise add it to ModelCache list.
		//Log.out( "ModelCache.add - name: " + vm.metadata.name + "  guid: " + vm.instanceInfo.modelGuid + "  instanceGuid: " + vm.instanceInfo.instanceGuid, Log.WARN );			
		if ( vm.instanceInfo.controllingModel )
		{
			//Log.out( "    which is child of  - name: " + vm.instanceInfo.controllingModel.metadata.name + "  guid: " + vm.instanceInfo.controllingModel.instanceInfo.modelGuid + "  instanceGuid: " + vm.instanceInfo.controllingModel.instanceInfo.instanceGuid, Log.WARN );			
			vm.instanceInfo.controllingModel.childAdd( vm );
			// ah, this is the instance by guid, basically the look up spot for things...
			// not the instances, which are used to draw everything.
			_instanceByGuid[vm.instanceInfo.instanceGuid] = vm;
			ModelEvent.dispatch( new ModelEvent( ModelEvent.CHILD_MODEL_ADDED, vm.instanceInfo.instanceGuid, null, null, vm.instanceInfo.controllingModel.instanceInfo.instanceGuid, vm ) );
		}
		else if ( vm.instanceInfo.dynamicObject )
		{
			if ( null == vm.instanceInfo.instanceGuid )
				vm.instanceInfo.instanceGuid = Globals.getUID();
			_instancesDynamic.push(vm);
			_instanceByGuidDynamic[vm.instanceInfo.instanceGuid] = vm;
			ModelEvent.dispatch( new ModelEvent( ModelEvent.DYNAMIC_MODEL_ADDED, vm.instanceInfo.instanceGuid ) );
		}
		else
		{
			if ( vm is Avatar ) {
				// need to seperate these out into their own catagory
				if ( null == _instanceByGuid[vm.instanceInfo.instanceGuid] ) {
					_instanceByGuid[vm.instanceInfo.instanceGuid] = vm;
					_instances.push(vm);
					if ( vm is Player )
						ModelEvent.dispatch( new ModelEvent( ModelEvent.AVATAR_MODEL_ADDED, vm.instanceInfo.instanceGuid ) );
					else	
						ModelEvent.dispatch( new ModelEvent( ModelEvent.AVATAR_MODEL_ADDED, vm.instanceInfo.instanceGuid ) );
				}
				else
					Log.out( "ModelCache.add - Trying to add a AVATAR with the same MODEL AND INSTANCE for a second time", Log.ERROR );
			}
			else {
				if ( null == vm.instanceInfo.instanceGuid )
					vm.instanceInfo.instanceGuid = Globals.getUID();
				// This keeps us from adding the same model twice
				if ( null == _instanceByGuid[vm.instanceInfo.instanceGuid] ) {
					_instanceByGuid[vm.instanceInfo.instanceGuid] = vm;
					_instances.push(vm);
					ModelEvent.dispatch( new ModelEvent( ModelEvent.PARENT_MODEL_ADDED, vm.instanceInfo.instanceGuid ) );
				}
				else
					Log.out( "ModelCache.add - Trying to add the same MODEL AND INSTANCE for a second time", Log.ERROR );
			}
		}
	}
	
	public function draw( $mvp:Matrix3D, $context:Context3D ):void {
		
		// TODO Could optimize here by only making the calls needed for this shader.
		// Since only one shader is used for each, this could save a LOT OF TIME for large number of models.
		var vm:VoxelModel;
		for ( var i:int = 0; i < _instances.length; i++ ) {
			vm = _instances[i];
			if ( vm && vm.complete && vm.instanceInfo.visible )
				vm.draw( $mvp, $context, false, false );	
		}
		
		// TODO - should sort models based on distance, and view frustrum - RSF
		for ( i = 0; i < _instancesDynamic.length; i++ ) {
			vm = _instancesDynamic[i];
			if ( vm && vm.complete && vm.instanceInfo.visible )
				vm.draw( $mvp, $context, false, false );	
		}
		
		if ( EditCursor.isEditing )
			EditCursor.currentInstance.drawCursor( $mvp, $context, false, false );
			
		for ( i = 0; i < _instances.length; i++ ) {
			vm = _instances[i];
			if ( vm && vm.complete && vm.instanceInfo.visible )
				vm.draw( $mvp, $context, false, true );	
		}
		
		// TODO - This is expensive and not needed if I dont have projectiles without alpha.. RSF
		for ( i = 0; i < _instancesDynamic.length; i++ ) {
			vm = _instancesDynamic[i];
			if ( vm && vm.complete && vm.instanceInfo.visible )
				vm.draw( $mvp, $context, false, true );	
		}
		
		if ( EditCursor.isEditing ) //  && ModelPlacementType.PLACEMENT_TYPE_PARENT == ModelPlacementType.modelPlacementTypeGet()
			EditCursor.currentInstance.drawCursor( $mvp, $context, false, true );
		
		bringOutYourDead();
		bringOutYourDeadDynamic();
	}
		
	public function update( $elapsedTimeMS:int ):void {
		
		ModelCacheUtils.worldSpaceStartAndEndPointCalculate();

		var taskTime:int = getTimer();
		// Make sure to call this before the model update, so that models have time to repair them selves.
		if ( 0 == Globals.g_landscapeTaskController.VVNextTask() )
		{
			Globals.g_flowTaskController.VVNextTask();
			//while ( 0 < Globals.g_lightTaskController.queueSize() )
				Globals.g_lightTaskController.VVNextTask();
		}
		taskTime = getTimer() - taskTime;

		var dynModelTime:int = getTimer();
		
		var vm:VoxelModel
		for ( var i:int; i < _instancesDynamic.length; i++ ) {
			vm = _instancesDynamic[i];
			vm.update( Globals.g_renderer.context,  $elapsedTimeMS );	
		}
		
		dynModelTime = getTimer() - dynModelTime;
		
		var modelTime:int = getTimer();
		for ( i = 0; i < _instances.length;  i++ ) {
			vm = _instances[i];
			vm.update( Globals.g_renderer.context,  $elapsedTimeMS );	
		}
		
		modelTime = getTimer() - modelTime;
			
		if ( EditCursor.isEditing )
			EditCursor.currentInstance.update( Globals.g_renderer.context, $elapsedTimeMS);

	}
	
	//public function dispose():void 	{
		//Log.out("ModelCache.dispose" );
		//var model:VoxelModel;
		//for each ( model in _instancesDynamic )
		//{
			//model.dispose();
		//}
		//
		//for each ( model in _instances )
		//{
			//model.dispose();	
		//}
	//}

	public function toObject():Array {
		var models:Array = new Array();
		for ( var i:int; i < _instances.length; i++ ) {
			var vm:VoxelModel = _instances[i];
			if ( vm is Player )
				continue;
			if ( vm.dead )
				continue;
			Log.out( "ModelCache.toObject - saving" + vm.instanceInfo.toString() )	
			models.push( vm.instanceInfo.toObject() );	
		}
		return models;
	}
	
	public function bringOutYourDead():void {
		var vm:VoxelModel
		for ( var i:int; i < _instances.length; ) {
			vm = _instances[i];
			if ( vm && true == vm.dead ) {
				_instances.splice( i, 1 );
				_instanceByGuid[vm.instanceInfo.instanceGuid] = null;
			}
			else 
				i++
		}
	}
	
	public function bringOutYourDeadDynamic():void {
		var vm:VoxelModel;
		for ( var i:int; i < _instancesDynamic.length; ) {
			vm = _instancesDynamic[i];
			if ( vm && true == vm.dead ) {
				_instancesDynamic.splice( i, 1 );
				_instanceByGuidDynamic[vm.instanceInfo.instanceGuid] = null;
				vm.release();
			}
			else 
				i++
		}
	}
	
	// Models removed this way are not dead, just no longer part of the parent model loop
	public function changeFromParentToChild( $vm:VoxelModel ):void {

		var vm:VoxelModel
		for ( var i:int; i < _instances.length; i++ ) {
			vm = _instances[i];
			if ( vm && $vm == vm )
			{
				_instances.splice( i, 1 );
				_instanceByGuid[vm.instanceInfo.instanceGuid] = null;
				break;
			}
		}
	}
}
}