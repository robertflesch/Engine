/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.persistance 
{
import com.voxelengine.worldmodel.animation.AnimationSound;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;

import playerio.PlayerIOError;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.PlayerIOPersistenceEvent;

/*
 * This class JUST loads the objects from the database, it doesnt care what is in them.
 */
public class PersistBigDB
{
	static public function addEvents():void {
		PersistenceEvent.addListener( PersistenceEvent.LOAD_REQUEST_TYPE, loadType );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_REQUEST, load );
		PersistenceEvent.addListener( PersistenceEvent.SAVE_REQUEST, save );
		PersistenceEvent.addListener( PersistenceEvent.DELETE_REQUEST, deleteHandler );
	}
	
	static private function isSupportedTable( $pe:PersistenceEvent ):Boolean {
		if ( false == Globals.online )
			return false;
			
		if ( Globals.BIGDB_TABLE_MODEL_METADATA == $pe.table )
			return true;
		else if ( Globals.BIGDB_TABLE_OXEL_DATA == $pe.table )	
			return true;
		else if ( Globals.BIGDB_TABLE_REGIONS == $pe.table )	
			return true;
		else if ( Globals.BIGDB_TABLE_INVENTORY == $pe.table )	
			return true;
		else if ( Globals.BIGDB_TABLE_AMMO == $pe.table )	
			return true;
		else if ( Globals.BIGDB_TABLE_ANIMATIONS == $pe.table )	
			return true;
		else if ( Globals.BIGDB_TABLE_MODEL_INFO == $pe.table )	
			return true;
		else if ( AnimationSound.BIGDB_TABLE_SOUNDS == $pe.table )
			return true;
		else {
			if ( Globals.isGuid( $pe.guid ) )
				Log.out( "PersistBigDB.isSupportedTable - FAILED table: " + $pe.table + " is not supported", Log.ERROR );
			return false;
		}
	}
	
	static private function load( $pe:PersistenceEvent ):void {
		
		if ( !isSupportedTable( $pe ) ) {
            //Log.out("PersistBigDB.load - TABLE IS NOT SUPPORTED EXT:" + $pe.table , Log.ERROR );
			//PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
			return;
		}
			
		//Log.out( "PersistBigDB.load - table: " + $pe.table + " for user: " + $pe.guid, Log.DEBUG );
		
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		// The loadObject can dispatch the above events
		Persistence.loadObject( $pe.table
							  , $pe.guid
							  , loadSuccess
							  , loadFail );
										
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		function loadSuccess( $dbo:DatabaseObject ):void {
			if ( !$dbo ) {
				// This seems to be the case where no record exists, not the error handler
				if ( !ModelMakerImport.isImporting )
					Log.out( "PersistBigDB.load.loadSuccess - NULL DatabaseObject -  table: " + $pe.table + "  guid:" + $pe.guid + "  " + $pe.toString(), Log.DEBUG );
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_NOT_FOUND, $pe.series, $pe.table, $pe.guid, null, null, $pe.format, $pe.other ) );
				return;
			}
			
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, $pe.series, $pe.table, $dbo.key, $dbo, null, $pe.format, $pe.other ) );
		}
		
		function loadFail( $pioe:PlayerIOError ):void {
			Log.out( "PersistBigDB.load.failed - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: " + $pioe, Log.ERROR, $pioe ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data, $pe.format, $pe.other ) );
		}		
		
		function errorNoClient( $piope:PlayerIOPersistenceEvent ):void {
			Log.out( "PersistBigDB.load.errorNoClient - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data, $pe.format, $pe.other ) );
		}		
		
		function errorNoDB( $piope:PlayerIOPersistenceEvent ):void {
			Log.out( "PersistBigDB.load.errorNoDB - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data, $pe.format, $pe.other ) );
		}		
	}
	
	static private function loadType( $pe:PersistenceEvent ):void {
	
		if ( false == Globals.online )
			return;
			
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, loadTypeNoClient );
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, loadTypeNoDB );
		
		//Log.out( "PersistRegion.loadType - table: " + $pe.table + "  index: " + ($pe.data as String) + "  type: " + $pe.guid, Log.DEBUG ); 
		Persistence.loadRange( $pe.table
							 , ($pe.data as String)
							 , [$pe.guid]
							 , null
							 , null
							 , 100
							 , loadTypeSucceed
							 , loadTypeFail );
							 
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, loadTypeNoClient );
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, loadTypeNoDB );
				
		function loadTypeSucceed( dba:Array ):void {
			//Log.out( "PersistRegion.loadType.succeed - regions loaded: " + dba.length, Log.DEBUG );
			for each ( var $dbo:DatabaseObject in dba )
			{
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, $pe.series, $pe.table, $dbo.key, $dbo, false ) );
			}
		}
		
		function loadTypeFail( $pioe:PlayerIOError ):void {
			Log.out( "PersistBigDB.loadTypeFail - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: " + $pioe, Log.ERROR, $pioe ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function loadTypeNoClient( $piope:PlayerIOPersistenceEvent ):void {
			Log.out( "PersistBigDB.loadTypeNoClient - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function loadTypeNoDB( $piope:PlayerIOPersistenceEvent ):void {
			Log.out( "PersistBigDB.loadTypeNoDB - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
		}		
	}
	

	static private function save( $pe:PersistenceEvent ):void {
		if ( false == Globals.online )
			return;
			
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, errorNoDB );
		if ( "0" != $pe.dbo.key )
		{
			//Log.out( "PersistBigDB.save - saving: " + $pe.guid );
			Persistence.saveObject( $pe.dbo
			                      , saveSucceed
								  , saveFailure );
		}
		else
		{
			Log.out( "PersistBigDB.create - creating object in table: " + $pe.table + "  guid:" + $pe.guid + "" );
			Persistence.createObject( $pe.table
									, $pe.guid
									, $pe.dbo
									, createSucceed
									, createFail
									);
		}
		
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		function createSucceed($dbo:DatabaseObject):void  {  
			Log.out( "PersistBigDB.save - CREATE Success - table: " + $pe.table + "  guid:" + $pe.guid, Log.DEBUG );
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.CREATE_SUCCEED, $pe.series, $pe.table, $pe.guid, $dbo ) );
		}
		
		function createFail(e:PlayerIOError):void { 
			Log.out( "PersistBigDB.save - CREATE FAILED error saving table: " + $pe.table + "  guid:" + $pe.guid + " error data: " + e, Log.ERROR, e);  
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.CREATE_FAILED, $pe.series, $pe.table, $pe.guid ) );
		}

		function saveSucceed():void  {  
			//Log.out( "PersistBigDB.save - Success - table: " + $pe.table + "  guid:" + $pe.guid, Log.DEBUG );
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.SAVE_SUCCEED, $pe.series, $pe.table, $pe.guid ) );
		}
		
		function saveFailure(e:PlayerIOError):void { 
			Log.out( "PersistBigDB.save - Failed - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: " + e, Log.ERROR, e ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.SAVE_FAILED, $pe.series, $pe.table, $pe.guid ) );
		}
		
		function errorNoClient($piope:PlayerIOPersistenceEvent):void {
			Log.out( "PersistBigDB.load.errorNoClient - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function errorNoDB($piope:PlayerIOPersistenceEvent):void {
			Log.out( "PersistBigDB.load.errorNoDB - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
		}		
	}
	
	static private function deleteHandler( $pe:PersistenceEvent ):void {
		if ( false == Globals.online )
			return;
			
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistenceEvent.addListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		// deleteKeys( $table:String, $keys:Array, $successHandler:Function, $errorHandler:Function ):Boolean {
		Persistence.deleteKeys( $pe.table
							  ,	[ $pe.guid ]
							  , deleteSucceed
							  , deleteFailure );
		
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistenceEvent.removeListener( PlayerIOPersistenceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		function deleteSucceed():void  {  
			//Log.out( "PersistBigDB.deleteRequest.deleteSucceed - table: " + $pe.table + "  guid:" + $pe.guid, Log.DEBUG );
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_SUCCEED, $pe.series, $pe.table, $pe.guid ) );
		}
		
		function deleteFailure(e:PlayerIOError):void { 
			Log.out( "PersistBigDB.deleteRequest.deleteFailure - Failed - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: " + e, Log.ERROR, e ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_FAILED, $pe.series, $pe.table, $pe.guid ) );
		}
		
		function errorNoClient($piope:PlayerIOPersistenceEvent):void {
			Log.out( "PersistBigDB.load.errorNoClient - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
		}		
		
		function errorNoDB($piope:PlayerIOPersistenceEvent):void {
			Log.out( "PersistBigDB.load.errorNoDB - table: " + $pe.table + "  guid:" + $pe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_FAILED, $pe.series, $pe.table, $pe.guid, null, $pe.data ) );
		}		
	}
	
}	
}
