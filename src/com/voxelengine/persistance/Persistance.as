/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.persistance 
{
import com.voxelengine.server.Network;
import flash.events.Event;
import flash.events.EventDispatcher;

import playerio.Client;
import playerio.BigDB;
import playerio.DatabaseObject;

import com.voxelengine.events.PlayerIOPersistanceEvent
	
// This class wraps the bigDB class, registers event handlers, and checks for valid connections
/* Generates Events
 * 		PersistanceEvent.PERSISTANCE_NO_CLIENT
 * 		PersistanceEvent.PERSISTANCE_NO_DB
 * 
 * handles Events
 * 		NONE
 * 
 * Classes of events handled
 * 		PersistanceEvent
 * */

public class Persistance
{
	static public function addEventHandlers():void {
		PersistRegion.addEvents();
		PersistInventory.addEvents();
		PersistAnimation.addEvents();
	}
	
	static private function validateConnection():Boolean {
		if ( !Network.client ) {
			PlayerIOPersistanceEvent.dispatch( new PlayerIOPersistanceEvent( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT ) );
			return false;
		}
		else if ( !Network.client.bigDB ) {
			PlayerIOPersistanceEvent.dispatch( new PlayerIOPersistanceEvent( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB ) );
			return false;
		}
		return true;
	}

	static public function loadMyPlayerObject( $success:Function, $failure:Function ):Boolean {
		if ( !validateConnection() )
			return false;
		Network.client.bigDB.loadMyPlayerObject( $success, $failure );
		return true;
	}
	
	static public function deleteKeys( $table:String, $keys:Array, $successHandler:Function, $errorHandler:Function ):Boolean {
		if ( !validateConnection() )
			return false;
		Network.client.bigDB.deleteKeys( $table, $keys, $successHandler, $errorHandler );
		return true;
	}

	static public function saveObject( $dbo:DatabaseObject, $successHandler:Function, $errorHandler:Function, $useOptimisticLock:Boolean=false, $fullOverwrite:Boolean=false ):Boolean {
		if ( !validateConnection() )
			return false;
		$dbo.save( $useOptimisticLock, $fullOverwrite, $successHandler, $errorHandler );
		return true;
	}
	

	static public function createObject( $table:String, $key:String, $data:Object, $successHandler:Function, $errorHandler:Function ):Boolean {
		if ( !validateConnection() )
			return false;
		Network.client.bigDB.createObject( $table, $key, $data, $successHandler, $errorHandler );
		return true;
	}
	
	// returns false if no valid client
	static public function loadObject( $table:String, $key:String, $successHandler:Function, $errorHandler:Function ):Boolean {
		if ( !validateConnection() )
			return false;
		Network.client.bigDB.load( $table, $key, $successHandler, $errorHandler );
		return true;
	}
	
	static public function loadKeys( $table:String, $key:Array, $successHandler:Function, $errorHandler:Function ):Boolean {
		if ( !validateConnection() )
			return false;
		Network.client.bigDB.loadKeys( $table, $key , $successHandler, $errorHandler );
		return true;
	}
	
	static public function loadRange( $table:String, $index:String, $path:Array, $start:Object, $stop:Object, $limit:int, $successHandler:Function, $errorHandler:Function ):Boolean {
		if ( !validateConnection() )
			return false;
		Network.client.bigDB.loadRange( $table, $index , $path, $start, $stop,  $limit, $successHandler, $errorHandler );
		return false;
	}
}	
}
