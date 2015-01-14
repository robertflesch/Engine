/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import com.voxelengine.worldmodel.models.Player;
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
	import com.voxelengine.events.RegionPersistanceEvent;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.RegionLoadedEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.server.PersistRegion;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.ModelManager;
	
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
		private var _guid:String = DEFAULT_REGION_ID;
		private var _owner:String;
		private var _editors:Vector.<String> = new Vector.<String>() //{ user Id1:role, user id2:role... }
		private var _admin:Vector.<String> = new Vector.<String>() // : { user Id1:role, user id2:role... }
		private var _created:Date;
		private var _modified:Date;
		private var _JSON:Object;
		private var _databaseObject:DatabaseObject  = null;							
		private var _changed:Boolean;								// INSTANCE NOT EXPORTED
		private var _playerPosition:Vector3D = new Vector3D();
		private var _playerRotation:Vector3D = new Vector3D();
		private var _loaded:Boolean = true;							// INSTANCE NOT EXPORTED
		private var _guestAllow:Boolean = true;
		private var _modelManager:ModelManager = new ModelManager();
		private var _skyColor:Vector3D = new Vector3D(92, 	172, 	238);
		private var _gravity:Boolean = true;

		public function get databaseObject():DatabaseObject { return _databaseObject; }
		public function set databaseObject(val:DatabaseObject):void { _databaseObject = val; }
		
		
		public function get worldId():String { return _worldId; }
		public function set worldId(val:String):void { _worldId = val; }
		public function get owner():String { return _owner; }
		public function set owner(val:String):void { _owner = val; }
		public function get desc():String { return _desc; }
		public function set desc(val:String):void { _desc = val; }
		public function get name():String { return _name; }
		public function set name(val:String):void { _name = val; }
		public function get guid():String { return _guid; }
		public function set guid(val:String):void { _guid = val; }
//		public function get regionJson():String { return _regionJson; }
		public function get gravity():Boolean { return _gravity; }
		public function set gravity(val:Boolean):void { _gravity = val; }
		public function get changed():Boolean { return _changed; }
		public function set changed(val:Boolean):void 
		{ 
			if ( !_loaded )
				return;
			_changed = val; 
		}
		public function set changedForce(val:Boolean):void { 
			_changed = val; 
		}
		
		private var _criticalModelDetected:Boolean = false;
		public function get criticalModelDetected():Boolean { return  _criticalModelDetected; } 
		
		public function get playerPosition():Vector3D { return _playerPosition; }
		public function get playerRotation():Vector3D {return _playerRotation; }
		public function get admin():Vector.<String>  { return _admin; }
		public function set admin(value:Vector.<String>):void { _admin = value; }
		public function get editors():Vector.<String> { return _editors; }
		public function set editors(value:Vector.<String>):void  { _editors = value; }
		public function get created():Date  { return _created; }
		public function set created(value:Date):void  { _created = value; }
		public function get modified():Date  { return _modified; }
		public function set modified(value:Date):void  { _modified = value; }
		public function get modelManager():ModelManager  { return _modelManager; }
		
		private function onCriticalModelDetected( me:ModelEvent ):void
		{
			_criticalModelDetected = true;
			Log.out( "Region.criticalModelDetected" );
		}
		
		public function Region( $guid:String ):void 
		{
			_guid = $guid;
			_created = new Date();
			_modified = _created;
		}
		
		public function update( $elapsed:int ):void {
			_modelManager.update( $elapsed );
		}
			
		private function onRegionUnload( le:RegionEvent ):void
		{
			if ( guid == le.guid )
				unload();
		}
		
		private function onLoadingComplete( le:LoadingEvent ):void
		{
			Log.out( "Region.onLoadingComplete: regionId: " + guid, Log.DEBUG );
			_loaded = true;
			Globals.g_app.removeEventListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
		}

		public function unload():void
		{
			Log.out( "Region.unloadRegion: " + guid, Log.DEBUG );
			// Removes anonymous function
			Globals.g_app.removeEventListener( RegionEvent.REGION_MODIFIED, handleRegionModified );
			//Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_ADDED, function( me:ModelEvent ):void { ; } );
			Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_REMOVED, function( me:ModelEvent ):void { ; } );
			Globals.g_app.removeEventListener( ModelEvent.CRITICAL_MODEL_DETECTED, onCriticalModelDetected );
