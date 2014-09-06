/*==============================================================================
Copyright 2011-2013 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.LoginEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.RegionLoadedEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.Globals;
import com.voxelengine.GUI.WindowRegionNew;
import com.voxelengine.GUI.WindowSandboxList;
import com.voxelengine.GUI.WindowSplash;
import com.voxelengine.Log;
import com.voxelengine.server.Network;
import com.voxelengine.server.VVServer;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.FileReference;
import org.flashapi.swing.Alert;
import playerio.PlayerIOError;
import playerio.DatabaseObject;
import com.voxelengine.server.Persistance;
import com.voxelengine.server.Network;
import mx.utils.StringUtil;
import com.voxelengine.utils.CustomURLLoader;
	import flash.net.URLRequest;

import com.voxelengine.worldmodel.Region;
/**
 * ...
 * @author Bob
 */
public class RegionManager 
{
	private var _regions:Vector.<Region> = null
	private var _currentRegion:Region = null
	
	public function get size():int { return _regions.length; }
	
	public function get currentRegion():Region { return _currentRegion; }
	public function set currentRegion(val:Region):void { 
		_currentRegion = val; 
		Log.out("RegionManager.currentRegion - set to: " + val.regionId ) 
	}
	
	public function get regions():Vector.<Region> { return _regions; }
	
	public function RegionManager():void 
	{
		_regions = new Vector.<Region>;
		
		Globals.g_app.addEventListener( RegionEvent.REQUEST_PUBLIC, cacheRequestPublic ); 
		Globals.g_app.addEventListener( RegionEvent.REQUEST_PRIVATE, cacheRequestPrivate ); 

		Globals.g_app.addEventListener( RegionEvent.REGION_LOAD, load ); 
		
		Globals.g_app.addEventListener( RegionLoadedEvent.REGION_CREATED, regionCreatedHandler ); 
		
		
		Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_ADDED
									  ,  function( me:ModelEvent ):void { if ( currentRegion ){ currentRegion.changed = true;}} );
		Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_REMOVED
									  ,  function( me:ModelEvent ):void { if ( currentRegion ){ currentRegion.changed = true;}} );
	}
	
	public function cacheRequestPrivate( e:RegionEvent ):void
	{
		Persistance.loadRegions( Network.userId );
	}
	
	public function cacheRequestPublic( e:RegionEvent ):void
	{
		Persistance.loadRegions( Persistance.DB_PUBLIC );
	}
	
	public function request( $regionId:String ):void
	{
		var fileNamePathWithExt:String = Globals.regionPath + $regionId + ".rjson"
		Log.out( "RegionManager.request - loading: " + fileNamePathWithExt );
		var _urlLoader:CustomURLLoader = new CustomURLLoader(new URLRequest( fileNamePathWithExt ));
		_urlLoader.addEventListener(Event.COMPLETE, onRegionLoadedAction);
		_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function (e:IOErrorEvent):void { Log.out("RegionManager.errorAction: " + e.toString(), Log.ERROR); }	);			
	}

	private function onRegionLoadedAction(event:Event):void
	{
		Log.out( "RegionManager.onRegionLoadedAction" );
		var req:URLRequest = CustomURLLoader(event.target).request;			
		var regionId:String = CustomURLLoader(event.target).fileName;			
		regionId = regionId.substr( 0, regionId.indexOf( "." ) );
		var newRegion:Region = new Region( regionId );
		var jsonString:String = StringUtil.trim(String(event.target.data));
		newRegion.processRegionJson( jsonString );
		// This adds it to the list of regions
		Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_CREATED, newRegion ) );
		// This tells the config manager that the local region was loaded and is ready to load rest of data.
		Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_STARTING_LOADED, regionId ) );
	}
	
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
			if ( region.regionId == e.region.regionId ) {
				Log.out( "RegionManager.regionCreatedHandler - DUPS FOUND: " + e.region.toString() );
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
	
	public function getRegion( $regionId:String ):Region
	{
		for each ( var region:Region in _regions ) {
			if ( region && region.regionId == $regionId ) {
				return region;
			}
		}
		return null;
	}
	
	private function load( e:RegionEvent ):void
	{
		if ( !WindowSplash.isActive )
			WindowSplash.create();
		
		if ( currentRegion )
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_UNLOAD, currentRegion.regionId ) );

		var region:Region = getRegion( e.regionId );
		if ( region ) {
			currentRegion = region;
			region.load();
			return;
		}
		
		// Should never get here
		// No matching region found, so we have to go load it
		var newRegion:Region = new Region( "ERROR_ID" );
		currentRegion = newRegion;
		Log.out( "RegionManager.loadRegion - ERROR creating new region: " + e.regionId, Log.ERROR );
	}
	
	public function save():void
	{
		Log.out( "RegionManager.save" );
		if ( Globals.online ) {
			currentRegion.save()
		}
		else {
			var fr:FileReference = new FileReference();
			fr.save( currentRegion.getJSON(), currentRegion.regionId );
		}
		
		//////////////////////////
			/*
	private function newRegionCreate( e:RegionEvent ):void
	{
		var region:Region = getRegion( e.regionId );
		if ( region )
			region.save();
		else
			throw new Error( "RegionManager.newRegionCreate - NO Region" );
			
	}
	
	private function newRegionCreateSucceed( e:PersistanceEvent ):void
	{
		Globals.g_app.removeEventListener( PersistanceEvent.PERSISTANCE_CREATE_SUCCESS, newRegionCreateSucceed ); 
		Globals.g_app.removeEventListener( PersistanceEvent.PERSISTANCE_CREATE_FAILURE, newRegionCreateFailure );
		if ( !WindowSandboxList.isActive )
			WindowSandboxList.create();
	}
	private function newRegionCreateFailure( e:PersistanceEvent ):void
	{
		Globals.g_app.removeEventListener( PersistanceEvent.PERSISTANCE_CREATE_SUCCESS, newRegionCreateSucceed ); 
		Globals.g_app.removeEventListener( PersistanceEvent.PERSISTANCE_CREATE_FAILURE, newRegionCreateFailure ); 
		new Alert( "RegionManager.newRegionCreateFailure - Failed to create new Region on Server" );
		if ( !WindowSandboxList.isActive )
			WindowSandboxList.create();
	}
	*/

	}
} // RegionManager
} // Package