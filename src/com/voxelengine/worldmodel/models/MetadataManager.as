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

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.server.Network;

/**
 * ...
 * @author Bob
 */
public class MetadataManager
{
	static private var _initializedPublic:Boolean;
	static private var _initializedPrivate:Boolean;
	
	// this acts as a cache for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _metadata:Dictionary = new Dictionary(false);
	
	public function MetadataManager() {	}
	
	static public function init():void {
		//ModelMetadataEvent.addListener( ModelMetadataEvent.LOAD, regionLoad ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.JOIN, requestServerJoin ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.CHANGED, regionChanged );	
		ModelMetadataEvent.addListener( ModelMetadataEvent.TYPE_REQUEST, modelMetadataTypeRequest );
		ModelMetadataEvent.addListener( ModelMetadataEvent.REQUEST, modelMetadataRequest );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, metadataLoadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, metadataLoadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, loadNotFound );		
	}
	
	static private function modelMetadataRequest( $mme:ModelMetadataEvent ):void 
	{   
		if ( null == $mme.guid ) {
			Log.out( "MetadataManager.modelMetadataRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		Log.out( "MetadataManager.modelMetadataRequest guid: " + $mme.guid, Log.INFO );
		var vmm:VoxelModelMetadata = _metadata[$mme.guid]; 
		if ( null == vmm )
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, Globals.DB_TABLE_MODELS, $mme.guid ) );
		else
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.ADDED, vmm.guid, vmm ) );
	}
	
	// This loads the first 100 objects from the users inventory OR the public inventory
	static private function modelMetadataTypeRequest( $mme:ModelMetadataEvent ):void {
		
		if ( Network.PUBLIC == $mme.guid ) {
			if ( false == _initializedPublic ) {
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Globals.DB_TABLE_MODELS, Network.PUBLIC, null, Globals.DB_INDEX_VOXEL_MODEL_OWNER ) );
				_initializedPublic = true;
			}
		}
			
		if ( Network.userId == $mme.guid ) {
			if ( false == _initializedPrivate ) {
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Globals.DB_TABLE_MODELS, Network.userId, null, Globals.DB_INDEX_VOXEL_MODEL_OWNER ) );
				_initializedPrivate = true;
			}
		}
			
		// This will return models already loaded.
		for each ( var vmm:VoxelModelMetadata in _metadata ) {
			if ( vmm.owner == $mme.guid )
				ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.ADDED, vmm.guid, vmm ) );
		}
	}
	
	static private function add( $vmm:VoxelModelMetadata ):void 
	{ 
		if ( null == $vmm || null == $vmm.guid ) {
			Log.out( "MetadataManager.add trying to add NULL metadata or guid", Log.WARN );
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
		Log.out( "MetadataManager.metadataLoadSucceed guid: " + $pe.guid, Log.WARN );
		if ( $pe.dbo ) {
			var vmm:VoxelModelMetadata = new VoxelModelMetadata();
			vmm.fromPersistanceMetadata( $pe.dbo );
			add( vmm );
		}
		else {
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.FAILED, $pe.guid, null ) );
		}
	}
	
	static private function metadataLoadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.DB_TABLE_MODELS != $pe.table )
			return;
		Log.out( "MetadataManager.metadataLoadFailed PersistanceEvent: " + $pe.toString(), Log.ERROR );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.FAILED, $pe.guid, null ) );
	}

	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.IVM_EXT != $pe.table && Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		Log.out( "MetadataManager.loadNotFound PersistanceEvent: " + $pe.toString(), Log.ERROR );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.FAILED, $pe.guid, null ) );
	}
	
}
}