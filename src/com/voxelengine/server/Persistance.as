package com.voxelengine.server 
{
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.events.PersistanceEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.RegionLoadedEvent;
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.Region;
	import playerio.Client;
	import playerio.BigDB;
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
	import flash.utils.ByteArray;
		
	import com.voxelengine.Log;
	
	public class Persistance
	{
		static public const DB_TABLE_OBJECTS:String = "voxelModels";
		static public const DB_TABLE_REGIONS:String = "regions";
		static public const PUBLIC:String = "public";
		
		static private var _table:String;
		static private var _key:String;
		static private var _data:Object;
		static private var _successHandler:Function;
		static private var _errorHandler:Function;
		static private var _isCreate:Boolean;
		
		static public function deleteKeys( $table:String, $keys:Array, $successHandler:Function, $errorHandler:Function ):void {
			if ( Network.client )
			{
				Network.client.bigDB.deleteKeys( $table, $keys, $successHandler, $errorHandler );
			}
			else
			{
				$errorHandler( new PlayerIOError( "No connection", 0 ) );
			}
		}

		static public function createObject( $table:String, $key:String, $data:Object, $successHandler:Function, $errorHandler:Function ):void {
			if ( Network.client )
			{
				Network.client.bigDB.createObject( $table, $key, $data, $successHandler, $errorHandler );
			}
			else
			{
				Globals.g_app.stage.addEventListener( LoginEvent.LOGIN_SUCCESS, onLoginSuccessCreateObject );
				Globals.g_app.stage.addEventListener( LoginEvent.LOGIN_FAILURE, onLoginFailureCreateObject );
				_table = $table;
				_key = $key;
				_data = $data;
				_successHandler = $successHandler;
				_errorHandler = $errorHandler;
				_isCreate = true;
				new WindowLogin();
			}
		}
		
		static public function loadObject( $table:String, $key:String, $successHandler:Function, $errorHandler:Function ):void {
			if ( Network.client )
				Network.client.bigDB.load( $table, $key, $successHandler, $errorHandler );
			else
			{
				Globals.g_app.stage.addEventListener( LoginEvent.LOGIN_SUCCESS, onLoginSuccessCreateObject );
				Globals.g_app.stage.addEventListener( LoginEvent.LOGIN_FAILURE, onLoginFailureCreateObject );
				_table = $table;
				_key = $key;
				_successHandler = $successHandler;
				_errorHandler = $errorHandler;
				_isCreate = false;
				new WindowLogin();
			}
		}
		
		static public function loadKeys( $table:String, $key:Array, $successHandler:Function, $errorHandler:Function ):void {
			if ( Network.client )
				Network.client.bigDB.loadKeys( $table, $key , $successHandler, $errorHandler );
			else
			{
				$errorHandler( new PlayerIOError( "LoadKeys", 0 ) );
			}
		}
		
		static public function loadRange( $table:String, $index:String, $path:Array, $start:Object, $stop:Object, $limit:int, $successHandler:Function, $errorHandler:Function ):void {
			/*
			 * Load a range of DatabaseObjects from a table using the specified index.
			 * @param table The table to load the DatabaseObject from
			 * @param index The name of the index to query for the DatabaseObject
			 * @param path Where in the index to start the range search: An array of objects of the same types as the index properties, specifying where in the index to start loading DatabaseObjects from. For instance, in the index [Mode,Map,Score] you might use ["expert","skyland"] as the indexPath and use the start and stop arguments to determine the range of scores you wish to return. IndexPath can be set to null if there is only one property in the index.
			 * @param start Where to start the range search. For instance, if the index is [Mode,Map,Score] and indexPath is ["expert","skyland"], then start defines the minimum score to include in the results
			 * @param stop Where to stop the range search. For instance, if the index is [Mode,Map,Score] and indexPath is ["expert","skyland"], then stop defines the maximum score to include in the results
			 * @param limit The max amount of objects to return
			 * @param callback Function executed when the DatabaseObjects are successfully loaded: An array of DatabaseObjects are passed to the method: function(dbarr:Array):void{...}
			 * @param errorHandler Function executed if an error occurs while loading the DatabaseObjects
			 * 
			function loadRange(table:String, index:String, path:Array, start:Object, stop:Object,  limit:int, callback:Function=null, errorHandler:Function=null):void;
			*/

			if ( Network.client )
				Network.client.bigDB.loadRange( $table, $index , $path, $start, $stop,  $limit, $successHandler, $errorHandler );
			else
			{
				$errorHandler( new PlayerIOError( "LoadKeys", 0 ) );
			}
		}
		
		static private function onLoginSuccessCreateObject(event : LoginEvent ) : void {
			Globals.g_app.stage.removeEventListener( LoginEvent.LOGIN_SUCCESS, onLoginSuccessCreateObject );
			if ( _isCreate )
			{
				if ( Network.client )
					Network.client.bigDB.createObject( _table, _key, _data, _successHandler, _errorHandler );
				else
				{
					//Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.BIGDB_CONNECTION_FAILURE ) );
					_errorHandler( event.error );
					Log.out( "Persistance.onLoginSuccessCreateObject.createObject - ERROR - ERROR - ERROR Login Failure", Log.ERROR );
				}
			}
			else
			{
				if ( Network.client )
					Network.client.bigDB.load( _table, _key, _successHandler, _errorHandler );
				else
				{
					_errorHandler( event.error );
					Log.out( "Persistance.onLoginSuccessCreateObject.loadObject - ERROR - ERROR - ERROR Login Failure", Log.ERROR );
				}
			}
		}
		
		static private function onLoginFailureCreateObject(event : LoginEvent ) : void {
			Globals.g_app.stage.removeEventListener( LoginEvent.LOGIN_FAILURE, onLoginFailureCreateObject );
			if ( _isCreate )
				Log.out( "Persistance.onLoginFailureCreateObject.createObject - ERROR - ERROR - ERROR Login Failure", Log.ERROR );
			else	
				Log.out( "Persistance.onLoginFailureCreateObject.loadObject - ERROR - ERROR - ERROR Login Failure", Log.ERROR );
				
			_errorHandler( event.error );	
		}

		///////////////// REGION ////////////////////////////////
		static public function loadRegions( $userName:String ):void {
			
			loadRange( Persistance.DB_TABLE_REGIONS
						 , "regionOwner"
						 , [$userName]
						 , null
						 , null
						 , 100
						, loadRegionKeysSuccessHandler
						, function (e:PlayerIOError):void {  Log.out( "Persistance.errorHandler - e: " + e ); } );
		}
		
		static private function loadRegionKeysSuccessHandler( dba:Array ):void {
			
			trace( "Persistance.loadKeysSuccessHandler - regions loaded: " + dba.length );
			for each ( var dbo:DatabaseObject in dba )
			{
				loadRegionFromDBO( dbo );
			}
		}
		
		// comma seperated variables
		static private function cvsToVector( value:String ):Vector.<String> {
			var v:Vector.<String> = new Vector.<String>;
			var start:int = 0;
			var end:int = value.indexOf( ",", 0 );
			while ( -1 < end ) {
				v.push( value.substring( start, end ) );
				start = end + 1;
				end = value.indexOf( ",", start );
			}
			// there is only one, or this is the last one
			if ( -1 == end && start < value.length ) {
				v.push( value.substring( start, value.length ) );
			}
			return v;
		}
		
		static private function loadRegionFromDBO( dbo:DatabaseObject):void
		{
			var newRegion:Region = new Region( dbo.key );
			newRegion.admin = cvsToVector( dbo.admin );
			newRegion.databaseObject = dbo;
			newRegion.desc = dbo.description;
			newRegion.name = dbo.name;
			newRegion.owner = dbo.owner
			newRegion.worldId = dbo.world;
			newRegion.editors = cvsToVector( dbo.editors );
			newRegion.created = dbo.created;
			newRegion.modified = dbo.modified;
			var $ba:ByteArray = dbo.data as ByteArray;
			
//			Log.out( "Persistance.loadFromDBO - regionJson: " + newRegion.name + "  owner: " + newRegion.owner );
			
			$ba.uncompress();
			$ba.position = 0;
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var regionJson:String = $ba.readUTFBytes( strLen );
			//regionJson = decodeURI(regionJson);
			newRegion.processRegionJson( regionJson );
			
			// Now that we have a fully formed region, inform the region manager
			Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_CREATED, newRegion ) );
		}

		static public function saveRegion( $metadata:Object, $dbo:DatabaseObject, $createSuccess:Function ):void {

			if ( $dbo )
			{
//				Log.out( "Persistance.save - saving region back to BigDB: " + $metadata.guid );
				$dbo.data = $metadata.data;
				$dbo.admin = $metadata.admin;
				$dbo.description = $metadata.desc;
				$dbo.editors = $metadata.editors;
				$dbo.modified = new Date();
				$dbo.name = $metadata.name;
				//$dbo.owner = $metadata.owner;  // Do not think this should be allowed to change under normal circumstances
				$dbo.world = $metadata.world;
				
				$dbo.save( false
					     , false
					     , function saveRegionSuccess():void  {  Log.out( "Persistance.saveRegionSuccess" ); }	
					     , function saveRegionFailed(e:PlayerIOError):void  { 
							Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_SAVE_FAILURE ) ); 
							Log.out( "Persistance.saveRegionFailed - error data: " + e); }  
						);
			}
			else
			{
				Log.out( "Persistance.create - creating new region: " + $metadata.guid + "" );
				createObject( Persistance.DB_TABLE_REGIONS
							, $metadata.guid
							, $metadata
							, $createSuccess
							, function createFailed(e:PlayerIOError):void { 
								Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_CREATE_FAILURE ) ); 
								Log.out( "Persistance.createFailed - error saving: " + $metadata.guid + " error data: " + e);  }
							);
			}
			
		}
		
		///////////////// MODELS ////////////////////////////////
		static public function loadUserObjectsMetadata( userName:String ):void {
			Persistance.loadRange( Persistance.DB_TABLE_OBJECTS
						 , "voxelModelOwner"
						 , [userName]
						 , null
						 , null
						 , 100
						, loadObjectsMetadata
						, function (e:PlayerIOError):void {  Log.out( "ModelManager.errorHandler - e: " + e ); } );
		}
		
		static public function loadPublicObjectsMetadata():void {
			Persistance.loadRange( Persistance.DB_TABLE_OBJECTS
						 , "voxelModelOwner"
						 , [Persistance.PUBLIC]
						 , null
						 , null
						 , 100
						, loadObjectsMetadata
						, function (e:PlayerIOError):void {  Log.out( "ModelManager.errorHandler - e: " + e ); } );
		}

		static private function loadObjectsMetadata( dba:Array ):void
		{
			for each ( var dbo:DatabaseObject in dba )
			{
				loadModelMetadataFromDBO( dbo );
			}
		}
		
		static private function loadModelMetadataFromDBO( dbo:DatabaseObject):void
		{
			var name:String = dbo.name;
			var description:String = dbo.description;
			var key:String = dbo.key;
			var owner:String = dbo.owner;
			var ba:ByteArray = dbo.data;
			var dbo:DatabaseObject = dbo;
			var template:Boolean = dbo.template;
			
			Log.out( "Persistance.loadModelMetadataFromDBO - name: " + name + "  description: " + description + "  key: " + key + "  owner: " + owner );
			
			Globals.g_app.dispatchEvent( new ModelMetadataEvent( ModelMetadataEvent.INFO_LOADED_PERSISTANCE, name, description, key, owner, template, ba, dbo ) );
		}
		///////////////// MODELS ////////////////////////////////
	}	
}
