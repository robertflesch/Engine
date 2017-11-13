/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{

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
import com.voxelengine.events.ModelEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelInfo;

public class ModelMakerClone extends ModelMakerBase {

    private var _waitForChildren:Boolean;
    private var _newModelGuid:String;
    private var _oldModelInfo:ModelInfo;

    public function ModelMakerClone( $instanceInfo:InstanceInfo, $mi:ModelInfo = null ) {
        super($instanceInfo.clone(), CLONING );

        Log.out("ModelMakerClone - clone model with modelGuid: " + $instanceInfo.modelGuid + "  instanceGuid: " + $instanceInfo.instanceGuid );

        _newModelGuid = Globals.getUID();
        _oldModelInfo = $mi;

        if ( _oldModelInfo )
            processModelInfo();
        else {
            requestModelInfo();
        }
    }

    override protected function retrievedModelInfo($mie:ModelInfoEvent):void  {
        if ( ii.modelGuid == $mie.modelGuid ) {
            removeMIEListeners();
            _oldModelInfo = $mie.modelInfo;
            processModelInfo();
        }
    }

    private function processModelInfo():void {
        // If the OLD modelInfo is completely build, move on to requesting the metadata, otherwise wait for it.
        if ( _oldModelInfo.oxelPersistence && ( 0 < _oldModelInfo.oxelPersistence.oxelCount ) ) {
            _modelInfo = _oldModelInfo.clone(_newModelGuid);
            Log.out( "ModelMakerClone.processModelInfo CLONED Model has a build Oxel _oldModelInfo.guid: " + _oldModelInfo.guid );
            if ( !parentModelGuid ) {
                var modelClass:String = _oldModelInfo.modelClass;
                modelInfo.animationClass = AnimationCache.requestAnimationClass(modelClass);
            }
            completeMake();
        } else {  // wait on OLD modelInfo's oxel to finish!
            Log.out( "ModelMakerClone.processModelInfo CLONED Models OXEL NOT READY wait for _oldModelInfo.guid: " + _oldModelInfo.guid );
            OxelDataEvent.addListener(OxelDataEvent.OXEL_BUILD_COMPLETE, onBaseModelOxelBuildComplete );
        }
    }

     private function onBaseModelOxelBuildComplete( $ode:OxelDataEvent ):void {
         // oxel s loaded, we can go!
         if ( $ode.modelGuid == _oldModelInfo.guid ) {
             Log.out("ModelMakerClone.onOxelBuildComplete OLD Models oxel is now ready ode.modelGuid: " + $ode.modelGuid + "  _oldModelInfo.guid: " + _oldModelInfo.guid );
             OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_COMPLETE, onBaseModelOxelBuildComplete);
             // go back and try again
             processModelInfo();
         }
     }


    private function completeMake():void {
        //Log.out("ModelMakerClone.completeMake: " + ii.toString());
        if ( null != modelInfo ) {

            _vm = make();
            if ( _vm ) {
                _vm.stateLock( true, 10000 ); // Lock state so that it has time to load animations
                addODEListeners();
                PersistenceEvent.create( PersistenceEvent.CLONE_SUCCEED, 0, Globals.IVM_EXT, modelInfo.guid, null, modelInfo.oxelPersistence.ba, null, String( modelInfo.bound  ) );
                if ( false == modelInfo.childrenLoaded ) { // its true if they are loaded or the model has no children.
                    _waitForChildren = true;
                    ModelLoadingEvent.addListener(ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady);
                }
            } else {
                markComplete(false);
            }
        }
        else
            Log.out( "ModelMakerClone.completeMake - modelInfo: " + modelInfo, Log.WARN );

        function childrenAllReady( $ode:ModelLoadingEvent):void {
            if ( modelInfo.guid == $ode.data.modelGuid  ) {
                Log.out( "ModelMakerClone.allChildrenReady - modelMetadata.description: " + modelInfo.description, Log.WARN );
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
            Log.out("ModelMakerClone.completeMake - waiting on quad build: " + modelInfo.description );

            ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );


            _vm.complete = true;

            modelInfo.changed = true;
            modelInfo.oxelPersistence.changed = true;
            _vm.save();

            Log.out("ModelMakerClone.quadsComplete - needed info found: " + modelInfo.description );
            ModelEvent.create( ModelEvent.CLONE_COMPLETE, modelInfo.guid, null, null, "", _vm );

            // Only do this for top level models, need ControlledModel to get offset.
            if ( null == ii.controllingModel && VoxelModel.controlledModel ) {
                var radius:int = Math.max(GrainCursor.get_the_g0_edge_for_grain(modelInfo.grainSize), 16)/2;
                // this gives me corner.
                var msCamPos:Vector3D = VoxelModel.controlledModel.cameraContainer.current.position;
                var adjCameraPos:Vector3D = VoxelModel.controlledModel.modelToWorld(msCamPos);

                var lav:Vector3D = VoxelModel.controlledModel.instanceInfo.invModelMatrix.deltaTransformVector(new Vector3D(-(radius + 8), adjCameraPos.y - radius, -radius * 3));
                var diffPos:Vector3D = VoxelModel.controlledModel.wsPositionGet();
                diffPos = diffPos.add(lav);
                _vm.instanceInfo.positionSet = diffPos;
            }

            var bmpd:BitmapData = Renderer.renderer.modelShot( _vm );
            _vm.modelInfo.thumbnail = drawScaled(bmpd, 128, 128);

            _oldModelInfo = null;
            super.markComplete(true);
        } else {
            if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" )
                Log.out( "ModelMakerClone.markComplete - Failed import, BUT has biomes to attemptMake instead : " + modelInfo.guid, Log.ERROR );
            else if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName )
                Log.out( "ModelMakerClone.markComplete - Failed import, Failed to load from IVM : " + modelInfo.guid, Log.ERROR );
            else
                Log.out( "ModelMakerClone.markComplete - Unknown error causing failure : " + ii.modelGuid, Log.ERROR );

            ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
            OxelDataEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
            super.markComplete( $success );
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