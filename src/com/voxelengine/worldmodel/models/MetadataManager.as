/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.server.Network;

/**
 * ...
 * @author Bob
 */
public class MetadataManager
{
	//static private var _modifiedDate:Date; // The date range used for loading from persistance, this is the oldest model to get. Gets updated each time it is used
	//static private var _guidError:String;
	static private var _initialized:Boolean;
	
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _metadata:Dictionary = new Dictionary(false);
	static private var _data:Dictionary = new Dictionary(false);
	
	public function MetadataManager() {
		
	}
	
	static public function init():void {
		//ModelMetadataEvent.addListener( ModelMetadataEvent.LOAD, regionLoad ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.JOIN, requestServerJoin ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.CHANGED, regionChanged );	
		ModelMetadataEvent.addListener( ModelMetadataEvent.TYPE_REQUEST, modelMetadataTypeRequest );
		ModelMetadataEvent.addListener( ModelMetadataEvent.REQUEST, modelMetadataRequest );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, metadataLoadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, metadataLoadFailed );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  METADATA
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function modelMetadataRequest( $mme:ModelMetadataEvent ):void 
	{   
		if ( null == $mme.guid ) {
			Log.out( "MetadataManager.modelMetadataRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		Log.out( "MetadataManager.modelMetadataRequest guid: " + $mme.guid, Log.WARN );
		var vmm:VoxelModelMetadata = _metadata[$mme.guid]; 
		if ( null == vmm )
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, Globals.DB_TABLE_MODELS, $mme.guid ) );
		else
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.ADDED, vmm.guid, vmm ) );
	}
	
	// This loads the first 100 objects from the users inventory and the public inventory
	static private function modelMetadataTypeRequest( $mme:ModelMetadataEvent ):void {
		
		if ( false == _initialized ) {
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Globals.DB_TABLE_MODELS, Network.userId, null, Globals.DB_INDEX_VOXEL_MODEL_OWNER ) );
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Globals.DB_TABLE_MODELS, Network.PUBLIC, null, Globals.DB_INDEX_VOXEL_MODEL_OWNER ) );
		}
			
		_initialized = true;
		
		// This will return models already loaded.
		for each ( var vmm:VoxelModelMetadata in _metadata ) {
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.ADDED, vmm.guid, vmm ) );
		}
	}
	
	static private function metadataAdd( $vmm:VoxelModelMetadata ):void 
	{ 
		if ( null == $vmm || null == $vmm.guid ) {
			Log.out( "MetadataManager.metadataAdd trying to add NULL metadata or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _metadata[$vmm.guid] ) {
			//Log.out( "MetadataManager.metadataAdd vmm: " + $vmm.toString(), Log.WARN );
			_metadata[$vmm.guid] = $vmm; 
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.ADDED, $vmm.guid, $vmm ) );
		}
	}
	
	static private function metadataLoadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.DB_TABLE_MODELS != $pe.table )
			return;
		Log.out( "MetadataManager.metadataLoadSucceed $pe: " + $pe.guid, Log.WARN );
		var vmm:VoxelModelMetadata = new VoxelModelMetadata();
		if ( $pe.dbo ) {
			vmm.fromPersistanceMetadata( $pe.dbo );
			metadataAdd( vmm );
		}
		else {
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.FAILED, null, null ) );
		}
	}
	
	static private function metadataLoadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.DB_TABLE_MODELS != $pe.table )
			return;
		Log.out( "MetadataManager.metadataLoadFailed vmm: ", Log.ERROR );
	}
	
}
}