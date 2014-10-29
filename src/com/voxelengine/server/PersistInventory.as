/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.server 
{
import playerio.PlayerIOError;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.events.InventoryPersistanceEvent;

public class PersistInventory extends Persistance
{
	// Fields
	//created:Date
	//modified:Date
	//data:ByteArray

	static private const DB_INVENTORY_TABLE:String = "inventory";
	//static private const DB_INVENTORY_INDEX_OWNER:String = "owner";
	
	static public function addEvents():void {
		Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_LOAD_REQUEST, load );
		Persistance.eventDispatcher.addEventListener( InventoryPersistanceEvent.INVENTORY_SAVE_REQUEST, save );
	}
	
	static private function load( $ie:InventoryPersistanceEvent ):void { 
		
		Log.out( "PersistInventory.load - loading inventory for player: " + $ie.guid, Log.DEBUG );
		var result:Boolean;
		result = Persistance.loadObject( DB_INVENTORY_TABLE
									  , $ie.guid
									  , loadSuccess
									  , function (e:PlayerIOError):void {
										  Log.out( "PersistInventory.load.failed - guid: " + $ie.guid + "  error data: " + e, Log.ERROR, e ) 
										  Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, $ie.guid ) );
										} );
		if ( false == result )		
			Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, $ie.guid ) );
										
		function loadSuccess( $dbo:DatabaseObject ):void {
			if ( !$dbo )
			{
				// This seems to be the failure case, not the error handler
				Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_LOAD_FAILED, $ie.guid ) );
				Log.out( "PersistInventory.load.loadSuccess - NULL DatabaseObject for guid:" + $ie.guid, Log.DEBUG );
				return;
			}
			
			loadFromDBO( $dbo );
		}
	}

	// use one extra level here in case I want to load an array of dbo object
	static private function loadFromDBO( $dbo:DatabaseObject ):void {
		Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_LOAD_SUCCEED, $dbo.key, $dbo ) );
	}

	static private function save( $ie:InventoryPersistanceEvent ):void {
		if ( $ie.dbo )
		{
			Log.out( "PersistInventory.save - saving inventory: " + $ie.guid );
			$ie.dbo.modified = new Date();
			
			$ie.dbo.save( false
						, false
						, function ():void  {  
							Log.out( "PersistInventory.save - Success - guid: " + $ie.guid, Log.DEBUG );
							Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_SAVE_SUCCEED, $ie.guid ) ); }
						, function (e:PlayerIOError):void { 
							Log.out( "PersistInventory.save - Failed - guid: " + $ie.guid + "  error data: " + e, Log.ERROR, e ) 
							Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_SAVE_FAILED, $ie.guid ) ); } );
		}
		else
		{
			Log.out( "PersistInventory.create - creating inventory: " + $ie.guid + "" );
			var metadata:Object = { created: new Date(), modified: new Date(), data: $ie.ba };
			createObject( DB_INVENTORY_TABLE
						, $ie.guid
						, metadata
						, function ($dbo:DatabaseObject):void  {  
							Log.out( "PersistInventory.save - CREATE Success - guid: " + $ie.guid, Log.DEBUG );
							Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_CREATE_SUCCEED, $ie.guid, $dbo ) ); }
						, function (e:PlayerIOError):void { 
							Persistance.eventDispatcher.dispatchEvent( new InventoryPersistanceEvent( InventoryPersistanceEvent.INVENTORY_CREATE_FAILED, $ie.guid ) ); 
							Log.out( "PersistInventory.save - CREATE FAILED error saving: " + $ie.guid + " error data: " + e, Log.ERROR, e);  }
						);
		}
	}
}	
}
