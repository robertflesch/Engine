/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
	import com.voxelengine.events.ModelLoadingEvent;
	import com.voxelengine.worldmodel.models.PersistanceObject;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import flash.geom.Vector3D;
	import flash.events.Event;
    import flash.events.TimerEvent;
	import flash.utils.ByteArray;
    import flash.utils.Timer;

	import org.flashapi.swing.Alert;
	
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.PersistanceEvent;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.WindowSplashEvent;
	import com.voxelengine.utils.JSONUtil;
	import com.voxelengine.server.Network;
	import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
	import com.voxelengine.worldmodel.models.types.Player;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelCache;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class Region extends PersistanceObject
	{
		static public const DEFAULT_REGION_ID:String = "000000-000000-000000";
		
		private var _info:Object;
		private var _permissions:PermissionsRegion;
		
		static public var _s_currentRegion:Region;
		static public function get currentRegion():Region { return _s_currentRegion; }
		
		private var _loaded:Boolean;							// INSTANCE NOT EXPORTED
		private var _criticalModelDetected:Boolean = false;
		private var _modelCache:ModelCache;
		private var _skyColor:Vector3D = new Vector3D();

		public function get worldId():String { return _info.worldId; }
		public function set worldId(val:String):void { _info.worldId = val; }
		public function get owner():String { return _info.owner; }
		public function set owner(val:String):void { _info.owner = val; }
		public function get desc():String { return _info.desc; }
		public function set desc(val:String):void { _info.desc = val; }
		public function get name():String { return _info.name; }
		public function set name(val:String):void { _info.name = val; }
		public function get gravity():Boolean { return _info.gravity; }
		public function set gravity(val:Boolean):void { _info.gravity = val; }
		public function getSkyColor():Vector3D { return _skyColor; }
		public function setSkyColor( r:int, g:int, b:int ):void { 
			_info.skyColor.r = r;
			_info.skyColor.g = g;
			_info.skyColor.b = b; 
			_skyColor.setTo( r, g , b );
		}
		public function get playerPosition():Object { return _info.playerPosition; }
		public function get playerRotation():Object {return _info.playerRotation; }
		
		public function set changedForce(val:Boolean):void { changed = val; }
		public function get criticalModelDetected():Boolean { return  _criticalModelDetected; } 
		

		public function get loaded():Boolean { return _loaded; }
		public function get modelCache():ModelCache  { return _modelCache; }

		public function createEmptyRegion():void { 
			var dbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_REGIONS, "0", "0", 0, true, null );
			dbo.data = new Object();
			dbo.data.models = []
			dbo.data.skyColor = { "r":92, "g":172, "b":238 }
			dbo.data.gravity = false
			fromObjectImport( dbo ); 
		}
		
		public function Region( $guid:String ):void {
			super( $guid, Globals.BIGDB_TABLE_REGIONS );
			// all regions listen to be loaded and saved, 
			// but those are the only region messages they listen to.
			// unless they are loaded
			RegionEvent.addListener( RegionEvent.LOAD, 		load );
			RegionEvent.addListener( ModelBaseEvent.SAVE, 	save );	
		}
		
		// allows me to release the listeners for temporary regions
		override public function release():void {
			super.release();
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
			// old style uses region.
			var count:int = loadRegionObjects(_info.models);
			
			_loaded = false;
			if ( 0 == count ) {
				_loaded = true;
				LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
				WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.DESTORY ) );
			}
			else
				Globals.g_landscapeTaskController.activeTaskLimit = 1;
				
			// for local use only
			if ( !Globals.online && !Player.player )
				Region.currentRegion.modelCache.createPlayer();
				
			Log.out( "Region.load - completed GUID: " + guid + "  name: " +  name, Log.DEBUG );
		}	
		
		// Makes sense, called from Region
		public function loadRegionObjects( $models:Object ):int {
			Log.out( "Region.loadRegionObjects - START =============================" );
			var count:int = 0;
			for each ( var v:Object in $models ) {
				if ( v ) {
					var instance:InstanceInfo = new InstanceInfo();
					instance.fromObject( v );
					if ( !instance.instanceGuid )
						instance.instanceGuid = Globals.getUID();
					ModelMakerBase.load( instance );
					count++;
				}
			}
			Log.out( "Region.loadRegionObjects - END " + "  count: " + count + "=============================" );
			return count;
		}

		private function addEventListeners():void {
			RegionEvent.addListener( ModelBaseEvent.CHANGED, 				regionChanged );	
			RegionEvent.addListener( RegionEvent.UNLOAD, 					unload );
				
			LoadingEvent.addListener( LoadingEvent.LOAD_COMPLETE, 			onLoadingComplete );
			ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_FAILURE,		removeFailedObjectFromRegion );
				
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
			
			ModelLoadingEvent.removeListener( ModelLoadingEvent.MODEL_LOAD_FAILURE,	removeFailedObjectFromRegion );									  
			
			ModelEvent.removeListener( ModelEvent.CRITICAL_MODEL_DETECTED, 	onCriticalModelDetected );
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_ADDED,		regionChanged );
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_REMOVED,		regionChanged );
		}
		
		private function removeFailedObjectFromRegion( $e:ModelLoadingEvent ):void {
			// Do I need to remove this failed load?
			Log.out( "Region.removeFailedObjectFromRegion - failed to load: " + $e.modelGuid, Log.ERROR );
			//currentRegion.changedForce = true;
		}
	
		private function onLoadingComplete( le:LoadingEvent ):void {
			//Log.out( "Region.onLoadingComplete: regionId: " + guid, Log.WARN );
			_loaded = true;
			LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
			//RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_COMPLETE, 0, guid ) );
		}
		public function toString():String {

			// This does not generate valid JSON
			var outString:String = "  name:" + name;
			outString += "  desc:" + desc;
			outString += "  owner:" + owner;
			outString += "  gravity:" +  gravity;
			return outString;
		}
		
		static public function resetPosition():void {
			if ( VoxelModel.controlledModel )
			{
				VoxelModel.controlledModel.instanceInfo.positionSetComp( currentRegion.playerPosition.x, currentRegion.playerPosition.y, currentRegion.playerPosition.z );
				VoxelModel.controlledModel.instanceInfo.rotationSetComp( currentRegion.playerRotation.x, currentRegion.playerRotation.y, currentRegion.playerRotation.z );
				//VoxelModel.controlledModel.instanceInfo.positionSetComp(0,0,0);
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
			
			// The null owner check makes it to we dont save local loaded regions to persistance
			if ( Globals.online && changed && null != owner && Globals.isGuid( guid ) ) {
				Log.out( "Region.save - SAVING region id: " + guid + "  name: " + name + "  and locking", Log.INFO );
				addSaveEvents();
				toObject();
				
				Log.out( "Region.save - PersistanceEvent.dispatch region id: " + guid + "  name: " + name, Log.WARN );
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.BIGDB_TABLE_REGIONS, guid, _dbo, null ) );
				// or could do this in the suceed, but if it fails do I want to keep retrying?
				changed = false;
			}
