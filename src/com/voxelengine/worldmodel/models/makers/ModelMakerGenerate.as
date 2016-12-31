/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
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
		_creationFunction 	= $miJson.name;
		_type 				= $miJson.biomes.layers[0].type;
		
		super( $ii );
		Log.out( "ModelMakerGenerate - ii: " + ii.toString() + "  using generation script: " + $miJson.biomes.layers[0].functionName );
		
		// This is a special case for modelInfo, the modelInfo its self is contained in the generate script
		_modelInfo = new ModelInfo( $ii.modelGuid );
		///////////////////
		var dbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_MODEL_INFO, "0", "0", 0, true, null );
		dbo.data = new Object();
		// This is for import from generated only.
		dbo.data.model = $miJson
		modelInfo.fromObjectImport( dbo );
		retrieveBaseInfo();
		attemptMake();
	}
	
	override protected function retrieveBaseInfo():void {
		
		_modelMetadata = new ModelMetadata( ii.modelGuid );
		var newObj:Object = ModelMetadata.newObject()
		_modelMetadata.fromObjectImport( newObj );

		if ( _type )
			_modelMetadata.name = _creationFunction + TypeInfo.name( _type ) + "-" + modelInfo.info.model.grainSize + "-" + _creationFunction;
		else	
			_modelMetadata.name = _creationFunction + "-" + modelInfo.info.model.grainSize;
		_modelMetadata.description = _creationFunction + "- GENERATED";
		_modelMetadata.owner = Network.userId;
		ModelMetadataEvent.dispatch( new ModelMetadataEvent ( ModelBaseEvent.GENERATION, 0, ii.modelGuid, _modelMetadata ) );
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		Log.out( "ModelMakerGenerate.attemptMake " + ii.modelGuid );
		if ( null != modelInfo && null != _modelMetadata ) {
			
			_vm = make();
			if ( _vm ) {
				OxelDataEvent.addListener( ModelBaseEvent.ADDED, listenForGenerationComplete );
				Region.currentRegion.modelCache.add( _vm );
			}
			else {
				Log.out( "ModelMakerGenerate.attemptMake FAILED to generate from " + _creationFunction, Log.WARN );
				markComplete( false, _vm );
			}
		}
	}
	
	override protected function markComplete( $success:Boolean, $vm:VoxelModel = null ):void {
		// do this last as it nulls everything.
		Log.out( "ModelMakerGenerate.markComplete " + ii.modelGuid );
		super.markComplete( $success, $vm );
		_vm = null;
		_creationFunction = null;
		_creationInfo = null;
	}

		private function listenForGenerationComplete( $e:OxelDataEvent ):void {
			if ( $e.modelGuid == ii.modelGuid ) {
				OxelDataEvent.removeListener( ModelBaseEvent.ADDED, listenForGenerationComplete );
				ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.GENERATION, 0, ii.modelGuid, _modelInfo ) );
				Log.out( "ModelMakerGenerate.listenForGenerationComplete " + ii.modelGuid + " == " + $e.modelGuid );
				_vm.complete = true;
				modelInfo.data = $e.oxelData;
				modelInfo.data.changed = true;
				modelInfo.changed = true;
				_modelMetadata.changed = true;
				_vm.save();
				markComplete( true, _vm );
			}
			else
				Log.out( "ModelMakerGenerate.listenForGenerationComplete " + ii.modelGuid + " != " + $e.modelGuid );

		}

	
}	
}