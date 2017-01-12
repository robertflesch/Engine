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
	import com.voxelengine.events.ModelLoadingEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
	import com.voxelengine.worldmodel.models.types.Avatar;
	import com.voxelengine.worldmodel.models.types.Player;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelCache;
	import com.voxelengine.worldmodel.models.PersistanceObject;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class Region extends PersistanceObject {
		
		
		static public var _s_currentRegion:Region;
		static public function get currentRegion():Region { return _s_currentRegion; }
		
		private var _loaded:Boolean;							// INSTANCE NOT EXPORTED
		private var _criticalModelDetected:Boolean = false;
		private var _permissions:PermissionsRegion;
		private var _modelCache:ModelCache;
		private var _skyColor:Vector3D = new Vector3D();

		public function get worldId():String { return info.worldId; }
		public function set worldId(val:String):void { info.worldId = val; }
		public function get owner():String { return info.owner; }
		public function set owner(val:String):void { info.owner = val; }
		public function get desc():String { return info.desc; }
		public function set desc(val:String):void { info.desc = val; }
		public function get name():String { return info.name; }
		public function set name(val:String):void { info.name = val; }
		public function get gravity():Boolean { return info.gravity; }
		public function set gravity(val:Boolean):void { info.gravity = val; }
		public function getSkyColor():Vector3D { return _skyColor; }
		public function setSkyColor( $skyColor:Object ):void { 
			if ( !$skyColor ) {
				Log.out( "Region.setSkyColor - no object", Log.ERROR)
				$skyColor = { "x":92, "y":172, "z":238 }
			}
			var x:int = $skyColor.x
			if ( x < 0 || 255 < x )
				$skyColor.x = 92
			var y:int = $skyColor.y
			if ( y < 0 || 255 < y )
				$skyColor.y = 172
			var z:int = $skyColor.z
			if ( z < 0 || 255 < z )
				$skyColor.z = 238
				
			info.skyColor = $skyColor
			_skyColor.setTo( info.skyColor.x, info.skyColor.y , info.skyColor.z )
		}
		public function get playerPosition():Object { return info.playerPosition; }
		public function get playerRotation():Object {return info.playerRotation; }
		
		public function set changedForce(val:Boolean):void { changed = val; }
		public function get criticalModelDetected():Boolean { return  _criticalModelDetected; } 
		

		public function get loaded():Boolean { return _loaded; }
		public function get modelCache():ModelCache  { return _modelCache; }

		public function createEmptyRegion():void { 
			var dbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_REGIONS, "0", "0", 0, true, null );
			dbo.data = new Object();
			dbo.data.models = []
			dbo.data.skyColor = { "x":92, "y":172, "z":238 }
			dbo.data.gravity = false
			fromObjectImport( dbo ); 
		}
		
		public function Region( $guid:String ):void {
			super( $guid, Globals.BIGDB_TABLE_REGIONS );
			// all regions listen to be loaded and saved, 
			// but those are the only region messages they listen to.
			// unless they are loaded
			RegionEvent.addListener( RegionEvent.LOAD, 		load );
			RegionEvent.addListener( ModelBaseEvent.SAVE, 	saveEvent );	
		}
		
		// allows me to release the listeners for temporary regions
		override public function release():void {
			super.release();
			RegionEvent.removeListener( RegionEvent.LOAD, 		load );
			RegionEvent.removeListener( ModelBaseEvent.SAVE, 	saveEvent );	
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
				RegionEvent.dispatch( new RegionEvent( RegionEvent.UNLOAD, 0, _s_currentRegion.guid ) );
			_s_currentRegion = this;
			
			_modelCache = new ModelCache( this );
			
			Log.out( "Region.load - loading    GUID: " + guid + "  name: " +  name, Log.DEBUG );
			
			addEventListeners();
			RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_BEGUN, 0, guid ) );
			// old style uses region.
			setSkyColor( info.skyColor );
			var count:int = loadRegionObjects(info.models);
			
			_loaded = false;
			if ( 0 == count ) {
				_loaded = true;
				LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.LOAD_COMPLETE, "" ) );
				WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.DESTORY ) );
			}
			else
				Globals.g_landscapeTaskController.paused = false
				
			// for local use only
			if ( !Globals.online && !Player.player )
				Avatar.createPlayer();
				
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
			if ( guid == $re.guid ) {
				Log.out( "Region.regionChanged" );
				changed = true;
			}
		}
		
		private function modelChanged(e:ModelEvent):void {
			if ( Region.currentRegion.guid == guid ) {
				//Log.out( "Region.modelChanged" );
				changed = true;
			}
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
			currentRegion.changedForce = true;
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
			if ( VoxelModel.controlledModel ) {
				VoxelModel.controlledModel.instanceInfo.positionSetComp( currentRegion.playerPosition.x, currentRegion.playerPosition.y, currentRegion.playerPosition.z );
				VoxelModel.controlledModel.instanceInfo.rotationSetComp( currentRegion.playerRotation.x, currentRegion.playerRotation.y, currentRegion.playerRotation.z );
				//VoxelModel.controlledModel.instanceInfo.positionSetComp(0,0,0);
			}
		}
		
		public function applyRegionInfoToPlayer( $avatar:Player ):void {
			//Log.out( "Region.applyRegionInfoToPlayer" );
			if ( playerPosition ) {
				//Log.out( "Player.onLoadingPlayerComplete - setting position to  - x: "  + playerPosition.x + "   y: " + playerPosition.y + "   z: " + playerPosition.z );
				$avatar.instanceInfo.positionSetComp( playerPosition.x, playerPosition.y, playerPosition.z );
			}
			else
				$avatar.instanceInfo.positionSetComp( 0, 0, 0 );
			
			if ( playerRotation ) {
				//Log.out( "Player.onLoadingPlayerComplete - setting player rotation to  -  y: " + playerRotation );
				$avatar.instanceInfo.rotationSet = new Vector3D( 0, playerRotation.y, 0 );
			}
			else
				$avatar.instanceInfo.rotationSet = new Vector3D( 0, 0, 0 );
				
			$avatar.usesGravity = gravity;
		}
		
		public function setPlayerPosition( $obj:Object ):void {
			info.playerPosition = $obj
		}
		
		public function setPlayerRotation( $obj:Object ):void {
			info.playerRotation = $obj
		}
		
		
		////////////////////////////////////////////////////////////////////////////////////////////////////
		// toPersistance
		////////////////////////////////////////////////////////////////////////////////////////////////////

		private function saveEvent( $re:RegionEvent ):void {
			if ( guid != $re.guid )
				return
			
			// The null owner check makes it to we dont save local loaded regions to persistance
			if ( null != owner && Globals.isGuid( guid ) )
				super.save()
		}
		
		override protected function toObject():void {
			//Log.out( "Region.toObject", Log.WARN );
			// modelCache will be true if this region has been loaded.
			// if it has not been loaded, just use the existing info.models data
			if ( _modelCache )
				info.models = _modelCache.toObject();
				
			_permissions.toObject();
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////
		// fromPersistance
		////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function fromObject( $dbo:DatabaseObject ):void {
			dbo = $dbo;
			info = $dbo;
			_permissions = new PermissionsRegion( info.permissions );
		}
		
		public function fromObjectImport( $dbo:DatabaseObject ):void {
			dbo = $dbo;
			info = $dbo.data;
			info.worldId = Globals.VOXELVERSE;
			info.name = "NewRegion";
			info.desc = "Describe what is special about this region";
			info.playerPosition = new Object();
			info.playerRotation = new Object();
			info.playerPosition.x = info.playerPosition.y = info.playerPosition.z = 0;
			info.playerRotation.x = info.playerRotation.y = info.playerRotation.z = 0;
			_permissions = new PermissionsRegion( info );
//			changed = true;
		}
	} // Region
} // Package