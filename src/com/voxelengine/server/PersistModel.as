package com.voxelengine.server 
{
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.worldmodel.models.VoxelModelMetadata;
	
	public class PersistModel extends Persistance
	{
		static public const DB_TABLE_MODELS:String = "voxelModels";
		static public const DB_INDEX_MODEL_OWNER:String = "voxelModelOwner";
		static public const DB_INDEX_OWNER_TEMPLATE:String = "ownerTemplate"
		static private var _modifedDate:Date;
		
		static public function loadModel( $guid:String, $success:Function, $error:Function ):void {

			Persistance.loadObject( DB_TABLE_MODELS, $guid, $success, $error );
		}
		
		static public function deleteModel( $guid:String ):void {
			
			Persistance.deleteKeys( DB_TABLE_MODELS
			                      , [$guid]
								  , function():void
									{
										Log.out("PersistModel.deleteModel - deleted: " + $guid);
									}
								  , function(e:PlayerIOError):void
									{
										Log.out("PersistModel.deleteModel - error deleting: " + $guid + " error data: " + e);
									}
								  );
		}
		
		static public function createModel( $guid:String, $metadata:Object, $success:Function, $error:Function ):void {
				Persistance.createObject( DB_TABLE_MODELS
								        , $guid
								        , $metadata
								        , $success
								        , $error );
		}
		
		static public function loadModels( $userName:String ):void {
			
			Persistance.loadRange( DB_TABLE_MODELS
						 , DB_INDEX_MODEL_OWNER
						 , [$userName]
						 , null
						 , null
						 , 100
						, loadObjectsMetadata
						, function (e:PlayerIOError):void {  Log.out( "PersistModel.errorHandler - e: " + e ); } );
		}
		
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

		static private function loadObjectsMetadata( dba:Array ):void {
			
			for each ( var dbo:DatabaseObject in dba )
			{
				var vmm:VoxelModelMetadata = new VoxelModelMetadata();
				vmm.fromPersistance( dbo );
				if ( vmm.modifiedDate < _modifedDate ) {
					vmm = null;
					continue;
				}
				
				Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, vmm ) );
			}
		}
	}	
}
