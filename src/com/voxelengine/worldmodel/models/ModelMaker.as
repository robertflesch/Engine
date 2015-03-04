/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelData;
import com.voxelengine.worldmodel.models.ModelMetadata;

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
	private var _vmd:ModelData;
	private var _vmm:ModelMetadata;
	
	public function ModelMaker( $ii:InstanceInfo ) {
		_ii = $ii;
		Log.out( "ModelMaker - ii: " + _ii.toString() );
		ModelMetadataEvent.addListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
		ModelDataEvent.addListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedData );		

		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST, _ii.guid, null ) );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST, _ii.guid, null ) );		

		_makerCount++;
	}
	
	private function failedMetadata( $mme:ModelMetadataEvent):void {
		Log.out( "ModelMaker.failedMetadata - ii: " + _ii.toString() + " ModelMetadataEvent: " + $mme.toString(), Log.WARN );
		markComplete();
	}
	
	private function failedData( $mde:ModelDataEvent):void  {
		Log.out( "ModelMaker.failedData - ii: " + _ii.toString() + " ModelDataEvent: " + $mde.toString(), Log.WARN );
		markComplete()
	}
	
	private function retriveMetadata(e:ModelMetadataEvent):void 
	{
		if ( _ii.guid == e.guid ) {
			ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );
			_vmm = e.vmm;
			attemptMake();
		}
	}
	
	private function retriveData(e:ModelDataEvent):void 
	{
		if ( _ii.guid == e.guid ) {
			ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
			_vmd = e.vmd;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	private function attemptMake():void {
		if ( null != _vmm && null != _vmd ) {
			Log.out( "ModelMaker.attemptMake - ii: " + _ii.toString() );
			ModelLoader.createFromMakerInfo( _ii, _vmd, _vmm );
			markComplete();
		}
	}
	
	private function markComplete():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.ADDED, retriveMetadata );		
		ModelMetadataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedMetadata );		
		ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		_makerCount--;
		if ( 0 == _makerCount ) {
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
			WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.ANNIHILATE ) );
		}
		Log.out( "ModelMaker.markComplete - makerCount: " + _makerCount );
	}
}	
}