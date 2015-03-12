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
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelData;
import com.voxelengine.worldmodel.models.ModelInfo;
import flash.utils.ByteArray;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata AND data has been loaded from persistance
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerLocal extends ModelMakerBase {
	
	// keeps track of how many makers there currently are.
	static private var _makerCount:int;
	
	private var _vmi:ModelInfo;
	
	public function ModelMakerLocal( $ii:InstanceInfo ) {
		super( $ii, false );
		_makerCount++;
		ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, retriveInfo );		
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		

		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, _ii.guid, null ) );		
	}
	
	private function failedInfo( $mie:ModelInfoEvent):void {
		if ( _ii.guid == $mie.guid ) {
			Log.out( "ModelMaker.failedInfo - ii: " + _ii.toString() + " ModelInfoEvent: " + $mie.toString(), Log.WARN );
			markComplete( false );
		}
	}
	
	private function retriveInfo(e:ModelInfoEvent):void {
		if ( _ii.guid == e.guid ) {
			ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retriveInfo );
			_vmi = e.vmi;
			attemptMake();
		}
	}
	
	// once they both have been retrived, we can make the object
	override protected function attemptMake():void {
		if ( null != _vmi && null != _vmd ) {
			
			var $ba:ByteArray = _vmd.ba;
			
			var versionInfo:Object = ModelLoader.modelMetaInfoRead( $ba );
			if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "VoxelModel.test - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes, even though we are using the data from the modelInfo file
			var modelInfoJson:String = $ba.readUTFBytes( strLen );
				
			var vmm:ModelMetadata = new ModelMetadata( _ii.guid );
			vmm.name = _vmi.fileName;
			vmm.description = _vmi.fileName;
			var vm:* = ModelLoader.instantiate( _ii, _vmi, vmm );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.fromByteArray( $ba );
			}

			vm.complete = true;
			vm.data = _vmd;
			
			markComplete();
		}
	}
	//////////////////////////////////////
	
	override protected function markComplete( $success:Boolean = true ):void {
		super.markComplete( $success );
		ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retriveInfo );		
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retriveInfo );		
		ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedInfo );		
		
		_makerCount--;
		if ( 0 == _makerCount )
			LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
		Log.out( "ModelMakerLocal.markComplete - makerCount: " + _makerCount + "  ii: " + _ii );
	}
	
	
}	
}