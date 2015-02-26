/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
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
	import com.voxelengine.worldmodel.models.ModelManager;
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
		static private const TABLE_REGIONS:String = "regions";

	

		
		static public var _s_currentRegion:Region;
		static public function get currentRegion():Region { return _s_currentRegion; }
		//public function set currentRegion(val:Region):void { 
			//_s_currentRegion = val; 
			//Log.out("RegionManager.currentRegion - set to: " + val.guid, Log.DEBUG ) 
		//}
		
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
		private var _dbo:DatabaseObject  = null;							
		private var _changed:Boolean;								// INSTANCE NOT EXPORTED
		private var _playerPosition:Vector3D = new Vector3D();
		private var _playerRotation:Vector3D = new Vector3D();
		private var _loaded:Boolean = true;							// INSTANCE NOT EXPORTED
		private var _guestAllow:Boolean = true;
		private var _modelManager:ModelManager = new ModelManager();
		private var _skyColor:Vector3D = new Vector3D(92, 	172, 	238);
		private var _gravity:Boolean = true;

		public function get databaseObject():DatabaseObject { return _dbo; }
		public function set databaseObject(val:DatabaseObject):void { _dbo = val; }
		
		
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
		public function set changed(val:Boolean):void { _changed = val; }
		public function set changedForce(val:Boolean):void { _changed = val; }
		
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
		public function get loaded():Boolean { return _loaded; }
		
		public function Region( $guid:String ):void 
		{
			_guid = $guid;
			RegionEvent.addListener( RegionEvent.LOAD, 				load );
		}
		
		private function onCriticalModelDetected( me:ModelEvent ):void
		{
			_criticalModelDetected = true;
			Log.out( "Region.criticalModelDetected" );
		}
		
		
		public function update( $elapsed:int ):void {
			_modelManager.update( $elapsed );
		}
			
		private function unload( $re:RegionEvent ):void
		{
			if ( guid != $re.guid )
				return;
				
			Log.out( "Region.unload: " + guid, Log.DEBUG );
			RegionEvent.removeListener( ModelBaseEvent.CHANGED, 		regionChanged );	
			RegionEvent.removeListener( ModelBaseEvent.SAVE, 			save );	
			RegionEvent.removeListener( RegionEvent.LOAD, 				load );
			RegionEvent.removeListener( RegionEvent.UNLOAD, 			unload );
			LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, 	onLoadingComplete );
			LoadingEvent.removeListener( LoadingEvent.MODEL_LOAD_FAILURE,removeFailedObjectFromRegion );									  
			// Removes anonymous function
			Globals.g_app.removeEventListener( ModelEvent.CRITICAL_MODEL_DETECTED, onCriticalModelDetected );
			Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_ADDED,	regionChanged );
			Globals.g_app.removeEventListener( ModelEvent.PARENT_MODEL_REMOVED,regionChanged );
			
