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

import flash.events.Event;
import flash.events.EventDispatcher;

import playerio.DatabaseObject;
import playerio.generated.PlayerIOError;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.server.PersistModel;

/**
 * ...
 * @author Bob
 */
public class MetadataManager
{
	// Used to distribue all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();
	
	///////////////// Event handler interface /////////////////////////////

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}
	
	static public function dispatch( $event:Event) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
	
	static private var _modifiedDate:Date; // The date range used for loading from persistance, this is the oldest model to get. Gets updated each time it is used
	static private var _guidError:String;
	
	// this acts as a holding spot for templates models in game
	static private var _metadata:Dictionary = new Dictionary(true);
	
	static private function metadataAdd( $vmm:VoxelModelMetadata ):void 
	{ 
		if ( $vmm && null ==  _metadata[$vmm.guid] ) {
			Log.out( "MetadataManager.metadataAdd vmm: " + $vmm.toString(), Log.WARN );
			_metadata[$vmm.guid] = $vmm; 
			dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_TEMPLATE_REPO, $vmm ) );
		}
	}

	static public function metadataLoad():void {
		// This should get any new models
		if ( null == _modifiedDate )
			_modifiedDate = new Date( 2000, 1, 1, 12, 0, 0, 0 );
		Log.out( "MetadataManager.metadataLoad _modifiedDate: " + _modifiedDate.toString(), Log.DEBUG );
		PersistModel.loadModelTemplates( Network.userId, _modifiedDate );
		PersistModel.loadModelTemplates( Network.PUBLIC, _modifiedDate );
		_modifiedDate = new Date();
		
		// This will return models already loaded.
		for each ( var vmm:VoxelModelMetadata in _metadata ) {
			dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_TEMPLATE_REPO, vmm ) );
		}
	}
	
	static public function metadataGetAll():Dictionary { return _metadata; }
	static public function metadataGet( $guid:String ):VoxelModelMetadata 
	{   
		Log.out( "MetadataManager.metadataGet guid: " + $guid, Log.WARN );
		var vmm:VoxelModelMetadata = _metadata[$guid]; 
		if ( null == vmm ) {
			_guidError = $guid;
			PersistModel.loadModel( $guid, loadSuccess, loadFailure );
		}
		return vmm; 
	}
	
	static private function loadSuccess( dbo:DatabaseObject ):void {
		
		var vmm:VoxelModelMetadata = new VoxelModelMetadata();
		if ( dbo ) {
			vmm.fromPersistance( dbo );
			metadataAdd( vmm );
			Log.out( "MetadataManager.templateLoadSuccess vmm: " + vmm.toString(), Log.WARN );
			dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, vmm ) );
		}
		else {
			vmm.guid = _guidError;
			dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, vmm ) );
		}
	}
	
	static private function loadFailure( $error:PlayerIOError ):void {
		
		Log.out( "MetadataManager.templateLoadFailure - error: " + $error.message, Log.ERROR, $error );
		var vmm:VoxelModelMetadata = new VoxelModelMetadata();
		vmm.guid = _guidError;
		dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, vmm ) );
	}
}
}