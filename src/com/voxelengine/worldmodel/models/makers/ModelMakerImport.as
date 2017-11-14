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

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.GUI.WindowModelInfo;
import com.voxelengine.server.Network;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.GrainCursor;

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
		requestModelInfo();
	}

	// override default since this version uses the file system
	override protected function requestModelInfo():void {
		// use default handler in base to go to next step
		// which is to attempt to build make the model.
		addMIEListeners();
		// Since this is the import, it uses the local file system rather then persistence
		ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, ii.modelGuid, null, ModelBaseEvent.USE_FILE_SYSTEM );
	}
	
	// next get or generate the metadata
	override protected function attemptMake():void {
		//Log.out( "ModelMakerImport - attemptMake: " + ii.toString() );
        // for imports we have no metadata, so we go ahead and either generate it, or prompt the user for it.
		if ( null != modelInfo ) {
			// The new guid is generated in the Window or in the hidden metadata creation
            modelInfo.description = ii.modelGuid + " - Imported";
            modelInfo.name = ii.modelGuid;
            modelInfo.owner = Network.userId;
			if ( _prompt ) {
				//Log.out( "ModelMakerImport - attemptMake: gathering metadata " + ii.toString() );
				ModelInfoEvent.addListener( ModelInfoEvent.DATA_COLLECTED, metadataFromUI );
				new WindowModelInfo( ii, _modelInfo, WindowModelInfo.TYPE_IMPORT ); }
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
		if ( !Globals.isGuid( modelInfo.guid ) ) {
			var newGuid:String = Globals.getUID();
			Log.out( "ModelMakerImport.markComplete setting guids to " + newGuid );

			modelInfo.guid 		= newGuid;
			ii.modelGuid 		= newGuid;
		}

		modelInfo.brandChildren();

		if ( !ii.controllingModel && modelInfo.oxelPersistence && modelInfo.oxelPersistence.oxelCount ) {
			// Only do this for top level models.
			var radius:int = Math.max(GrainCursor.get_the_g0_edge_for_grain(modelInfo.oxelPersistence.oxel.gc.bound), 16)/2;
			// this gives me corner.
			const cm:VoxelModel = VoxelModel.controlledModel;
			if ( cm ) {
                var msCamPos:Vector3D = cm.cameraContainer.current.position;
                var adjCameraPos:Vector3D = cm.modelToWorld(msCamPos);

                var lav:Vector3D = cm.instanceInfo.invModelMatrix.deltaTransformVector(new Vector3D(-(radius + 8), adjCameraPos.y - radius, -radius * 3));
                var diffPos:Vector3D = cm.wsPositionGet();
                diffPos = diffPos.add(lav);
                _vm.instanceInfo.positionSet = diffPos;
            }
		}

		// This works for simple models, but not for deep hierarchies
		var bmpd:BitmapData = Renderer.renderer.modelShot( _vm );
		_vm.modelInfo.thumbnail = drawScaled( bmpd, 128, 128 );

		ModelInfoEvent.create( ModelBaseEvent.UPDATE, 0, ii.modelGuid, _modelInfo );
		_vm.complete = true;

		modelInfo.changed = true;
		_vm.save();

		Log.out("ModelMakerImport.quadsComplete - needed info found: " + modelInfo.description );
		// The function Chunk.quadsBuildPartialComplete publishes these event in this order
		// OxelDataEvent.create(OxelDataEvent.OXEL_BUILD_COMPLETE, 0, _guid, _op);
		// So we dont want to do this until OXEL_BUILD_COMPLETE is complete
		// super.markComplete(true);

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


