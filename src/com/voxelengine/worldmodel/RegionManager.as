/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.RoomEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.server.Network;
import com.voxelengine.server.Room;

/**
 * ...
 * @author Bob
 */
public class RegionManager 
{
	private var _regions:Vector.<Region> = null
	private var _requestPublic:Boolean;
	//private var _resultsPublic:Boolean;
	private var _requestPrivate:Boolean;
	//private var _resultsPrivate:Boolean;
	
	public function get size():int { return _regions.length; }
	
	public function get regions():Vector.<Region> { return _regions; }
	
	//public function get modelLoader():ModelLoader { return _modelLoader; }
	static private var _s_instance:RegionManager;
	static public function get instance():RegionManager {
		if ( null == _s_instance )
			_s_instance = new RegionManager();		
		return _s_instance	
	}
	
	public function RegionManager():void 
	{
		_regions = new Vector.<Region>;

		//RegionEvent.addListener( RegionEvent.LOAD, 			regionLoad ); 
		RegionEvent.addListener( RegionEvent.JOIN, 			requestServerJoin ); 
		RegionEvent.addListener( ModelBaseEvent.REQUEST_TYPE, 	regionTypeRequest );
		RegionEvent.addListener( ModelBaseEvent.REQUEST, 		regionRequest );	
		
		RoomEvent.addListener( RoomEvent.ROOM_DISCONNECT, 	requestDefaultRegionLoad );
		RoomEvent.addListener( RoomEvent.ROOM_JOIN_SUCCESS, onJoinRoomEvent );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );			
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFail );			
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	regionCreatedHandler ); 
									  
		LoadingEvent.addListener( LoadingEvent.LOAD_CONFIG_COMPLETE, configComplete );
	}
	
	/**
	 * @param  - RegionEvent generated by a region when it has 
	 * @return - None
	 * Generates Event RegionEvent.UNLOAD if it is the current region
	*/
	private function regionLoad( $re:RegionEvent ):void
	{
		Log.out( "RegionManager.load - region: " + $re.guid, Log.DEBUG );
		WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.CREATE ) );
		
		RegionEvent.dispatch( new RegionEvent( RegionEvent.UNLOAD, 0, null ) );
		RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD, 0, $re.guid ) );
	}
	
	private function regionRequest( $re:RegionEvent):void 	{
		
		if ( null == $re.guid ) {
			Log.out( "RegionManager.regionRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		Log.out( "RegionManager.regionRequest guid: " + $re.guid, Log.INFO );
		var region:Region = regionGet( $re.guid );
		if ( region ) {
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.RESULT, 0, region.guid, region ) );
			return;
		}
		
		if ( true == Globals.online )
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $re.series, Globals.BIGDB_TABLE_REGIONS, $re.guid ) );
		else	
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $re.series, Globals.REGION_EXT, $re.guid, null, null ) );			
	}
	
	private function regionTypeRequest(e:RegionEvent):void {
		
		if ( Network.PUBLIC == e.guid && false == _requestPublic ) {
			_requestPublic = true;
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, e.series, Globals.BIGDB_TABLE_REGIONS, Network.PUBLIC, null, Globals.BIGDB_TABLE_REGIONS_INDEX_OWNER ) );			
		}
		if ( Network.userId == e.guid && false == _requestPrivate ) {
			_requestPrivate = true;
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, e.series, Globals.BIGDB_TABLE_REGIONS, Network.userId, null, Globals.BIGDB_TABLE_REGIONS_INDEX_OWNER ) );			
		}
			
		// Get a list of what we currently have
		for each ( var region:Region in _regions ) {
			if ( region && region.owner == e.guid )
				RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.RESULT, 0, region.guid, region ) );
		}
	}
	
	private function loadFail( $pe:PersistanceEvent ):void 
	{
		if ( Globals.BIGDB_TABLE_REGIONS != $pe.table && Globals.REGION_EXT != $pe.table )
			return;
			
		Log.out( "RegionManager.loadFail - region: " + $pe.guid, Log.ERROR );
		throw new Error( "RegionManager.loadFail - why did I fail to load region PersistanceEvent: " + $pe.toString(), Log.WARN );
	}
	
	private function loadSucceed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.BIGDB_TABLE_REGIONS == $pe.table ) {
			//Log.out( "RegionManager.loadSucceed - creating new region: " + $pe.guid, Log.DEBUG );
			var newRegion:Region = new Region( $pe.guid );
			newRegion.fromPersistance( $pe.dbo );
			// When I create a new region I have to create a temporary DBO to transfer metadata and data.
			// otherwise the $pe.data will be false or null. This temporary DBO must be removed before the region is saved.
			if ( $pe.data && true == $pe.data )
				newRegion.dbo = null;
			regionAdd( $pe, newRegion );
		}
		// Bad thing about this is it ignores all the metadata
		else if ( Globals.REGION_EXT == $pe.table ) {
			var region:Region = new Region( $pe.guid );
			region.initJSON( $pe.data );
			regionAdd( null, region );
		}
	}
	
	private function regionAdd( $pe:PersistanceEvent, $region:Region ):void {
		//Log.out( "RegionManager.regionAdd - adding region: " + $region.guid, Log.DEBUG );
		if ( false == regionHas( $region.guid ) ) {
			_regions.push( $region );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.ADDED, ($pe ? $pe.series: 0), $region.guid, $region ) );
		}
		else
			Log.out( "RegionManager.regionAdd - NOT loading duplicate region: " + $region.guid, Log.DEBUG );
	}
	
	////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////
	
	public function configComplete( $e:LoadingEvent ):void
	{
		startWithEmptyRegion();
		
		// Add a listener to tell when file has been loaded
//		RegionEvent.addListener( ModelBaseEvent.ADDED, startingRegionLoaded );
		// now request the file be loaded
//		RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.REQUEST, 0, $guid ) );
	}
	public function startWithEmptyRegion():void
	{
		var startingRegion:Region = new Region( "Blank" );
		startingRegion.createEmptyRegion();
		regionAdd( null, startingRegion );
		RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD, 0, startingRegion.guid ) ); 
		RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_COMPLETE, 0, startingRegion.guid ) );
		// This tells the config manager that the local region was loaded and is ready to load rest of data.
	}
	
	
	private function startingRegionLoaded( $re:RegionEvent):void 
	{
		// remove this handler
		RegionEvent.removeListener( ModelBaseEvent.ADDED, startingRegionLoaded );
		// now load the file that was designated as the starting region
		RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD, 0, $re.guid, $re.region ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	static public function requestServerJoin( e:RegionEvent ):void {
		Log.out( "RegionManager.requestServerJoin - guid: " + e.guid, Log.DEBUG );
		Room.createJoinRoom( e.guid );	
	}
	
	static public function requestDefaultRegionLoad( e:RoomEvent ):void {
		Log.out( "RegionManager.requestDefaultRegionLoad", Log.DEBUG );
		var defaultRegionJSON:Object = ConfigManager.instance.defaultRegionJson;
		var defaultRegionID:String = defaultRegionJSON.config.region.startingRegion;
		Room.createJoinRoom( defaultRegionID );	
	}
	
	public function onJoinRoomEvent( e:RoomEvent ):void {
		Log.out( "RegionManager.onJoinRoomEvent - guid: " + e.guid, Log.DEBUG );
		RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD, 0, e.guid ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	
	// this calls the region and its model manager to update
	public function update( $elapsed:int ):void {
		if ( Region.currentRegion )
			Region.currentRegion.update( $elapsed );
	}
	
	// Just assign the dbo from the create to the region
	private function regionCreatedHandler( $pe:PersistanceEvent ):void {
		if ( Globals.BIGDB_TABLE_REGIONS != $pe.table )
			return;
		
		Log.out( "RegionManager.regionCreatedHandler: " + $pe.guid );
		// check for duplicates
		var region:Region = regionGet( $pe.guid )
		if ( region )
			region.dbo = $pe.dbo;
		else	
			Log.out( "RegionManager.regionCreatedHandler: ERROR region not found for returned guid: " + $pe.guid );
	}
	
	/**
	 * @param  - guid of region
	 * @return - region or null
	 * 
	*/
	private function regionGet( $guid:String ):Region
	{
		for each ( var region:Region in _regions ) {
			if ( region && region.guid == $guid ) {
				return region;
			}
		}
		return null;
	}
	
	public function regionHas( $guid:String ):Boolean
	{
		for each ( var region:Region in _regions ) {
			if ( region && region.guid == $guid ) {
				return true;
			}
		}
		return false;
	}

} // RegionManager
} // Package