//			_modelManager.removeAllModelInstances( true );
			_modelManager.removeAllModelInstances( false ); // dont delete player object.
			_modelManager.bringOutYourDead();
		}
		
		private function regionChanged( $re:RegionEvent):void 
		{
			changed = true;
		}
		
		private function removeFailedObjectFromRegion( $e:LoadingEvent):void {
			// Do I need to remove this failed load?
			Log.out( "RegionManager.removeFailedObjectFromRegion - failed to load: " + $e.guid, Log.ERROR );
			//currentRegion.changedForce = true;
		}
	
		private function onLoadingComplete( le:LoadingEvent ):void
		{
			Log.out( "Region.onLoadingComplete: regionId: " + guid, Log.DEBUG );
			_loaded = true;
			LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
			RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_COMPLETE, guid ) );
		}

		
		private function load( $re:RegionEvent ):void
		{
			if ( guid != $re.guid )
				return;
				
			_s_currentRegion = this;
			
			Log.out( "Region.load - loading    GUID: " + guid + "  name: " +  name, Log.DEBUG );
			RegionEvent.addListener( ModelBaseEvent.CHANGED, 	regionChanged );	
			RegionEvent.addListener( ModelBaseEvent.SAVE, 		save );	
			RegionEvent.addListener( RegionEvent.UNLOAD, 		unload );
			
			Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_ADDED,	regionChanged );
			Globals.g_app.addEventListener( ModelEvent.PARENT_MODEL_REMOVED,regionChanged );
			
			LoadingEvent.addListener( LoadingEvent.MODEL_LOAD_FAILURE,removeFailedObjectFromRegion );									  
			LoadingEvent.addListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
			
			Globals.g_app.addEventListener( ModelEvent.CRITICAL_MODEL_DETECTED, onCriticalModelDetected );
			
			RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_BEGUN, guid ) );

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

		static public function resetPosition():void
		{
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
		
		
		public function createEmptyRegion():void { initJSON( BLANK_REGION_TEMPLETE ); }
		
		////////////////////////////////////////////////////////////////////////////////////////////////////
		// toPersistance
		////////////////////////////////////////////////////////////////////////////////////////////////////

		private function save( $re:RegionEvent ):void {
			
			// Models might have changes not seen in the region file
			_modelManager.save();
			
			if ( Globals.online && changed ) {
				Log.out( "Region.save - Saving region id: " + guid, Log.WARN );
				if ( _dbo )
					toPersistance();
				else {
					var ba:ByteArray = new ByteArray();	
					ba = asByteArray( ba );
				}
				addSaveEvents();
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, TABLE_REGIONS, guid, _dbo, metadata(ba) ) );
			}
			else
				Log.out( "Region.save - Saving Region, either offline or NOT changed - guid: " + guid, Log.DEBUG );
		}
		
		private function saveSucceed( $pe:PersistanceEvent ):void 
		{ 
			if ( TABLE_REGIONS != $pe.table )
				return;
			removeSaveEvents();
			Log.out( "Region.saveSucceed - created: " + guid, Log.DEBUG ); 
		}	
		
		private function createSucceed( $pe:PersistanceEvent ):void 
		{ 
			if ( TABLE_REGIONS != $pe.table )
				return;
			removeSaveEvents();
			if ( $pe.dbo )
				databaseObject = $pe.dbo;
			Log.out( "Region.createSuccess - created: " + guid, Log.DEBUG ); 
		}	
		
		private function saveFail( $pe:PersistanceEvent ):void 
		{ 
			if ( TABLE_REGIONS != $pe.table )
				return;
			removeSaveEvents();
			Log.out( "Region.saveFail - ", Log.ERROR ); 
		}	
		
		
		private function addSaveEvents():void {
			PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
			PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
			PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, 	saveFail );
		}
		
		private function removeSaveEvents():void {
			PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
			PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
			PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, 		saveFail );
		}
	
		
		public function toPersistance():void 
		{
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
		
		public function asByteArray( $ba:ByteArray ):ByteArray {
			// Lets see if this updates the _JSON object.
			_JSON.playerPosition = _playerPosition;
			_JSON.playerRotation = _playerRotation;
			_JSON.skyColor = _skyColor;
			_JSON.gravity = _gravity;
			
			var regionJson:String = JSON.stringify(_JSON);
			$ba.writeInt( regionJson.length );
			$ba.writeUTFBytes( regionJson );
			$ba.compress();
			
			return $ba;	
		}
		
		private function metadata( ba: ByteArray ):Object {
			Log.out( "Region.metadata userId: " + Network.userId + "  this region is owned by: " + _owner, Log.DEBUG );
			return {
					admin: 			adminListGet(),
					created: 		_created ? _created : new Date(),
					data: 			ba,
					description: 	_desc,
					editors: 		editorsListGet(),
					name: 			_name,
					owner:  		_owner,
					world: 			_worldId
					};
		}
		
		private function editorsListGet():String { return _editors.toString(); }
		private function adminListGet():String { return _admin.toString(); }

		////////////////////////////////////////////////////////////////////////////////////////////////////
		// fromPersistance
		////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function fromPersistance( $dbo:DatabaseObject ):void 
		{
			admin = cvsToVector( $dbo.admin );
			databaseObject = $dbo;
			desc = $dbo.description;
			name = $dbo.name;
			owner = $dbo.owner
			worldId = $dbo.world;
			editors = cvsToVector( $dbo.editors );
			created = $dbo.created;
			modified = $dbo.modified;
			
			Log.out( "Region.loadSucceed - region Name: " + name + "  owner: " + owner + "  guid: " + guid, Log.DEBUG );
			
			if ( $dbo && $dbo.data ) {
				var ba:ByteArray = $dbo.data 
				if ( ba && 0 < ba.bytesAvailable ) {
					ba.uncompress();
					fromByteArray( ba );
				}
			}
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