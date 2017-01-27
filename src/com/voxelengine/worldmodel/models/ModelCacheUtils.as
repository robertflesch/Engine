/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.worldmodel.models.types.Avatar;
	import com.voxelengine.worldmodel.models.types.EditCursor;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.TypeInfo;
	import flash.geom.Matrix3D;
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.oxel.GrainCursorIntersection;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class ModelCacheUtils 
	{
		static public const FRONT:int = 0;
		static public const BACK:int = 1;
		static public const LEFT:int = 2;
		static public const RIGHT:int = 3;
		static public const UP:int = 4;
		static public const DOWN:int = 5;
		
		// temporary reference to last model from by find closest model function
		static private var _lastFoundModel:VoxelModel = null;
		
		static private const EDIT_RANGE:int = 250;
		
		static private var _totalIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
		static private var _worldSpaceIntersections:Vector.<GrainCursorIntersection> = new Vector.<GrainCursorIntersection>();
		static private var _worldSpaceStartPoint:Vector3D;
		static private var _worldSpaceEndPoint:Vector3D;
		static private var _gci:GrainCursorIntersection;
		static private var _cameraMatrix:Matrix3D = new Matrix3D();
		
		static private var _viewDistances:Vector.<Vector3D> = new Vector.<Vector3D>(6); 
		
		static public function get worldSpaceStartPoint():Vector3D { return _worldSpaceStartPoint; }
		
		static public function get gci():GrainCursorIntersection { return _gci; }
		
		public function ModelCacheUtils() { }
		
		static public function init():void {
			_viewDistances[FRONT] = new Vector3D(0, 0, -1);
			_viewDistances[BACK] = new Vector3D(0, 0, 1);
			_viewDistances[LEFT] = new Vector3D(-1, 0, 0);
			_viewDistances[RIGHT] = new Vector3D(1, 0, 0);
			_viewDistances[UP] = new Vector3D(0, 1, 0);
			_viewDistances[DOWN] = new Vector3D(0, -1, 0);
		}
		
		static public function viewVectorNormalizedGet():Vector3D {
			var newV:Vector3D = _worldSpaceEndPoint.subtract( _worldSpaceStartPoint );
			newV.normalize();
			return newV;
		}
		
		static private function sortIntersectionsGeneral( pointModel1:Object, pointModel2:Object ):Number	{
			// CHECK WORLD SPACE DATA HERE in pointModels
			var point1Rel:Number = _worldSpaceStartPoint.subtract( pointModel1.wsPoint ).length;
			var point2Rel:Number = _worldSpaceStartPoint.subtract( pointModel2.wsPoint ).length;
			if ( point1Rel < point2Rel )
				return -1;
			else if ( point1Rel > point2Rel ) 
				return 1;
			else 
				return 0;			
		}
		
		static private function sortIntersections( pointModel1:GrainCursorIntersection, pointModel2:GrainCursorIntersection ):Number {
			var point1Rel:Number = _worldSpaceStartPoint.subtract( pointModel1.wsPoint ).length;
			var point2Rel:Number = _worldSpaceStartPoint.subtract( pointModel2.wsPoint ).length;
			if ( point1Rel < point2Rel )
				return -1;
			else if ( point1Rel > point2Rel ) 
				return 1;
			else 
				return 0;			
		}

		static public function highLightEditableOxel( $ignoreType:uint = 100 ):void {
			if ( !VoxelModel.controlledModel )
				return;
			
			_totalIntersections.length = 0;
			_worldSpaceIntersections.length = 0;
			
			// We should only use the models in the view frustrum - TODO - RSF
			var ignoreType:uint = Globals.g_underwater ? TypeInfo.WATER : TypeInfo.AIR
			var editableModel:VoxelModel = findEditableModel();
			_totalIntersections.length = 0;
			_worldSpaceIntersections.length = 0;
			if ( editableModel )
			{
				//if ( _lastFoundModel != editableModel && _lastFoundModel )
					//EditCursor.currentInstance.visible = false;	
				
				VoxelModel.selectedModel = editableModel;
				
				if ( EditCursor.isEditing )
				{
					const minSize:int = EditCursor.currentInstance.grain;
					
					editableModel.lineIntersectWithChildren( _worldSpaceStartPoint, _worldSpaceEndPoint, _worldSpaceIntersections, $ignoreType, minSize )
						
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
						//_gci.point = editableModel.worldToModel( _gci.point );
						EditCursor.currentInstance.gciDataSet( _gci );
					}
					else	
					{
						EditCursor.currentInstance.instanceInfo.visible = false;	
						EditCursor.currentInstance.gciDataClear();
					}
					_lastFoundModel = editableModel;
				}
			}
			else
				VoxelModel.selectedModel = null;
			
			totalIntersectionsClear();
			worldSpaceIntersectionsClear()
		}
		
		static public function findClosestIntersectionInDirection( $dir:int = UP ):GrainCursorIntersection	{
			if ( !VoxelModel.controlledModel )
				return null;
			
			worldSpaceStartAndEndPointCalculate( $dir );
			
			// We should only use the models in the view frustrum - TODO - RSF
			var vm:VoxelModel = findEditableModel();
			if ( vm )
			{
				const minSize:int = 2; // TODO pass this in?
				vm.lineIntersectWithChildren( _worldSpaceStartPoint, _worldSpaceEndPoint, _worldSpaceIntersections, TypeInfo.AIR, minSize )
					
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

		static private	function findEditableModel():VoxelModel {
			var foundModel:VoxelModel = null;
			var intersections:Vector.<GrainCursorIntersection> = findRayIntersections( Region.currentRegion.modelCache.getEditableModels, true );
			intersections.sort( sortIntersections );
			// get first (closest) interesction
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
				EditCursor.currentInstance.instanceInfo.visible = false;
				_lastFoundModel	= null;
			}
			
			return foundModel;
		}

		
		static public	function worldSpaceStartAndEndPointCalculate( $direction:int = FRONT, $editRange:int = EDIT_RANGE ):void {
			//////////////////////////////////////
			// This works for camera at 0,0,0
			//////////////////////////////////////
			// Empty starting matrix
			var cm:VoxelModel = VoxelModel.controlledModel;
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
				//trace( "ModelCacheUtils.calculate - _worldSpaceStartPoint 1: " + _worldSpaceStartPoint );
				
				// This is ugly...
				_worldSpaceStartPoint = cm.instanceInfo.worldSpaceMatrix.transformVector( msCamPos );
				_worldSpaceStartPoint.y = _cameraMatrix.transformVector( msCamPos ).y;
				//trace( "ModelCacheUtils.calculate - _worldSpaceStartPoint 2: " + _worldSpaceStartPoint + " p: " + p + "  p1: " + p1 );
				
				var viewDistance:Vector3D = _viewDistances[$direction].clone();
				viewDistance.scaleBy( $editRange );
				msCamPos = msCamPos.add( viewDistance );
				_worldSpaceEndPoint = _cameraMatrix.transformVector( msCamPos );
			}
		}
		
		static private	function worldSpaceIntersectionsClear():void { _worldSpaceIntersections.splice(0, _worldSpaceIntersections.length ); }
		static private	function totalIntersectionsClear():void { _totalIntersections.splice(0, _totalIntersections.length ); }

		// TODO RSF - If the closest model has a hole in it, that the ray should pass thru
		// it still stops and identifies that as the closest model.
		static public function findRayIntersections( $candidateModels:Vector.<VoxelModel>, $checkChildModels:Boolean = false ):Vector.<GrainCursorIntersection> {
			// TODO - RSF  - We should only use the models in the view frustrum
			for each ( var vm:VoxelModel in $candidateModels )
			{
				worldSpaceIntersectionsClear();
				// finds up to two intersecting planes per model
				vm.lineIntersect( _worldSpaceStartPoint, _worldSpaceEndPoint, _worldSpaceIntersections );

				for each ( var gcIntersection:GrainCursorIntersection in _worldSpaceIntersections )
					_totalIntersections.push( gcIntersection );

				// did I intersect this model, and do I need to check its children?
				// this will add any intersection with the child model to the totalIntersections list
				if ( true == $checkChildModels && 0 < _worldSpaceIntersections.length && 0 < vm.modelInfo.childVoxelModels.length )
					findRayIntersections( vm.modelInfo.childVoxelModelsGet(), true );
			}
			
			return _totalIntersections;
		}

		static public function sphereCollideWithModels( $testObject:VoxelModel ):Vector.<VoxelModel> {
			var scenter:Vector3D = $testObject.modelToWorld( $testObject.instanceInfo.center );
			var radius:int = $testObject.modelInfo.data.oxel.gc.size() / 8; //2
			var collidingModels:Vector.<VoxelModel> = new Vector.<VoxelModel>;
			var models:Vector.<VoxelModel> = Region.currentRegion.modelCache.models;
			for each ( var vm:VoxelModel in models )
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
		
		static public function presetBoundBoxCollide( testModel:VoxelModel ):Boolean {
			var modelList:Vector.<VoxelModel> = whichModelsIsThisInsideOfNew( testModel );
			var result:Boolean = false;
			var cm:VoxelModel = VoxelModel.controlledModel;
			if ( modelList.length )
			{
				for each ( var vm:VoxelModel in modelList )
				{
					var wsCenterPointOfModel:Vector3D = cm.instanceInfo.worldSpaceMatrix.transformVector( cm.camera.current.position );

					var msp:Vector3D = vm.worldToModel( wsCenterPointOfModel );
					// RSF 9.13/13 - Verify that vm.modelInfo.data.oxel.gc.grain is correct value to pass in.
					result = vm.isPassable( msp.x, msp.y, msp.z, vm.grain );
					
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

		static public function whichModelsIsThisInsideOfNew( vm:VoxelModel ):Vector.<VoxelModel> {
			const numOfCorners:int = 8;
			var points:Vector.<Vector3D> = new Vector.<Vector3D>(numOfCorners, true);
			var scratch:Vector3D = new Vector3D();
			var size:int = vm.modelInfo.data.oxel.gc.size()
			
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
			var models:Vector.<VoxelModel> = Region.currentRegion.modelCache.models;
			var testPoint:Vector3D = null;
			for each ( var instance:VoxelModel in models )
			{
				if ( instance && instance.complete && instance != vm )
				{
					for each ( var cpoint:Vector3D in points )
					{
						testPoint = instance.worldToModel( cpoint );
						if ( instance.modelInfo.data.oxel.gc.containsModelSpacePoint( testPoint ) ) 
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
		static private var _s_worldSpaceStartPointCorner:Vector3D = new Vector3D();
		static private var _s_offset:Vector3D = new Vector3D();
		static private var _s_mspOrigin:Vector3D = new Vector3D();
		
		static public function whichModelsIsThisInfluencedBy( vm:VoxelModel ):Vector.<VoxelModel> {
			var modelList:Vector.<VoxelModel> = new Vector.<VoxelModel>;
			if ( !vm.modelInfo.data )
				return modelList;
			var worldSpaceStartPointOrigin:Vector3D = vm.instanceInfo.positionGet;
			_s_worldSpaceStartPointCorner.setTo( worldSpaceStartPointOrigin.x, worldSpaceStartPointOrigin.y, worldSpaceStartPointOrigin.z );
			// add size to get corner
			// might want to do all 8 corners if we need to be through
			_s_worldSpaceStartPointCorner.x += vm.modelInfo.data.oxel.gc.size();
			_s_worldSpaceStartPointCorner.y += vm.modelInfo.data.oxel.gc.size();
			_s_worldSpaceStartPointCorner.z += vm.modelInfo.data.oxel.gc.size();

			
			var models:Vector.<VoxelModel> = Region.currentRegion.modelCache.models;
			for each ( var collideCandidate:VoxelModel in models )
			{
				if ( collideCandidate is Avatar )
					continue;
				// I suspect there is a way faster way to eliminate models that are far away.
				// TODO - optimize RSF
				if ( collideCandidate && collideCandidate.complete && collideCandidate != vm )
				{
					
					var sizeOfInstance:Number = collideCandidate.size();
					if ( sizeOfInstance <= 2 ) 
						continue;
					_s_offset.setTo( sizeOfInstance, sizeOfInstance, sizeOfInstance );
					_s_offset.scaleBy( 0.05 );
					
					//var mspOrigin:Vector3D = collideCandidate.worldToModelNew( worldSpaceStartPointOrigin, _s_mspOrigin );
					//mspOrigin.scaleBy( 0.9 );
					//mspOrigin.x += offset.x;
					//mspOrigin.y += offset.y;
					//mspOrigin.z += offset.z;
					collideCandidate.worldToModelNew( worldSpaceStartPointOrigin, _s_mspOrigin );
					_s_mspOrigin.scaleBy( 0.9 );
					_s_mspOrigin.x += _s_offset.x;
					_s_mspOrigin.y += _s_offset.y;
					_s_mspOrigin.z += _s_offset.z;
					
					var mspHead:Vector3D = collideCandidate.worldToModel( _s_worldSpaceStartPointCorner );
					mspHead.scaleBy( 0.9 );
					//mspHead = mspHead.add( _s_offset );
					mspHead.x += _s_offset.x;
					mspHead.y += _s_offset.y;
					mspHead.z += _s_offset.z;
					if ( collideCandidate.modelInfo.data.oxel.gc.containsModelSpacePoint( _s_mspOrigin ) ) 
					{
						modelList.push( collideCandidate );
					}
					else if ( collideCandidate.modelInfo.data.oxel.gc.containsModelSpacePoint( mspHead ) ) 
					{
						modelList.push( collideCandidate );
					}
				}
			}
			
			return modelList;
		}
		
		// Very similar to above, but does exact match - Not currently used
		static public function whichModelsIsThisInsideOf( vm:VoxelModel ):Vector.<VoxelModel> {
			var worldSpaceStartPointOrigin:Vector3D = vm.instanceInfo.positionGet;
			var worldSpaceStartPointCorner:Vector3D = vm.instanceInfo.positionGet.clone();
			// add size to get corner
			worldSpaceStartPointCorner.x = worldSpaceStartPointCorner.x + vm.modelInfo.data.oxel.gc.size();
			worldSpaceStartPointCorner.y = worldSpaceStartPointCorner.y + vm.modelInfo.data.oxel.gc.size();
			worldSpaceStartPointCorner.z = worldSpaceStartPointCorner.z + vm.modelInfo.data.oxel.gc.size();

			var modelList:Vector.<VoxelModel> = new Vector.<VoxelModel>;
			var models:Vector.<VoxelModel> = Region.currentRegion.modelCache.models;
			for each ( var collideCandidate:VoxelModel in models )
			{
				// I suspect there is a way faster way to eliminate models that are far away.
				// TODO - optimize RSF
				if ( collideCandidate && collideCandidate.complete && collideCandidate != vm )
				{
					var mspOrigin:Vector3D = collideCandidate.worldToModel( worldSpaceStartPointOrigin );
					var mspHead:Vector3D = collideCandidate.worldToModel( worldSpaceStartPointCorner );
					if ( collideCandidate.modelInfo.data.oxel.gc.containsModelSpacePoint( mspOrigin ) ) 
					{
						modelList.push( collideCandidate );
					}
					else if ( collideCandidate.modelInfo.data.oxel.gc.containsModelSpacePoint( mspHead ) ) 
					{
						modelList.push( collideCandidate );
					}
				}
			}
			
			return modelList;
		}
	}
	
	import flash.geom.Vector3D;
	flash.geom.Vector3D.prototype.toJSON = function (k:*):* { 
	return {x:this.x, y:this.y, z:this.z};
	} 	
	
}