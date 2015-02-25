﻿/*==============================================================================
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
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.PlayerIOPersistanceEvent;

/*
 * This class JUST loads the objects from the database, it doesnt care what is in them.
 */
public class PersistBigDB
{
	static public function addEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.LOAD_REQUEST_TYPE, loadType );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_REQUEST, load );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_REQUEST, save );
	}
	
	static private function load( $pe:PersistanceEvent ):void { 
		
		if ( false == Globals.online )
			return;
			
		Log.out( "PersistBigDB.load - table: " + $pe.table + " for user: " + $pe.guid, Log.DEBUG );
		
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		// The loadObject can dispatch the above events
		Persistance.loadObject( $pe.table
							  , $pe.guid
							  , loadSuccess
							  , loadFail );
										
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		function loadSuccess( $dbo:DatabaseObject ):void {
			if ( !$dbo ) {
				// This seems to be the case where no record exists, not the error handler
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_NOT_FOUND, $pe.table, $pe.guid ) );
				Log.out( "PersistBigDB.load.loadSuccess - NULL DatabaseObject table: " + $pe.table + "  guid:" + $pe.guid, Log.DEBUG );
				return;
			}
			
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $pe.table, $dbo.key, $dbo ) );
		}
		
		function loadFail( $pioe:PlayerIOError ):void {
			Log.out( "PersistBigDB.load.failed - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: " + $pioe, Log.ERROR, $pioe ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function errorNoClient( $piope:PlayerIOPersistanceEvent ):void {
			Log.out( "PersistBigDB.load.errorNoClient - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function errorNoDB( $piope:PlayerIOPersistanceEvent ):void {
			Log.out( "PersistBigDB.load.errorNoDB - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
	}
	
	static private function loadType( $pe:PersistanceEvent ):void {
	
		if ( false == Globals.online )
			return;
			
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, loadTypeNoClient );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, loadTypeNoDB );
		
		Log.out( "PersistRegion.loadType - table: " + $pe.table + "  index: " + ($pe.data as String) + "  type: " + $pe.guid, Log.DEBUG ); 
		Persistance.loadRange( $pe.table
							 , ($pe.data as String)
							 , [$pe.guid]
							 , null
							 , null
							 , 100
							 , loadTypeSucceed
							 , loadTypeFail );
							 
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, loadTypeNoClient );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, loadTypeNoDB );
				
		function loadTypeSucceed( dba:Array ):void {
			Log.out( "PersistRegion.loadType.succeed - regions loaded: " + dba.length, Log.DEBUG );
			for each ( var $dbo:DatabaseObject in dba )
			{
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $pe.table, $dbo.key, $dbo ) );
			}
		}
		
		function loadTypeFail( $pioe:PlayerIOError ):void {
			Log.out( "PersistBigDB.loadTypeFail - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: " + $pioe, Log.ERROR, $pioe ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function loadTypeNoClient( $piope:PlayerIOPersistanceEvent ):void {
			Log.out( "PersistBigDB.loadTypeNoClient - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function loadTypeNoDB( $piope:PlayerIOPersistanceEvent ):void {
			Log.out( "PersistBigDB.loadTypeNoDB - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
	}
	

	static private function save( $pe:PersistanceEvent ):void {
		if ( false == Globals.online )
			return;
			
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		if ( $pe.dbo )
		{
			Log.out( "PersistBigDB.save - saving inventory: " + $pe.guid );
			$pe.dbo.modified = new Date();
			
			Persistance.saveObject( $pe.dbo
			                      , function ():void  {  
										Log.out( "PersistBigDB.save - Success - table: " + $pe.table + "  guid:" + $pe.guid, Log.DEBUG );
										PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_SUCCEED, $pe.table, $pe.guid ) ); }
								  , function (e:PlayerIOError):void { 
										Log.out( "PersistBigDB.save - Failed - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: " + e, Log.ERROR, e ) 
										PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_FAILED, $pe.table, $pe.guid ) ); } );
		}
		else
		{
			Log.out( "PersistBigDB.create - creating table: " + $pe.table + "  guid:" + $pe.guid + "" );
			//var metadata:Object = { created: new Date(), modified: new Date(), data: $pe.data };
			var metadata:Object = $pe.data as Object;
			Persistance.createObject( $pe.table
									, $pe.guid
									, metadata
									, function ($dbo:DatabaseObject):void  {  
										Log.out( "PersistBigDB.save - CREATE Success - table: " + $pe.table + "  guid:" + $pe.guid, Log.DEBUG );
										PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.CREATE_SUCCEED, $pe.table, $pe.guid, $dbo ) ); }
									, function (e:PlayerIOError):void { 
										PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.CREATE_FAILED, $pe.table, $pe.guid ) ); 
										Log.out( "PersistBigDB.save - CREATE FAILED error saving table: " + $pe.table + "  guid:" + $pe.guid + " error data: " + e, Log.ERROR, e);  }
									);
		}
		
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		function errorNoClient($piope:PlayerIOPersistanceEvent):void {
			Log.out( "PersistBigDB.load.errorNoClient - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function errorNoDB($piope:PlayerIOPersistanceEvent):void {
			Log.out( "PersistBigDB.load.errorNoDB - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_FAILED, $pe.table, $pe.guid, null, $pe.data ) );
		}		
	}
}	
}