/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.server 
{
	import flash.events.EventDispatcher;
	
	import playerio.Client;
	import playerio.BigDB;
		
	// This class wraps the bigDB class, registers event handlers, and checks for valid connections
	public class Persistance
	{
		static public function addEventHandlers():void {
			PersistRegion.addEvents();
			PersistInventory.addEvents();
			PersistAnimation.addEvents();
		}
		
		// Used to distribue all persistance messages
		static private var _eventDispatcher:EventDispatcher = new EventDispatcher();
		static public function get eventDispatcher():EventDispatcher { return _eventDispatcher; }
		
		static public function loadMyPlayerObject( $success:Function, $failure:Function ):Boolean {
			if ( !Network.client || !Network.client.bigDB )
				return false;
			Network.client.bigDB.loadMyPlayerObject( $success, $failure );
			return true;
		}
		
		static public function deleteKeys( $table:String, $keys:Array, $successHandler:Function, $errorHandler:Function ):Boolean {
			if ( !Network.client || !Network.client.bigDB )
				return false;
			Network.client.bigDB.deleteKeys( $table, $keys, $successHandler, $errorHandler );
			return true;
		}

		static public function createObject( $table:String, $key:String, $data:Object, $successHandler:Function, $errorHandler:Function ):Boolean {
			if ( !Network.client || !Network.client.bigDB )
				return false;
			Network.client.bigDB.createObject( $table, $key, $data, $successHandler, $errorHandler );
			return true;
		}
		
		// returns false if no valid client
		static public function loadObject( $table:String, $key:String, $successHandler:Function, $errorHandler:Function ):Boolean {
			if ( !Network.client || !Network.client.bigDB )
				return false;
			Network.client.bigDB.load( $table, $key, $successHandler, $errorHandler );
			return true;
		}
		
		static public function loadKeys( $table:String, $key:Array, $successHandler:Function, $errorHandler:Function ):Boolean {
			if ( !Network.client || !Network.client.bigDB )
				return false;
			Network.client.bigDB.loadKeys( $table, $key , $successHandler, $errorHandler );
			return true;
		}
		
		static public function loadRange( $table:String, $index:String, $path:Array, $start:Object, $stop:Object, $limit:int, $successHandler:Function, $errorHandler:Function ):Boolean {
			if ( !Network.client || !Network.client.bigDB )
				return false;
			Network.client.bigDB.loadRange( $table, $index , $path, $start, $stop,  $limit, $successHandler, $errorHandler );
			return false;
		}
	}	
}
