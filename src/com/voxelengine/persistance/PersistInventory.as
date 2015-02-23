/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.persistance 
{
import playerio.PlayerIOError;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.PlayerIOPersistanceEvent;
import com.voxelengine.events.InventoryPersistanceEvent;

/*
 * This class JUST loads the objects from the database, it doesnt care what is in them.
 */
public class PersistInventory
{
	static private const DB_INVENTORY_TABLE:String = "inventory";
	
	static public function addEvents():void {
		InventoryPersistanceEvent.addListener( PersistanceEvent.LOAD_REQUEST, load );
		InventoryPersistanceEvent.addListener( PersistanceEvent.SAVE_REQUEST, save );
	}
	
	static private function load( $ie:InventoryPersistanceEvent ):void { 
		
		Log.out( "PersistInventory.load - loading inventory for player: " + $ie.guid, Log.DEBUG );
		
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		// The loadObject can dispatch the above events
		Persistance.loadObject( DB_INVENTORY_TABLE
							  , $ie.guid
							  , loadSuccess
							  , loadFail );
										
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		function loadSuccess( $dbo:DatabaseObject ):void {
			if ( !$dbo ) {
				// This seems to be the case where no record exists, not the error handler
				InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_NOT_FOUND, $ie.guid ) );
				Log.out( "PersistInventory.load.loadSuccess - NULL DatabaseObject for guid:" + $ie.guid, Log.DEBUG );
				return;
			}
			
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $dbo.key, $dbo ) );
		}
		
		function loadFail(e:PlayerIOError):void {
			Log.out( "PersistInventory.load.failed - guid: " + $ie.guid + "  error data: " + e, Log.ERROR, e ) 
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_FAILED, $ie.guid ) );
		}		
		
		function errorNoClient($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistInventory.load.errorNoClient - guid: " + $ie.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_FAILED, $ie.guid ) );
		}		
		
		function errorNoDB($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistInventory.load.errorNoDB - guid: " + $ie.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_FAILED, $ie.guid ) );
		}		
	}

	static private function save( $ie:InventoryPersistanceEvent ):void {
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		if ( $ie.dbo )
		{
			Log.out( "PersistInventory.save - saving inventory: " + $ie.guid );
			$ie.dbo.modified = new Date();
			
			Persistance.saveObject( $ie.dbo
			                      , function ():void  {  
										Log.out( "PersistInventory.save - Success - guid: " + $ie.guid, Log.DEBUG );
										InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.SAVE_SUCCEED, $ie.guid ) ); }
								  , function (e:PlayerIOError):void { 
										Log.out( "PersistInventory.save - Failed - guid: " + $ie.guid + "  error data: " + e, Log.ERROR, e ) 
										InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.SAVE_FAILED, $ie.guid ) ); } );
		}
		else
		{
			Log.out( "PersistInventory.create - creating inventory: " + $ie.guid + "" );
			var metadata:Object = { created: new Date(), modified: new Date(), data: $ie.ba };
			Persistance.createObject( DB_INVENTORY_TABLE
									, $ie.guid
									, metadata
									, function ($dbo:DatabaseObject):void  {  
										Log.out( "PersistInventory.save - CREATE Success - guid: " + $ie.guid, Log.DEBUG );
										InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.CREATE_SUCCEED, $ie.guid, $dbo ) ); }
									, function (e:PlayerIOError):void { 
										InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.CREATE_FAILED, $ie.guid ) ); 
										Log.out( "PersistInventory.save - CREATE FAILED error saving: " + $ie.guid + " error data: " + e, Log.ERROR, e);  }
									);
		}
		
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		function errorNoClient($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistInventory.load.errorNoClient - guid: " + $ie.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_FAILED, $ie.guid ) );
		}		
		
		function errorNoDB($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistInventory.load.errorNoDB - guid: " + $ie.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			InventoryPersistanceEvent.dispatch( new InventoryPersistanceEvent( PersistanceEvent.LOAD_FAILED, $ie.guid ) );
		}		
	}
}	
}
