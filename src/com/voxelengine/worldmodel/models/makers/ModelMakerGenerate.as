/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;

import flash.utils.ByteArray;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.PermissionsBase;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel
import com.voxelengine.worldmodel.tasks.landscapetasks.TaskLibrary;
	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to generate the modelInfo and the modelMetadata
	 * The class is different then all the other makers which depend on local or persistent object
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerGenerate extends ModelMakerBase {
	private var _creationInfo:Object;
	private var _creationFunction:String;
	private var _type:int;
	private  var _vm:VoxelModel;
	
	public function ModelMakerGenerate( $ii:InstanceInfo, $miJson:Object ) {
		_creationFunction = $miJson.name;
		_type = $miJson.biomes.layers[0].type;
		_creationInfo = $miJson;
		Log.out("ModelMakerGenerate - ii: " + $ii.toString() + "  using generation script: " + $miJson.biomes.layers[0].functionName);
		super($ii);
		retrieveOrGenerateModelInfo();
	}

	private function retrieveOrGenerateModelInfo():void {
		// So there is a chance that this model already exists, as in the case for the DefaultPlayer
		// Check to see if this modelInfo already exists.
		ModelInfoEvent.addListener( ModelBaseEvent.EXISTS, modelInfoExists );
		ModelInfoEvent.addListener( ModelBaseEvent.EXISTS_FAILED, modelInfoDoesNotExists );
		ModelInfoEvent.create( ModelBaseEvent.EXISTS_REQUEST, 0, ii.modelGuid, null );

		function modelInfoExists( $e:ModelInfoEvent ):void {
			if ( $e.modelGuid != ii.modelGuid )
				return;
			removeModelInfoEventHandler();
			_modelInfo = $e.vmi;
			retrieveOrGenerateModelMetadata();
		}

		function modelInfoDoesNotExists( $e:ModelInfoEvent ):void {
			if ( $e.modelGuid != ii.modelGuid )
				return;

			removeModelInfoEventHandler();

			_modelInfo = new ModelInfo( ii.modelGuid );
			var newObj:Object = ModelInfo.newObject();
			newObj.data.model = _creationInfo;
			modelInfo.fromObjectImport( newObj );

			retrieveOrGenerateModelMetadata();
		}

		function removeModelInfoEventHandler():void {
			ModelInfoEvent.removeListener( ModelBaseEvent.EXISTS, modelInfoExists );
			ModelInfoEvent.removeListener( ModelBaseEvent.EXISTS_FAILED, modelInfoDoesNotExists );
		}

	}


	private function retrieveOrGenerateModelMetadata(): void {
		ModelMetadataEvent.addListener( ModelBaseEvent.EXISTS, modelMetadataExists );
		ModelMetadataEvent.addListener( ModelBaseEvent.EXISTS_FAILED, modelMetadataDoesNotExists );
		ModelMetadataEvent.create( ModelBaseEvent.EXISTS_REQUEST, 0, ii.modelGuid, null );

		function modelMetadataExists( $e:ModelMetadataEvent ):void {
			if ( $e.modelGuid != ii.modelGuid )
				return;
			removeModelMetadataEventHandler();
			_modelMetadata = $e.modelMetadata;
			attemptMake();
		}

		function modelMetadataDoesNotExists( $e:ModelMetadataEvent ):void {
			if ( $e.modelGuid != ii.modelGuid )
				return;
			removeModelMetadataEventHandler();
			retrieveBaseInfo();
			attemptMake();
		}

		function removeModelMetadataEventHandler():void {
			ModelMetadataEvent.removeListener( ModelBaseEvent.EXISTS, modelMetadataExists );
			ModelMetadataEvent.removeListener( ModelBaseEvent.EXISTS_FAILED, modelMetadataDoesNotExists );
		}
	}

	override protected function retrieveBaseInfo():void {
		Log.out( "ModelMakerGenerate.retrieveBaseInfo " + ii.modelGuid );
		_modelMetadata = new ModelMetadata( ii.modelGuid );
		var newObj:Object = ModelMetadata.newObject();
		_modelMetadata.fromObjectImport( newObj );

		// Bypass the setter so that we dont set it to changed
		if ( _type )
			_modelMetadata.info.name = _creationFunction + TypeInfo.name( _type ) + "-" + modelInfo.info.model.grainSize + "-" + _creationFunction;
		else
			_modelMetadata.info.name = _creationFunction + "-" + modelInfo.info.model.grainSize;
		_modelMetadata.info.description = _creationFunction + "- GENERATED";
		_modelMetadata.info.owner = Network.userId;
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		Log.out( "ModelMakerGenerate.attemptMake " + ii.modelGuid );
		if ( null != modelInfo && null != _modelMetadata ) {
			_vm = make();
			if ( _vm ) {
				if ( !_vm.modelInfo.data ) {
					OxelDataEvent.addListener(ModelBaseEvent.ADDED, listenForGenerationComplete);
					_modelInfo.oxelLoadData();
				} else
					markComplete( true, _vm );
			}
			else {
				Log.out( "ModelMakerGenerate.attemptMake FAILED to generate from " + _creationFunction, Log.WARN );
				markComplete( false, _vm );
			}
		}

		function listenForGenerationComplete( $e:OxelDataEvent ):void {
			if ( $e.modelGuid == ii.modelGuid ) {
				OxelDataEvent.removeListener( ModelBaseEvent.ADDED, listenForGenerationComplete );
				Log.out( "ModelMakerGenerate.listenForGenerationComplete " + ii.modelGuid + " == " + $e.modelGuid );
				modelInfo.data = $e.oxelData;
				markComplete( true, _vm );
			}
			else
				Log.out( "ModelMakerGenerate.listenForGenerationComplete " + ii.modelGuid + " != " + $e.modelGuid );

		}
	}
	
	override protected function markComplete( $success:Boolean, $vm:VoxelModel = null ):void {
		// do this last as it nulls everything.
		Log.out( "ModelMakerGenerate.markComplete " + ii.modelGuid );
		if ( $success ){
			// Everything worked, add these to the caches and save them
			ModelMetadataEvent.create( ModelBaseEvent.GENERATION, 0, ii.modelGuid, _modelMetadata );
			ModelInfoEvent.create( ModelBaseEvent.GENERATION, 0, ii.modelGuid, _modelInfo );
			_vm.complete = true;

			if ( modelInfo.guid != "DefaultPlayer" ) {
				modelInfo.data.changed = true;
				modelInfo.changed = true;
				_modelMetadata.changed = true;
				_vm.save();
			}
			Region.currentRegion.modelCache.add( _vm );
		}

		super.markComplete( $success, $vm );
		_vm = null;
		_creationFunction = null;
		_creationInfo = null;
	}

}
}