//			else
//				Log.out( "Region.save FAILED CONDITION - online:" + Globals.online + "  changed:" + changed + "  owner:" + owner + "  locked:" + _lockDB + "  name: " + name + "  - guid: " + guid, Log.DEBUG );
		}
		
		public function toObject():void {
			if ( _modelCache )
				_info.models = _modelCache.toObject();
			else
				_info.models = [];
				
			_permissions.toObject();
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////
		// fromPersistance
		////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function fromObject( $dbo:DatabaseObject ):void {
			_dbo = $dbo;
			_info = $dbo;
			_permissions = new PermissionsRegion( _info.permissions );
			fromInfo();
			changed = false;
		}
		
		public function fromObjectImport( $dbo:DatabaseObject ):void {
			_dbo = $dbo;
			_info = $dbo.data;
			_info.worldId = Globals.VOXELVERSE;
			_info.name = "NewRegion";
			_info.desc = "Describe what is special about this region";
			_info.playerPosition = new Object();
			_info.playerRotation = new Object();
			_info.playerPosition.x = _info.playerPosition.y = _info.playerPosition.z = 0;
			_info.playerRotation.x = _info.playerRotation.y = _info.playerRotation.z = 0;
			_permissions = new PermissionsRegion( _info );
			fromInfo();
			changed = true;
		}
		
		private function fromInfo():void {
			// push it into the vector3d
			setSkyColor( _info.skyColor.r, _info.skyColor.g, _info.skyColor.b );
			
			for each ( var instanceInfo:Object in _info.models ) {
				var ii:InstanceInfo = new InstanceInfo();
				ii.fromObject( instanceInfo );
			}
		}
		
	} // Region
} // Package