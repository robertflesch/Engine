/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.VoxelModelData;
import com.voxelengine.worldmodel.models.VoxelModelMetadata;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMaker {
	
	// keeps track of how many makers there currently are.
	static public var _makerCount:int;
	
	private var _ii:InstanceInfo;
	private var _vmd:VoxelModelData;
	private var _vmm:VoxelModelMetadata;
	
	public function ModelMaker( $ii:InstanceInfo ) {
		_ii = $ii;
		Log.out( "ModelMaker - ii: " + _ii.toString() );
		ModelMetadataEvent.addListener( ModelMetadataEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelMetadataEvent.FAILED, failedMetadata );		
		ModelDataEvent.addListener( ModelDataEvent.ADDED, retriveData );		
		ModelDataEvent.addListener( ModelDataEvent.FAILED, failedData );		

		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.REQUEST, _ii.guid, null ) );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.REQUEST, _ii.guid, null ) );		

		_makerCount++;
	}
	
	private function failedMetadata(e:ModelMetadataEvent):void {
		Log.out( "ModelMaker.failedMetadata - ii: " + _ii.toString() );
		markComplete();
	}
	
	private function failedData(e:ModelDataEvent):void  {
		Log.out( "ModelMaker.failedData - ii: " + _ii.toString() );
		markComplete()
	}
	
	private function retriveMetadata(e:ModelMetadataEvent):void 
	{
		if ( _ii.guid == e.guid ) {
			ModelMetadataEvent.removeListener( ModelMetadataEvent.ADDED, retriveMetadata );
			_vmm = e.vmm;
			attemptMake();
		}
	}
	
	private function retriveData(e:ModelDataEvent):void 
	{
		if ( _ii.guid == e.guid ) {
			ModelDataEvent.removeListener( ModelDataEvent.ADDED, retriveData );		
			_vmd = e.vmd;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	private function attemptMake():void {
		if ( null != _vmm && null != _vmd ) {
			Log.out( "ModelMaker.attemptMake - ii: " + _ii.toString() );
			ModelLoader.loadFromManifestByteArrayNew( _ii, _vmd );
			markComplete();
		}
	}
	
	private function markComplete():void {
		ModelMetadataEvent.removeListener( ModelMetadataEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelMetadataEvent.FAILED, failedMetadata );		
		ModelDataEvent.removeListener( ModelDataEvent.ADDED, retriveData );		
		ModelDataEvent.removeListener( ModelDataEvent.FAILED, failedData );		
		_makerCount--;
		if ( 0 == _makerCount )
			Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
		
	}
}	
}