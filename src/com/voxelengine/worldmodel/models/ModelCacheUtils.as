/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import org.as3commons.collections.Set;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.oxel.GrainIntersection;
import com.voxelengine.worldmodel.models.types.Avatar;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.oxel.OxelBad;

public class ModelCacheUtils {
	static public const FRONT:int = 0;
	static public const BACK:int = 1;
	static public const LEFT:int = 2;
	static public const RIGHT:int = 3;
	static public const UP:int = 4;
	static public const DOWN:int = 5;

	// temporary reference to last model from by find closest model function
	static private var _lastFoundModel:VoxelModel = null;

	static private const EDIT_RANGE:int = 250;

	static private var _modelIntersections:Vector.<GrainIntersection> = new Vector.<GrainIntersection>();
	static private	function get modelIntersections():Vector.<GrainIntersection>  { return _modelIntersections; }
	static private	function modelIntersectionsClear():void { _modelIntersections.splice(0, _modelIntersections.length ); }

	static private var _oxelIntersections:Vector.<GrainIntersection> = new Vector.<GrainIntersection>();
	static private	function get oxelIntersections():Vector.<GrainIntersection>  { return _oxelIntersections; }
	static private	function oxelIntersectionsClear():void { _oxelIntersections.splice(0, _oxelIntersections.length ); }

	static private var _worldSpaceStartPoint:Vector3D;
	static private var _worldSpaceEndPoint:Vector3D;
	static private var _gci:GrainIntersection;
	static private var _cameraMatrix:Matrix3D = new Matrix3D();

	static private var _viewVectors:Vector.<Vector3D> = new Vector.<Vector3D>(6);
	static public function viewVector( $dir:int ):Vector3D { return _viewVectors[$dir].clone() }

    static public function get worldSpaceStartPoint():Vector3D { return _worldSpaceStartPoint; }
	static public function get worldSpaceEndPoint():Vector3D { return _worldSpaceEndPoint; }
	static public function worldSpaceStartPointFunction():Vector3D { return _worldSpaceStartPoint ? _worldSpaceStartPoint : new Vector3D(); }
	static public function worldSpaceEndPointFunction():Vector3D { return _worldSpaceEndPoint ? _worldSpaceEndPoint : new Vector3D(); }

	static public function get gci():GrainIntersection { return _gci; }

	public function ModelCacheUtils() { }

	static public function init():void {
		_viewVectors[FRONT] = new Vector3D(0, 0, -1);
		_viewVectors[BACK] = new Vector3D(0, 0, 1);
		_viewVectors[LEFT] = new Vector3D(-1, 0, 0);
		_viewVectors[RIGHT] = new Vector3D(1, 0, 0);
		_viewVectors[UP] = new Vector3D(0, 1, 0);
		_viewVectors[DOWN] = new Vector3D(0, -1, 0);
	}

	static public  function viewVectorNormalizedGet():Vector3D {
		var newV:Vector3D = _worldSpaceEndPoint.subtract( _worldSpaceStartPoint );
		newV.normalize();
		return newV;
	}

	static private function sortIntersections(pointModel1:GrainIntersection, pointModel2:GrainIntersection ):Number {
		var point1Rel:Number = _worldSpaceStartPoint.subtract( pointModel1.wsPoint ).length;
		var point2Rel:Number = _worldSpaceStartPoint.subtract( pointModel2.wsPoint ).length;
		if ( point1Rel < point2Rel )
			return -1;
		else if ( point1Rel > point2Rel )
			return 1;
		else
			return 0;
	}

	static public  function highLightEditableOxel( $ignoreType:uint = 100 ):void {
		if ( !VoxelModel.controlledModel && !EditCursor.isEditing ) {
			VoxelModel.selectedModel = null;
			_gci = null;
			EditCursor.currentInstance.gciDataSet( _gci );
			return;
		}
		// TODO - We should only use the models in the view frustum - RSF
		var ignoreType:uint = Globals.g_underwater ? TypeInfo.WATER : TypeInfo.AIR;
		modelIntersectionsClear(); // findRayIntersectionsWithBoundingBox uses modelIntersections static
		var boundingBoxIntersections:Vector.<GrainIntersection> = findRayIntersectionsWithBoundingBox( Region.currentRegion.modelCache.getEditableModels );
		boundingBoxIntersections = sortIntersectionsAndRemoveDups( boundingBoxIntersections );

		const minSize:int = EditCursor.currentInstance.grain;
		// this gets the child intersections with each model, since two models might overlap
		// its important to collect all of them first
		oxelIntersectionsClear();
		for each( var bbIntersection:GrainIntersection in boundingBoxIntersections ) {
			bbIntersection.model.lineIntersectWithChildOxels( _worldSpaceStartPoint, _worldSpaceEndPoint, oxelIntersections, $ignoreType, minSize);
		}
		oxelIntersections.sort(sortIntersections);
		_gci = null;
		for each( var childIntersection:GrainIntersection in oxelIntersections ) {
			// now get the oxel that corresponds to the oxel at that location
			var oxel:Oxel = childIntersection.model.getOxelAtWSPoint(childIntersection.wsPoint, childIntersection.model.grain);
			if (OxelBad.INVALID_OXEL == oxel)
				continue;
			if (oxel.type == TypeInfo.AIR && 1 == oxel.childCount)
				continue;

			_gci = childIntersection;
			VoxelModel.selectedModel = childIntersection.model;
			EditCursor.currentInstance.gciDataSet( _gci );
			_lastFoundModel = _gci.model;
			break;
		}

		if ( null == _gci ) {
			EditCursor.currentInstance.instanceInfo.visible = false;
			EditCursor.currentInstance.gciDataClear();
		}
	}

