/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.RegionPersistanceEvent;
import com.voxelengine.worldmodel.inventory.InventoryManager;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.geom.Vector3D;
import flash.net.FileReference;
import flash.net.URLRequest;
import mx.utils.StringUtil;

import playerio.PlayerIOError;
import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.RoomEvent;
import com.voxelengine.server.Network;
import com.voxelengine.server.Room;
import com.voxelengine.persistance.PersistRegion;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelLoader;
import com.voxelengine.worldmodel.models.ModelManager;
import com.voxelengine.worldmodel.models.VoxelModel;
import com.voxelengine.utils.CustomURLLoader;
import com.voxelengine.worldmodel.models.MetadataManager;

import com.voxelengine.GUI.WindowSplash;
/**
 * ...
 * @author Bob
 */
public class RegionManager 
{
	private var _regions:Vector.<Region> = null
	private var _currentRegion:Region = null
	private var _modelLoader:ModelLoader = new ModelLoader();
	private var _initialized:Boolean;
	
	public function get size():int { return _regions.length; }
	
	public function get currentRegion():Region { return _currentRegion; }
	public function set currentRegion(val:Region):void { 
		_currentRegion = val; 
		Log.out("RegionManager.currentRegion - set to: " + val.guid, Log.DEBUG ) 
	}
	
	public function get regions():Vector.<Region> { return _regions; }
	
	public function get modelLoader():ModelLoader { return _modelLoader; }
	
