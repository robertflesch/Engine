/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import com.voxelengine.events.WindowSplashEvent;
	import com.voxelengine.worldmodel.models.ModelCache;
	import flash.geom.Vector3D;
	import flash.events.Event;
    import flash.events.TimerEvent;
	import flash.utils.ByteArray;
    import flash.utils.Timer;
	
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.PersistanceEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.Player;
	
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
		  //}}
		  //.....
	   //]
	//}	
	
	/**
	 * ...
	 * @author Bob
	 */
	public class Region 
	{
		static public const DEFAULT_REGION_ID:String = "000000-000000-000000";
		static private const BLANK_REGION_TEMPLATE:String = "{\"region\":[],\"skyColor\": {\"r\":92,\"g\":172,\"b\":238 },\"gravity\":false }";
		
		static public var _s_currentRegion:Region;
		static public function get currentRegion():Region { return _s_currentRegion; }
		private var _name:String;
		private var _desc:String;
		private var _worldId:String = "VoxelVerse";
		private var _guid:String = DEFAULT_REGION_ID;
		private var _owner:String;
		private var _editors:Vector.<String> = new Vector.<String>() //{ user Id1:role, user id2:role... }
		private var _admin:Vector.<String> = new Vector.<String>() // : { user Id1:role, user id2:role... }
		private var _created:Date;
		private var _modified:Date;
		private var _JSON:Object;
		private var _dbo:DatabaseObject;							
		private var _changed:Boolean;								// INSTANCE NOT EXPORTED
		private var _playerPosition:Vector3D = new Vector3D();
		private var _playerRotation:Vector3D = new Vector3D();
		private var _loaded:Boolean;							// INSTANCE NOT EXPORTED
		private var _guestAllow:Boolean = true;
		private var _skyColor:Vector3D = new Vector3D(92, 	172, 	238);
		private var _gravity:Boolean = true;
		private var _lockDB:Boolean = false; // This keeps a second save or create from happening until first one clears.
		private var _criticalModelDetected:Boolean = false;
		private var _modelCache:ModelCache;

		public function get dbo():DatabaseObject { return _dbo; }
		public function set dbo(val:DatabaseObject):void { _dbo = val; }
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
		public function get gravity():Boolean { return _gravity; }
		public function set gravity(val:Boolean):void { _gravity = val; }
		public function get changed():Boolean { return _changed; }
		public function set changed(val:Boolean):void { _changed = val; }
		public function set changedForce(val:Boolean):void { _changed = val; }
		
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
		public function get loaded():Boolean { return _loaded; }
		public function get modelCache():ModelCache  { return _modelCache; }
		public function getSkyColor():Vector3D { return _skyColor; }
		public function setSkyColor( r:int, g:int, b:int ):void { _skyColor.setTo( r, g, b ); }
		private function editorsListGet():String { return _editors.toString(); }
		private function adminListGet():String { return _admin.toString(); }

		public function createEmptyRegion():void { initJSON( BLANK_REGION_TEMPLATE ); }
		
		public function Region( $guid:String ):void {
			_guid = $guid;
			// all regions listen to be loaded and saved, 
			// but those are the only region messages they listen to.
			// unless they are loaded
			RegionEvent.addListener( RegionEvent.LOAD, 		load );
			RegionEvent.addListener( ModelBaseEvent.SAVE, 	save );	
		}
		
		// allows me to release the listeners for temporary regions
		public function release():void {
			RegionEvent.removeListener( RegionEvent.LOAD, 		load );
			RegionEvent.removeListener( ModelBaseEvent.SAVE, 	save );	
		}
		
		private function onCriticalModelDetected( me:ModelEvent ):void {
			_criticalModelDetected = true;
			Log.out( "Region.criticalModelDetected" );
		}
		
		
		public function update( $elapsed:int ):void {
			_modelCache.update( $elapsed );
		}
			
		private function load( $re:RegionEvent ):void {
			// all regions listen to be loaded, but that is the only region message they listen to.
			if ( guid != $re.guid )
				return;
				
			if ( _s_currentRegion )
				_s_currentRegion.unload( null );
			_s_currentRegion = this;
			
			_modelCache = new ModelCache( this );
			
			Log.out( "Region.load - loading    GUID: " + guid + "  name: " +  name, Log.DEBUG );
			
			addEventListeners();
			RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_BEGUN, 0, guid ) );
			var count:int = ModelLoader.loadRegionObjects(_JSON.region);
			

			if ( 0 == count ) {
				_loaded = true;
				LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
				WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.DESTORY ) );
			}
			else {
				_loaded = false;
				Globals.g_landscapeTaskController.activeTaskLimit = 1;
			}
				
			// for local use only
			if ( !Globals.online && !Globals.player )
				Region.currentRegion.modelCache.createPlayer();
				
			Log.out( "Region.load - completed GUID: " + guid + "  name: " +  name, Log.DEBUG );
		}	

		private function addEventListeners():void {
			RegionEvent.addListener( ModelBaseEvent.CHANGED, 				regionChanged );	
			RegionEvent.addListener( RegionEvent.UNLOAD, 					unload );
				
			LoadingEvent.addListener( LoadingEvent.LOAD_COMPLETE, 			onLoadingComplete );
			LoadingEvent.addListener( LoadingEvent.MODEL_LOAD_FAILURE,		removeFailedObjectFromRegion );									  
				
			ModelEvent.addListener( ModelEvent.CRITICAL_MODEL_DETECTED,		onCriticalModelDetected );
			ModelEvent.addListener( ModelEvent.PARENT_MODEL_ADDED,			modelChanged );
			ModelEvent.addListener( ModelEvent.PARENT_MODEL_REMOVED,		modelChanged );
		}
		
		private function regionChanged( $re:RegionEvent):void  { 
			Log.out( "Region.regionChanged" );
			changed = true;
		}
		
		private function modelChanged(e:ModelEvent):void {
			Log.out( "Region.modelChanged" );
			changed = true;
		}
		
		private function unload( $re:RegionEvent ):void {
			Log.out( "Region.unload: " + guid, Log.DEBUG );
			removeEventListeners();
			_modelCache.unload();
		}
		
		private function removeEventListeners():void {
			RegionEvent.removeListener( ModelBaseEvent.CHANGED, 			regionChanged );	
			RegionEvent.removeListener( RegionEvent.UNLOAD, 				unload );
			
			LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, 		onLoadingComplete );
			LoadingEvent.removeListener( LoadingEvent.MODEL_LOAD_FAILURE,	removeFailedObjectFromRegion );									  
			
			ModelEvent.removeListener( ModelEvent.CRITICAL_MODEL_DETECTED, 	onCriticalModelDetected );
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_ADDED,		regionChanged );
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_REMOVED,		regionChanged );
		}
		
		private function removeFailedObjectFromRegion( $e:LoadingEvent):void {
			// Do I need to remove this failed load?
			Log.out( "Region.removeFailedObjectFromRegion - failed to load: " + $e.guid, Log.ERROR );
			//currentRegion.changedForce = true;
		}
	
		private function onLoadingComplete( le:LoadingEvent ):void {
			Log.out( "Region.onLoadingComplete: regionId: " + guid, Log.DEBUG );
			_loaded = true;
			LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
			RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_COMPLETE, 0, guid ) );
		}
		
		public function initJSON( $regionJson:String ):void {
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
		
		static public function resetPosition():void {
			if ( Globals.controlledModel )
			{
				Globals.controlledModel.instanceInfo.positionSet = currentRegion.playerPosition;
				Globals.controlledModel.instanceInfo.rotationSet = currentRegion.playerRotation;
				//Globals.controlledModel.instanceInfo.positionSetComp(0,0,0);
			}
		}
		
		public function applyRegionInfoToPlayer( $avatar:Player ):void {
			//Log.out( "Region.applyRegionInfoToPlayer" );
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
		
		////////////////////////////////////////////////////////////////////////////////////////////////////
		// toPersistance
		////////////////////////////////////////////////////////////////////////////////////////////////////

		private function save( $re:RegionEvent ):void {
			
			if ( guid != $re.guid ) {
				//Log.out( "Region.save - Ignoring save meant for other region my guid: " + guid + " target guid: " + $re.guid, Log.WARN );
				return;
			}
			
			// Models might have changes not seen in the region file
			if ( _modelCache )
				_modelCache.save();
			
			
			// The null owner check makes it to we dont save local loaded regions to persistance
			if ( Globals.online && changed && null != owner && false == _lockDB ) {
				Log.out( "Region.save - SAVING region id: " + guid + "  name: " + name + "  and locking", Log.INFO );
				addSaveEvents();
				
				if ( _dbo )
					toPersistance();
				else {
					var ba:ByteArray = new ByteArray();	
					ba = asByteArray( ba );
				}
//Log.out( "Region.save - NOT SAVING NOT SAVING NOT SAVING", Log.WARN );
//return;	
				//Log.out( "Region.save - PersistanceEvent.dispatch region id: " + guid + "  name: " + name + "  locking status: " + _lockDB, Log.WARN );
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.DB_TABLE_REGIONS, guid, _dbo, metadata(ba) ) );
				// or could do this in the suceed, but if it fails do I want to keep retrying?
				changed = false;
			}
			else
				Log.out( "Region.save - NOT online:" + Globals.online + "  changed:" + changed + "  owner:" + owner + "  locked:" + _lockDB + "  name: " + name + "  - guid: " + guid, Log.DEBUG );
		}
		
		private function saveSucceed( $pe:PersistanceEvent ):void { 
			if ( Globals.DB_TABLE_REGIONS != $pe.table )
				return;
			removeSaveEvents();
			Log.out( "Region.saveSucceed - guid: " + guid, Log.DEBUG ); 
		}	
		
		private function createSucceed( $pe:PersistanceEvent ):void { 
			if ( Globals.DB_TABLE_REGIONS != $pe.table )
				return;
			if ( $pe.dbo )
				dbo = $pe.dbo;
			removeSaveEvents();
			Log.out( "Region.createSuccess - guid: " + guid, Log.DEBUG ); 
		}	
		
		private function saveFail( $pe:PersistanceEvent ):void { 
			if ( Globals.DB_TABLE_REGIONS != $pe.table )
				return;
			removeSaveEvents();
			Log.out( "Region.saveFail - ", Log.ERROR ); 
		}	
		
		
		private function addSaveEvents():void {
			_lockDB = true;
			PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
			PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
			PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, 	saveFail );
		}
		
		private function removeSaveEvents():void {
			PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
			PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
			PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, 		saveFail );
			_lockDB = false;
		}
	
		
		public function toPersistance():void {
			_dbo.admin = adminListGet();
			_dbo.description = desc;
			_dbo.name = name;
			_dbo.owner = owner;
			_dbo.world = worldId;
			_dbo.editors = editorsListGet();
			_dbo.created = created;
			_dbo.modified = new Date();
			
			var ba:ByteArray = new ByteArray(); 
			_dbo.data 			= asByteArray( ba );
		}
		
		public function getJSON():String {
			var outString:String = "{\"region\":";
			if ( _modelCache ) {
				outString += "[";
				outString += _modelCache.getJSON();
				outString += "],"
			}
			else {
				// If the region has not been loaded yet, just copy the props over.
				outString += JSON.stringify( _JSON.region );
				outString += ","
			}
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


		public function asByteArray( $ba:ByteArray ):ByteArray {
			var regionJson:String = getJSON();
			$ba.writeInt( regionJson.length );
			$ba.writeUTFBytes( regionJson );
			$ba.compress();
			
			return $ba;	
		}
		
		private function metadata( ba: ByteArray ):Object {
			Log.out( "Region.metadata userId: " + Network.userId + "  name: " + name + "  this region is owned by: " + _owner, Log.DEBUG );
			return {
					admin: 			adminListGet(),
					created: 		_created ? _created : _created = new Date(),
					modified: 		_modified = new Date(),
					data: 			ba,
					description: 	_desc,
					editors: 		editorsListGet(),
					name: 			_name,
					owner:  		_owner,
					world: 			_worldId
					};
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////
		// fromPersistance
		////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function fromPersistance( $dbo:DatabaseObject ):void {
			admin = cvsToVector( $dbo.admin );
			dbo = $dbo;
			desc = $dbo.description;
			name = $dbo.name;
			owner = $dbo.owner
			worldId = $dbo.world;
			editors = cvsToVector( $dbo.editors );
			created = $dbo.created;
			modified = $dbo.modified;
			
			Log.out( "Region.fromPersistance - region Name: " + name + "  owner: " + owner + "  guid: " + guid, Log.DEBUG );
			
			if ( $dbo && $dbo.data ) {
				var ba:ByteArray = $dbo.data 
				ba.position = 0;
				if ( ba && 0 < ba.bytesAvailable ) {
					ba.uncompress();
					fromByteArray( ba );
				}
			}
			changed = true;
			// comma seperated variables
			function cvsToVector( value:String ):Vector.<String> {
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
		
		private function fromByteArray( $ba:ByteArray ):void {
			$ba.position = 0;
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var regionJson:String = $ba.readUTFBytes( strLen );
			initJSON( regionJson );
		}
		
		
	} // Region
} // Package