	static private function sortIntersectionsAndRemoveDups( intersections:Vector.<GrainIntersection> ):Vector.<GrainIntersection> {
		if ( 0 == intersections.length )
			return intersections;
		intersections.sort( sortIntersections );
		var modelDups:Set = new Set();
		var deDuppedIntersections:Vector.<GrainIntersection> = new Vector.<GrainIntersection>();
		for each ( var intersection:GrainIntersection in intersections ) {
			if ( !modelDups.has( intersection.model ) ) {
				modelDups.add(intersection.model);
				deDuppedIntersections.push(intersection);
			}
		}
		return deDuppedIntersections;
	}

	static public  function worldSpaceStartAndEndPointCalculate( $direction:int = FRONT, $editRange:int = EDIT_RANGE ):void {
		var pm:Avatar = Player.pm;
		if ( pm ) {
			var msCamPos:Vector3D = new Vector3D( 8, Avatar.AVATAR_HEIGHT, 8 );
            _worldSpaceStartPoint = pm.modelToWorld( msCamPos ); // Perfect, it scales it with avatar
//            trace( "MCU - " + FM( "wssp: ", worldSpaceStartPoint )  ); // + FM( " avatar rot: ", pm.instanceInfo.rotationGet )

            // now create a vector in direction we are looking
            var cmRotation:Vector3D;
			if ( VoxelModel.controlledModel )
            	cmRotation = VoxelModel.controlledModel.cameraContainer.current.rotation;
			else
				cmRotation = new Vector3D();
            _cameraMatrix.identity();
			_cameraMatrix.prependRotation( -cmRotation.z, Vector3D.Z_AXIS );
			_cameraMatrix.prependRotation( -cmRotation.y, Vector3D.Y_AXIS );
            _cameraMatrix.prependRotation( -cmRotation.x, Vector3D.X_AXIS );
            var endPoint:Vector3D = viewVector($direction);
            endPoint.scaleBy( $editRange );
            var tranformedVector:Vector3D = _cameraMatrix.deltaTransformVector( endPoint );
//			trace( "MCU - " + FM( "viewVector: ", viewVector ) + FM( "  cmRotation: ", cmRotation ) );

            _worldSpaceEndPoint = _worldSpaceStartPoint.add( tranformedVector );
//			trace( "MCU - " + FM( "worldSpaceEndPoint: ", _worldSpaceEndPoint ) );

			/////////////////////////////////////
		}

		function FM( $title:String , $v:Vector3D ):String {
			return $title + " { " + $v.x.toFixed(2) + " " + $v.y.toFixed(2)+ " " + $v.z.toFixed(2) + " }";
		}
	}

	// TODO - NEED TO call modelIntersectionsClear() first
	static public function findRayIntersectionsWithBoundingBox( $candidateModels:Vector.<VoxelModel>, $checkChildModels:Boolean = false ):Vector.<GrainIntersection> {
		// TODO - RSF  - We should only use the models in the view frustrum
		for each ( var vm:VoxelModel in $candidateModels ) {
			// finds up to two intersecting planes per model
			vm.lineIntersect( _worldSpaceStartPoint, _worldSpaceEndPoint, modelIntersections );

			// so I intersected a model, and do I need to check its children?
			// this will add any intersection with the child model to the modelIntersections list
			if ( true == $checkChildModels && 0 < modelIntersections.length && 0 < vm.modelInfo.childVoxelModels.length ) {
				// TODO - RSF this does not check for editable model, it just gets all models
				findRayIntersectionsWithBoundingBox(vm.modelInfo.childVoxelModelsGet(), true);
			}
		}

		return modelIntersections;
	}

