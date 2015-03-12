/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.LoadingEvent;
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
	 * This class is used to load a models data, it is used by all of the current Makers
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes. 
	 * Not sure what a failure case for a timeout would be would be
	 */
public class ModelMakerBase {
	
	protected var _ii:InstanceInfo;
	protected var _vmd:ModelData;
	
	public function ModelMakerBase( $ii:InstanceInfo, $fromTables:Boolean = true ) {
		_ii = $ii;
		Log.out( "ModelMakerBase - ii: " + _ii.toString(), Log.DEBUG );
		ModelDataEvent.addListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.addListener( ModelBaseEvent.RESULT, retriveData );		
		ModelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		ModelDataEvent.dispatch( new ModelDataEvent( ModelBaseEvent.REQUEST, 0, _ii.guid, null, $fromTables ) );		
	}
	
	private function retriveData($mde:ModelDataEvent):void  {
		if ( _ii.guid == $mde.guid ) {
			_vmd = $mde.vmd;
			attemptMake();
		}
	}
	
	private function failedData( $mde:ModelDataEvent):void  {
		if ( _ii.guid == $mde.guid ) {
			Log.out( "ModelMakerBase.failedData - ii: " + _ii.toString() + " ModelDataEvent: " + $mde.toString(), Log.WARN );
			//(new Alert( "Failed to import model: " + _ii.guid + " data not found" ).display() );
			markComplete( false );
		}
	}
	
	// once they both have been retrived, we can make the object
	protected function attemptMake():void { }
	protected function markComplete( $success:Boolean = true ):void {
		
		ModelDataEvent.removeListener( ModelBaseEvent.ADDED, retriveData );		
		ModelDataEvent.removeListener( ModelBaseEvent.RESULT, retriveData );		
		ModelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedData );		
		Log.out( "ModelMakerBase.markComplete - ii: " + _ii + "  success: " + $success, Log.DEBUG );
		if ( $success )
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_COMPLETE, _ii.guid ) );
		else	
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.MODEL_LOAD_FAILURE, _ii.guid ) );
		
	}
}	
}