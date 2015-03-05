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
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelData;
import org.flashapi.swing.Alert;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerBase {
	
	protected var _ii:InstanceInfo;
	protected var _vmd:ModelData;
	
	public function ModelMakerBase( $ii:InstanceInfo ) {
		_ii = $ii;
		Log.out( "ModelMakerBase - ii: " + _ii.toString() );
		ModelDataEvent.addListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST, _ii.guid, null, false ) );		
	}
	
	private function retriveData($mde:ModelDataEvent):void  {
		if ( _ii.guid == $mde.guid ) {
			_vmd = $mde.vmd;
			attemptMake();
		}
	}
	
	private function failedData( $mde:ModelDataEvent):void  {
		if ( _ii.guid == $mde.guid ) {
			Log.out( "ModelMaker.failedData - ii: " + _ii.toString() + " ModelDataEvent: " + $mde.toString(), Log.WARN );
			(new Alert( "Failed to import model: " + _ii.guid + " data not found" ).display() );
			// TODO need some sort of shut down message for the WindowModelMetadata
			markComplete();
		}
	}
	
	// once they both have been retrived, we can make the object
	protected function attemptMake():void { }
	protected function markComplete():void {
		
		ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		Log.out( "ModelMakerBase.markComplete - ii: " + _ii );
	}
}	
}