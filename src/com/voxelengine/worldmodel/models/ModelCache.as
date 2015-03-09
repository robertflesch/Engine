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
	import flash.utils.getTimer;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.Region;
	
	public class ModelCache 
	{
		// these are the active parent objects or dynamic objects
		private var _models:Vector.<VoxelModel> = new Vector.<VoxelModel>();
		private var _modelsDynamic:Vector.<VoxelModel> = new Vector.<VoxelModel>();
		private var _region:Region;
		
		public function get models():Vector.<VoxelModel> { return _models; }
		public function modelsGet():Vector.<VoxelModel> { return _models; }
		public function get modelsDynamic():Vector.<VoxelModel> { return _modelsDynamic; }
		
		private var m:ModelCacheUtils;
		
		public function ModelCache( $region:Region ) {
			_region = $region;
		}
		
		public function createPlayer():Boolean	{
			var instanceInfo:InstanceInfo = new InstanceInfo();
			Log.out( "ModelCache.createPlayer - creating from LOCAL", Log.DEBUG );
			instanceInfo.guid = "player";
			instanceInfo.grainSize = 4;
			ModelLoader.load( instanceInfo );
			return true
		}

		public function save():void {
			if ( false == Globals.online || false == Globals.inRoom )
				return;
			
			// check all models to see if they have changed, if so save them to server.
			for each ( var vm:VoxelModel in _models )
				vm.save();
		}
		
		public function unload():void {
			var vm:VoxelModel;
			for ( var i:int = 0; i < _models.length; i++ ) {
				vm = _models[i];
				if ( vm is Player )
					continue;
				vm.dead = true;	
			}
			
			for ( i = 0; i < _modelsDynamic.length; i++ ) {
				vm = _modelsDynamic[i];
				vm.dead = true;
			}
		}
		
		public function add( vm:VoxelModel ):void {
			// if this is a child model, give it to parent, 
			// next check to see if its a dynamic model
			//otherwise add it to ModelCache list.
			Log.out( "ModelCache.add - guid: " + vm.instanceInfo.guid );			
			if ( vm.instanceInfo.controllingModel )
			{
				vm.instanceInfo.controllingModel.childAdd( vm );
				ModelEvent.dispatch( new ModelEvent( ModelEvent.CHILD_MODEL_ADDED, vm.instanceInfo.guid, null, null, vm.instanceInfo.controllingModel.instanceInfo.guid ) );
			}
			else if ( vm.instanceInfo.dynamicObject )
			{
				_modelsDynamic.push(vm);
				ModelEvent.dispatch( new ModelEvent( ModelEvent.DYNAMIC_MODEL_ADDED, vm.instanceInfo.guid ) );
			}
			else
			{
				if ( vm is Avatar ) {
					// need to seperate these out into their own catagory
					_models.push(vm);
					ModelEvent.dispatch( new ModelEvent( ModelEvent.AVATAR_MODEL_ADDED, vm.instanceInfo.guid ) );
				}
				else {
					_models.push(vm);
					ModelEvent.dispatch( new ModelEvent( ModelEvent.PARENT_MODEL_ADDED, vm.instanceInfo.guid ) );
				}
			}
		}
		
		public function draw( $mvp:Matrix3D, $context:Context3D ):void {
			
			// TODO Could optimize here by only making the calls needed for this shader.
			// Since only one shader is used for each, this could save a LOT OF TIME for large number of models.
			var vm:VoxelModel;
			for ( var i:int = 0; i < _models.length; i++ ) {
				vm = _models[i];
				if ( vm && vm.complete && vm.visible )
					vm.draw( $mvp, $context, false );	
			}
			
			// TODO - should sort models based on distance, and view frustrum - RSF
			for ( i = 0; i < _modelsDynamic.length; i++ ) {
				vm = _modelsDynamic[i];
				if ( vm && vm.complete && vm.visible )
					vm.draw( $mvp, $context, false );	
			}
			
			for ( i = 0; i < _models.length; i++ ) {
				vm = _models[i];
				if ( vm && vm.complete && vm.visible )
					vm.drawAlpha( $mvp, $context, false );	
			}
			
			// TODO - This is expensive and not needed if I dont have projectiles without alpha.. RSF
			for ( i = 0; i < _modelsDynamic.length; i++ ) {
				vm = _modelsDynamic[i];
				if ( vm && vm.complete && vm.visible )
					vm.drawAlpha( $mvp, $context, false );	
			}
			
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
			for ( var i:int; i < _modelsDynamic.length; i++ ) {
				vm = _modelsDynamic[i];
				vm.update( Globals.g_renderer.context,  $elapsedTimeMS );	
			}
			
			dynModelTime = getTimer() - dynModelTime;
			
			var modelTime:int = getTimer();
			for ( i = 0; i < _models.length;  i++ ) {
				vm = _models[i];
				vm.update( Globals.g_renderer.context,  $elapsedTimeMS );	
			}
			
			modelTime = getTimer() - modelTime;
			
			if ( Globals.g_app.toolOrBlockEnabled )
				ModelCacheUtils.highLightEditableOxel();
		}
		
		public function dispose():void 	{
			Log.out("ModelCache.dispose" );
			var model:VoxelModel;
			for each ( model in _modelsDynamic )
			{
				model.dispose();
			}
			
			for each ( model in _models )
			{
				model.dispose();	
			}
		}

		public function getJSON( outString:String ):String {
			var count:int = 0;
			//for each ( var vm:VoxelModel in _modelInstances )
			//	count++;
			var instanceData:Vector.<String> = new Vector.<String>;
				
			var model:VoxelModel;
			for each ( model in _models )
			{
				if ( model is Player )
					continue;
				Log.out( "ModelCache.getJSON - instance: " + model.getJSON() );
				instanceData.push( model.getJSON() );	
			}
			
			var len:int = instanceData.length;
			for ( var index:int; index < len; index++ ) {
				outString += instanceData[index];
				if ( index == len - 1 )
					continue;
				outString += ",";
			}
			return outString;
		}
		
		public function reinitialize( $context:Context3D ):void 	{
			
			//Log.out("ModelManager.reinitialize" );
			Globals.g_textureBank.reinitialize( $context );
			
			var vm:VoxelModel
			for ( var i:int; i < _modelsDynamic.length; i++ ) {
				vm = _modelsDynamic[i];
				vm.reinitialize( $context );
			}
			
			for ( i = 0; i < _models.length; i++ ) {
				vm = _models[i];
				vm.reinitialize( $context );	
			}
		}
		
		public function bringOutYourDead():void {
			var vm:VoxelModel
			for ( var i:int; i < _models.length; ) {
				vm = _models[i];
				if ( vm && true == vm.dead )
					_models.splice( i, 1 );
				else 
					i++
			}
		}
		
		public function bringOutYourDeadDynamic():void {
			var vm:VoxelModel;
			for ( var i:int; i < _modelsDynamic.length; ) {
				vm = _modelsDynamic[i];
				if ( vm && true == vm.dead )
					_modelsDynamic.splice( i, 1 );
				else 
					i++
			}
		}
	}
}