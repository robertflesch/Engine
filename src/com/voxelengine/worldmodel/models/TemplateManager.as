/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.server.PersistModel;
	import flash.utils.Dictionary;
	import playerio.DatabaseObject;
	import playerio.generated.PlayerIOError;

	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.VoxelModel;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class TemplateManager 
	{
		static private var _modifiedDate:Date;
		static private var _initialized:Boolean;
		static private var _guidError:String;
		
		// this acts as a holding spot for templates models in game
		static private var _templates:Dictionary = new Dictionary(true);
		
		static public function templateAdd( $vmm:VoxelModelMetadata ):void 
		{ 
			Log.out( "TemplateManager.templateAdd vmm: " + $vmm.toString(), Log.DEBUG );
			_templates[$vmm.guid] = $vmm; 
			Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_TEMPLATE_REPO, $vmm ) );
		}

		static public function templatesLoad():void {
			// This should get any new models
			if ( null == _modifiedDate )
				_modifiedDate = new Date( 2000, 1, 1, 12, 0, 0, 0 );
			Log.out( "TemplateManager.templatesLoad _modifiedDate: " + _modifiedDate.toString(), Log.DEBUG );
			PersistModel.loadModelTemplates( Network.userId, _modifiedDate );
			PersistModel.loadModelTemplates( Network.PUBLIC, _modifiedDate );
			_modifiedDate = new Date();
			
			// This will return models already loaded.
			for each ( var vmm:VoxelModelMetadata in _templates ) {
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_TEMPLATE_REPO, vmm ) );
			}
		}
		
		static public function addEvents():void { 
			if ( _initialized )
				return;
			
			_initialized = true;
			Globals.g_app.addEventListener( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, templateLoaded );
		}
		
		static public function templateLoaded( $e:ModelMetadataEvent ):void {
			templateAdd( $e.vmm );
		}
		
		static public function templateGetDictionary():Dictionary { return _templates; }
		static public function templateGet( $guid:String ):VoxelModelMetadata 
		{   
			var vmm:VoxelModelMetadata = _templates[$guid]; 
			if ( null == vmm ) {
				_guidError = $guid;
				PersistModel.loadModel( $guid, templateLoadSuccess, templateLoadFailure );
			}
			return vmm; 
		}
		
		static private function templateLoadSuccess( dbo:DatabaseObject ):void {
			
			var vmm:VoxelModelMetadata = new VoxelModelMetadata();
			if ( dbo ) {
				vmm.fromPersistance( dbo );
				Log.out( "TemplateManager.templateLoadSuccess vmm: " + vmm.toString(), Log.DEBUG );
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, vmm ) );
			}
			else {
				vmm.guid = _guidError;
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, vmm ) );
			}
		}
		
		static private function templateLoadFailure( $error:PlayerIOError ):void {
			
			Log.out( "TemplateManager.templateLoadFailure - error: " + $error.message, Log.ERROR, $error );
			var vmm:VoxelModelMetadata = new VoxelModelMetadata();
			vmm.guid = _guidError;
			Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_FAILED_PERSISTANCE, vmm ) );
		}
	}
}