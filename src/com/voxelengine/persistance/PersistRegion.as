package com.voxelengine.persistance 
{
import adobe.utils.CustomActions;
import flash.utils.ByteArray;

import playerio.PlayerIOError;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.RegionPersistanceEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.persistance.Persistance;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.RegionManager;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.events.PlayerIOPersistanceEvent;

public class PersistRegion
{
	static public const DB_TABLE_REGIONS:String = "regions";
	static public const DB_TABLE_INDEX_OWNER:String = "regionOwner";
	
	static public function addEvents():void {
		RegionPersistanceEvent.addListener( PersistanceEvent.LOAD_REQUEST_TYPE,	loadType );
		RegionPersistanceEvent.addListener( PersistanceEvent.LOAD_REQUEST, 		load );
		RegionPersistanceEvent.addListener( PersistanceEvent.SAVE_REQUEST, 		save );
	}
	
	static private function load( $rpe:RegionPersistanceEvent ):void {
		if ( false == Globals.online )
			return;
			
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClientLoad );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDBLoad );
		
		Log.out( "PersistRegion.loadRegion - guid: " + $rpe.guid, Log.DEBUG ); 
		Persistance.loadObject( DB_TABLE_REGIONS
							  , $rpe.guid
							  , succeedLoad
							  , failLoad );
					
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClientLoad );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDBLoad );
				
		function succeedLoad( dbo:DatabaseObject ):void {
			Log.out( "PersistRegion.load.succeed - loaded guid: " + $rpe.guid ); 
			if ( dbo )
				RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $rpe.guid, dbo ) );
			else	
				RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_FAILED, $rpe.guid ) );
				
		}
		
		function failLoad(e:PlayerIOError):void 
		{  
			Log.out( "PersistRegion.load.fail - guid: " + $rpe.guid + " error: " + e.message, Log.ERROR, e ); 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_FAILED, $rpe.guid ) );
		}
		
		function errorNoClientLoad($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistRegion.load.errorNoClient - guid: " + $rpe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_FAILED, $rpe.guid ) );
		}		
		
		function errorNoDBLoad($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistRegion.load.errorNoDB - guid: " + $rpe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_FAILED, $rpe.guid ) );
		}		
	}

	static private function loadType( $rpe:RegionPersistanceEvent ):void {
		if ( false == Globals.online )
			return;
	
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		Log.out( "PersistRegion.loadType - type: " + $rpe.guid, Log.DEBUG ); 
		Persistance.loadRange( DB_TABLE_REGIONS
							 , DB_TABLE_INDEX_OWNER
							 , [$rpe.guid]
							 , null
							 , null
							 , 100
							 , succeed
							 , fail );
							 
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
				
		function succeed( dba:Array ):void {
			Log.out( "PersistRegion.loadType.succeed - regions loaded: " + dba.length, Log.DEBUG );
			for each ( var $dbo:DatabaseObject in dba )
			{
				RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_SUCCEED, $dbo.key, $dbo ) );
			}
		}
		
		function fail(e:PlayerIOError):void 
		{  
			Log.out( "PersistRegion.loadType.fail - guid: " + $rpe.guid + " error: " + e.message, Log.ERROR, e ); 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_FAILED, $rpe.guid ) );
		}
		
		function errorNoClient($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistRegion.loadType.errorNoClient - guid: " + $rpe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_FAILED, $rpe.guid ) );
		}		
		
		function errorNoDB($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistRegion.loadType.errorNoDB - guid: " + $rpe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_FAILED, $rpe.guid ) );
		}		
	}

	
	
	static private function save( $rpe:RegionPersistanceEvent ):void {
		if ( false == Globals.online )
			return;
		
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.addListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
		if ( $rpe.dbo )
		{
			Log.out( "PersistRegion.save - saving inventory: " + $rpe.guid );
			$rpe.dbo.modified = new Date();
			
			Persistance.saveObject( $rpe.dbo, saveSucceed, saveFail );
		}
		else
		{
			Log.out( "PersistRegion.create - creating inventory: " + $rpe.guid + "" );
			var metadata:Object = { created: new Date(), modified: new Date(), data: $rpe.ba };
			Persistance.createObject( DB_TABLE_REGIONS
									, $rpe.guid
									, metadata
									, createSucceed 
									, createFail );
		}
		
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_CLIENT, errorNoClient );
		PlayerIOPersistanceEvent.removeListener( PlayerIOPersistanceEvent.PERSISTANCE_NO_DB, errorNoDB );
		
	    function saveSucceed():void  {  
			Log.out( "PersistRegion.save - Success - guid: " + $rpe.guid, Log.DEBUG );
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.SAVE_SUCCEED, $rpe.guid ) ); 
		}
			
		function saveFail(e:PlayerIOError):void { 
			Log.out( "PersistRegion.save - Failed - guid: " + $rpe.guid + "  error data: " + e, Log.ERROR, e ) 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.SAVE_FAILED, $rpe.guid ) ); 
		}

		function createSucceed($dbo:DatabaseObject):void  {  
			Log.out( "PersistRegion.save - CREATE Success - guid: " + $rpe.guid, Log.DEBUG );
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.CREATE_SUCCEED, $rpe.guid, $dbo ) ); 
		}
		
		function createFail(e:PlayerIOError):void { 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.CREATE_FAILED, $rpe.guid ) ); 
			Log.out( "PersistRegion.save - CREATE FAILED error saving: " + $rpe.guid + " error data: " + e, Log.ERROR, e);  
		}

		function errorNoClient($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistRegion.load.errorNoClient - guid: " + $rpe.guid + "  error data: NOT CONNECTED TO THE INTERNET", Log.ERROR ) 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.SAVE_FAILED, $rpe.guid ) );
		}		
		
		function errorNoDB($pe:PlayerIOPersistanceEvent):void {
			Log.out( "PersistRegion.load.errorNoDB - guid: " + $rpe.guid + "  error data: DATABASE NOT FOUND", Log.ERROR ) 
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.SAVE_FAILED, $rpe.guid ) );
		}		
	}
		
	/*
	static public function save( $guid:String, $metadata:Object, $dbo:DatabaseObject, $createSuccess:Function ):void {

		if ( $dbo )
		{
//				Log.out( "PersistRegion.save - saving region back to BigDB: " + $metadata.guid );
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
					 , function ():void  {  Log.out( "PersistRegion.saveRegionSuccess - guid: " + $guid, Log.DEBUG ); }	
					 , function (e:PlayerIOError):void { 
									Globals.g_app.dispatchEvent( new RegionPersistanceEvent( PersistanceEvent.SAVE_FAILED, $metadata.guid ) ); 
									Log.out( "PersistRegion.saveRegionFailed - error data: " + e, Log.ERROR, e ) } );
		}
		else
		{
			Log.out( "PersistRegion.create - creating new region: " + $metadata.guid + "" );
			Persistance.createObject( PersistRegion.DB_TABLE_REGIONS
						, $guid
						, $metadata
						, $createSuccess
						, function createFailed(e:PlayerIOError):void { 
							Globals.g_app.dispatchEvent( new RegionPersistanceEvent( PersistanceEvent.CREATE_FAILED, $metadata.guid ) ); 
							Log.out( "PersistRegion.createFailed - error saving: " + $metadata.guid + " error data: " + e, Log.ERROR, e);  }
						);
		}
		
	}
	*/
	
}	
}