	static public function whichModelsIsThisInsideOfNew( vm:VoxelModel ):Vector.<VoxelModel> {
		const numOfCorners:int = 8;
		var points:Vector.<Vector3D> = new Vector.<Vector3D>(numOfCorners, true);
		var scratch:Vector3D = new Vector3D();
		var size:int = vm.modelInfo.oxelPersistence.oxel.gc.size();

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
					if ( instance.modelInfo.oxelPersistence.oxel.gc.containsModelSpacePoint( testPoint ) )
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
		if ( !vm.modelInfo.oxelPersistence || 0 == vm.modelInfo.oxelPersistence.oxelCount )
			return modelList;
		var worldSpaceStartPointOrigin:Vector3D = vm.instanceInfo.positionGet;
		_s_worldSpaceStartPointCorner.setTo( worldSpaceStartPointOrigin.x, worldSpaceStartPointOrigin.y, worldSpaceStartPointOrigin.z );
		// add size to get corner
		// might want to do all 8 corners if we need to be through
		_s_worldSpaceStartPointCorner.x += vm.modelInfo.oxelPersistence.oxel.gc.size();
		_s_worldSpaceStartPointCorner.y += vm.modelInfo.oxelPersistence.oxel.gc.size();
		_s_worldSpaceStartPointCorner.z += vm.modelInfo.oxelPersistence.oxel.gc.size();


		var models:Vector.<VoxelModel> = Region.currentRegion.modelCache.models;
		for each ( var collideCandidate:VoxelModel in models )
		{
			if ( collideCandidate is Avatar )
				continue;
			// I suspect there is a way faster way to eliminate models that are far away.
			// TODO - optimize RSF
			if ( collideCandidate && collideCandidate.complete && !collideCandidate.dead && collideCandidate != vm )
			{
				if ( !collideCandidate.modelInfo.oxelPersistence )
					continue;
				if ( 0 == collideCandidate.modelInfo.oxelPersistence.oxelCount )
					continue;
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
				if ( collideCandidate.modelInfo.oxelPersistence.oxel.gc.containsModelSpacePoint( _s_mspOrigin ) )
				{
					modelList.push( collideCandidate );
				}
				else if ( collideCandidate.modelInfo.oxelPersistence.oxel.gc.containsModelSpacePoint( mspHead ) )
				{
					modelList.push( collideCandidate );
				}
			}
		}

		return modelList;
	}

	static public function sphereCollideWithModels( $testObject:VoxelModel ):Vector.<VoxelModel> {
		var scenter:Vector3D = $testObject.modelToWorld( $testObject.instanceInfo.center );
		var radius:int = $testObject.modelInfo.oxelPersistence.oxel.gc.size() / 8; //2
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
				var wsCenterPointOfModel:Vector3D = cm.instanceInfo.worldSpaceMatrix.transformVector( cm.cameraContainer.current.position );

				var msp:Vector3D = vm.worldToModel( wsCenterPointOfModel );
				// RSF 9.13/13 - Verify that vm.modelInfo.oxelPersistence.oxel.gc.grain is correct value to pass in.
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

	// Very similar to above, but does exact match - Not currently used
	static public function whichModelsIsThisInsideOf( vm:VoxelModel ):Vector.<VoxelModel> {
		var worldSpaceStartPointOrigin:Vector3D = vm.instanceInfo.positionGet;
		var worldSpaceStartPointCorner:Vector3D = vm.instanceInfo.positionGet.clone();
		// add size to get corner
		worldSpaceStartPointCorner.x = worldSpaceStartPointCorner.x + vm.modelInfo.oxelPersistence.oxel.gc.size();
		worldSpaceStartPointCorner.y = worldSpaceStartPointCorner.y + vm.modelInfo.oxelPersistence.oxel.gc.size();
		worldSpaceStartPointCorner.z = worldSpaceStartPointCorner.z + vm.modelInfo.oxelPersistence.oxel.gc.size();

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
				if ( collideCandidate.modelInfo.oxelPersistence.oxel.gc.containsModelSpacePoint( mspOrigin ) )
				{
					modelList.push( collideCandidate );
				}
				else if ( collideCandidate.modelInfo.oxelPersistence.oxel.gc.containsModelSpacePoint( mspHead ) )
				{
					modelList.push( collideCandidate );
				}
			}
		}

		return modelList;
	}
}

	// This is not recognized by compiler, but works like a charm
	// http://tobyho.com/2009/05/02/modifying-core-types-in/
//	flash.geom.Vector3D.prototype.toJSON = function (k:*):* {
//	return {x:this.x, y:this.y, z:this.z};
//	}
}