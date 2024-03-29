/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelInfoEvent
import com.voxelengine.events.LoadingImageEvent
import com.voxelengine.events.ModelLoadingEvent
import com.voxelengine.events.ObjectHierarchyData;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.*
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.oxel.GrainCursor;


/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a models data, it is used by all of the current Makers
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes. 
	 * Not sure what a failure case for a timeout would be would be
	 */
public class ModelMakerBase {

    static public const IMPORTING:String = "IMPORTING";
    static public const CLONING:String = "CLONING";
    static public const MAKING:String = "MAKING";

    // hack to allow import state to be read, cleaned up from everywhere else.
	static private var _s_importing:Boolean = false;
    static public function get isImporting():Boolean { return _s_importing;}

    static private var _s_makerCount:int;
    static public function makerCountGet():int { return _s_makerCount }
    static public function makerCountIncrement():void {
        _s_makerCount++;
        if ( 0 == makerCountGet() ) {
            LoadingImageEvent.create(LoadingImageEvent.CREATE);
        }
    }
    static public function makerCountDecrement():void {
        _s_makerCount-- ;
        if ( 0 == makerCountGet() ) {
            LoadingImageEvent.create( LoadingImageEvent.DESTROY );
            if ( !Region.currentRegion.loaded )
                RegionEvent.create( RegionEvent.LOAD_COMPLETE, 0, Region.currentRegion.guid );
        }
    }

    protected 		var _buildState:String = MAKING;

	protected 	       var _modelInfo:ModelInfo;
	protected function get modelInfo():ModelInfo { return _modelInfo }
	
	private   		   var _ii:InstanceInfo;
	protected function get ii():InstanceInfo { return _ii }
	
	private   		   var _parentModelGuid:String;
	protected function get parentModelGuid():String { return _parentModelGuid }
	
	static private var _s_parentChildCount:Array = [];
	protected  			var _vm:VoxelModel;

	private var _addToRegionWhenComplete:Boolean = true;
	public function get addToRegionWhenComplete():Boolean { return _addToRegionWhenComplete; }
	public function set addToRegionWhenComplete(value:Boolean):void { _addToRegionWhenComplete = value; }


	/*
	//   This generates either a
	//	 ModelLoadingEvent.MODEL_LOAD_COMPLETE
	//	 ModelLoadingEvent.MODEL_LOAD_FAILURE
	//   event
	*/

	public function ModelMakerBase( $ii:InstanceInfo, $buildState:String = MAKING ) {
		_buildState = $buildState;
        if ( _buildState == IMPORTING )
			_s_importing = true;
		if ( null == $ii )
			throw new Error( "ModelMakerBase - NO instanceInfo received in constructor" );
		_ii = $ii;
		if ( null == _ii.instanceGuid )
			_ii.instanceGuid = Globals.getUID();

		if ( $ii.controllingModel ) {
			//Log.out( "ModelMakerBase - _ii.modelGuid: " + _ii.modelGuid + "  $ii.controllingModel: " + $ii.controllingModel);
			// Using modelGuid rather then instanceGuid since imported models have no instanceGuid at this point.
			// No sure if using model guid has a down side or not.
			//Log.out( "ModelMakerBase has controlling model - modelGuid of parent: " + $ii.controllingModel.instanceInfo.modelGuid, Log.WARN )
			_parentModelGuid = $ii.controllingModel.instanceInfo.modelGuid;
			var count:int = _s_parentChildCount[_parentModelGuid];
			_s_parentChildCount[_parentModelGuid] = ++count
		}
	}

	/////////////////////////////////////////////////////////////
	// ModelInfo

