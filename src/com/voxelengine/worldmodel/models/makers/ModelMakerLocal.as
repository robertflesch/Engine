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
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.Region;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its model AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerLocal extends ModelMakerBase {
	
	// keeps track of how many makers there currently are.
	
	private var _vmi:ModelInfo;
	
	public function ModelMakerLocal( $ii:InstanceInfo ) {
		//Log.out( "ModelMakerLocal ii.modelGuid: " + $ii.modelGuid, Log.WARN );
		super( $ii, false );
		makerCountIncrement();
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, retriveInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		

		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _ii.modelGuid, null ) );		
	}
	
	private function failedInfo( $mie:ModelInfoEvent):void {
		if ( _ii.modelGuid == $mie.modelGuid ) {
			Log.out( "ModelMakerLocal.failedInfo - ii: " + _ii.toString() + " ModelInfoEvent: " + $mie.toString(), Log.WARN );
			markComplete( false );
		}
	}
	
	private function retriveInfo(e:ModelInfoEvent):void {
		if ( _ii.modelGuid == e.modelGuid ) {
			ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retriveInfo );
			_vmi = e.vmi;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi && null != _vmd ) {
			
			var ba:ByteArray = new ByteArray();
			ba.writeBytes( _vmd.compressedBA, 0, _vmd.compressedBA.length );
			try { ba.uncompress(); }
			catch (error:Error) { ; }
			if ( null == ba ) {
				Log.out( "ModelMakerLocal.attemptMake - Exception - NO data in VoxelModelMetadata: " + _vmd.modelGuid, Log.ERROR );
				return;
			}

			var versionInfo:Object = modelMetaInfoRead( ba );
			if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "ModelMakerLocal.attemptMake - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = ba.readInt();
			// read off that many bytes, even though we are using the data from the modelInfo file
			var modelInfoJson:String = ba.readUTFBytes( strLen );
				
			var vmm:ModelMetadata = new ModelMetadata( _ii.modelGuid );
			vmm.name = _vmi.fileName;
			vmm.description = _vmi.fileName;
			var vm:* = instantiate( _ii, _vmi, vmm, ba, versionInfo );
			if ( vm ) {
				vm.data = _vmd;
				vm.modelInfo.animationsLoad( vm );			
				Region.currentRegion.modelCache.add( vm );
			}
			
			markComplete();
		}
	}
	//////////////////////////////////////
	
	override protected function markComplete( $success:Boolean = true ):void {
		super.markComplete( $success );
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retriveInfo );		
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		
		makerCountDecrement();
		if ( 0 == makerCountGet() ) {
			//Log.out( "ModelMakerLocal.markComplete - makerCount: 0, SHUTTING DOWN SPLASH", Log.WARN );
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.ANNIHILATE ) );
		}
	}
	
	
}	
}