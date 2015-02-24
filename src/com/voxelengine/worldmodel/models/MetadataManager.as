/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.events.ModelMetadataPersistanceEvent;
import com.voxelengine.events.ModelDataPersistanceEvent;
import com.voxelengine.events.PersistanceEvent;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import flash.events.Event;
import flash.events.EventDispatcher;

import playerio.DatabaseObject;
import playerio.generated.PlayerIOError;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
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
		//ModelMetadataEvent.addListener( ModelMetadataEvent.REGION_LOAD, regionLoad ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.REQUEST_JOIN, requestServerJoin ); 
		//ModelMetadataEvent.addListener( ModelMetadataEvent.REGION_CHANGED, regionChanged );	
		ModelMetadataEvent.addListener( ModelMetadataEvent.TYPE_REQUEST, modelMetadataTypeRequest );
		ModelMetadataEvent.addListener( ModelMetadataEvent.REQUEST, modelMetadataRequest );
		
		ModelMetadataPersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, metadataLoadSucceed );
		ModelMetadataPersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, metadataLoadFailed );
		
		ModelDataPersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, dataLoadSucceed );
		ModelDataPersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, dataLoadFailed );
		
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
			ModelMetadataPersistanceEvent.dispatch( new ModelMetadataPersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mme.guid ) );
		else
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.ADDED, vmm.guid, vmm ) );
	}
	
	// This loads the first 100 objects from the users inventory and the public inventory
	static private function modelMetadataTypeRequest( $mme:ModelMetadataEvent ):void {
		
		if ( false == _initialized ) {
			ModelMetadataPersistanceEvent.dispatch( new ModelMetadataPersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Network.userId ) );
			ModelMetadataPersistanceEvent.dispatch( new ModelMetadataPersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Network.PUBLIC ) );
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
	
	static private function metadataLoadSucceed( $mmpe:ModelMetadataPersistanceEvent):void 
	{
		Log.out( "MetadataManager.metadataLoadSucceed $mmpe: " + $mmpe.guid, Log.WARN );
		var vmm:VoxelModelMetadata = new VoxelModelMetadata();
		if ( $mmpe.dbo ) {
			vmm.fromPersistanceMetadata( $mmpe.dbo );
			metadataAdd( vmm );
		}
		else {
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.FAILED, null, null ) );
		}
	}
	
	static private function metadataLoadFailed( $mmpe:ModelMetadataPersistanceEvent ):void 
	{
		Log.out( "MetadataManager.metadataLoadFailed vmm: ", Log.ERROR );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  DATA
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function modelDataRequest( $mde:ModelDataEvent ):void 
	{   
		if ( null == $mde.guid ) {
			Log.out( "MetadataManager.modelDataRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		
		var vmd:VoxelModelData = _data[$mde.guid]; 
		if ( null == vmd )
			ModelDataPersistanceEvent.dispatch( new ModelDataPersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mde.guid ) );
		else
			ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.ADDED, vmd.guid, vmd ) );
	}
	
	static private function dataAdd( $vmd:VoxelModelData ):void 
	{ 
		if ( null == $vmd || null == $vmd.guid || null == $vmd.dbo ) {
			Log.out( "MetadataManager.dataAdd trying to add VoxelModelData", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _data[$vmd.guid] ) {
			Log.out( "MetadataManager.dataAdd vmd: " + $vmd.guid, Log.WARN );
			_metadata[$vmd.guid] = $vmd; 
			ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.ADDED, $vmd.guid, $vmd ) );
		}
	}
	
	static private function dataLoadSucceed(e:ModelDataPersistanceEvent):void 
	{
		Log.out( "MetadataManager.dataLoadSucceed guid: " + e.dbo , Log.WARN );
		if ( e.dbo ) {
			var vmd:VoxelModelData = new VoxelModelData( e.dbo.key, e.dbo );
			dataAdd( vmd );
		}
		else {
			ModelDataEvent.dispatch( new ModelDataEvent( ModelDataEvent.FAILED, null, null ) );
		}
	}
	
	static private function dataLoadFailed(e:ModelDataPersistanceEvent):void 
	{
		Log.out( "MetadataManager.metadataLoadFailed vmm: ", Log.ERROR );
	}

}
}