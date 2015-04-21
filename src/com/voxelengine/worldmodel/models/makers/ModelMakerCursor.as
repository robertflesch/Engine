/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.worldmodel.models.makers.ModelMakerCursor;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.Region;
import flash.utils.getTimer;
import flash.utils.ByteArray;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.ModelInfo;
	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerCursor extends ModelMakerBase {
	
	// keeps track of how many makers there currently are.
	private var _vmm:ModelMetadata;
	
	public function ModelMakerCursor( $ii:InstanceInfo, $vmm:ModelMetadata ) {
		Log.out( "ModelMakerCursor.constructor", Log.WARN );
		_vmm = $vmm;
		if ( 0 == makerCountGet() )
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
		makerCountIncrement();
		super( $ii, true );
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmm && null != _vmd ) {
			//Log.out( "ModelMakerCursor.attemptMake - ii: " + _ii.toString() );
			var vm:VoxelModel = createFromMakerInfo();
			markComplete();
			EditCursor.objectModelSet( vm );
		}
		else if ( null != _vmm && true == _vmdFailed )
			markComplete( false );
	}
	
	override protected function markComplete( $success:Boolean = true ):void {
		super.markComplete( $success );
		makerCountDecrement();
		if ( 0 == makerCountGet() ) {
			LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.ANNIHILATE ) );
		}
	}

	private function createFromMakerInfo():VoxelModel {
		
		var ba:ByteArray = new ByteArray();
		ba.writeBytes( _vmd.compressedBA, 0, _vmd.compressedBA.length );
		try { ba.uncompress(); }
		catch (error:Error) { ; }
		if ( null == ba ) {
			Log.out( "ModelMakerCursor.createFromMakerInfo - Exception - NO data in VoxelModelMetadata: " + _vmd.modelGuid, Log.ERROR );
			return null;
		}
		
		var versionInfo:Object = modelMetaInfoRead( ba );
		if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion ) {
			Log.out( "ModelMakerCursor.createFromMakerInfo - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
			return null;
		}
		
		var mi:ModelInfo = modelInfoFromByteArray( _vmd.modelGuid, ba );
		
		var vm:* = instantiate( _ii, mi, _vmm, ba, versionInfo );
		if ( vm ) {
			vm.data = _vmd;
			vm.modelInfo.loadAnimations( vm );
		}

		return vm;
	}
}	
}