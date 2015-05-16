/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.worldmodel.Region;
import flash.utils.getTimer;
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.VoxelModel;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is the base class of the model makers, 
	 * model makers are temporary objects which go away after the model has loaded of failed.
	 * As the base class of makers, its responsibility is to load the models metadata.
	 * once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMaker extends ModelMakerBase {
	
	// keeps track of how many makers there currently are.
	private var _vmm:ModelMetadata;
	private var _addToRegionWhenComplete:Boolean;
	
	public function ModelMaker( $ii:InstanceInfo, $addToRegionWhenComplete:Boolean ) {
		Log.out( "ModelMaker.constructor model:" + ($ii.modelGuid ? $ii.modelGuid : $ii.instanceGuid), Log.DEBUG );
		_addToRegionWhenComplete = $addToRegionWhenComplete;
		super( $ii, true );
		if ( 0 == makerCountGet() )
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
		makerCountIncrement();
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.RESULT, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		

		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null ) );		
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		Log.out( "ModelMaker.failedMetadata - ii: " + _ii.toString() + " ModelMetadataEvent: " + $mme.toString(), Log.WARN );
		markComplete(false);
	}
	
	private function retriveMetadata(e:ModelMetadataEvent):void {
		if ( _ii.modelGuid == e.modelGuid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );
			_vmm = e.vmm;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmm && null != _vmd ) {
			Log.out( "ModelMaker.attemptMake - ii: " + _ii.toString() );
			///////////////////////////////////////
			var ba:ByteArray = new ByteArray();
			ba.writeBytes( _vmd.compressedBA, 0, _vmd.compressedBA.length );
			try { ba.uncompress(); }
			catch (error:Error) { ; }
			
			if ( null == ba ) {
				Log.out( "ModelMaker.createFromMakerInfo - Exception - NO data in VoxelModelMetadata: " + _vmd.modelGuid, Log.ERROR );
				return;
			}
			
			var versionInfo:Object = extractVersionInfo( ba );
			if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion ) {
				Log.out( "ModelMaker.createFromMakerInfo - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return;
			}
			
			var modelInfoObject:Object = extractModelInfo( ba );
			var mi:ModelInfo = new ModelInfo();
			mi.initJSON( _ii.modelGuid, modelInfoObject );
			
			var vm:* = instantiate( _ii, mi );
			if ( vm ) {
				vm.data = _vmd;
				vm.version = versionInfo.version;
				vm.init( mi, _vmm );
				vm.fromByteArray( ba );
				vm.modelInfo.animationsLoad( vm );
				vm.complete = true;
			}
			
			markComplete();
			if ( vm && _addToRegionWhenComplete )
				Region.currentRegion.modelCache.add( vm );
		}
		else if ( null != _vmm && true == _vmdFailed )
			markComplete( false );
	}
	
	override protected function markComplete( $success:Boolean = true ):void {
		super.markComplete( $success );
		
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.RESULT, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
		makerCountDecrement();
		if ( 0 == makerCountGet() ) {
			//Log.out( "ModelMaker.markComplete - makerCount: 0, SHUTTING DOWN SPLASH", Log.WARN );
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.ANNIHILATE ) );
		}
	}
}	
}