/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import flash.events.Event;
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
//import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.RegionLoadedEvent;
import com.voxelengine.events.RoomEvent;
import com.voxelengine.server.Network;
import com.voxelengine.server.Room;
import com.voxelengine.server.PersistRegion;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelLoader;
import com.voxelengine.worldmodel.models.ModelManager;
import com.voxelengine.worldmodel.models.VoxelModel;
import com.voxelengine.utils.CustomURLLoader;
import com.voxelengine.worldmodel.models.TemplateManager;

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

		Globals.g_app.addEventListener( RegionEvent.REGION_LOAD, regionLoad ); 
		Globals.g_app.addEventListener( RoomEvent.ROOM_JOIN_SUCCESS, onJoinRoomEvent );
		
		Globals.g_app.addEventListener( RegionEvent.REQUEST_JOIN, requestServerJoin ); 
		Globals.g_app.addEventListener( RegionLoadedEvent.REGION_CREATED, regionCreatedHandler ); 
		
		
		Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_ADDED
									  ,  function( me:ModelEvent ):void { if ( currentRegion ){ currentRegion.changed = true;}} );
		Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_REMOVED
									  ,  function( me:ModelEvent ):void { if ( currentRegion ) { currentRegion.changed = true; }} );
									  
		Globals.g_app.addEventListener( LoadingEvent.MODEL_LOAD_FAILURE, removeFailedObjectFromRegion );									  
		Globals.g_app.addEventListener( LoadingEvent.LOAD_CONFIG_COMPLETE, requestStartingRegionFile );
		
		Globals.g_app.addEventListener( RoomEvent.ROOM_DISCONNECT, requestDefaultRegionLoad );
		
		
		// This adds the event handlers
		TemplateManager.addEvents();
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
	
	public function requestStartingRegionFile( $e:LoadingEvent ):void
	{
		var fileNamePathWithExt:String = Globals.regionPath + $e.guid + ".rjson"
		Log.out( "RegionManager.requestStartingRegionFile - downloading: " + fileNamePathWithExt, Log.DEBUG );
		var _urlLoader:CustomURLLoader = new CustomURLLoader(new URLRequest( fileNamePathWithExt ));
		_urlLoader.addEventListener(Event.COMPLETE, onStartingRegionLoadedActionFromFile );
		_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onRegionLoadError );			
	}
	
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
		Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_CREATED, newRegion ) );
		// This tells the config manager that the local region was loaded and is ready to load rest of data.
		Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_LOAD, guid ) ); 
	}
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
		
		var region:Region = regionGet( e.guid );
		if ( null == region ) {
			Globals.g_app.addEventListener( RegionLoadedEvent.REGION_LOADED, regionLoadedFromPersistance );
			return;
		}
		Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_LOAD, e.guid ) );
	}
	
	private function regionLoadedFromPersistance( $rle:RegionLoadedEvent ):void {
		Globals.g_app.removeEventListener( RegionLoadedEvent.REGION_LOADED, regionLoadedFromPersistance );
		Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_LOAD, $rle.region.guid ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////
	
	// this calls the region and its model manager to update
	public function update( $elapsed:int ):void {
		if ( currentRegion )
			currentRegion.update( $elapsed );
	}
	
	// This adds both local and remote region to the _regions list.
	private function regionCreatedHandler( e:RegionLoadedEvent ):void {

//		Log.out( "RegionManager.regionCreatedHandler: " + e.region.toString() );
		// check for duplicates
		for each ( var region:Region in _regions ) {
			if ( region.guid == e.region.guid ) {
				Log.out( "RegionManager.regionCreatedHandler - DUPS FOUND: " + e.region.toString(), Log.WARN );
				return;
			}
		}
		
		// if this is a newly created region, save it.
		if ( Globals.online )
			if ( null == e.region.databaseObject )
				e.region.save();
				
		_regions.push( e.region );
		
		Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_LOADED, e.region ) );
	}
	
	/**
	 * @param  - guid of region
	 * @return - region or null, if null tries to load it from persistance
	 * Generates Event RegionLoadedEvent.REGION_LOADED when region is loaded
	*/
	public function regionGet( $guid:String ):Region
	{
		for each ( var region:Region in _regions ) {
			if ( region && region.guid == $guid ) {
				return region;
			}
		}
		
		// if not found load it
		PersistRegion.loadRegion( $guid );
		
		return null;
	}
	
	/**
	 * @param  - RegionEvent generated by a region when it has 
	 * @return - region or null, if null tries to load it from persistance
	 * Generates Event RegionLoadedEvent.REGION_LOADED when region is loaded
	*/
	private function regionLoad( e:RegionEvent ):void
	{
		Log.out( "RegionManager.load - region: " + e.guid, Log.DEBUG );
		if ( !WindowSplash.isActive )
			WindowSplash.create();
		
		if ( currentRegion )
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_UNLOAD, currentRegion.guid ) );

		var region:Region = regionGet( e.guid );
		if ( region ) {
			currentRegion = region;
			region.load();
			return;
		}
		
		// Should never get here
		// No matching region found, so we have to go load it
		var newRegion:Region = new Region( "ERROR_ID" );
		newRegion.createEmptyRegion();
		currentRegion = newRegion;
		Log.out( "RegionManager.loadRegion - ERROR creating new region: " + e.guid, Log.ERROR );
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