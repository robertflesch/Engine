/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import flash.utils.Dictionary;
	
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
		static private var _modifiedDate:Date;
		static private var _initialized:Boolean;
		static private var _guidError:String;
		
		// this acts as a holding spot for templates models in game
		static private var _metadata:Dictionary = new Dictionary(true);
		
		static private function metadataAdd( $vmm:VoxelModelMetadata ):void 
		{ 
			if ( $vmm && null ==  _metadata[$vmm.guid] ) {
				Log.out( "MetadataManager.metadataAdd vmm: " + $vmm.toString(), Log.WARN );
				_metadata[$vmm.guid] = $vmm; 
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_TEMPLATE_REPO, $vmm ) );
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
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_TEMPLATE_REPO, vmm ) );
			}
		}
		
		static public function addEvents():void { 
			if ( _initialized )
				return;
			
			_initialized = true;
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
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, vmm ) );
			}
			else {
				vmm.guid = _guidError;
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, vmm ) );
			}
		}
		
		static private function loadFailure( $error:PlayerIOError ):void {
			
			Log.out( "MetadataManager.templateLoadFailure - error: " + $error.message, Log.ERROR, $error );
			var vmm:VoxelModelMetadata = new VoxelModelMetadata();
			vmm.guid = _guidError;
			Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, vmm ) );
		}
	}
}