	protected function requestModelInfo( $fromTables:Boolean = true ):void {
		//Log.out( "ModelMakerBase.retrieveBaseInfo - _ii.modelGuid: " + _ii.modelGuid + " from tables?: " + $fromTables );
		addMIEListeners();
		ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null, $fromTables );
	}
	
	protected function retrievedModelInfo($mie:ModelInfoEvent):void  {
        //Log.out( "ModelMakerBase.retrievedModelInfo - ii: " + _ii.modelGuid + " $mie.modelGuid: " + $mie.modelGuid, Log.DEBUG );
		if (_ii.modelGuid == $mie.modelGuid ) {
			//Log.out( "ModelMakerBase.retrievedModelInfo - ii: " + _ii.toString(), Log.DEBUG )
			removeMIEListeners();
			_modelInfo = $mie.modelInfo;
			attemptMake();
		}
	}

	protected function failedModelInfo( $mie:ModelInfoEvent):void  {
		if ( _ii && _ii.modelGuid == $mie.modelGuid ) {
			Log.out( "ModelMakerBase.failedData - ii: " + _ii.toString(), Log.WARN );
			removeMIEListeners();
			if ( ii.controllingModel ) {
				// Tell the parent one of the children failed to load
                ii.controllingModel.modelInfo.onChildAddFailure( $mie.modelGuid );
			}
			markComplete( false );
		}
	}

	protected function addMIEListeners():void {
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, retrievedModelInfo );
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );
	}

	protected function removeMIEListeners():void {
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retrievedModelInfo );
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );
	}

	// ModelInfo
	/////////////////////////////////////////////////////////////

	// check to make sure all of info required is here
	protected function attemptMake():void { throw new Error( "ModelMakerBase.attemptMake is an abstract method" ) }
	
	// once they both have been retrieved, we can make the object
	protected function make():VoxelModel {
		var modelAsset:String = _modelInfo.modelClass;
		var modelClass:Class = ModelLibrary.getAsset( modelAsset );

		var vm:VoxelModel = new modelClass( _ii );
		if ( null == vm ) {
			Log.out( "ModelMakerBase.make - Model failed in creation - modelAsset: " + modelAsset + "  modelClass: " + modelClass, Log.ERROR );
			return null
		}
		vm.init( _modelInfo, _buildState );
		return vm;

	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////
	// OxelPersistence
	protected function addODEListeners():void {
		//Log.out( "ModelMakerBase.addODEListeners  guid: " + modelInfo.guid, Log.WARN );
		OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
		OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
		OxelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
		OxelDataEvent.addListener( ModelBaseEvent.RESULT, oxelPersistenceComplete );
	}

	protected function removeODEListeners():void {
        //Log.out( "ModelMakerBase.removeODEListeners guid: " + modelInfo.guid , Log.WARN );
		OxelDataEvent.removeListener( ModelBaseEvent.RESULT, oxelPersistenceComplete );
		OxelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, oxelBuildFailed);
		OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_FAILED, oxelBuildFailed);
		OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_COMPLETE, oxelBuildComplete);
	}

	protected function oxelPersistenceComplete($ode:OxelDataEvent):void {
		if ($ode.modelGuid == modelInfo.guid ) {
            //Log.out( "ModelMakerBase.oxelPersistenceComplete MINE    guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid + " type: " + $ode.type , Log.WARN );
            removeODEListeners();

			modelInfo.oxelPersistence = $ode.oxelPersistence;
			// This is before quads have been built
			if ( ii.baseLightLevel )
				modelInfo.oxelPersistence.baseLightLevel( ii.baseLightLevel, false );
			// This puts the object into the model cache which will then add the rendering tasks needed.
			_vm.calculateCenter();
			_vm.modelInfo.bound = $ode.oxelPersistence.bound;
			_vm.complete = true;
			if ( addToRegionWhenComplete )
				RegionEvent.create( RegionEvent.ADD_MODEL, 0, Region.currentRegion.guid, _vm );
			markComplete( true );
		} //else {
        	//Log.out( "ModelMakerBase.oxelPersistenceComplete NOT MINE guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid + " type: " + $ode.type , Log.WARN );
		//}
	}

	protected function oxelBuildComplete($ode:OxelDataEvent):void {
		if ($ode.modelGuid == modelInfo.guid ) {
            //Log.out("ModelMakerBase.oxelBuildComplete  type: " + $ode.type + "  guid: " + modelInfo.guid, Log.WARN);
			removeODEListeners();
			markComplete( true );
		}
	}

	protected function oxelBuildFailed($ode:OxelDataEvent):void {
		if ($ode.modelGuid == modelInfo.guid ) {
            //Log.out("ModelMakerBase.oxelBuildFailed - Error generating OXEL data guid: " + $ode.modelGuid, Log.ERROR);
			removeODEListeners();
			modelInfo.oxelPersistence = null;
			_vm.dead = true;
			markComplete( false );
		}
	}

	// OxelPersistence
	////////////////////////////////////////////////////////////////////////////////////////////////////////

	protected function placeModelIfPositionZero():void {
		if (  null == ii.controllingModel && VoxelModel.controlledModel && 0 == ii.positionGet.length ) {
            // Only do this for top level models.
            var size:int = Math.max(GrainCursor.get_the_g0_edge_for_grain(modelInfo.bound), 32);
            // this give me edge,  really want center.
            var cm:VoxelModel = VoxelModel.controlledModel;
            var cmRotation:Vector3D = cm.cameraContainer.current.rotation;
            var cameraMatrix:Matrix3D = new Matrix3D();
            cameraMatrix.identity();
            cameraMatrix.prependRotation(-cmRotation.z, Vector3D.Z_AXIS);
            cameraMatrix.prependRotation(-cmRotation.y, Vector3D.Y_AXIS);
            cameraMatrix.prependRotation(-cmRotation.x, Vector3D.X_AXIS);

            var endPoint:Vector3D = ModelCacheUtils.viewVector(ModelCacheUtils.FRONT);
            endPoint.scaleBy(size * 1.1);
            var viewVector:Vector3D = cameraMatrix.deltaTransformVector(endPoint);
            viewVector = viewVector.add(cm.instanceInfo.positionGet);
            viewVector.setTo(viewVector.x - size / 2, viewVector.y - size / 2, viewVector.z - size / 2);
            ii.positionSet = viewVector;
//            Log.out( "ModelMakerBase.placeModelIfNotZero sets position to: " + viewVector );

        }
//		else
//		{
//            var hasControlledModel:Boolean = ( null != VoxelModel.controlledModel );
//            var hasControllingModel:Boolean = ( null == ii.controllingModel );
//            Log.out("ModelMakerBase.placeCompletedModel - placing model at default location because "
//                    + "\n hasControlledModel: " + hasControlledModel
//                    + "\n hasControllingModel: " + hasControllingModel
//                    + "\n ii.positionGet: " + ii.positionGet, Log.WARN);
//        }
	}