	public function RegionManager():void 
	{
		_regions = new Vector.<Region>;

		RegionEvent.addListener( RegionEvent.REGION_LOAD, regionLoad ); 
		RegionEvent.addListener( RegionEvent.REQUEST_JOIN, requestServerJoin ); 
		RegionEvent.addListener( RegionEvent.REGION_CHANGED, regionChanged );	
		RegionEvent.addListener( RegionEvent.REGION_TYPE_REQUEST, regionTypeRequest );
		
		RoomEvent.addListener( RoomEvent.ROOM_DISCONNECT, requestDefaultRegionLoad );
		RoomEvent.addListener( RoomEvent.ROOM_JOIN_SUCCESS, onJoinRoomEvent );
		
		RegionPersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, loadSucceed );			
		RegionPersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, loadFail );			
		RegionPersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED , regionCreatedHandler ); 
		
		Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_ADDED,  regionModelChanged );
		Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_REMOVED, regionModelChanged );
									  
		Globals.g_app.addEventListener( LoadingEvent.MODEL_LOAD_FAILURE, removeFailedObjectFromRegion );									  
		Globals.g_app.addEventListener( LoadingEvent.LOAD_CONFIG_COMPLETE, configComplete );
		
		// This adds the event handlers
		// Is there a central place to do this?
		MetadataManager.init();
		// This causes the to load its caches and listeners
		InventoryManager.init();
		MouseKeyboardHandler.init();
	}
	
	private function regionTypeRequest(e:RegionEvent):void 
	{
		if ( false == _initialized ) {
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Network.PUBLIC ) );			
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_REQUEST_TYPE, Network.userId ) );			
		}
			
		_initialized = true;
		// Get a list of what we currently have
		for each ( var region:Region in _regions ) {
			if ( region && region.owner == e.guid )
				RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_ADDED, region.guid, region ) );
		}
	}
	
	private function loadFail( $rpe:RegionPersistanceEvent ):void 
	{
		Log.out( "RegionManager.loadFail - region: " + $rpe.guid, Log.ERROR );
	}
	
	private function loadSucceed( $rpe:RegionPersistanceEvent ):void 
	{
		Log.out( "RegionManager.loadSucceed - region: " + $rpe.guid, Log.WARN );
		if ( regionHas( $rpe.guid ) ) {
			Log.out( "RegionManager.loadSucceed - NOT loading duplicate region: " + $rpe.guid, Log.DEBUG );
			return;
		}
			
		Log.out( "RegionManager.loadSucceed - creating new region: " + $rpe.guid, Log.DEBUG );
		var newRegion:Region = new Region( $rpe.guid );
		newRegion.loadFromDBO( $rpe.dbo );
		regionAdd( newRegion );
	}
	
	private function regionAdd( $region:Region ):void {
		Log.out( "RegionManager.regionAdd - adding region: " + $region.guid, Log.DEBUG );
		_regions.push( $region );
		RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_ADDED, $region.guid, $region ) );
	}
	
	private function regionChanged( $re:RegionEvent):void 
	{
		var region:Region = regionGet( $re.guid );
		if ( region )
			region.save();
		else	
			Log.out( "RegionManager.regionChanged- did not find: " + $re.guid + " in order to save", Log.ERROR );
	}
	
	
	private function regionModelChanged( me:ModelEvent ):void { 
		var region:Region = currentRegion;
		if ( region && region.loaded )
			currentRegion.changed = true;
	}
	

	
	////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////
	
	private function removeFailedObjectFromRegion( $e:LoadingEvent):void {
		// Do I need to remove this failed load?
		Log.out( "RegionManager.removeFailedObjectFromRegion - failed to load: " + $e.guid, Log.ERROR );
		currentRegion.changedForce = true;
		// Dont want to save if partially loaded
		//currentRegion.save();
	}
	
	public function configComplete( $e:LoadingEvent ):void
	{
		var startingRegion:Region = new Region( $e.guid );
		startingRegion.createEmptyRegion();
		regionAdd( startingRegion );
		RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_LOAD, startingRegion.guid ) ); 
		RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_LOAD_COMPLETE, startingRegion.guid ) );
		// This tells the config manager that the local region was loaded and is ready to load rest of data.
		
		//var fileNamePathWithExt:String = Globals.regionPath + $e.guid + ".rjson"
		//Log.out( "RegionManager.requestStartingRegionFile - downloading: " + fileNamePathWithExt, Log.DEBUG );
		//var _urlLoader:CustomURLLoader = new CustomURLLoader(new URLRequest( fileNamePathWithExt ));
		//_urlLoader.addEventListener(Event.COMPLETE, onStartingRegionLoadedActionFromFile );
		//_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onRegionLoadError );			
	}
	
	/*
	private function onRegionLoadError(error:IOErrorEvent):void
	{
		Log.out("RegionManager.onRegionLoadError - ERROR: " + error.toString(), Log.ERROR );
	}

	private function onStartingRegionLoadedActionFromFile(event:Event):void
	{
		Log.out( "RegionManager.onRegionLoadedActionFromFile", Log.DEBUG );
		var guid:String = CustomURLLoader(event.target).fileName;			
		guid = guid.substr( 0, guid.indexOf( "." ) );
		var newRegion:Region = new Region( guid );
		var jsonString:String = StringUtil.trim(String(event.target.data));
		newRegion.initJSON( jsonString );
		// This adds it to the list of regions
		RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_LOAD_COMPLETE, newRegion.guid ) );
		// This tells the config manager that the local region was loaded and is ready to load rest of data.
		RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_LOAD, guid ) ); 
	}
	*/
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	static public function requestServerJoin( e:RegionEvent ):void {
		Log.out( "RegionManager.requestServerJoin - guid: " + e.guid, Log.DEBUG );
		Room.createJoinRoom( e.guid );	
	}
	
	static public function requestDefaultRegionLoad( e:RoomEvent ):void {
		Log.out( "RegionManager.requestDefaultRegionLoad", Log.DEBUG );
		var defaultRegionJSON:Object = Globals.g_app.configManager.defaultRegionJson;
		var defaultRegionID:String = defaultRegionJSON.config.region.startingRegion;
		Room.createJoinRoom( defaultRegionID );	
	}
	
	public function onJoinRoomEvent( e:RoomEvent ):void {
		Log.out( "RegionManager.onJoinRoomEvent - guid: " + e.guid, Log.DEBUG );
		
//		var region:Region = regionGet( e.guid );
		RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_LOAD, e.guid ) );
	}
	
	private function regionLoadedFromPersistance( $rpe:RegionPersistanceEvent ):void {
		RegionPersistanceEvent.removeListener( PersistanceEvent.LOAD_SUCCEED, regionLoadedFromPersistance );
		RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_LOAD, $rpe.guid ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	
	// this calls the region and its model manager to update
	public function update( $elapsed:int ):void {
		if ( currentRegion )
			currentRegion.update( $elapsed );
	}
	
	// Just assign the dbo from the create to the region
	private function regionCreatedHandler( e:RegionPersistanceEvent ):void {
		Log.out( "RegionManager.regionCreatedHandler: " + e.guid );
		// check for duplicates
		var region:Region = regionGet( e.guid )
		if ( region )
			region.databaseObject = e.dbo;
		else	
			Log.out( "RegionManager.regionCreatedHandler: ERROR region not found for returned guid: " + e.guid );
	}
	
	/**
	 * @param  - guid of region
	 * @return - region or null
	 * 
	*/
	public function regionGet( $guid:String ):Region
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

	/**
	 * @param  - RegionEvent generated by a region when it has 
	 * @return - region or null, if null tries to load it from persistance
	 * Generates Event RegionLoadedEvent.REGION_LOADED when region is loaded
	*/
	private function regionLoad( $re:RegionEvent ):void
	{
		Log.out( "RegionManager.load - region: " + $re.guid, Log.DEBUG );
		if ( !WindowSplash.isActive )
			WindowSplash.create();
		
		if ( currentRegion )
			RegionEvent.dispatch( new RegionEvent( RegionEvent.REGION_UNLOAD, currentRegion.guid ) );

		var region:Region = regionGet( $re.guid );
		if ( region ) {
			currentRegion = region;
			region.load();
			return;
		}
		else
			RegionPersistanceEvent.dispatch( new RegionPersistanceEvent( PersistanceEvent.LOAD_REQUEST, $re.guid ) );		
		
		// Should never get here
		// No matching region found, so we have to go load it
		var newRegion:Region = new Region( "ERROR_ID" );
		newRegion.createEmptyRegion();
		currentRegion = newRegion;
		Log.out( "RegionManager.loadRegion - ERROR creating new region: " + $re.guid, Log.ERROR );
	}
	
	public function save():void
	{
		Log.out( "RegionManager.save", Log.DEBUG );
		if ( true == Globals.online && true == Globals.inRoom ) {
			currentRegion.save()
		}
		else {
			var fr:FileReference = new FileReference();
			fr.save( currentRegion.getJSON(), currentRegion.guid );
		}
	}
	
} // RegionManager
} // Package