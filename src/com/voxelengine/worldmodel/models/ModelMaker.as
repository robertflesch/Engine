/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.MetadataManager;
import com.voxelengine.worldmodel.models.VoxelModelMetadata;

	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to load a model once its metadata has been loaded from persistance
	 * it then removes its listener, which should cause it be to be garbage collected.
	 */
public class ModelMaker {
	static public var _makerCount:int;
	
	private var _ii:InstanceInfo;
	
	public function ModelMaker( $ii:InstanceInfo ) {
		_ii = $ii;
		MetadataManager.addListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, makeMe );		
		_makerCount++;
	}
	
	private function makeMe(e:ModelMetadataEvent):void 
	{
		if ( _ii.guid == e.vmm.guid ) {
			MetadataManager.removeListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, makeMe );		
			var vmm:VoxelModelMetadata = e.vmm;
			ModelLoader.loadFromManifestByteArrayNew( _ii, vmm );
			_makerCount--;
		}
		if ( 0 == _makerCount )
			Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
		
	}
}	
}