//    protected function placeCompletedModel():void {
//        // Only do this for top level models, so no controllingModel, need controlledModel to get current world position.
//        //if ( !ii.controllingModel && VoxelModel.controlledModel && modelInfo.oxelPersistence && modelInfo.oxelPersistence.oxelCount)
//        if ( !ii.controllingModel && VoxelModel.controlledModel )
//            placeModel();
//        else {
//            var hasControlledModel:Boolean = ( null != VoxelModel.controlledModel );
//            var hasControllingModel:Boolean = ( null != ii.controllingModel );
//            var hasOxelPersistence:Boolean = ( null != modelInfo.oxelPersistence );
//            var oxelCount:int = modelInfo.oxelPersistence.oxelCount;
//            Log.out("ModelMakerBase.placeCompletedModel - placing model at default location because "
//                    + "\n hasControlledModel: " + hasControlledModel
//                    + "\n hasControllingModel: " + hasControllingModel
//                    + "\n hasOxelPersistence: " + hasOxelPersistence
//                    + "\n oxelCount: " + oxelCount, Log.WARN);
//        }
//    }
//
//	private function placeModel():void {
//        var radius:int = Math.max(GrainCursor.get_the_g0_edge_for_grain(modelInfo.grainSize), 16) / 2;
//		if ( modelInfo.oxelPersistence && modelInfo.oxelPersistence.oxelCount ) {
//            var radius1:int = Math.max(GrainCursor.get_the_g0_edge_for_grain(modelInfo.oxelPersistence.oxel.gc.bound), 16) / 2;
//            Log.out("ModelMakerBase.placeCompletedModel - radius: " + radius + "  radius1: " + radius1, Log.WARN);
//        } else
//            Log.out("ModelMakerBase.placeCompletedModel - radius: " + radius + "  radius1: NO OxelPersistence to use for radius1", Log.WARN);
//
//        // this gives me corner.
//        const cm:VoxelModel = VoxelModel.controlledModel;
//		var msCamPos:Vector3D = cm.cameraContainer.current.position;
//		var adjCameraPos:Vector3D = cm.modelToWorld(msCamPos);
//
//		var lav:Vector3D = cm.instanceInfo.invModelMatrix.deltaTransformVector(new Vector3D(-(radius + 8), adjCameraPos.y - radius, -radius * 3));
//		var diffPos:Vector3D = cm.wsPositionGet();
//		diffPos = diffPos.add(lav);
//		_vm.instanceInfo.positionSet = diffPos;
//		Log.out ( "ModelMaker.placeModel - placing model at location: " + _vm.instanceInfo.positionGet, Log.WARN );
//        Log.out("ModelMakerBase.placeCompletedModel - placing model at default location because "
//                + "\n msCamPos: " + msCamPos
//                + "\n adjCameraPos: " + adjCameraPos
//                + "\n lav: " + lav
//                + "\n diffPos: " + diffPos, Log.WARN);
//
//    }

	protected function markComplete( $success:Boolean ):void {
		//Log.out("ModelMakerBase.markComplete - instanceGuid: " + ii.instanceGuid + "  model guid: " + modelInfo.guid + "  success: " + $success, Log.WARN);
		var ohd:ObjectHierarchyData = new ObjectHierarchyData();
		if ( $success ) {
			ohd.fromModel( _vm );
			ModelLoadingEvent.create( ModelLoadingEvent.MODEL_LOAD_COMPLETE, ohd, _vm );
            if ( _buildState == IMPORTING ) {
                ModelLoadingEvent.create( ModelBaseEvent.IMPORT_COMPLETE, ohd, _vm );
			}
		}
		else {
			ohd.fromGuids( _ii.modelGuid, _parentModelGuid );
			ModelLoadingEvent.create( ModelLoadingEvent.MODEL_LOAD_FAILURE, ohd );
		}

		_modelInfo = null;
		_ii = null;
		_vm = null;
	}

//	public function makerCountIncrement():void {
//		if ( 0 == makerCountGet() && !( _vm is Avatar ) )
//			LoadingImageEvent.create( LoadingImageEvent.CREATE );
//		if (!( _vm is Avatar ))
//			_makerCount++;
//	}
//	public function makerCountDecrement():void {
//        if (!( _vm is Avatar ))
//			_makerCount-- ;
//		if ( 0 == makerCountGet() ) {
//			LoadingImageEvent.create( LoadingImageEvent.DESTROY );
//			if ( !Region.currentRegion.loaded )
//				RegionEvent.create( RegionEvent.LOAD_COMPLETE, 0, Region.currentRegion.guid );
//		}
//	}
}
}