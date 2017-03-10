/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.Dictionary;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.server.Network;

import com.voxelengine.utils.JSONUtil;
import com.voxelengine.utils.StringUtils;

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
	static private var _block:Block = new Block();
	
	public function ModelMetadataCache() {	}
	
	static public function init():void {
		ModelMetadataEvent.addListener( ModelBaseEvent.EXISTS_REQUEST, 	checkIfExists );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST_TYPE, 	requestType );
		ModelMetadataEvent.addListener( ModelBaseEvent.REQUEST, 		request );
		ModelMetadataEvent.addListener( ModelBaseEvent.UPDATE, 			update );
		ModelMetadataEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler );
		//ModelMetadataEvent.addListener( ModelBaseEvent.GENERATION, 		generated );
		ModelMetadataEvent.addListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid );		
		
		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
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
		
		//Log.out( "ModelMetadataCache.requestType  owner: " + $mme.modelGuid, Log.WARN );
		// For each one loaded this will send out a new ModelMetadataEvent( ModelBaseEvent.ADDED, $vmm.guid, $vmm ) event
		if ( Network.PUBLIC == $mme.modelGuid ) {
			if ( false == _initializedPublic ) {
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, Network.PUBLIC, null, Globals.BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER ) );
				_initializedPublic = true;
			}
		}
			
		if ( Network.userId == $mme.modelGuid ) {
			if ( false == _initializedPrivate ) {
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, Network.userId, null, Globals.BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER ) );
				_initializedPrivate = true;
			}
		}
			
		// This will return models already loaded.
		for each ( var vmm:ModelMetadata in _metadata ) {
			if ( vmm && vmm.owner == $mme.modelGuid ) {
				//Log.out( "ModelMetadataCache.requestType returning guid: " + vmm.guid + "  owner: " + vmm.owner, Log.WARN );
				ModelMetadataEvent.create( ModelBaseEvent.RESULT, $mme.series, vmm.guid, vmm );
			}
			//else 
			//	Log.out( "ModelMetadataCache.requestType REJECTING guid: " + vmm.guid + "  owner: " + vmm.owner, Log.WARN );
		}
	}
	
	static private function request( $mme:ModelMetadataEvent ):void {
		if ( null == $mme || null == $mme.modelGuid ) { // Validator
			Log.out( "ModelMetadataCache.request - event or guid is NULL: ", Log.ERROR );
			ModelMetadataEvent.create( ModelBaseEvent.EXISTS_ERROR, ( $mme ? $mme.series: -1 ), "MISSING", null );
		} else {
			//Log.out( "ModelMetadataCache.request guid: " + $mme.modelGuid, Log.INFO );
			var vmm:ModelMetadata = _metadata[$mme.modelGuid];
			if (null == vmm) {
				if (_block.has($mme.modelGuid))
					return;
				_block.add($mme.modelGuid);
				PersistenceEvent.dispatch(new PersistenceEvent(PersistenceEvent.LOAD_REQUEST, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, $mme.modelGuid));
			}
			else {
				//Log.out( "ModelMetadataCache.request returning guid: " + vmm.guid + "  owner: " + vmm.owner, Log.WARN );
				ModelMetadataEvent.create(ModelBaseEvent.RESULT, $mme.series, vmm.guid, vmm);
			}
		}
	}

	static private function checkIfExists( $mme:ModelMetadataEvent ):void {
		if ( null == $mme || null == $mme.modelGuid ) { // Validator
			Log.out( "ModelMetadataCache.checkIfExists - event or guid is NULL: ", Log.ERROR );
			ModelMetadataEvent.create( ModelBaseEvent.EXISTS_ERROR, ( $mme ? $mme.series: -1 ), "MISSING", null );
		} else {
			var vmm:ModelMetadata = _metadata[$mme.modelGuid];
			if (null != vmm)
				ModelMetadataEvent.create(ModelBaseEvent.EXISTS, $mme.series, $mme.modelGuid, vmm);
			else
				ModelMetadataEvent.create(ModelBaseEvent.EXISTS_FAILED, $mme.series, $mme.modelGuid, null);
		}
	}

	
	static private function update($mme:ModelMetadataEvent):void {
		if ( null == $mme || null == $mme.modelGuid ) { // Validator
			Log.out("ModelMetadataCache.update - event or guid is NULL: ", Log.ERROR);
			ModelMetadataEvent.create(ModelBaseEvent.EXISTS_ERROR, ( $mme ? $mme.series : -1 ), "MISSING", null);
		} else {
			// check to make sure is not already there
			var vmm:ModelMetadata = _metadata[$mme.modelGuid];
			if ( null ==  vmm ) {
				Log.out( "ModelMetadataCache.update trying update NULL metadata or guid, adding instead", Log.WARN );
				add( 0, $mme.modelMetadata );
			} else {
				vmm.update( $mme.modelMetadata );
			}
		}
	}
	
	static private function deleteHandler( $mme:ModelMetadataEvent ):void {
		if ( null == $mme || null == $mme.modelGuid ) { // Validator
			Log.out("ModelMetadataCache.deleteHandler - event or guid is NULL: ", Log.ERROR);
			ModelMetadataEvent.create(ModelBaseEvent.EXISTS_ERROR, ( $mme ? $mme.series : -1 ), "MISSING", null);
		} else {
			//Log.out( "ModelMetadataCache.deleteHandler $mme: " + $mme, Log.WARN );
			var mmd:ModelMetadata = _metadata[$mme.modelGuid];
			if (null != mmd) {
				_metadata[$mme.modelGuid] = null;
				// TODO need to clean up eventually
				mmd = null;
				//Log.out( "ModelMetadataCache.deleteHandler making call to PersistenceEvent", Log.WARN );
			}
			PersistenceEvent.dispatch(new PersistenceEvent(PersistenceEvent.DELETE_REQUEST, $mme.series, Globals.BIGDB_TABLE_MODEL_METADATA, $mme.modelGuid, null));
		}
	}
	
	static private function updateGuid( $mme:ModelMetadataEvent ):void {
		var guidArray:Array = $mme.modelGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var modelMetadataExisting:ModelMetadata = _metadata[oldGuid];
		if ( null == modelMetadataExisting ) {
			//Log.out( "ModelMetadataCache.updateGuid - guid not found: " + oldGuid, Log.WARN );
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
	//  Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	
	static private function loadSucceed( $pe:PersistenceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;

		var vmm:ModelMetadata = _metadata[$pe.guid];
		if ( null != vmm ) {
			// we already have it, publishing this results in dulicate items being sent to inventory window.
			//ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.RESULT, $pe.series, $pe.guid, vmm ) );
			Log.out( "ModelMetadataCache.loadSucceed - attempting to load duplicate ModelMetadata guid: " + $pe.guid, Log.WARN );
			return;
		}

		if ( $pe.dbo ) {
			vmm = new ModelMetadata( $pe.guid, $pe.dbo );
			add( $pe.series, vmm );
		} else if ( $pe.data ) {
 			// This is for cloning and importing existing objects only.
			var fileData:String = String( $pe.data );
			fileData = StringUtils.trim(fileData);
			var newData:Object = JSONUtil.parse( fileData, $pe.guid + $pe.table, "ModelMetadataEvent.loadSucceed" );
			if ( null == newData ) {
				Log.out( "ModelMetadataCache.loadSucceed - error parsing ModelMetadata on import. guid: " + $pe.guid, Log.ERROR );
				ModelMetadataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null );
				return;
			}
			vmm = new ModelMetadata( $pe.guid, null, newData );
			add( $pe.series, vmm );
		} else {
			Log.out( "ModelMetadataCache.loadSucceed NO oxelPersistence or DBO PersistenceEvent: " + $pe.toString(), Log.WARN );
			ModelMetadataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
		}

	}
	
	static private function loadFailed( $pe:PersistenceEvent ):void  {
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		Log.out( "ModelMetadataCache.metadataLoadFailed PersistenceEvent: " + $pe.toString(), Log.ERROR );
		ModelMetadataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}

	static private function loadNotFound( $pe:PersistenceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		Log.out( "ModelMetadataCache.loadNotFound PersistenceEvent: " + $pe.toString(), Log.WARN );
		ModelMetadataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistence Events
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
			//Log.out( "ModelMetadataCache.add vmm: " + $vmm.guid, Log.WARN );
			_metadata[$vmm.guid] = $vmm; 
			if ( _block.has( $vmm.guid ) )
				_block.clear( $vmm.guid )
			//Log.out( "ModelMetadataCache.add returning guid: " + $vmm.guid + "  owner: " + $vmm.owner, Log.WARN );
			ModelMetadataEvent.create( ModelBaseEvent.ADDED, $series, $vmm.guid, $vmm );
		}
	}
}
}