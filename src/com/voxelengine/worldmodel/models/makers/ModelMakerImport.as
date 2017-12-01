/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers {
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.Region;

import flash.display.BitmapData;
import flash.geom.Matrix;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.GUI.PopupCollectModelInfo;
import com.voxelengine.server.Network;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.animation.AnimationCache;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerImport extends ModelMakerBase {
	
	private var _prompt:Boolean;

	public function ModelMakerImport( $ii:InstanceInfo, $prompt:Boolean = true ) {
		// This should never happen in a release version, so dont worry about setting it to false when done
		_prompt = $prompt;
		super( $ii, IMPORTING );
		Log.out( "ModelMakerImport - ii: " + ii.toString(), Log.DEBUG );
		// First request the modelInfo
		requestModelInfo( ModelBaseEvent.USE_FILE_SYSTEM );
	}

	// next get or generate the metadata
	override protected function attemptMake():void {
		Log.out( "ModelMakerImport - attemptMake: " + ii.toString() );
        // for imports we have no metadata, so we go ahead and either generate it, or prompt the user for it.
		if ( null != modelInfo ) {
			// The new guid is generated in the Window or in the hidden metadata creation
            modelInfo.description = ii.modelGuid + " - Imported";
            modelInfo.name = ii.modelGuid;
            modelInfo.owner = Network.userId;
			if ( _prompt ) {
				//Log.out( "ModelMakerImport - attemptMake: gathering metadata " + ii.toString() );
				ModelInfoEvent.addListener( ModelInfoEvent.DATA_COLLECTED, metadataFromUI );
				new PopupCollectModelInfo( ii, _modelInfo, PopupCollectModelInfo.TYPE_IMPORT ); }
			else {
				//Log.out( "ModelMakerImport - attemptMake: generating metadata " + ii.toString() );
				attemptMakeRetrieveParentModelInfo(); }
		}
		else if ( null == modelInfo )
			Log.out( "ModelMakerImport - attemptMake: null == modelInfo && null == _modelMetadata " + ii.toString(), Log.ERROR );
		else if ( null == modelInfo )
			Log.out( "ModelMakerImport - attemptMake: null == modelInfo " + ii.toString(), Log.ERROR );
		else
			Log.out( "ModelMakerImport - attemptMake: INVALID CONDITION" + ii.toString(), Log.ERROR );

	}
	
	// The metadata has been collected in the UI
	private function metadataFromUI( $mi:ModelInfoEvent):void {
		if ( $mi.modelGuid == modelInfo.guid ) {
            ModelInfoEvent.removeListener( ModelInfoEvent.DATA_COLLECTED, metadataFromUI );
			// Now check if this has a parent model, if so, get the animation class from the parent.
			//Log.out( "ModelMakerImport.metadataFromUI: " + ii.toString() );
			attemptMakeRetrieveParentModelInfo();
		}
	}

	private function attemptMakeRetrieveParentModelInfo():void {
		if ( parentModelGuid ) {
			//Log.out("ModelMakerImport.attemptMakeRetrieveParentModelInfo - retrieveParentModelInfo " + ii.toString());
			retrieveParentModelInfo();
            modelInfo.childOf = parentModelGuid;
		}
		else {
			//Log.out("ModelMakerImport.attemptMakeRetrieveParentModelInfo - completeMake " + ii.toString());
			if ( modelInfo.modelClass ) {
				var modelClass:String = modelInfo.modelClass;
                modelInfo.animationClass = AnimationCache.requestAnimationClass(modelClass);
			} else
                modelInfo.animationClass = AnimationCache.MODEL_UNKNOWN;

			completeMake();
		}
	}
	
	private function retrieveParentModelInfo():void {
		//Log.out("ModelMakerImport.retrieveParentModelInfo: " + ii.toString());
		// We need the parents modelClass so we can know what kind of animations are correct for this model.
		addParentModelInfoListener();
		var _topMostModelGuid:String = ii.topmostModelGuid();
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _topMostModelGuid, null ) );

		function parentModelInfoResult($mie:ModelInfoEvent):void {
			if ( $mie.modelGuid == _topMostModelGuid ) {
				//Log.out("ModelMakerImport.parentModelInfoResult: " + ii.toString());
				removeParentModelInfoListener();
				var modelClass:String = $mie.modelInfo.modelClass;
                modelInfo.animationClass = AnimationCache.requestAnimationClass( modelClass );
				completeMake();
			}
		}

		function parentModelInfoResultFailed($mie:ModelInfoEvent):void {
			Log.out("ModelMakerImport.parentModelInfoResultFailed: " + ii.toString(), Log.WARN );
			if ( $mie.modelGuid == modelInfo.guid ) {
				removeParentModelInfoListener();
				markComplete( false );
			}
		}

		function addParentModelInfoListener():void {
			ModelInfoEvent.addListener( ModelBaseEvent.RESULT, parentModelInfoResult );
			ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed );
		}

		function removeParentModelInfoListener():void {
			ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, parentModelInfoResult);
			ModelInfoEvent.removeListener(ModelBaseEvent.REQUEST_FAILED, parentModelInfoResultFailed);
		}
	}

	// Need to override the base method since we need to assign the new model guid at this point.
    override protected function oxelPersistenceComplete($ode:OxelDataEvent):void {
        if ($ode.modelGuid == modelInfo.guid) {
            removeODEListeners();
			// do this before assigning new guids so that the OP guid gets updated
            modelInfo.oxelPersistence = $ode.oxelPersistence;
            if (!Globals.isGuid(modelInfo.guid)) {
                var newGuid:String = Globals.getUID();
                Log.out("ModelMakerImport.oxelPersistenceComplete setting guids to " + newGuid);

                modelInfo.guid = newGuid;
                ii.modelGuid = newGuid;
            }
			// can NOT call the super on this since the guid changed!
			//super.oxelPersistenceComplete( $ode );

            //Log.out( "ModelMakerBase.oxelPersistenceComplete MINE    guid: " + modelInfo.guid + "  $ode.modelGuid: " + $ode.modelGuid + " type: " + $ode.type , Log.WARN );

            // This is before quads have been built
            if ( ii.baseLightLevel )
                modelInfo.oxelPersistence.baseLightLevel( ii.baseLightLevel, false );
            // This puts the object into the model cache which will then add the rendering tasks needed.
            _vm.calculateCenter();
            _vm.complete = true;
            if ( addToRegionWhenComplete )
                RegionEvent.create( RegionEvent.ADD_MODEL, 0, Region.currentRegion.guid, _vm );
            markComplete( true );
        }
    }


	private var waitForChildren:Boolean;
	private function completeMake():void {
		//Log.out("ModelMakerImport.completeMake: " + ii.toString());
		if ( null != modelInfo ) {

			_vm = make();
			if ( _vm ) {
				_vm.stateLock( true, 10000 ); // Lock state so that it has time to load animations
				// Now request that the oxel be built
				addODEListeners();

				if ( false == modelInfo.childrenLoaded ) { // its true if they are loaded or the model has no children.
					waitForChildren = true;
                    Log.out( "ModelMakerImport.completeMake - adding listener for CHILD_LOADING_COMPLETE description: " + modelInfo.description, Log.WARN );
					ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady);
				}

				if ( modelInfo && modelInfo.biomes && modelInfo.biomes.layers[0] && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" )
					OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, modelInfo.guid, null, true, true, modelInfo.toGenerationObject() );
				else
					OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, modelInfo.guid, null, ModelBaseEvent.USE_FILE_SYSTEM );
			}
		}
		else
			Log.out( "ModelMakerImport.completeMake ERROR - modelInfo: " + modelInfo, Log.WARN );

		function childrenAllReady( $ode:ModelLoadingEvent):void {
			if ( modelInfo.guid == $ode.data.parentModelGuid ) {
                waitForChildren = false;
				Log.out( "ModelMakerImport.allChildrenReady - modelInfo.guid: " + modelInfo.guid + "  modelInfo.description: " + modelInfo.description, Log.WARN );
				ModelLoadingEvent.removeListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childrenAllReady );
				// If the oxel loads before the children are ready this doesn't work.
                markComplete( true );
            }
		}
	}

	override protected function oxelBuildComplete($ode:OxelDataEvent):void {
		if ( modelInfo && $ode.modelGuid == modelInfo.guid ) {
			Log.out( "ModelMakerBase.oxelBuildComplete  guid: " + modelInfo.guid, Log.WARN );
			removeODEListeners();
			// This has the additional wait for children
			if ( !waitForChildren )
				markComplete( true );
			else
				Log.out( "ModelMakerBase.oxelBuildComplete  WAITING ON CHILDREN  guid: " + modelInfo.guid, Log.WARN );
		}
	}

	override protected function oxelBuildFailed($ode:OxelDataEvent):void {
		if ( modelInfo &&  $ode.modelGuid == modelInfo.guid ) {
			removeODEListeners();
			modelInfo.oxelPersistence = null;
			_vm.dead = true;
			Log.out("ModelMakerImport - ERROR LOADING OXEL - how do I handle children?", Log.WARN);
			// TODO cancel children loading???
			markComplete( false );
		}
	}

        override protected function markComplete( $success:Boolean ):void {
		if ( true == $success ) {
			if ( !waitForChildren )
				importComplete();
		} else {
			if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName != "LoadModelFromIVM" )
				Log.out( "ModelMakerImport.markComplete - Failed import, BUT has biomes to attemptMake instead : " + modelInfo.guid, Log.ERROR );
			else if ( modelInfo && modelInfo.boimeHas() && modelInfo.biomes.layers[0].functionName )
				Log.out( "ModelMakerImport.markComplete - Failed import, Failed to load from IVM : " + modelInfo.guid, Log.ERROR );
			else
				Log.out( "ModelMakerImport.markComplete - Unknown error causing failure : " + ii.modelGuid, Log.ERROR );

			ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
			super.markComplete( $success );
		}
	}

	private function importComplete():void {
		modelInfo.brandChildren();

        placeModelIfPositionZero();

        OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_COMPLETE, readyForModelShot );

		_vm.complete = true;
	}

	private function readyForModelShot( $ode:OxelDataEvent ):void {
        if ( modelInfo &&  $ode.modelGuid == modelInfo.guid ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_COMPLETE, readyForModelShot);
            // This works for simple models, but not for deep hierarchies
            var bmpd:BitmapData = Renderer.renderer.modelShot( _vm );
            _vm.modelInfo.thumbnail = drawScaledAndCropped( bmpd, 128, 128 );
            ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );
            modelInfo.changed = true;
            _vm.save();
            Log.out("ModelMakerImport.readyForModelShot - MAKER COMPLETE - needed info found: " + modelInfo.name );
            super.markComplete(true);
        }

        function drawScaledAndCropped($bmp:BitmapData, destWidth:int, destHeight:int ):BitmapData {
            var m:Matrix = new Matrix();
            m.scale(destHeight/$bmp.height, destHeight/$bmp.height);
			var scale:Number = $bmp.height/destHeight;
			var finalWidth:int = $bmp.width/scale;
			var totalOffest:int = finalWidth - destWidth;
            m.translate( -totalOffest/2, 0 );
            var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
            bmpd.draw($bmp, m );
            return bmpd;
        }

	}
}
}


