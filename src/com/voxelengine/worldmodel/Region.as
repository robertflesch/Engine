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
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.RegionLoadedEvent;
	import com.voxelengine.server.Persistance;
	import com.voxelengine.server.Network;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
    import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
    import flash.utils.Timer;
	import flash.net.FileReference;
	
	import mx.utils.StringUtil;
	
	import playerio.DatabaseObject;
	import playerio.PlayerIOError;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	import com.voxelengine.server.Persistance;

	//{
	   //"region":[
		  //{"model":{
			 //"instanceGuid":"1",
			 //"modelGuid":"6spheres",
			 //"texture":{ "textureName":"assets/textures/oxel.png", "textureScale":"2048" },
			 //"shader":{  "name":"com.voxelengine.renderer.shaders.ShaderOxel" },
			 //"scale" :{ "rootGrain" : "6", "x":"1", "y":"1", "z":"1" },
			//"location" : {  "x":"0", "y":"0", "z":"0" },
			//"rotation" : { "x":"0", "y":"0", "z":"0" }
			 //},
			 //"transform" : {
				//"angularVelocity" : {  "x":"0", "y":"0", "z":"0", "time":"-1" },
				//"rotationalVelocity" : {  "x":"0", "y":"0", "z":"0", "time":"-1" },
				//"life" : {  "x":"0", "y":"0", "z":"0", "time":"-1" }
			 //}
		  //}},
		  //{"model":{
			 //"instanceGuid":"1",
			 //"modelGuid":"6spheres",
			 //"texture":{ "textureName":"assets/textures/oxel.png", "textureScale":"2048" },
			 //"shader":{  "name":"com.voxelengine.renderer.shaders.ShaderOxel" },
			 //"scale" :{ "rootGrain" : "6", "x":"1", "y":"1", "z":"1" },
			//"location" : {  "x":"0", "y":"0", "z":"0" },
			//"rotation" : { "x":"0", "y":"0", "z":"0" }
			 //},
			 //"transform" : {
				//"angularVelocity" : {  "x":"0", "y":"0", "z":"0", "time":"-1" },
				//"rotationalVelocity" : {  "x":"0", "y":"0", "z":"0", "time":"-1" },
				//"life" : {  "x":"0", "y":"0", "z":"0", "time":"-1" }
			 //}
		  //}}
	   //]
	//}	
	
	//name: friendly name
	//world: guid
	//region: 000000-000000-000000
	//template: guid
	//owner: user Id1
	//editors: { user Id1:role, user id2:role... }
	//admin: { user Id1:role, user id2:role... }
	//created: date
	//modified: date
	//data: encoded jsonString
	//
	/**
	 * ...
	 * @author Bob
	 */
	public class Region 
	{
		static public const DEFAULT_REGION_ID:String = "000000-000000-000000";
		static private const BLANK_REGION_TEMPLETE:String = "{\"region\":[],\"skyColor\": {\"r\":92,\"g\":172,\"b\":238 },\"gravity\":false }";
		private var _name:String = "";
		private var _desc:String = "";
		private var _worldId:String = "VoxelVerse";
		private var _regionId:String = DEFAULT_REGION_ID;
		private var _template:String = DEFAULT_REGION_ID;
		private var _owner:String;
		private var _editors:Vector.<String> = new Vector.<String>() //{ user Id1:role, user id2:role... }
		private var _admin:Vector.<String> = new Vector.<String>() // : { user Id1:role, user id2:role... }
		private var _created:Date;
		private var _modified:Date;
		private var _data:String;
		private var _JSON:Object;
		private var _databaseObject:DatabaseObject  = null;							// INSTANCE NOT EXPORTED
		private var _changed:Boolean;
        private var _changeTimer:Timer;
		private var _playerPosition:Vector3D = new Vector3D();
		private var _playerRotation:Vector3D = new Vector3D();
		private var _loaded:Boolean = true;


		public function get databaseObject():DatabaseObject { return _databaseObject; }
		public function set databaseObject(val:DatabaseObject):void { _databaseObject = val; }
		
		private var _skyColor:Vector3D = new Vector3D(92, 	172, 	238);
		private var _gravity:Boolean = true;
		
		public function get worldId():String { return _worldId; }
		public function set worldId(val:String):void { _worldId = val; }
		public function get owner():String { return _owner; }
		public function set owner(val:String):void { _owner = val; }
		public function get desc():String { return _desc; }
		public function set desc(val:String):void { _desc = val; }
		public function get name():String { return _name; }
		public function set name(val:String):void { _name = val; }
		public function get regionId():String { return _regionId; }
		public function set regionId(val:String):void { _regionId = val; }
//		public function get regionJson():String { return _regionJson; }
		public function get gravity():Boolean { return _gravity; }
		public function set gravity(val:Boolean):void { _gravity = val; }
		public function get changed():Boolean { return _changed; }
		public function set changed(val:Boolean):void 
		{ 
			if ( !_loaded )
				return;
			Log.out( "Region.changed: " + val );
			_changed = val; 
		}
		
		private var _criticalModelDetected:Boolean = false;
		public function get criticalModelDetected():Boolean { return  _criticalModelDetected; } 
		
		public function get playerPosition():Vector3D 
		{
			return _playerPosition;
		}
		
		public function get playerRotation():Vector3D 
		{
			return _playerRotation;
		}
		
		public function get admin():Vector.<String> 
		{
			return _admin;
		}
		
		public function set admin(value:Vector.<String>):void 
		{
			_admin = value;
		}
		
		public function get editors():Vector.<String> 
		{
			return _editors;
		}
		
		public function set editors(value:Vector.<String>):void 
		{
			_editors = value;
		}
		
		public function get created():Date 
		{
			return _created;
		}
		
		public function set created(value:Date):void 
		{
			_created = value;
		}
		
		public function get modified():Date 
		{
			return _modified;
		}
		
		public function set modified(value:Date):void 
		{
			_modified = value;
		}
		
		private function onCriticalModelDetected( me:ModelEvent ):void
		{
			_criticalModelDetected = true;
			Log.out( "Region.criticalModelDetected" );
		}
		
		public function Region():void 
		{
			_created = new Date();
			_modified = _created;
		}
			
		private function onRegionUnload( le:RegionEvent ):void
		{
			if ( regionId == le.regionId )
				unload();
		}
		
		private function onLoadingComplete( le:LoadingEvent ):void
		{
			Log.out( "Region.onLoadingComplete: regionId: " + regionId );
			_loaded = true;
			Globals.g_app.removeEventListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
		}

		public function unload():void
		{
			Log.out( "Region.unloadRegion: " + regionId );
			// Removes anonymous function
			Globals.g_app.removeEventListener( RegionEvent.REGION_MODIFIED, handleRegionModified );
			Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_ADDED, function( me:ModelEvent ):void { ; } );
			Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_REMOVED, function( me:ModelEvent ):void { ; } );
			Globals.g_app.removeEventListener( ModelEvent.CRITICAL_MODEL_DETECTED, onCriticalModelDetected );
			Globals.g_modelManager.removeAllModelInstances();
		}
		
		public function request( $regionId:String ):void
		{
			_regionId = $regionId;
			var _urlLoader:URLLoader = new URLLoader();
			var fileNameWithExt:String = $regionId + ".rjson"
			Log.out( "Region.request - loading: " + Globals.regionPath + fileNameWithExt );
			_urlLoader.load(new URLRequest( Globals.regionPath + fileNameWithExt ));
			_urlLoader.addEventListener(Event.COMPLETE, onRegionLoadedAction);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorAction);			
			_urlLoader.addEventListener(ProgressEvent.PROGRESS, onProgressAction);
		}

		private function onRegionLoadedAction(event:Event):void
		{
			trace( "Region.onRegionLoadedAction" );

			var jsonString:String = StringUtil.trim(String(event.target.data));
			processRegionJson( jsonString );
		}
		
		private function handleRegionModified( $re:RegionEvent ):void {
			changed = true;	
			save();
		}
				
		public function load():void
		{
			Log.out( "Region.load - loading region: " + regionId + "  name: " +  name );
			Globals.g_app.addEventListener( RegionEvent.REGION_UNLOAD, onRegionUnload );
			Globals.g_app.addEventListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
			Globals.g_app.addEventListener( ModelEvent.CRITICAL_MODEL_DETECTED, onCriticalModelDetected );
			Globals.g_app.addEventListener( RegionEvent.REGION_MODIFIED, handleRegionModified);

			var count:int = Globals.g_modelManager.loadRegionObjects(_JSON.region);
			if ( 0 < count )
				_loaded = false;

			//if ( 0 == count )
			//	Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_COMPLETE ) );

			
			if ( 0 == count && name != "defaultRegion" )
				Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_COMPLETE ) );
			
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_LOAD_BEGUN, regionId ) );
			Log.out( "Region.load - completed processing on: " + name );
		}		

		private function onProgressAction(event:ProgressEvent):void
		{
			var percentLoaded:Number=event.bytesLoaded/event.bytesTotal*100;
			//trace("Region.onProgressAction: "+percentLoaded+"%");
			//trace("loading xml");
		}
		
		public function getSkyColor():Vector3D
		{
			return _skyColor;
		}
		
		public function setSkyColor( r:int, g:int, b:int ):void
		{
			_skyColor.x = r;
			_skyColor.y = g;
			_skyColor.z = b;
		}
		
		public function processRegionJson( $regionJson:String ):void
		{
			//Log.out( "Region.processRegionJson: " + $regionJson );
			_JSON = JSON.parse($regionJson);
			if ( _JSON.skyColor )
				setSkyColor( _JSON.skyColor.r, _JSON.skyColor.g, _JSON.skyColor.b );
				
			if ( _JSON.name && "" == _name )
				_name = _JSON.name;

			if ( _JSON.desc  && "" == _desc )
				_desc = _JSON.desc;
				
			if ( _JSON.gravity )
				_gravity = true;
			else		
				_gravity = false;
				
			if ( _JSON.modified )
				_modified = _JSON.modified as Date;
				
			if ( _JSON.created )
				_created = _JSON.created as Date;
					
			if ( _JSON.playerPosition )
				_playerPosition.setTo( _JSON.playerPosition.x, _JSON.playerPosition.y, _JSON.playerPosition.z );
			
			if ( _JSON.playerRotation )
				_playerRotation.setTo( 0, _JSON.playerRotation, 0 );
				
			if ( !Globals.online )
//				Globals.g_app.dispatchEvent( new RegionLoadedEvent( RegionLoadedEvent.REGION_EVENT_LOADED, this ) );
//			else
				Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_CACHE_COMPLETE, regionId ) );
		}
		
		public function toString():String {

			var outString:String = "  name:" + JSON.stringify(name);
			outString += "  owner:" + JSON.stringify( _owner );
			outString += "  gravity:" + JSON.stringify(gravity);
			outString += "  desc:" + JSON.stringify(desc);
			outString += "  created:" + JSON.stringify(_created);
			outString += "  modifed:" + JSON.stringify(_modified);
			outString += "  editors:" + JSON.stringify(_editors);
			outString += "  admin:" + JSON.stringify(_admin);
			return outString;
		}
		
		public function getJSON():String
		{
			var outString:String = "{\"region\":[";
			outString = Globals.g_modelManager.getModelJson(outString);
			outString += "],"
			// if you dont do it this way, there is a null at begining of string
			outString += "\"skyColor\": {" + "\"r\":" + _skyColor.x  + ",\"g\":" + _skyColor.y + ",\"b\":" + _skyColor.z + "}";
			outString += ","
			outString += "\"gravity\":" + JSON.stringify(gravity);
			outString += ","
			outString += "\"name\":" + JSON.stringify(name);
			outString += ","
			outString += "\"desc\":" + JSON.stringify(desc);
			outString += ","
			outString += "\"created\":" + JSON.stringify(_created);
			outString += ","
			outString += "\"modifed\":" + JSON.stringify(_modified);
			outString += ","
			outString += "\"editors\":" + JSON.stringify(_editors);
			outString += ","
			outString += "\"admin\":" + JSON.stringify(_admin);
			outString += "}"
			return outString;
		}

		
		private function errorAction(e:IOErrorEvent):void
		{
			trace("Region.errorAction: " + e.toString());
		}	
		
		private function changeRegionId():void
		{
			var newId:String = Globals.getUID();
			_regionId = newId;
		}
		
		public function saveLocal():void 
		{
			var fr:FileReference = new FileReference();
			_modified = new Date();
			var outString:String = getJSON();
			fr.save( outString, regionId );
		}
		
		// TO do I dont like that I have reference to BigDB here
		// this should all get refactored out to be part of the Persistance Object
		public function save():void 
		{
			if ( !changed )
				return;
				
			if ( !Globals.online )
				return;
				
			Log.out( "Region.save - saving changes to Persistance" ); 
			var ba:ByteArray = new ByteArray();
			ba.clear();

			_owner = Network.userId;
			_editors.push( _owner );
			_admin.push( _owner );
			writeToByteArray( ba );
			if ( databaseObject )
			{
				Log.out( "Region.save - saving region back to BigDB: " + regionId );
				databaseObject.data = ba;
				databaseObject.modified = new Date();
				databaseObject.owner = _owner,
				databaseObject.save( false
								   , false
								   , saveSuccess
								   , saveFailed );
			}
			else
			{
				Log.out( "Region.create - creating new region: " + regionId + "" );
				Persistance.createObject( Persistance.DB_TABLE_REGIONS
								  , regionId
								  , metadata( ba )
								  , createSuccess
								  , createFailed );
			}
		}
		
		public function createEmptyRegion():void {
			processRegionJson( BLANK_REGION_TEMPLETE );
		}
		
		private function saveFailed(e:PlayerIOError):void 
		{ 
			Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_SAVE_FAILURE ) ); 
			Log.out( "Region.saveFailed - error saving: " + regionId + " error data: " + e); 
			_changed = false;
		} 
		
		private function saveSuccess():void 
		{ 
			Log.out( "Region.saveSuccess - saved: " + regionId + " name: " + name ); 
			_changed = false;
		}	
		
		private function createSuccess(o:DatabaseObject):void 
		{ 
			if ( o )
				databaseObject = o;
			Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_CREATE_SUCCESS ) ); 
			Log.out( "Region.createSuccess - created: " + regionId ); 
			_changed = false;
		}	
		
		private function createFailed(e:PlayerIOError):void 
		{ 
			Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_CREATE_FAILURE ) ); 
			Log.out( "Region.createFailed - error saving: " + regionId + " error data: " + e); 
			_changed = false;
		} 

		private function writeToByteArray( ba:ByteArray ):void
		{
			var regionJson:String = getJSON();
			//regionJson = encodeURI(regionJson);
			Log.out( "Region.writeToByteArray: " + regionJson );
			ba.writeInt( regionJson.length );
			ba.writeUTFBytes( regionJson );
			//ba.compress();
		}
		
		private function metadata( ba: ByteArray ):Object
		{
			Log.out( "Region.metadata userId: " + Network.userId + "  this region is owned by: " + _owner );
			// give it all to them!
			return {
					admin: GetAdminList(),
					created: _created ? _created : new Date(),
					data: ba,
					description: _desc,
					editors: GetEditorsList(),
					modified: _modified,
					name: _name,
					owner:  _owner,
					region: _regionId,
					world: _worldId
					};
		}
		
		private function GetEditorsList():String
		{
			return _editors.toString();
		}
		
		private function GetAdminList():String
		{
			return _admin.toString();
		}
	} // Region
} // Package