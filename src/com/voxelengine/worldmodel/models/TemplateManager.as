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
	import com.voxelengine.server.PersistModel;
	import flash.utils.Dictionary;

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
		
		// this acts as a holding spot for templates models in game
		static private var _templates:Dictionary = new Dictionary(true);

		static public function templatesLoad():void {
			// This should get any new models
			if ( null == _modifiedDate )
				_modifiedDate = new Date( 2000, 1, 1, 12, 0, 0, 0 );
			PersistModel.loadModelTemplates( _modifiedDate );
			_modifiedDate = new Date();
			
			// This will return models already loaded.
			for each ( var vmm:VoxelModelMetadata in _templates ) {
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, vmm ) );
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
		static public function templateGet( $guid:String ):VoxelModelMetadata {  return _templates[$guid]; }
		static public function templateAdd( $vmm:VoxelModelMetadata ):void { _templates[$vmm.guid] = $vmm; }
	}
}