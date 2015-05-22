/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.OxelData;
import com.voxelengine.worldmodel.tasks.landscapetasks.TaskLibrary;
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
public class ModelMakerGenerate {
	
	private var _vmi:ModelInfo;
	private var _vmm:ModelMetadata;
	private var _ii:InstanceInfo;
	private var _vmd:OxelData;
	
	public function ModelMakerGenerate( $ii:InstanceInfo ) {
		_ii = $ii;
		Log.out( "ModelMakerGenerate - ii: " + _ii.toString() );
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );

		_vmm = new ModelMetadata( _ii.modelGuid );
		_vmm.name = _ii.modelGuid;
		_vmm.description = _ii.modelGuid + "-GENERATED";
		_vmm.owner = Network.userId;
		_vmm.modifiedDate = new Date();
		
		// This is a special case for modelInfo, the modelInfo its self is contained in the generate script
		_vmi = new ModelInfo( $ii.modelGuid );
		var functionClass:* = TaskLibrary.getAsset( $ii.modelGuid );
		var json:Object = functionClass.script();
		_vmi.initJSON( "modelGuid", json );
		var layer:LayerInfo = _vmi.biomes.layers[0];
		// the layer details are passed in via the ii;
		_vmi.biomes.addToTaskControllerUsingNewStyle( _ii );
			
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, loadSucceed );

		// This unblocks the landscape task controller when all terrain tasks have been added
		if (0 == Globals.g_landscapeTaskController.activeTaskLimit)
			Globals.g_landscapeTaskController.activeTaskLimit = 1;
	}
	
	private function loadSucceed(e:PersistanceEvent):void 
	{
		if ( e.guid == _ii.modelGuid ) {
			_vmd = new OxelData( _ii.modelGuid );
			try {  e.data.compress(); }
			catch (error:Error) { ; }
			_vmd.compressedBA = e.data;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	protected function attemptMake():void {
		
		if ( null != _vmi && null != _vmd && null != _vmm ) {
			
			var ba:ByteArray = new ByteArray();
			ba.writeBytes( _vmd.compressedBA, 0, _vmd.compressedBA.length );
			try { ba.uncompress(); }
			catch (error:Error) { ; }
			if ( null == ba ) {
				Log.out( "ModelMakerGenerate.createFromMakerInfo - Exception - NO data in VoxelModelMetadata: " + _vmd.guid, Log.ERROR );
				return;
			}
			
			var versionInfo:Object =  ModelMakerBase.extractVersionInfo( ba );
			if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "ModelMakerGenerate.attemptMake - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = ba.readInt();
			// read off that many bytes, even though we are using the data from the modelInfo file
			var modelInfoJson:String = ba.readUTFBytes( strLen );
			// reset the file name that it was loaded from and assign a new guid
			_ii.modelGuid = _vmm.guid = _vmd.guid = _vmi.guid = Globals.getUID();
			_vmi.fileName = "";
			
			var vm:* = ModelMakerBase.instantiate( _ii, _vmi );
			if ( vm ) {
				vm.data = _vmd;
				vm.version = versionInfo.version;
				vm.init( _vmi, _vmm );
				vm.fromByteArray( ba );
				vm.changed = true;
				vm.complete = true;
				vm.save();
				Region.currentRegion.modelCache.add( vm );
			}
			markComplete();
		}
	}
	
	protected function markComplete( $success:Boolean = true ):void {
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
		ModelLoadingEvent.dispatch( new ModelLoadingEvent( ModelLoadingEvent.MODEL_LOAD_COMPLETE, _ii.modelGuid ) );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.CREATED, 0, _ii.modelGuid, _vmm ) );
		OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.CREATED, 0, _ii.modelGuid, _vmd ) );
		
	}
}	
}