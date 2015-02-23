/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.persistance 
{
	import com.voxelengine.events.ModelPersistanceEvent;
	import com.voxelengine.persistance.Persistance;
	import com.voxelengine.worldmodel.models.MetadataManager;
	import flash.utils.ByteArray;
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	
	public class PersistModel
	{
		static public const DB_TABLE_MODELS:String = "voxelModels";
		static public const DB_TABLE_MODELS_DATA:String = "voxelModelsData";
		static public const DB_INDEX_MODEL_OWNER:String = "voxelModelOwner";
		static public const DB_INDEX_OWNER_TEMPLATE:String = "ownerTemplate"
		static private var _modifedDate:Date;
		
		//////////////////////////////////////////////////////////////////////
		// TO PERSISTANCE
		//////////////////////////////////////////////////////////////////////
		static public function save( $dbo:DatabaseObject ):void {
			
			Persistance.saveObject( $dbo, saved, failed );
				
			function saved():void 
			{ 
				Log.out("PersistModel.saveModel.saved - saving changes to guid: " + $dbo.key );
			}	
			
			function failed( $e:PlayerIOError ):void 
			{ 
				Log.out( "PersistModel.saveModel.failed - error saving changes to guid: " + $dbo.key + " error: " + $e.message, Log.ERROR, $e )
				// seems like this MIGHT throw it in an endless loop
			} 
		}
		
		static public function create( $table:String, $guid:String, $metadata:Object ):void {
			Persistance.createObject( $table
									, $guid
									, $metadata
									, created
									, failed );

			function created( dbo:DatabaseObject ):void 
			{ 
				if ( dbo ) {
					var vmm:VoxelModelMetadata = MetadataManager.metadataGet( dbo.key )
					if ( vmm ) {
						Log.out( "PersistModel.createModel.created: " + dbo.key ); 
//						MetadataManager.dispatch( new ModelPersistanceEvent( ModelPersistanceEvent.MODEL_CREATE_SUCCEED, $guid, dbo ) );
					}
					else {
						Log.out( "PersistModel.createModel.created Failed to find voxelmodelmetadata: " + $guid, Log.ERROR ); 
//						MetadataManager.dispatch( new ModelPersistanceEvent( ModelPersistanceEvent.MODEL_CREATE_FAILED, $guid, dbo ) );
					}
				}
				else {
					// This should never happen
					Log.out( "PersistModel.createModel.created ERROR Unknown unable to save guid: " + $guid, Log.ERROR ); 
//					MetadataManager.dispatch( new ModelPersistanceEvent( ModelPersistanceEvent.MODEL_CREATE_FAILED, $guid, null ) );
				}
			}	
			
			function failed( $e:PlayerIOError ):void 
			{ 
				Log.out( "PersistModel.createModel.failed - error saving changes to guid: " + $guid + " error: " + $e.message, Log.ERROR, $e )
//				MetadataManager.dispatch( new ModelPersistanceEvent( ModelPersistanceEvent.MODEL_CREATE_FAILED, $guid, null ) );
				// seems like this MIGHT throw it in an endless loop
			} 
		}
		/*
		static public function createModelData( $guid:String, $data:ByteArray, $success:Function, $error:Function ):void {
				Persistance.createObject( DB_TABLE_MODELS_DATA
								        , $guid
								        , $data
								        , $success
								        , $error );
		}
		*/
		
		//////////////////////////////////////////////////////////////////////
		// FROM PERSISTANCE
		//////////////////////////////////////////////////////////////////////
		static public function loadModel( $guid:String, $success:Function, $error:Function ):void {

			Persistance.loadObject( DB_TABLE_MODELS, $guid, $success, $error );
		}
		
		static public function loadModelsMetadata( $userName:String, $startDate:Date ):void {
			
			Persistance.loadRange( DB_TABLE_MODELS
						 , DB_INDEX_MODEL_OWNER
						 , [$userName]
						 , $startDate
						 , new Date()
						 , 100
						, loadObjectsMetadata
						, loadModelsError );
						
			function loadModelsError(e:PlayerIOError):void {
				Log.out( "PersistModel.loadModelsError - e: " + e, Log.ERROR );
			}
		}
/*
		static public function loadModelTemplates( $userName:String, $modifiedDate:Date ):void {
			
			_modifedDate = $modifiedDate;
			Persistance.loadRange( DB_TABLE_MODELS
						 , DB_INDEX_OWNER_TEMPLATE
						 , [$userName]
						 , true
						 , null
						 , 100
						, loadObjectsMetadata
						, function (e:PlayerIOError):void {  Log.out( "PersistModel.errorHandler - e: " + e ); } );
						
		}
*/

		static private function loadObjectsData( dba:Array ):void {
			
			for each ( var dbo:DatabaseObject in dba )
			{
				var key:String = dbo.key;
				var vmm:VoxelModelMetadata = MetadataManager.metadataGet( key );
				if ( vmm ) {
					vmm.fromPersistanceData( dbo );
					MetadataManager.dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_DATA_PERSISTANCE, vmm ) );
				}
				else
					MetadataManager.dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_DATA_PERSISTANCE, vmm ) );
			}
		}
		
		static private function loadObjectsMetadata( dba:Array ):void {
			
			for each ( var dbo:DatabaseObject in dba )
			{
				var vmm:VoxelModelMetadata = new VoxelModelMetadata();
				vmm.fromPersistanceMetadata( dbo );
				if ( vmm.modifiedDate < _modifedDate ) {
					vmm = null;
					continue;
				}
				
				MetadataManager.dispatch( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, vmm ) );
			}
		}
		
		//static public function deleteModel( $guid:String ):void {
			//
			//Persistance.deleteKeys( DB_TABLE_MODELS
			                      //, [$guid]
								  //, function():void
									//{
										//Log.out("PersistModel.deleteModel - deleted: " + $guid);
									//}
								  //, function(e:PlayerIOError):void
									//{
										//Log.out("PersistModel.deleteModel - error deleting: " + $guid + " error data: " + e);
									//}
								  //);
		//}
		
	}	
}
