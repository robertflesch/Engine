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
public class ModelMetadataCache
{
	static private var _initializedPublic:Boolean;
	static private var _initializedPrivate:Boolean;
	
	// this acts as a cache for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _metadata:Dictionary = new Dictionary(false);
	
	public function ModelMetadataCache() {	}
	
	static public function init():void {
		//ModelMetadataEvent.addListener( ModelMetadataEvent.LOAD, regionLoad ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.JOIN, requestServerJoin ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.CHANGED, regionChanged );	
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_TYPE, requestType );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST, request );
		ModelMetadataEvent.addListener( ModelBaseEvent.UPDATE, update );
		ModelMetadataEvent.addListener( ModelBaseEvent.CREATED, created );
		ModelMetadataEvent.addListener( ModelBaseEvent.DELETE, deleteHandler );

		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, loadNotFound );		
	}
	
	static private function deleteHandler( $mde:ModelMetadataEvent ):void {
		var mmd:ModelMetadata = _metadata[$mde.modelGuid];
		if ( null != mmd ) {
			_metadata[$mde.modelGuid] = null; 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, $mde.series, Globals.DB_TABLE_MODELS, $mde.modelGuid, mmd.dbo ) );
			mmd = null;
			// TODO need to clean up eventually
		}
	}
	
	static private function created($mme:ModelMetadataEvent):void  { add( 0, $mme.vmm ); }
	
	static private function update($mme:ModelMetadataEvent):void 
	{
		if ( null == $mme || null == $mme.modelGuid ) {
			Log.out( "MetadataManager.update trying to add NULL metadata or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		var vmm:ModelMetadata = _metadata[$mme.modelGuid];
		if ( null ==  vmm ) {
			Log.out( "MetadataManager.update trying update NULL metadata or guid, adding instead", Log.WARN );
			add( 0, $mme.vmm );
		} else {
			vmm.update( $mme.vmm );
		}
		
	}
	
	static private function request( $mme:ModelMetadataEvent ):void 
	{   
		if ( null == $mme.modelGuid ) {
			Log.out( "MetadataManager.request guid rquested is NULL: ", Log.WARN );
			return;
		}
		//Log.out( "MetadataManager.request guid: " + $mme.modelGuid, Log.INFO );
		var vmm:ModelMetadata = _metadata[$mme.modelGuid]; 
		if ( null == vmm )
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mme.series, Globals.DB_TABLE_MODELS, $mme.modelGuid ) );
		else
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.RESULT, $mme.series, vmm.modelGuid, vmm ) );
	}
	
	// This loads the first 100 objects from the users inventory OR the public inventory
	static private function requestType( $mme:ModelMetadataEvent ):void {
		
		// For each one loaded this will send out a new ModelMetadataEvent( ModelBaseEvent.ADDED, $vmm.guid, $vmm ) event
		if ( Network.PUBLIC == $mme.modelGuid ) {
			if ( false == _initializedPublic ) {
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, $mme.series, Globals.DB_TABLE_MODELS, Network.PUBLIC, null, Globals.DB_INDEX_VOXEL_MODEL_OWNER ) );
				_initializedPublic = true;
			}
		}
			
		if ( Network.userId == $mme.modelGuid ) {
			if ( false == _initializedPrivate ) {
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, $mme.series, Globals.DB_TABLE_MODELS, Network.userId, null, Globals.DB_INDEX_VOXEL_MODEL_OWNER ) );
				_initializedPrivate = true;
			}
		}
			
		// This will return models already loaded.
		for each ( var vmm:ModelMetadata in _metadata ) {
			if ( vmm && vmm.owner == $mme.modelGuid )
				ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.RESULT, $mme.series, vmm.modelGuid, vmm ) );
		}
	}
	
	static private function add( $series:int, $vmm:ModelMetadata ):void 
	{ 
		if ( null == $vmm || null == $vmm.modelGuid ) {
			Log.out( "MetadataManager.add trying to add NULL metadata or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _metadata[$vmm.modelGuid] ) {
			//Log.out( "ModelMetadataCache.add vmm: " + $vmm.toString(), Log.WARN );
			_metadata[$vmm.modelGuid] = $vmm; 
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.ADDED, $series, $vmm.modelGuid, $vmm ) );
		}
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.DB_TABLE_MODELS != $pe.table )
			return;
		if ( $pe.dbo ) {
			//Log.out( "MetadataManager.loadSucceed guid: " + $pe.guid, Log.INFO );
			var vmm:ModelMetadata = new ModelMetadata( $pe.guid );
			vmm.fromPersistance( $pe.dbo );
			if ( $pe.data && true == $pe.data )
				vmm.dbo = null;
			add( $pe.series, vmm );
		}
		else {
			Log.out( "MetadataManager.loadSucceed FAILED no DBO PersistanceEvent: " + $pe.toString(), Log.WARN );
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.DB_TABLE_MODELS != $pe.table || Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "MetadataManager.metadataLoadFailed PersistanceEvent: " + $pe.toString(), Log.ERROR );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}

	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.DB_TABLE_MODELS != $pe.table || Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "MetadataManager.loadNotFound PersistanceEvent: " + $pe.toString(), Log.ERROR );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
}
}