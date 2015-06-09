/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.worldmodel.TypeInfo;
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.tasks.landscapetasks.TaskLibrary;
	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerGenerate extends ModelMakerBase {
	private var _creationInfo:Object;
	private var _creationFunction:String;
	private var _type:int;
	
	public function ModelMakerGenerate( $ii:InstanceInfo, $miJson:Object ) {
		_creationInfo = $miJson;
		_creationFunction = $miJson.biomes.layers[0].functionName;
		_type = _creationInfo.biomes.layers[0].type;
		
		super( $ii );
		Log.out( "ModelMakerGenerate - ii: " + _ii.toString() + "  using generation script: " + _creationFunction );
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
		
		// This is a special case for modelInfo, the modelInfo its self is contained in the generate script
		_vmi = new ModelInfo( $ii.modelGuid );
		_vmi.fromObject( $miJson, null );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.GENERATION, 0, $ii.modelGuid, _vmi ) );
		
		retrieveBaseInfo();
		attemptMake();
	}
	
	override protected function retrieveBaseInfo():void {
		_vmm = new ModelMetadata( _ii.modelGuid );
		_vmm.name = TypeInfo.name( _type ) + _creationInfo.grainSize + "-" + _creationFunction;
		_vmm.description = _creationFunction + "- GENERATED";
		_vmm.owner = Network.userId;
		_vmm.modifiedDate = new Date();
		ModelMetadataEvent.dispatch( new ModelMetadataEvent ( ModelBaseEvent.GENERATION, 0, _ii.modelGuid, _vmm ) );
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi && null != _vmm ) {
			_vmi.fileName = "";
			
			var vm:* = make();
			if ( vm ) {
				vm.complete = true;
				vm.changed = true;
				_vmi.changed = true;
				_vmm.changed = true;
				vm.save();
				Region.currentRegion.modelCache.add( vm );
			}
			markComplete( true, vm );
		}
	}
}	
}