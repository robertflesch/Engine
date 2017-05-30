/*==============================================================================
Copyright 2011-2017 Robert Flesch
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
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.server.Network;
import com.voxelengine.server.Room;
import com.voxelengine.worldmodel.models.types.Axes;
import com.voxelengine.worldmodel.models.types.VoxelModel;

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
	
	static private var _s_instance:RegionManager;
	static public function get instance():RegionManager {
		if ( null == _s_instance )
			_s_instance = new RegionManager();		
		return _s_instance	
	}
	
	public function RegionManager():void {
		_regions = new Vector.<Region>;

		RegionEvent.addListener( RegionEvent.JOIN, 				requestServerJoin ); 
		RegionEvent.addListener( ModelBaseEvent.REQUEST_TYPE, 	regionTypeRequest );
		RegionEvent.addListener( ModelBaseEvent.REQUEST, 		regionRequest );
		RegionEvent.addListener( ModelBaseEvent.SAVE, 			save );
		RegionEvent.addListener( RegionEvent.ADD_MODEL, 		addModel );

		RoomEvent.addListener( RoomEvent.ROOM_DISCONNECT, 		requestDefaultRegionLoad );
		RoomEvent.addListener( RoomEvent.ROOM_JOIN_SUCCESS, 	onJoinRoomEvent );
		
		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFail );
		PersistenceEvent.addListener( PersistenceEvent.CREATE_SUCCEED, 	regionCreatedHandler );
									  
		LoadingEvent.addListener( LoadingEvent.LOAD_CONFIG_COMPLETE, configComplete );
	}
	
	/**
	 * @param  - RegionEvent generated by a region when it has 
	 * @return - None
	 * Generates Event RegionEvent.UNLOAD if it is the current region
	*/
	//private function regionLoad( $re:RegionEvent ):void {
		//Log.out( "RegionManager.load - region: " + $re.guid, Log.DEBUG );
		//WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.CREATE ) );
		//
		//RegionEvent.dispatch( new RegionEvent( RegionEvent.UNLOAD, 0, null ) );
		//RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD, 0, $re.guid ) );
	//}
	
	private function regionRequest( $re:RegionEvent):void {
		
		if ( null == $re.guid ) {
			Log.out( "RegionManager.regionRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		Log.out( "RegionManager.regionRequest guid: " + $re.guid, Log.INFO );
		var region:Region = regionGet( $re.guid );
		if ( region ) {
			RegionEvent.create( ModelBaseEvent.RESULT, 0, region.guid, region );
			return;
		}
		
		if ( true == Globals.online )
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $re.series, Globals.BIGDB_TABLE_REGIONS, $re.guid ) );
		else	
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $re.series, Globals.REGION_EXT, $re.guid, null, null ) );
	}
	
	private function regionTypeRequest(e:RegionEvent):void {
		
		if ( Network.PUBLIC == e.guid && false == _requestPublic ) {
			_requestPublic = true;
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, e.series, Globals.BIGDB_TABLE_REGIONS, Network.PUBLIC, null, Globals.BIGDB_TABLE_REGIONS_INDEX_OWNER ) );
		}
		if ( Network.userId == e.guid && false == _requestPrivate ) {
			_requestPrivate = true;
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, e.series, Globals.BIGDB_TABLE_REGIONS, Network.userId, null, Globals.BIGDB_TABLE_REGIONS_INDEX_OWNER ) );
		}
			
		// Get a list of what we currently have
		for each ( var region:Region in _regions ) {
			if ( region && region.owner == e.guid )
				RegionEvent.create( ModelBaseEvent.RESULT, 0, region.guid, region );
		}
	}
	
	private function loadFail( $pe:PersistenceEvent ):void {
		if ( Globals.BIGDB_TABLE_REGIONS != $pe.table && Globals.REGION_EXT != $pe.table )
			return;
			
		Log.out( "RegionManager.loadFail - region: " + $pe.guid, Log.ERROR );
		throw new Error( "RegionManager.loadFail - why did I fail to load region PersistenceEvent: " + $pe.toString(), Log.WARN );
	}
	
	private function loadSucceed( $pe:PersistenceEvent ):void {
		if ( Globals.BIGDB_TABLE_REGIONS == $pe.table || Globals.REGION_EXT == $pe.table ) {
			//Log.out( "RegionManager.loadSucceed - creating new region: " + $pe.guid, Log.DEBUG );
			var newRegion:Region = new Region( $pe.guid, $pe.dbo, $pe.data );
			add( $pe, newRegion );
		}
	}
	
	public function add($pe:PersistenceEvent, $region:Region ):void {
		//Log.out( "RegionManager.regionAdd - adding region: " + $region.guid, Log.DEBUG );
		if ( false == regionHas( $region.guid ) ) {
			_regions.push( $region );
			RegionEvent.create( ModelBaseEvent.ADDED, ($pe ? $pe.series: 0), $region.guid, $region );
		}
		else
			Log.out( "RegionManager.regionAdd - NOT loading duplicate region: " + $region.guid, Log.DEBUG );
	}
	
	////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////
	
	public function configComplete( $e:LoadingEvent ):void {
		startWithEmptyRegion();
		Axes.createAxes();

		// Add a listener to tell when file has been loaded
//		RegionEvent.addListener( ModelBaseEvent.ADDED, startingRegionLoaded );
		// now request the file be loaded
//		RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.REQUEST, 0, $guid ) );
	}
	
	public function startWithEmptyRegion():void {
		var startingRegion:Region = new Region( "Blank", null, {} );
		add( null, startingRegion );
		RegionEvent.create( RegionEvent.LOAD, 0, startingRegion.guid );
		//RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_COMPLETE, 0, startingRegion.guid ) );
		// This tells the config manager that the local region was loaded and is ready to load rest of data.
	}
	
	private function startingRegionLoaded( $re:RegionEvent):void {
		// remove this handler
		RegionEvent.removeListener( ModelBaseEvent.ADDED, startingRegionLoaded );
		// now load the file that was designated as the starting region
		RegionEvent.create( RegionEvent.LOAD, 0, $re.guid, $re.data );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	static public function requestServerJoin( e:RegionEvent ):void {
		//Log.out( "RegionManager.requestServerJoin - guid: " + e.guid, Log.DEBUG );
		Room.createJoinRoom( e.guid );	
	}
	
	static public function requestDefaultRegionLoad( e:RoomEvent ):void {
		Log.out( "RegionManager.requestDefaultRegionLoad", Log.DEBUG );
		var defaultRegionJSON:Object = ConfigManager.instance.defaultRegionJson;
		var defaultRegionID:String = defaultRegionJSON.config.region.startingRegion;
		Room.createJoinRoom( defaultRegionID );	
	}
	
	public function onJoinRoomEvent( e:RoomEvent ):void {
		//Log.out( "RegionManager.onJoinRoomEvent - guid: " + e.guid, Log.DEBUG );
		RegionEvent.create( RegionEvent.LOAD, 0, e.guid );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	
	// this calls the region and its model manager to update
	public function update( $elapsed:int ):void {
		if ( Region.currentRegion )
			Region.currentRegion.update( $elapsed );
	}
	
	// Just assign the dbo from the create to the region
	private function regionCreatedHandler( $pe:PersistenceEvent ):void {
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
	
	private function regionGet( $guid:String ):Region {
		for each ( var region:Region in _regions ) {
			if ( region && region.guid == $guid ) {
				return region;
			}
		}
		return null;
	}
	
	public function regionHas( $guid:String ):Boolean {
		var region:Region = regionGet( $guid );
		return (null != region);
	}

	private function save( $re:RegionEvent ):void {
		var region:Region = regionGet( $re.guid );
		if ( region )
			region.save();
	}

	private function addModel( $re:RegionEvent ):void {
		var region:Region = regionGet( $re.guid );
		if ( region )
			region.modelCache.add( $re.data );
	}

} // RegionManager
} // Package