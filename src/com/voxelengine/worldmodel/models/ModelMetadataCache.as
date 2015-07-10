/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.Dictionary;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.ModelInfoEvent;
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
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_TYPE, 	requestType );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST, 		request );
		ModelMetadataEvent.addListener( ModelBaseEvent.UPDATE, 			update );
		ModelMetadataEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler );
		ModelMetadataEvent.addListener( ModelBaseEvent.GENERATION, 		generated );
		ModelMetadataEvent.addListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid );		
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );		
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  ModelMetadataEvent
	/////////////////////////////////////////////////////////////////////////////////////////////
	//static private function requestChildren( $mme:ModelMetadataEvent):void {
		//for each ( var mmd:ModelMetadata in _metadata ) {
			//if ( mmd && mmd.parentModelGuid == $mme.modelGuid )
				//ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.RESULT_CHILDREN, $mme.series, $mme.modelGuid, mmd ) );		
		//}
		//// this is the end of series message
		//ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.RESULT_CHILDREN, $mme.series, $mme.modelGuid, null ) );		
	//}
	
	// This loads the first 100 objects from the users inventory OR the public inventory
	static private function requestType( $mme:ModelMetadataEvent ):void {
		
		// For each one loaded this will send out a new ModelMetadataEvent( ModelBaseEvent.ADDED, $vmm.guid, $vmm ) event
		if ( Network.PUBLIC == $mme.modelGuid ) {
			if ( false == _initializedPublic ) {
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, Network.PUBLIC, null, Globals.BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER ) );
				_initializedPublic = true;
			}
		}
			
		if ( Network.userId == $mme.modelGuid ) {
			if ( false == _initializedPrivate ) {
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, Network.userId, null, Globals.BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER ) );
				_initializedPrivate = true;
			}
		}
			
		// This will return models already loaded.
		for each ( var vmm:ModelMetadata in _metadata ) {
			if ( vmm && vmm.owner == $mme.modelGuid )
				ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.RESULT, $mme.series, vmm.guid, vmm ) );
		}
	}
	
	static private function request( $mme:ModelMetadataEvent ):void {   
		if ( null == $mme.modelGuid ) {
			Log.out( "ModelMetadataCache.request guid rquested is NULL: ", Log.WARN );
			return;
		}
		//Log.out( "ModelMetadataCache.request guid: " + $mme.modelGuid, Log.INFO );
		var vmm:ModelMetadata = _metadata[$mme.modelGuid]; 
		if ( null == vmm )
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, $mme.modelGuid ) );
		else
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.RESULT, $mme.series, vmm.guid, vmm ) );
	}
	
	static private function update($mme:ModelMetadataEvent):void {
		if ( null == $mme || null == $mme.modelGuid ) {
			Log.out( "ModelMetadataCache.update trying to add NULL metadata or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		var vmm:ModelMetadata = _metadata[$mme.modelGuid];
		if ( null ==  vmm ) {
			Log.out( "ModelMetadataCache.update trying update NULL metadata or guid, adding instead", Log.WARN );
			add( 0, $mme.modelMetadata );
		} else {
			vmm.update( $mme.modelMetadata );
		}
	}
	
	static private function deleteHandler( $mme:ModelMetadataEvent ):void {
		var mmd:ModelMetadata = _metadata[$mme.modelGuid];
		if ( null != mmd ) {
			_metadata[$mme.modelGuid] = null; 
			// TODO need to clean up eventually
			mmd = null;
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, $mme.modelGuid, null ) );
		}
	}
	
	static private function generated( $mme:ModelMetadataEvent ):void  {
		add( 0, $mme.modelMetadata );
	}

	static private function updateGuid( $mme:ModelMetadataEvent ):void {
		var guidArray:Array = $mme.modelGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var modelMetadataExisting:ModelInfo = _metadata[oldGuid];
		if ( null == modelMetadataExisting ) {
			Log.out( "ModelMetadataCache.updateGuid - guid not found: " + oldGuid, Log.ERROR );
			return; }
		else {
			_metadata[oldGuid] = null;
			_metadata[newGuid] = modelMetadataExisting;
		}
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - ModelMetadataEvent
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Persistance Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	
	static private function loadSucceed( $pe:PersistanceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		if ( $pe.dbo ) {
			//Log.out( "ModelMetadataCache.loadSucceed guid: " + $pe.guid, Log.INFO );
			var vmm:ModelMetadata = new ModelMetadata( $pe.guid );
			vmm.fromPersistance( $pe.dbo );
			if ( $pe.data && true == $pe.data )
				vmm.dbo = null;
			add( $pe.series, vmm );
		}
		else {
			Log.out( "ModelMetadataCache.loadSucceed FAILED no DBO PersistanceEvent: " + $pe.toString(), Log.WARN );
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void  {
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		Log.out( "ModelMetadataCache.metadataLoadFailed PersistanceEvent: " + $pe.toString(), Log.ERROR );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}

	static private function loadNotFound( $pe:PersistanceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		Log.out( "ModelMetadataCache.loadNotFound PersistanceEvent: " + $pe.toString(), Log.ERROR );
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistance Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Internal Methods
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function add( $series:int, $vmm:ModelMetadata ):void { 
		if ( null == $vmm || null == $vmm.guid ) {
			Log.out( "ModelMetadataCache.add trying to add NULL metadata or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _metadata[$vmm.guid] ) {
			//Log.out( "ModelMetadataCache.add vmm: " + $vmm.modelGuid, Log.WARN );
			_metadata[$vmm.guid] = $vmm; 
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.ADDED, $series, $vmm.guid, $vmm ) );
		}
	}
}
}