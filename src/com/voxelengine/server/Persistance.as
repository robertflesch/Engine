package com.voxelengine.server 
{
	import flash.events.EventDispatcher;
	import playerio.Client;
	import playerio.BigDB;
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
		
	//import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	public class Persistance
	{
		static private var _table:String;
		static private var _key:String;
		static private var _data:Object;
		static private var _successHandler:Function;
		static private var _errorHandler:Function;
		static private var _isCreate:Boolean;
		
		private var _persistInventory:PersistInventory;
		private var _persistRegion:PersistRegion;
		
		static private var _eventDispatcher:EventDispatcher = new EventDispatcher();
		static public function get eventDispatcher():EventDispatcher { return _eventDispatcher; }
		
		static public function loadMyPlayerObject( $success:Function, $failure:Function ):void {
			Network.client.bigDB.loadMyPlayerObject( $success, $failure );
		}
		
		public function Persistance() {
		}
		
		public function addEventHandlers():void {
			PersistRegion.addEvents();
			PersistInventory.addEvents();
			PersistAnimation.addEvents();
		}
		
		static public function deleteKeys( $table:String, $keys:Array, $successHandler:Function, $errorHandler:Function ):void {
			if ( Network.client )
				Network.client.bigDB.deleteKeys( $table, $keys, $successHandler, $errorHandler );
			else
				$errorHandler( new PlayerIOError( "No connection", 0 ) );
		}

		static public function createObject( $table:String, $key:String, $data:Object, $successHandler:Function, $errorHandler:Function ):Boolean {
			var result:Boolean;
			if ( Network.client ) {
				Network.client.bigDB.createObject( $table, $key, $data, $successHandler, $errorHandler );
				result = true;
			}
			return result;
		}
		
		static public function loadObject( $table:String, $key:String, $successHandler:Function, $errorHandler:Function ):Boolean {
			var result:Boolean;
			if ( Network.client ) {
				Network.client.bigDB.load( $table, $key, $successHandler, $errorHandler );
				result = true;
			}
			return result;
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
	}	
}
