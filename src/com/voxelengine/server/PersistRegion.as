package com.voxelengine.server 
{
	import com.voxelengine.worldmodel.RegionManager;
	import flash.utils.ByteArray;
	
	import playerio.BigDB;
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.RegionPersistanceEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.RegionLoadedEvent;
	import com.voxelengine.worldmodel.Region;
	
	public class PersistRegion extends Persistance
	{
		static public const DB_TABLE_REGIONS:String = "regions";
		
		static public function addEvents():void {
			RegionManager.addListener( RegionEvent.REQUEST_PUBLIC, cacheRequestPublic ); 
			RegionManager.addListener( RegionEvent.REQUEST_PRIVATE, cacheRequestPrivate ); 
		}
		
		static private function cacheRequestPrivate( e:RegionEvent ):void { loadRegions( Network.userId ); }
		static private function cacheRequestPublic( e:RegionEvent ):void { loadRegions( Network.PUBLIC ); }
		
		static public function loadRegion( $guid:String ):void {
		
			Log.out( "PersistRegion.loadRegion - guid: " + $guid, Log.DEBUG ); 
			loadObject( DB_TABLE_REGIONS
						 , $guid
						, loadRegionSuccessHandler
						, loadRegionFailureHandler );
						
			function loadRegionFailureHandler(e:PlayerIOError):void 
			{  
				Log.out( "PersistRegion.loadRegion - errorHandler requesting guid: " + $guid + " error: " + e.message, Log.ERROR, e ); 
				// We have failed to load a region, to keep app from trying over and over again, load a blank region.
				var newRegion:Region = new Region( $guid );
				newRegion.createEmptyRegion();
				// Now that we have a fully formed region, inform the region manager
				Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_CREATED, newRegion ) );
			}
		}

		static private function loadRegionSuccessHandler( dbo:DatabaseObject ):void {
			loadRegionFromDBO( dbo );
		}

		static private function loadRegions( $userName:String ):void {
			
			loadRange( DB_TABLE_REGIONS
						 , "regionOwner"
						 , [$userName]
						 , null
						 , null
						 , 100
						, loadRegionKeysSuccessHandler
						, function (e:PlayerIOError):void {  Log.out( "PersistRegion.errorHandler - e: " + e.message, Log.ERROR, e ); } );
		}
		
		static private function loadRegionKeysSuccessHandler( dba:Array ):void {
			
			Log.out( "PersistRegion.loadKeysSuccessHandler - regions loaded: " + dba.length, Log.DEBUG );
			for each ( var dbo:DatabaseObject in dba )
			{
				loadRegionFromDBO( dbo );
			}
		}
		
		static private function loadRegionFromDBO( dbo:DatabaseObject ):void
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
			
			Log.out( "PersistRegion.loadFromDBO - region Name: " + newRegion.name + "  owner: " + newRegion.owner + "  guid: " + newRegion.guid, Log.DEBUG );
			
			$ba.uncompress();
			$ba.position = 0;
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var regionJson:String = $ba.readUTFBytes( strLen );
			//regionJson = decodeURI(regionJson);
			newRegion.initJSON( regionJson );
			
			// Now that we have a fully formed region, inform the region manager
			Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_CREATED, newRegion ) );
		}

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
										Globals.g_app.dispatchEvent( new RegionPersistanceEvent( RegionPersistanceEvent.REGION_SAVE_FAILURE, $metadata.guid ) ); 
										Log.out( "PersistRegion.saveRegionFailed - error data: " + e, Log.ERROR, e ) } );
			}
			else
			{
				Log.out( "PersistRegion.create - creating new region: " + $metadata.guid + "" );
				createObject( PersistRegion.DB_TABLE_REGIONS
							, $guid
							, $metadata
							, $createSuccess
							, function createFailed(e:PlayerIOError):void { 
								Globals.g_app.dispatchEvent( new RegionPersistanceEvent( RegionPersistanceEvent.REGION_CREATE_FAILURE, $metadata.guid ) ); 
								Log.out( "PersistRegion.createFailed - error saving: " + $metadata.guid + " error data: " + e, Log.ERROR, e);  }
							);
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
	}	
}
