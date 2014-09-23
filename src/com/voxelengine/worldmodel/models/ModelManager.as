/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.oxel.GrainCursorIntersection;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.net.FileReference;
	import flash.utils.Dictionary;
	import flash.utils.ByteArray;
	import flash.display3D.Context3D;
	
	import mx.utils.StringUtil;
	
	import com.voxelengine.server.Persistance;
	import playerio.PlayerIOError;
		
	
	import com.developmentarc.core.tasks.tasks.ITask;
	import com.developmentarc.core.tasks.groups.TaskGroup;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.pools.*;
	import com.voxelengine.utils.CustomURLLoader;
	import com.voxelengine.worldmodel.models.*;
	import com.voxelengine.worldmodel.tasks.landscapetasks.CompletedModel;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LoadModelFromBigDB;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class ModelManager 
	{
		static public const FRONT:int = 0;
		static public const BACK:int = 1;
		static public const LEFT:int = 2;
		static public const RIGHT:int = 3;
		static public const UP:int = 4;
		static public const DOWN:int = 5;
		// these are the active parent objects or dynamic objects
		private var _modelInstances:Dictionary = new Dictionary(true);
		
		private var _modelDynamicInstances:Dictionary = new Dictionary(true);
		
		// this acts as a holding spot for all models in game
		// whether they are parent OR child models
		private var _instanceDictionary:Dictionary = new Dictionary(true);
		
		// holds the byte data for models loaded from hard drive.
		private var _modelByteArrays:Dictionary = new Dictionary(true);
		
		// the model mjson for an model guid
		private var _modelInfo:Dictionary = new Dictionary(true);
		
		// temporary reference to last model from by find closest model function
		private var _lastFoundModel:VoxelModel = null;
		
		private const EDIT_RANGE:int = 250;
		private var _viewDistances:Vector.<Vector3D> = null;
		
		public function modelInfoGetDictionary():Dictionary { return _modelInfo; }
		public function modelInfoGet( fileName:String ):ModelInfo {
			var mi:ModelInfo = _modelInfo[fileName]
			if ( mi )
			{
				// All guid based object are unique by definition. so no need to clone them.
				// Non guid based objects are templates, so copies of templates require a clone
				if ( Globals.isGuid(fileName) )
					return mi;
				else	
					return mi.clone( fileName );
			}
			else
				return null;
		}
		public function modelInfoAdd( modelInfo:ModelInfo ):void  { _modelInfo[modelInfo.fileName] = modelInfo; }
		public function get modelByteArrays():Dictionary { return _modelByteArrays; }
		
		public function get worldSpaceStartPoint():Vector3D 
		{
			return _worldSpaceStartPoint;
		}
		
		public function instanceInfoAdd(val:InstanceInfo):void  {  _instanceDictionary[val.guid] = val; }
		public function instanceInfoGet( guid:String ):InstanceInfo  {  return _instanceDictionary[guid]; }
		
		public function ModelManager() {
			_viewDistances = new Vector.<Vector3D>(6); 
			_viewDistances[FRONT] = new Vector3D(0, 0, -1);
			_viewDistances[BACK] = new Vector3D(0, 0, 1);
			_viewDistances[LEFT] = new Vector3D(-1, 0, 0);
			_viewDistances[RIGHT] = new Vector3D(1, 0, 0);
			_viewDistances[UP] = new Vector3D(0, 1, 0);
			_viewDistances[DOWN] = new Vector3D(0, -1, 0);
		}
		
		//////////////////////////////////////////////////////////////////////////////////
		//////////////////////// modelInstances //////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////
		
		public function modelInstancesGetDictionary():Dictionary { return _modelInstances; }
		public function modelInstancesGet( guid:String ):VoxelModel { 
			var vm:VoxelModel = _modelInstances[guid];
			if ( vm )
				return vm;
			
			vm = _modelDynamicInstances[guid];
			
			return vm;
		}
		
		public function modelInstancesChangeGuid( $oldGuid:String, $newGuid:String ):void { 
			var vm:VoxelModel = _modelInstances[$oldGuid];
			if ( vm ) {
				vm.instanceInfo.guid = $newGuid;
				_modelInstances[vm.instanceInfo.guid] = vm;
				_modelInstances[$oldGuid] = null;
				_modelInstances = clearDictionaryOfNullsAndDead( _modelInstances );
			}
		}

		public function getModelInstance( guid:String ):VoxelModel {
			// This tried to get the model directly
			var vm:VoxelModel = modelInstancesGet(guid);
			// if not found, perhaps it is a child model.
			if ( !vm )
			{
				// Get the instanceInfo for the model
				var ii:InstanceInfo = instanceInfoGet( guid );
				if ( ii )
				{
					// if has instanceInfo, see if there is a parent model
					var parentModel:VoxelModel = ii.controllingModel;
					if ( parentModel )
						vm = parentModel.childModelFind( guid );
					else
					{
						return null;
						//return Globals.player;
						//Log.out("ModelManager.getModelInstance - parent model not found: " + guid, Log.ERROR );	
					}
				}
				else
					Log.out("ModelManager.getModelInstance - model not found: " + guid, Log.ERROR );	
			}
				
			return vm;	
		}
			

		public function modelInstancesGetFirst():VoxelModel { 
			for each ( var vm:VoxelModel in _modelInstances )
				return vm;

			return null;
		}
		
		// Models removed this way are not dead, just no longer part of the parent model loop
		public function changeFromParentToChild( $vm:VoxelModel ):void {
			var found:Boolean = false;
			for each ( var vm:VoxelModel in _modelInstances )
			{
				if ( vm && $vm == vm )
				{
					_modelInstances[$vm.instanceInfo.guid] = null;
					found = true;
					break;
				}
			}
			
			if ( found )
				_modelInstances = clearDictionaryOfNullsAndDead( _modelInstances );
		}
		
		public function save():void {
			// check all models to see if they have changed, if so save them to server.
			for each ( var vm:VoxelModel in _modelInstances )
			{
				vm.save();
			}
		}
		
		public function bringOutYourDead():void {
			var hasDead:Boolean = false;
			for each ( var vm:VoxelModel in _modelInstances )
			{
				if ( vm && true == vm.instanceInfo.dead )
				{
					hasDead = true;
					// This seems like a REALLY bad idea.
					// vm.removeFromBigDB();
					break;
				}
			}
			
			if ( hasDead )
			{
				_modelInstances = clearDictionaryOfNullsAndDead( _modelInstances );
				_instanceDictionary = clearInstanceInfoOfNullsAndDead( _instanceDictionary );
			}
		}
		
		public function removeAllModelInstances( $removePlayer:Boolean = false ):void {
			Log.out( "ModelManager.removeAllModelInstances - Should this remove the player since it is now unique?" );
			// clear out old models
			for each ( var vm:VoxelModel in _modelInstances )
			{
				if ( vm )
				{
					if (vm is Player)
						if ( !$removePlayer )
							continue;
						else {
							Globals.player.loseControl( vm );
							Globals.player = null;
						}
					trace( "ModelManager.removeAllModelInstances - marking as dead: " + vm.instanceInfo.guid );
					markDead( vm.instanceInfo.guid );
				}
			}
			
			//_modelInfo = null;
			//_modelInfo = new Dictionary();
		}	
		
		//////////////////////////////////////////////////////////////////////////////////
		//////////////////////// END modelInstances //////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////
		
		public function addIVM( fileName:String, ba:ByteArray ):void {
			//Log.out( "ModelManager.addIVM: " + fileName );
			_modelByteArrays[fileName] = ba;
		}
		
		public function findIVM( fileName:String ):ByteArray {
			var ba:ByteArray = _modelByteArrays[fileName];
			if ( ba )
			{
				ba.position = 0;
				return ba;
			}
			else {
				
				for (var k:Object in _modelByteArrays)
				{
					var key:String  = k as String;
					var index:int = key.indexOf( fileName, 0 );
					if ( -1 != index )
						return _modelByteArrays[k];
				}
				
			}
			return null;
		}
		
		public function modelAdd( vm:VoxelModel ):void {
			// if this is a child model, give it to parent, 
			// next check to see if its a dynamic model
			//otherwise add it to modelmanager list.
			Log.out( "ModelManager.modelAdd - guid: " + vm.instanceInfo.guid );			
			if ( vm.instanceInfo.controllingModel )
			{
				vm.instanceInfo.controllingModel.childAdd( vm );
				Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.CHILD_MODEL_ADDED, vm.instanceInfo.guid, null, null, vm.instanceInfo.controllingModel.instanceInfo.guid ) );
			}
			else if ( vm.instanceInfo.dynamicObject )
			{
				_modelDynamicInstances[vm.instanceInfo.guid] = vm;
				Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.DYNAMIC_MODEL_ADDED, vm.instanceInfo.guid ) );
			}
			else
			{
				_modelInstances[vm.instanceInfo.guid] = vm;
				Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.PARENT_MODEL_ADDED, vm.instanceInfo.guid ) );
			}
		}
		
		static private function stripExtension( fileName:String ):String {
			return fileName.substr( 0, fileName.indexOf( "." ) );
		}

		public function markDead( guid:String ):void {
			// This works on both dyamanic and regular instances
			var vm:VoxelModel = modelInstancesGet(guid);
			if ( vm )
			{
				Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.PARENT_MODEL_REMOVED, vm.instanceInfo.guid ) );
				vm.instanceInfo.dead = true;
			}
		}

		public function bringOutYourDeadDynamic():void {
			var hasDead:Boolean = false;
			for each ( var vm:VoxelModel in _modelDynamicInstances )
			{
				if ( vm && true == vm.instanceInfo.dead )
				{
					hasDead = true;
					break;
				}
			}
			
			if ( hasDead )
			{
				_modelDynamicInstances = clearDictionaryOfNullsAndDead( _modelDynamicInstances );
			}
		}
			
		
		private function clearInstanceInfoOfNullsAndDead( oldDic:Dictionary ):Dictionary {
			var tempDic:Dictionary = new Dictionary(true);
			for each ( var instance:InstanceInfo in oldDic )
			{
				if ( instance ) {
					if ( true == instance.dead )
					{
						var oldGuid:String = instance.guid;
						instance = null;
						oldDic[oldGuid] = null;
					}
					else
					{
						tempDic[instance.guid] = instance;
					}
				}
			}
			oldDic = null;
			return tempDic;
		}
		
		private function countDict( oldDic:Dictionary ):int {
			var count:int = 0;
			for each ( var instance:InstanceInfo in oldDic )
			{
				count++;
			}
			
			return count;
		}

		private function clearDictionaryOfNullsAndDead( oldDic:Dictionary ):Dictionary {
			var tempDic:Dictionary = new Dictionary(true);
			for each ( var instance:VoxelModel in oldDic )
			{
				// If its marked dead release it
				if ( instance && true == instance.instanceInfo.dead )
				{
					oldDic[instance.instanceInfo.guid] = null;
					instance.release();
					// could I just use a delete here, rather then creating new dictionary? See Dictionary class for details - RSF
				}
				else
				{
					if ( instance )
						tempDic[instance.instanceInfo.guid] = instance;
					else
						Log.out( "ModelManager.clearDictionaryOfNullsAndDead - Null found" );
				}
			}
			oldDic = null;
			return tempDic;
		}
		
		public function draw( $mvp:Matrix3D, $context:Context3D ):void {
			
			// TODO Could optimize here by only making the calls needed for this shader.
			// Since only one shader is used for each, this could save a LOT OF TIME for large number of models.
			for each ( var instance:VoxelModel in _modelInstances )
			{
				if ( instance && instance.complete && instance.visible )
					instance.draw( $mvp, $context, false );	
			}
			
			// TODO - should sort models based on distance, and view frustrum - RSF
			for each ( var instanceDyn:VoxelModel in _modelDynamicInstances )
			{
				if ( instanceDyn && instanceDyn.complete && instanceDyn.visible )
					instanceDyn.draw( $mvp, $context, false );	
			}
			
			for each ( var instanceAlpha:VoxelModel in _modelInstances )
			{
				if ( instanceAlpha && instanceAlpha.complete && instanceAlpha.visible )
					instanceAlpha.drawAlpha( $mvp, $context, false );	
			}
			
			// TODO - This is expensive and not needed if I dont have projectiles without alpha.. RSF
			for each ( var instanceDynAlpha:VoxelModel in _modelDynamicInstances )
			{
				if ( instanceDynAlpha && instanceDynAlpha.complete && instanceDynAlpha.visible )
					instanceDynAlpha.drawAlpha( $mvp, $context, false );	
			}
			
			bringOutYourDead();
			bringOutYourDeadDynamic();
		}
			
		public function updateFileName( $newFileName:String, $oldFileName:String ):ModelInfo {
			var modelInfo:ModelInfo = _modelInfo[ $oldFileName ];
			if ( !modelInfo )
				throw new Error( "ModelManager.updatefileName - modelInfo not found for: " + $oldFileName );
			
			var newModelInfo:ModelInfo = modelInfo.clone($newFileName);
			_modelInfo[$newFileName] = newModelInfo;
			return newModelInfo;
		}
		
		public function createPlayer():void	{
			
			//private static var g_player:Player = null;			
			//Log.out("ModelManager.createPlayer" );
			var instanceInfo:InstanceInfo = new InstanceInfo();
			if ( Globals.online ) {
				Persistance.loadMyPlayerObject( onPlayerLoadedAction, onPlayerLoadError );
			}
			else {
				instanceInfo.guid = "player";
				instanceInfo.grainSize = 4;
				ModelLoader.load( instanceInfo );
			}
		}
		
		import playerio.DatabaseObject;
		private function onPlayerLoadedAction( o:DatabaseObject ):void {
			
			var instanceInfo:InstanceInfo = new InstanceInfo();
			instanceInfo.grainSize = 4;
			instanceInfo.guid = "2C18D274-DE77-6BDD-1E7B-816BFA7286AE"
			//instanceInfo.guid = "player";
			//Log.out("ModelManager.onPlayerLoadedAction" );
			ModelLoader.load( instanceInfo );
			o.name = "Bob";
			o.age = 32;
			o.save();
		}
		
		private function onPlayerLoadError(error:PlayerIOError):void {
			
			Log.out("ModelManager.onPlayerLoadError" );
		}


		
		public function update( $elapsedTimeMS:int ):void {
			
			worldSpaceStartAndEndPointCalculate();
			
			// Make sure to call this before the model update, so that models have time to repair them selves.
			if ( 0 == Globals.g_landscapeTaskController.VVNextTask() )
			{
				Globals.g_flowTaskController.VVNextTask();
				//while ( 0 < Globals.g_lightTaskController.queueSize() )
					Globals.g_lightTaskController.VVNextTask();
			}

			if ( Globals.g_app.toolOrBlockEnabled )
				highLightEditableOxel();

			for each ( var instanceDyn:VoxelModel in _modelDynamicInstances )
			{
				instanceDyn.update( Globals.g_renderer.context,  $elapsedTimeMS );	
			}
			
			for each ( var instance:VoxelModel in _modelInstances )
			{
				instance.update( Globals.g_renderer.context, $elapsedTimeMS );	
			}
		}
		
		public function dispose():void 	{
			Log.out("ModelManager.dispose" );
			
			for each ( var dm:VoxelModel in _modelDynamicInstances )
			{
				dm.dispose();
			}
			
			for each ( var vm:VoxelModel in _modelInstances )
			{
				vm.dispose();	
			}
		}
		
		public function reinitialize( $context:Context3D ):void 	{
			
			//Log.out("ModelManager.reinitialize" );
			Globals.g_textureBank.reinitialize( $context );
			
			for each ( var dm:VoxelModel in _modelDynamicInstances )
			{
				dm.reinitialize( $context );
			}
			
			for each ( var vm:VoxelModel in _modelInstances )
			{
				vm.reinitialize( $context );	
			}
		}
		
		private function sortIntersectionsGeneral( pointModel1:Object, pointModel2:Object ):Number	{
			var point1Rel:Number = _worldSpaceStartPoint.subtract( pointModel1.point ).length;
			var point2Rel:Number = _worldSpaceStartPoint.subtract( pointModel2.point ).length;
			if ( point1Rel < point2Rel )
				return -1;
			else if ( point1Rel > point2Rel ) 
				return 1;
			else 
				return 0;			
		}
		
		private function sortIntersections( pointModel1:GrainCursorIntersection, pointModel2:GrainCursorIntersection ):Number {
			var point1Rel:Number = _worldSpaceStartPoint.subtract( pointModel1.point ).length;
			var point2Rel:Number = _worldSpaceStartPoint.subtract( pointModel2.point ).length;
			if ( point1Rel < point2Rel )
				return -1;
			else if ( point1Rel > point2Rel ) 
				return 1;
			else 
				return 0;			
		}

		private var _totalIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
		private var _worldSpaceIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
		private var _worldSpaceStartPoint:Vector3D;
		private var _worldSpaceEndPoint:Vector3D;
		
		public function viewVectorNormalizedGet():Vector3D {
			var newV:Vector3D = _worldSpaceEndPoint.subtract( _worldSpaceStartPoint );
			newV.normalize();
			return newV;
		}
		
		public var _gci:GrainCursorIntersection;
		public function highLightEditableOxel():void {
			if ( !Globals.controlledModel )
				return;
			
			_totalIntersections.length = 0;
			_worldSpaceIntersections.length = 0;
			
			// We should only use the models in the view frustrum - TODO - RSF
			var editableModel:VoxelModel = findEditableModel();
			_totalIntersections.length = 0;
			_worldSpaceIntersections.length = 0;
			if ( editableModel )
			{
				if ( _lastFoundModel != editableModel && _lastFoundModel )
					_lastFoundModel.editCursor.visible = false;	
				
				Globals.selectedModel = editableModel;
				
				if ( Globals.g_app.editing && editableModel.editCursor )
				{
					const minSize:int = editableModel.editCursor.oxel.gc.grain;
					
					editableModel.lineIntersectWithChildren( _worldSpaceStartPoint, _worldSpaceEndPoint, _worldSpaceIntersections, minSize )
						
					for each ( var gcIntersection:GrainCursorIntersection in _worldSpaceIntersections )
					{
						gcIntersection.model = editableModel;
						_totalIntersections.push( gcIntersection );
					}
					_totalIntersections.sort( sortIntersections );

					_gci = _totalIntersections.shift();
					/////////////////////////////////////////
					if ( _gci )
					{
						_gci.point = editableModel.worldToModel( _gci.point );
						editableModel.editCursor.setGCIData( _gci );
					}
					else	
					{
						editableModel.editCursor.visible = false;	
						editableModel.editCursor.clearGCIData();
					}
					_lastFoundModel = editableModel;
				}
			}
			totalIntersectionsClear();
			worldSpaceIntersectionsClear()
		}
		
		public function findClosestIntersectionInDirection( $dir:int = UP ):GrainCursorIntersection	{
			if ( !Globals.controlledModel )
				return null;
			
			worldSpaceStartAndEndPointCalculate( $dir );
			
			// We should only use the models in the view frustrum - TODO - RSF
			var vm:VoxelModel = findEditableModel();
			if ( vm )
			{
				const minSize:int = 2; // TODO pass this in?
				vm.lineIntersectWithChildren( _worldSpaceStartPoint, _worldSpaceEndPoint, _worldSpaceIntersections, minSize )
					
				for each ( var gcIntersection:GrainCursorIntersection in _worldSpaceIntersections )
				{
					gcIntersection.model = vm;
					_totalIntersections.push( gcIntersection );
				}
				_totalIntersections.sort( sortIntersections );

				var gci:GrainCursorIntersection = _totalIntersections.shift();
			}
			totalIntersectionsClear();
			worldSpaceIntersectionsClear()
			
			return gci;
		}

		private	function findEditableModel():VoxelModel {
			var foundModel:VoxelModel = null;
			var intersections:Vector.<GrainCursorIntersection> = findRayIntersections();
			var intersection:GrainCursorIntersection = intersections.shift();
			if ( intersection && intersection.point.length )
			{
				//if ( intersection.point.length < EDIT_RANGE )
					foundModel = intersection.model;
				//else
				//	trace( "out of range" );
			}
			
			if ( null == foundModel && null != _lastFoundModel )
			{
				_lastFoundModel.editCursor.visible = false;
				_lastFoundModel	= null;
			}
			
			return foundModel;
		}

		
		private var _cameraMatrix:Matrix3D = new Matrix3D();
		public	function worldSpaceStartAndEndPointCalculate( $direction:int = FRONT, $editRange:int = EDIT_RANGE ):void {
/*
			var cm:VoxelModel = Globals.controlledModel;
			var wsPositionCamera:Vector3D = cm.instanceInfo.worldSpaceMatrix.transformVector( cm.camera.current.position );
			
			// Empty starting matrix
			_cameraMatrix.identity();
			
			const cmRotation:Vector3D = cm.camera.rotationGet;
			_cameraMatrix.prependRotation( -cmRotation.x, Vector3D.X_AXIS );
			_cameraMatrix.prependRotation( -cmRotation.y, Vector3D.Y_AXIS );
			_cameraMatrix.prependRotation( -cmRotation.z, Vector3D.Z_AXIS );

			// the position of the controlled model
 			_cameraMatrix.prependTranslation( wsPositionCamera.x, wsPositionCamera.y, wsPositionCamera.z ); 
			
			var viewDistance:Vector3D = _viewDistances[$direction].clone();
			viewDistance.scaleBy( $editRange );
			
			_worldSpaceStartPoint = wsPositionCamera;
			_worldSpaceEndPoint = _cameraMatrix.transformVector( viewDistance );
			*/
			/*
			var cm:VoxelModel = Globals.controlledModel;
			_cameraMatrix = cm.instanceInfo.worldSpaceMatrix.clone();
			var msCamPos:Vector3D = cm.camera.current.position;
			const cmRotation:Vector3D = cm.camera.rotationGet;
			//_cameraMatrix.appendRotation( -cmRotation.x, Vector3D.X_AXIS );
			_cameraMatrix.prependRotation( -cmRotation.x, Vector3D.X_AXIS );
			//_cameraMatrix.prependRotation( -cmRotation.y, Vector3D.Y_AXIS );
			_cameraMatrix.prependRotation( -cmRotation.z, Vector3D.Z_AXIS );

			_worldSpaceStartPoint = _cameraMatrix.transformVector( msCamPos );
			var viewDistance:Vector3D = _viewDistances[$direction].clone();
			viewDistance.scaleBy( $editRange );
			msCamPos = msCamPos.add( viewDistance );
			_worldSpaceEndPoint = _cameraMatrix.transformVector( msCamPos );
			*/
			
			//////////////////////////////////////
			// This works for camera at 0,0,0
			//////////////////////////////////////
			// Empty starting matrix
			var cm:VoxelModel = Globals.controlledModel;
			if ( cm )
			{
				
				_cameraMatrix.identity();
				
				const cmRotation:Vector3D = cm.camera.rotationGet;
				_cameraMatrix.prependRotation( -cmRotation.x, Vector3D.X_AXIS );
				//_cameraMatrix.prependRotation( -cmRotation.y, Vector3D.Y_AXIS );
				_cameraMatrix.prependRotation( -cmRotation.z, Vector3D.Z_AXIS );
				
				_cameraMatrix.append( cm.instanceInfo.worldSpaceMatrix );
				//var p:Vector3D = cm.instanceInfo.worldSpaceMatrix.position;
				//var p1:Vector3D = cm.instanceInfo.positionGet;
				
				var msCamPos:Vector3D = cm.camera.current.position;
				//_worldSpaceStartPoint = _cameraMatrix.transformVector( msCamPos );
				//trace( "ModelManager.calculate - _worldSpaceStartPoint 1: " + _worldSpaceStartPoint );
				
				// This is ugly...
				_worldSpaceStartPoint = cm.instanceInfo.worldSpaceMatrix.transformVector( msCamPos );
				_worldSpaceStartPoint.y = _cameraMatrix.transformVector( msCamPos ).y;
				//trace( "ModelManager.calculate - _worldSpaceStartPoint 2: " + _worldSpaceStartPoint + " p: " + p + "  p1: " + p1 );
				
				var viewDistance:Vector3D = _viewDistances[$direction].clone();
				viewDistance.scaleBy( $editRange );
				msCamPos = msCamPos.add( viewDistance );
				_worldSpaceEndPoint = _cameraMatrix.transformVector( msCamPos );
			}
			
/*
			var cm:VoxelModel = Globals.controlledModel;
			_worldSpaceStartPoint = cm.instanceInfo.worldSpaceMatrix.transformVector( cm.camera.current.position );
			_cameraMatrix.identity();
			
			//const cmRotation:Vector3D = cm.camera.rotationGet;
			_cameraMatrix.prependRotation( cmRotation.x, Vector3D.X_AXIS );
			_cameraMatrix.prependRotation( cmRotation.y, Vector3D.Y_AXIS );
			_cameraMatrix.prependRotation( cmRotation.z, Vector3D.Z_AXIS );

			// the position of the controlled model
 			_cameraMatrix.prependTranslation( _worldSpaceStartPoint.x, _worldSpaceStartPoint.y, _worldSpaceStartPoint.z ); 
			var viewDistance:Vector3D = _viewDistances[$direction].clone();
			viewDistance.scaleBy( $editRange );
			viewDistance = viewDistance.add( cm.camera.current.position );
			_worldSpaceEndPoint = cm.instanceInfo.worldSpaceMatrix.transformVector( viewDistance );
*/			
		}
		
		private	function worldSpaceIntersectionsClear():void { _worldSpaceIntersections.splice(0, _worldSpaceIntersections.length ); }
		private	function totalIntersectionsClear():void { _totalIntersections.splice(0, _totalIntersections.length ); }
		
		// TODO RSF - If the closest model has a hole in it, that the ray should pass thru
		// it still stops and identifies that as the closest model.
		public function findRayIntersections():Vector.<GrainCursorIntersection> {
			// We should only use the models in the view frustrum - TODO - RSF
			var cm:VoxelModel = Globals.controlledModel;
			for each ( var vm:VoxelModel in _modelInstances )
			{
				if ( vm == cm )
					continue;
					
				// finds up to two intersecting planes per model
				if ( vm && vm.complete && vm.metadata.modify )
				{
					vm.lineIntersect( _worldSpaceStartPoint, _worldSpaceEndPoint, _worldSpaceIntersections );
				
					for each ( var gcIntersection:GrainCursorIntersection in _worldSpaceIntersections )
						_totalIntersections.push( gcIntersection );
					
					worldSpaceIntersectionsClear()
				}
			}
			
			_totalIntersections.sort( sortIntersections );
			return _totalIntersections;
		}
				
		// Test of basic path routing to sun
		public function pathToSun( startPoint:Vector3D, endPoint:Vector3D ):Vector.<GrainCursorIntersection> {
			// We should only use the models in the view frustrum - TODO - RSF
			_totalIntersections.length = 0;
			_worldSpaceIntersections.length = 0;
			for each ( var vm:VoxelModel in _modelInstances )
			{
				// finds up to two intersecting planes
				if ( vm && vm.complete && vm.metadata.modify )
				{
					vm.lineIntersect( startPoint, endPoint, _worldSpaceIntersections );
				}
			}
			
			return _worldSpaceIntersections;
		}

		public function sphereCollideWithModels( $testObject:VoxelModel ):Vector.<VoxelModel> {
			var scenter:Vector3D = $testObject.modelToWorld( $testObject.instanceInfo.center );
			var radius:int = $testObject.oxel.gc.size() / 8; //2
			var collidingModels:Vector.<VoxelModel> = new Vector.<VoxelModel>;
			for each ( var vm:VoxelModel in _modelInstances )
			{
				if ( vm && vm.complete && vm != $testObject && vm.instanceInfo.collidable )
				{
					var bmp:Vector3D = vm.worldToModel( scenter );
					if ( vm.doesOxelIntersectSphere( bmp, radius ) )
					{
						collidingModels.push( vm );
					}
				}
			}
			return collidingModels;
		}
		
		public function presetBoundBoxCollide( testModel:VoxelModel ):Boolean {
			var modelList:Vector.<VoxelModel> = whichModelsIsThisInsideOfNew( testModel );
			var result:Boolean = false;
			var cm:VoxelModel = Globals.controlledModel;
			if ( modelList.length )
			{
				for each ( var vm:VoxelModel in modelList )
				{
					var wsCenterPointOfModel:Vector3D = cm.instanceInfo.worldSpaceMatrix.transformVector( cm.camera.current.position );

					var msp:Vector3D = vm.worldToModel( wsCenterPointOfModel );
					// RSF 9.13/13 - Verify that vm.oxel.gc.grain is correct value to pass in.
					result = vm.isPassable( msp.x, msp.y, msp.z, vm.oxel.gc.grain );
					
					// If any result fails, position is invalid, restore last position
					if ( !result )
					{
						testModel.instanceInfo.restoreOld();
						return result;
					}
				}
			}
			return true;
		}

		public function whichModelsIsThisInsideOfNew( vm:VoxelModel ):Vector.<VoxelModel> {
			const numOfCorners:int = 8;
			var points:Vector.<Vector3D> = new Vector.<Vector3D>(numOfCorners, true);
			var scratch:Vector3D = new Vector3D();
			var size:int = vm.oxel.gc.size()
			
			var origin:Vector3D = vm.worldToModel( vm.instanceInfo.positionGet );
			points[0] = vm.modelToWorld( origin );
			scratch.setTo( 0, 0, size );
			points[1] = vm.modelToWorld( origin.add( scratch ) );
			scratch.setTo( 0, size, 0 );
			points[2] = vm.modelToWorld( origin.add( scratch ) );
			scratch.setTo( 0, size, size );
			points[3] = vm.modelToWorld( origin.add( scratch ) );
			scratch.setTo( size, 0, 0 );
			points[4] = vm.modelToWorld( origin.add( scratch ) );
			scratch.setTo( size, 0, size );
			points[5] = vm.modelToWorld( origin.add( scratch ) );
			scratch.setTo( size, size, 0 );
			points[6] = vm.modelToWorld( origin.add( scratch ) );
			scratch.setTo( size, size, size );
			points[7] = vm.modelToWorld( origin.add( scratch ) );

			var modelList:Vector.<VoxelModel> = new Vector.<VoxelModel>;
			var testPoint:Vector3D = null;
			for each ( var instance:VoxelModel in _modelInstances )
			{
				if ( instance && instance.complete && instance != vm )
				{
					for each ( var cpoint:Vector3D in points )
					{
						testPoint = instance.worldToModel( cpoint );
						if ( instance.oxel.gc.containsModelSpacePoint( testPoint ) ) 
						{
							modelList.push( instance );
							break;
						}
					}
				}
			}
			return modelList;
		}
		
		// this version effective scales up models, so you show up inside of them
		// even when you are not physically in the model space. Just close.
		// This allow us to detect edges of models we are approaching
		public function whichModelsIsThisInfluencedBy( vm:VoxelModel ):Vector.<VoxelModel> {
			var worldSpaceStartPointOrigin:Vector3D = vm.instanceInfo.positionGet;
			var worldSpaceStartPointCorner:Vector3D = vm.instanceInfo.positionGet.clone();
			// add size to get corner
			// might want to do all 8 corners if we need to be through
			worldSpaceStartPointCorner.x = worldSpaceStartPointCorner.x + vm.oxel.gc.size();
			worldSpaceStartPointCorner.y = worldSpaceStartPointCorner.y + vm.oxel.gc.size();
			worldSpaceStartPointCorner.z = worldSpaceStartPointCorner.z + vm.oxel.gc.size();

			var modelList:Vector.<VoxelModel> = new Vector.<VoxelModel>;
			for each ( var collideCandidate:VoxelModel in _modelInstances )
			{
				// I suspect there is a way faster way to eliminate models that are far away.
				// TODO - optimize RSF
				if ( collideCandidate && collideCandidate.complete && collideCandidate != vm )
				{
					var sizeOfInstance:Number = collideCandidate.oxel.gc.size();
					var offset:Vector3D = new Vector3D( sizeOfInstance, sizeOfInstance, sizeOfInstance );
					offset.scaleBy( 0.05 );
					
					var mspOrigin:Vector3D = collideCandidate.worldToModel( worldSpaceStartPointOrigin );
					mspOrigin.scaleBy( 0.9 );
					mspOrigin = mspOrigin.add( offset );
//					trace( "whichModelsIsThisInsideOf - mspOrigin: " + mspOrigin );
					
					var mspHead:Vector3D = collideCandidate.worldToModel( worldSpaceStartPointCorner );
					mspHead.scaleBy( 0.9 );
					mspHead = mspHead.add( offset );
					if ( collideCandidate.oxel.gc.containsModelSpacePoint( mspOrigin ) ) 
					{
						modelList.push( collideCandidate );
					}
					else if ( collideCandidate.oxel.gc.containsModelSpacePoint( mspHead ) ) 
					{
						modelList.push( collideCandidate );
					}
				}
			}
			
			return modelList;
		}
		
		// Very similar to above, but does exact match - Not currently used
		public function whichModelsIsThisInsideOf( vm:VoxelModel ):Vector.<VoxelModel> {
			var worldSpaceStartPointOrigin:Vector3D = vm.instanceInfo.positionGet;
			var worldSpaceStartPointCorner:Vector3D = vm.instanceInfo.positionGet.clone();
			// add size to get corner
			worldSpaceStartPointCorner.x = worldSpaceStartPointCorner.x + vm.oxel.gc.size();
			worldSpaceStartPointCorner.y = worldSpaceStartPointCorner.y + vm.oxel.gc.size();
			worldSpaceStartPointCorner.z = worldSpaceStartPointCorner.z + vm.oxel.gc.size();

			var modelList:Vector.<VoxelModel> = new Vector.<VoxelModel>;
			for each ( var collideCandidate:VoxelModel in _modelInstances )
			{
				// I suspect there is a way faster way to eliminate models that are far away.
				// TODO - optimize RSF
				if ( collideCandidate && collideCandidate.complete && collideCandidate != vm )
				{
					var mspOrigin:Vector3D = collideCandidate.worldToModel( worldSpaceStartPointOrigin );
					var mspHead:Vector3D = collideCandidate.worldToModel( worldSpaceStartPointCorner );
					if ( collideCandidate.oxel.gc.containsModelSpacePoint( mspOrigin ) ) 
					{
						modelList.push( collideCandidate );
					}
					else if ( collideCandidate.oxel.gc.containsModelSpacePoint( mspHead ) ) 
					{
						modelList.push( collideCandidate );
					}
				}
			}
			
			return modelList;
		}
		
		flash.geom.Vector3D.prototype.toJSON = function (k:*):* { 
		return {x:this.x, y:this.y, z:this.z};
		} 	

		public function getModelJson( outString:String ):String {
			var count:int = 0;
			//for each ( var vm:VoxelModel in _modelInstances )
			//	count++;
			var instanceData:Vector.<String> = new Vector.<String>;
				
			for each ( var instance:VoxelModel in _modelInstances )
			{
				if ( instance  )
				{
					if ( instance is Player )
						continue;
					instanceData.push( instance.getJSON() );	
				}
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
		
		public function TestCheckForFlow():void
		{
			for each ( var vm:VoxelModel in _modelInstances )
			{
				if ( vm is Player )
					continue;
				
				vm.flow( 6, 9 );	
			}
			
		}
	}
}