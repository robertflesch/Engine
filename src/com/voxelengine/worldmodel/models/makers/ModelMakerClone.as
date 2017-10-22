/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{

import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;

import flash.display.BitmapData;
import flash.geom.Matrix;

import flash.geom.Vector3D;

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.ModelMetadataEvent
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.oxel.GrainCursor;

public class ModelMakerClone extends ModelMakerBase {

    private var _waitForChildren:Boolean;
    private var _newModelGuid:String;
    public function ModelMakerClone( $instanceInfo:InstanceInfo, $modelInfo:ModelInfo = null, $modelMetadata:ModelMetadata = null, $killOldModel:Boolean = true ) {
		super($instanceInfo.clone());
		Log.out("ModelMakerClone - clone model with instanceGuid: " + $instanceInfo.instanceGuid + "  modelGuid: " + $instanceInfo.modelGuid);
        _newModelGuid = Globals.getUID();
		Log.out("ModelMakerClone - clone model with NEW instanceGuid: " + ii.instanceGuid + "  NEW modelGuid: " + ii.modelGuid);
		if ($killOldModel) {
            var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( ii.instanceGuid );
			if ( vm )
                vm.dead = true;
		} else {
			// Only do this for top level models.
			if ( null == $instanceInfo.controllingModel ) {
				var size:int = GrainCursor.two_to_the_g( $modelInfo.oxelPersistence.oxel.gc.grain );
				var v:Vector3D = ii.positionGet.clone();
				ii.positionSetComp(v.x + size / 4, v.y + size / 4, v.z + size / 4);
			}
		}

        if ( $modelMetadata )
            _modelMetadata = $modelMetadata.clone( _newModelGuid );
        if ( $modelInfo ) {
            _modelInfo = $modelInfo.clone( _newModelGuid );
            if ( $modelMetadata ){
                _modelMetadata = $modelMetadata.clone( _newModelGuid );
                attemptMakeRetrieveParentModelInfo();
            } else {
                addMetadataListeners();
                ModelMetadataEvent.create( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null );
            }
        } else {
            requestModelInfo();
        }
	}

    override protected function retrievedModelInfo($mie:ModelInfoEvent):void  {
        if ( ii.modelGuid == $mie.modelGuid ) {
            removeMIEListeners();
            _modelInfo = $mie.vmi.clone( _newModelGuid );
            if ( _modelMetadata ){
                attemptMakeRetrieveParentModelInfo();
            } else {
                addMetadataListeners();
                ModelMetadataEvent.create( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null );
            }
        }
    }

    override protected function retrievedMetadata( $mme:ModelMetadataEvent):void {
        if ( ii.modelGuid == $mme.modelGuid ) {
            removeMetadataListeners();
            _modelMetadata = $mme.modelMetadata.clone( ii.modelGuid );
            //Log.out( "ModelMakerBase.retrievedMetadata - metadata: " + _modelMetadata.toString() )
            attemptMakeRetrieveParentModelInfo();
        }
    }

	private function attemptMakeRetrieveParentModelInfo():void {
        ii.modelGuid = _newModelGuid;
		if ( parentModelGuid )
			retrieveParentModelInfo();
		else
			completeMake();
	}

	private function retrieveParentModelInfo():void {
		//Log.out("ModelMakerClone.retrieveParentModelInfo: " + ii.toString());
		// We need the parents modelClass so we can know what kind of animations are correct for this model.
		addParentModelInfoListener();
		var _topMostModelGuid:String = ii.topmostModelGuid();
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _topMostModelGuid, null ) );

		function parentModelInfoResult($mie:ModelInfoEvent):void {
			if ( $mie.modelGuid == _topMostModelGuid ) {
				//Log.out("ModelMakerClone.parentModelInfoResult: " + ii.toString());
				removeParentModelInfoListener();
				var modelClass:String = $mie.vmi.modelClass;
				_modelMetadata.animationClass = AnimationCache.requestAnimationClass( modelClass );
				completeMake();
			}
		}

		function parentModelInfoResultFailed($mie:ModelInfoEvent):void {
			Log.out("ModelMakerClone.parentModelInfoResultFailed: " + ii.toString(), Log.ERROR);
			if ( $mie.modelGuid == modelInfo.guid ) {
				removeParentModelInfoListener();
				markComplete( false );
			}
		}

		function addParentModelInfoListener():void {
			ModelInfoEvent.addListener( ModelBaseEvent.RESULT, parentModelInfoResult );
			ModelInfoEvent.addListener( ModelBaseEvent.ADDED, parentModelInfoResult );
			ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed );
		}

		function removeParentModelInfoListener():void {
			ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, parentModelInfoResult);
			ModelInfoEvent.removeListener(ModelBaseEvent.ADDED, parentModelInfoResult);
			ModelInfoEvent.removeListener(ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed);
		}
	}

    private function completeMake():void {
        //Log.out("ModelMakerClone.completeMake: " + ii.toString());
        if ( null != modelInfo && null != _modelMetadata ) {

            _vm = make();
            if ( _vm ) {
                _vm.stateLock( true, 10000 ); // Lock state so that it has time to load animations
                addODEListeners();
                PersistenceEvent.create( PersistenceEvent.GENERATE_SUCCEED, 0, Globals.IVM_EXT, modelInfo.guid, null, modelInfo.oxelPersistence.ba, null, String( _modelMetadata.bound  ) );
                if ( false == modelInfo.childrenLoaded ) { // its true if they are loaded or the model has no children.
                    _waitForChildren = true;
                    ModelLoadingEvent.addListener(ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady);
                }
            } else {
                markComplete(false);
            }
        }
        else
            Log.out( "ModelMakerClone.completeMake - modelInfo: " + modelInfo + "  modelMetadata: " + _modelMetadata, Log.WARN );

        function childrenAllReady( $ode:ModelLoadingEvent):void {
            if ( modelInfo.guid == $ode.data.modelGuid  ) {
                Log.out( "ModelMakerClone.allChildrenReady - modelMetadata.description: " + _modelMetadata.description, Log.WARN );
                ModelLoadingEvent.removeListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
                markComplete( true );
            }
        }
    }

    override protected function oxelBuildComplete($ode:OxelDataEvent):void {
        if ($ode.modelGuid == modelInfo.guid ) {
            Log.out( "ModelMakerBase.oxelBuildComplete  guid: " + modelInfo.guid, Log.WARN );
            removeODEListeners();
            // This has the additional wait for children
            if ( !_waitForChildren )
                markComplete( true );
        }
    }

    override protected function oxelBuildFailed($ode:OxelDataEvent):void {
        if ($ode.modelGuid == modelInfo.guid ) {
            removeODEListeners();
            modelInfo.oxelPersistence = null;
            _vm.dead = true;
            if ( _waitForChildren ) {
                Log.out("ModelMakerImport - ERROR LOADING OXEL", Log.WARN);
                // TODO cancel children loading???
            }
            markComplete( false );
        }
    }

    override protected function markComplete( $success:Boolean ):void {
        if ( true == $success ) {
            modelInfo.brandChildren();
            OxelDataEvent.addListener( OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE,  quadsComplete );
            Log.out("ModelMakerClone.completeMake - waiting on quad build: " + _modelMetadata.description );
        } else {
            if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" )
                Log.out( "ModelMakerClone.markComplete - Failed import, BUT has biomes to attemptMake instead : " + modelInfo.guid, Log.ERROR );
            else if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName )
                Log.out( "ModelMakerClone.markComplete - Failed import, Failed to load from IVM : " + modelInfo.guid, Log.ERROR );
            else
                Log.out( "ModelMakerClone.markComplete - Unknown error causing failure : " + ii.modelGuid, Log.ERROR );

            ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
            OxelDataEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
            ModelMetadataEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
            super.markComplete( $success );
        }

    }

    private	function quadsComplete( $ode:OxelDataEvent ):void {
        if ( _modelMetadata.guid == $ode.modelGuid ) {

            if ( !ii.controllingModel ) {
                // Only do this for top level models.
                var radius:int = Math.max(GrainCursor.get_the_g0_edge_for_grain(modelInfo.oxelPersistence.oxel.gc.bound), 16)/2;
                // this gives me corner.
                var msCamPos:Vector3D = VoxelModel.controlledModel.cameraContainer.current.position;
                var adjCameraPos:Vector3D = VoxelModel.controlledModel.modelToWorld( msCamPos );

                var lav:Vector3D = VoxelModel.controlledModel.instanceInfo.invModelMatrix.deltaTransformVector( new Vector3D( -(radius + 8), adjCameraPos.y-radius, -radius * 3 ) );
                var diffPos:Vector3D = VoxelModel.controlledModel.wsPositionGet();
                diffPos = diffPos.add(lav);
                _vm.instanceInfo.positionSet = diffPos;
            }

            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, quadsComplete);
            var bmpd:BitmapData = Renderer.renderer.modelShot( _vm );
            _vm.metadata.thumbnail = drawScaled(bmpd, 128, 128);

            ModelMetadataEvent.create( ModelBaseEvent.IMPORT_COMPLETE, 0, ii.modelGuid, _modelMetadata );
            ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );
            _vm.complete = true;

            modelInfo.changed = true;
            modelInfo.oxelPersistence.changed = true;
            _modelMetadata.changed = true;
            _vm.save();

            Log.out("ModelMakerClone.quadsComplete - needed info found: " + _modelMetadata.description );
            super.markComplete(true);
        }

        function drawScaled(obj:BitmapData, destWidth:int, destHeight:int ):BitmapData {
            var m:Matrix = new Matrix();
            m.scale(destWidth/obj.width, destHeight/obj.height);
            var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
            bmpd.draw(obj, m);
            return bmpd;
        }
    }

}
}