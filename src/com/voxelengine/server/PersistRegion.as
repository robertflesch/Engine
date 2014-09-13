package com.voxelengine.server 
{
	import flash.utils.ByteArray;
	
	import playerio.BigDB;
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.PersistanceEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.RegionLoadedEvent;
	import com.voxelengine.worldmodel.Region;
	
	public class PersistRegion extends Persistance
	{
		static public const DB_TABLE_REGIONS:String = "regions";
		
		public function PersistRegion():void {
			Globals.g_app.addEventListener( RegionEvent.REQUEST_PUBLIC, cacheRequestPublic ); 
			Globals.g_app.addEventListener( RegionEvent.REQUEST_PRIVATE, cacheRequestPrivate ); 
		}
		
		public function cacheRequestPrivate( e:RegionEvent ):void { loadRegions( Network.userId ); }
		public function cacheRequestPublic( e:RegionEvent ):void { loadRegions( Persistance.PUBLIC ); }
		

		static public function loadRegions( $userName:String ):void {
			
			loadRange( PersistRegion.DB_TABLE_REGIONS
						 , "regionOwner"
						 , [$userName]
						 , null
						 , null
						 , 100
						, loadRegionKeysSuccessHandler
						, function (e:PlayerIOError):void {  Log.out( "PersistRegion.errorHandler - e: " + e ); } );
		}
		
		static private function loadRegionKeysSuccessHandler( dba:Array ):void {
			
			trace( "PersistRegion.loadKeysSuccessHandler - regions loaded: " + dba.length );
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
			
//			Log.out( "PersistRegion.loadFromDBO - regionJson: " + newRegion.name + "  owner: " + newRegion.owner );
			
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

		static public function saveRegion( $metadata:Object, $dbo:DatabaseObject, $createSuccess:Function ):void {

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
					     , function saveRegionSuccess():void  {  Log.out( "PersistRegion.saveRegionSuccess - guid: " + $metadata.guid ); }	
					     , function saveRegionFailed(e:PlayerIOError):void  { 
							Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_SAVE_FAILURE, $metadata.guid ) ); 
							Log.out( "PersistRegion.saveRegionFailed - error data: " + e); }  
						);
			}
			else
			{
				Log.out( "PersistRegion.create - creating new region: " + $metadata.guid + "" );
				createObject( PersistRegion.DB_TABLE_REGIONS
							, $metadata.guid
							, $metadata
							, $createSuccess
							, function createFailed(e:PlayerIOError):void { 
								Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_CREATE_FAILURE, $metadata.guid ) ); 
								Log.out( "PersistRegion.createFailed - error saving: " + $metadata.guid + " error data: " + e);  }
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