//			_modelManager.removeAllModelInstances( true );
//			Globals.player = null;
			_modelManager.removeAllModelInstances( false ); // dont delete player object.
			_modelManager.bringOutYourDead();
		}
		
		private function handleRegionModified( $re:RegionEvent ):void {
			changed = true;	
			save();
		}
				
		public function load():void
		{
			Log.out( "Region.load - loading    GUID: " + guid + "  name: " +  name, Log.DEBUG );
			Globals.g_app.addEventListener( RegionEvent.REGION_UNLOAD, onRegionUnload );
			Globals.g_app.addEventListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
			Globals.g_app.addEventListener( ModelEvent.CRITICAL_MODEL_DETECTED, onCriticalModelDetected );
			Globals.g_app.addEventListener( RegionEvent.REGION_MODIFIED, handleRegionModified);
			
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_LOAD_BEGUN, guid ) );

			var count:int = ModelLoader.loadRegionObjects(_JSON.region);
			if ( 0 < count )
				_loaded = false;
				
			if ( !Globals.online && !Globals.player )
				Globals.createPlayer();
				
			Log.out( "Region.load - completed GUID: " + guid + "  name: " +  name, Log.DEBUG );
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
		
		public function initJSON( $regionJson:String ):void
		{
			//Log.out( "Region.processRegionJson: " + $regionJson );
			_JSON = JSON.parse($regionJson);
			if ( _JSON.skyColor ) {
				// legacy < v008 has rgb values
				if ( _JSON.skyColor.r )
					setSkyColor( _JSON.skyColor.r, _JSON.skyColor.g, _JSON.skyColor.b );
				else	
					_skyColor.setTo( _JSON.skyColor.x, _JSON.skyColor.y, _JSON.skyColor.z );
			}
				
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
				_playerRotation.setTo( 0, _JSON.playerRotation.y, 0 );
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
			outString += "  guests:" + JSON.stringify(_guestAllow);
			return outString;
		}
		
		public function getJSON():String
		{
			var outString:String = "{\"region\":[";
			outString = _modelManager.getModelJson(outString);
			outString += "],"
			// if you dont do it this way, there is a null at begining of string
			outString += "\"skyColor\":" + JSON.stringify( _skyColor );
			outString += ","
			outString += "\"playerPosition\":" + JSON.stringify( _playerPosition );
			outString += ","
			outString += "\"playerRotation\":" + JSON.stringify( _playerRotation );
			outString += ","
			outString += "\"gravity\":" + JSON.stringify(gravity);
			outString += "}"
			return outString;
		}
		
		// TO do I dont like that I have reference to BigDB here
		// this should all get refactored out to be part of the Persistance Object
		public function save():void 
		{
			// dont save changes to anything if we are not online
			if ( !Globals.online )
				return;
				
			// Models might have changes not seen in the region file
			_modelManager.save();
			
			if ( !changed )
				return;
			
			if ( !Globals.isGuid( guid ) ) {
				Log.out( "Region.save - INVALID REGION DATA", Log.ERROR ); 
				return;
			}
				
			Log.out( "Region.save - saving changes to Persistance: " + guid, Log.DEBUG ); 
			var ba:ByteArray = new ByteArray();
			ba.clear();
			var regionJson:String = getJSON();
			ba.writeInt( regionJson.length );
			ba.writeUTFBytes( regionJson );
			ba.compress();
			
			PersistRegion.save( guid, metadata( ba ), databaseObject, createSuccess );

			changed = false;
		}
		
		// TO do I dont like that I have reference to BigDB here
		// this should all get refactored out to be part of the Persistance Object
		public function saveEdit():void 
		{
			// dont save changes to anything if we are not online
			if ( !Globals.online )
				return;
				
			if ( !Globals.isGuid( guid ) ) {
				Log.out( "Region.saveEdit - INVALID REGION DATA", Log.ERROR ); 
				return;
			}
				
			Log.out( "Region.saveEdit - saving changes to Persistance: " + guid, Log.DEBUG ); 
			var ba:ByteArray = new ByteArray();
			ba.clear();
			// Lets see if this updates the _JSON object.
			_JSON.playerPosition = _playerPosition;
			_JSON.playerRotation = _playerRotation;
			_JSON.skyColor = _skyColor;
			_JSON.gravity = _gravity;
			
			var regionJson:String = JSON.stringify(_JSON);
			ba.writeInt( regionJson.length );
			ba.writeUTFBytes( regionJson );
			ba.compress();
			
			PersistRegion.save( guid, metadata( ba ), databaseObject, createSuccess );

			changed = false;
		}

		public function saveLocal():void {
			var fr:FileReference = new FileReference();
			_modified = new Date();
			var outString:String = getJSON();
			fr.save( outString, guid );
		}
		
		private function metadata( ba: ByteArray ):Object {
			Log.out( "Region.metadata userId: " + Network.userId + "  this region is owned by: " + _owner, Log.DEBUG );
			return {
					admin: 			GetAdminList(),
					created: 		_created ? _created : new Date(),
					data: 			ba,
					description: 	_desc,
					editors: 		GetEditorsList(),
					name: 			_name,
					owner:  		_owner,
					world: 			_worldId
					};
		}

		private function createSuccess(o:DatabaseObject):void 
		{ 
			if ( o )
				databaseObject = o;
			Globals.g_app.dispatchEvent( new RegionPersistanceEvent( RegionPersistanceEvent.REGION_CREATE_SUCCESS, guid ) ); 
			Log.out( "Region.createSuccess - created: " + guid, Log.DEBUG ); 
		}	
		
		static public function resetPosition():void
		{
			if ( Globals.controlledModel )
			{
				Globals.controlledModel.instanceInfo.positionSet = Globals.g_regionManager.currentRegion.playerPosition;
				Globals.controlledModel.instanceInfo.rotationSet = Globals.g_regionManager.currentRegion.playerRotation;
				//Globals.controlledModel.instanceInfo.positionSetComp(0,0,0);
			}
		}
		
		public function applyRegionInfoToPlayer( $avatar:Player ):void {
			Log.out( "Region.applyRegionInfoToPlayer" );
			if ( playerPosition )
			{
				//Log.out( "Player.onLoadingPlayerComplete - setting position to  - x: "  + playerPosition.x + "   y: " + playerPosition.y + "   z: " + playerPosition.z );
				$avatar.instanceInfo.positionSetComp( playerPosition.x, playerPosition.y, playerPosition.z );
			}
			else
				$avatar.instanceInfo.positionSetComp( 0, 0, 0 );
			
			if ( playerRotation )
			{
				//Log.out( "Player.onLoadingPlayerComplete - setting player rotation to  -  y: " + playerRotation );
				$avatar.instanceInfo.rotationSet = new Vector3D( 0, playerRotation.y, 0 );
			}
			else
				$avatar.instanceInfo.rotationSet = new Vector3D( 0, 0, 0 );
				
			$avatar.usesGravity = gravity;
		}
		
		
		
		public function createEmptyRegion():void { initJSON( BLANK_REGION_TEMPLETE ); }
		private function GetEditorsList():String { return _editors.toString(); }
		private function GetAdminList():String { return _admin.toString(); }
	} // Region
} // Package