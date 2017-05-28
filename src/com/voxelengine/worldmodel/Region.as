/*==============================================================================
  Copyright 2011-2017 Robert Flesch
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
	import com.voxelengine.events.PersistenceEvent;
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
	import com.voxelengine.worldmodel.models.PersistenceObject;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class Region extends PersistenceObject {
		
		
		static public var _s_currentRegion:Region;
		static public function get currentRegion():Region { return _s_currentRegion; }

		// INSTANCE NOT EXPORTED
		private var _loaded:Boolean;
		private var _criticalModelDetected:Boolean = false;
		private var _modelCache:ModelCache;
		private var _permissions:PermissionsRegion;
		// INSTANCE AND EXPORTED - Run time optimization
		private var _skyColor:Vector3D = new Vector3D();

		public function get worldId():String { return dbo.worldId; }
		public function set worldId(val:String):void { dbo.worldId = val; }
		public function get owner():String { return dbo.owner; }
		public function set owner(val:String):void { dbo.owner = val; }
		public function get desc():String { return dbo.desc; }
		public function set desc(val:String):void { dbo.desc = val; }
		public function get name():String { return dbo.name; }
		public function set name(val:String):void { dbo.name = val; }
		public function get gravity():Boolean { return dbo.gravity; }
		public function set gravity(val:Boolean):void { dbo.gravity = val; }
		public function get playerPosition():Object { return dbo.playerPosition; }
		public function get playerRotation():Object {return dbo.playerRotation; }
		public function setPlayerPosition( $obj:Object ):void { dbo.playerPosition = $obj }
		public function setPlayerRotation( $obj:Object ):void { dbo.playerRotation = $obj }

		public function set changedForce(val:Boolean):void { changed = val; }

		public function get loaded():Boolean { return _loaded; }
		public function get modelCache():ModelCache  { return _modelCache; }

		public function getSkyColor():Vector3D { return _skyColor; }
		public function setSkyColor( $skyColor:Object ):void {
			if ( !$skyColor ) {
				Log.out( "Region.setSkyColor - no object", Log.ERROR);
				$skyColor = { "x":92, "y":172, "z":238 }
			}
			var x:int = $skyColor.x;
			if ( x < 0 || 255 < x )
				$skyColor.x = 92;
			var y:int = $skyColor.y;
			if ( y < 0 || 255 < y )
				$skyColor.y = 172;
			var z:int = $skyColor.z;
			if ( z < 0 || 255 < z )
				$skyColor.z = 238;

			dbo.skyColor = $skyColor;
			_skyColor.setTo( dbo.skyColor.x, dbo.skyColor.y , dbo.skyColor.z )
		}

		public function Region( $guid:String, $dbo:DatabaseObject, $importedData:Object ):void {
			super( $guid, Globals.BIGDB_TABLE_REGIONS );
			if( $dbo ) {
                dbo = $dbo;
            } else {
				assignNewDatabaseObject();
            }

			init();

			// all regions listen to be loaded and saved,
			// but those are the only region messages they listen to.
			// unless they are loaded
			RegionEvent.addListener( RegionEvent.LOAD, 		load );

			function init():void {
				// This creates and parses the permissions
				_permissions = new PermissionsRegion(dbo);
			}
		}

		override protected function assignNewDatabaseObject():void {
			super.assignNewDatabaseObject()
			dbo.models = [];
			dbo.skyColor = {"x": 92, "y": 172, "z": 238};
			dbo.gravity = false;
			dbo.worldId = Globals.VOXELVERSE;
			dbo.name = "NewRegion";
			dbo.desc = "Describe what is special about this region";
			dbo.playerPosition = {};
			dbo.playerPosition.x = dbo.playerPosition.y = dbo.playerPosition.z = 0;
			dbo.playerRotation = {};
			dbo.playerRotation.x = dbo.playerRotation.y = dbo.playerRotation.z = 0;
		}
		
		// allows me to release the listeners for temporary regions
		override public function release():void {
			super.release();
			RegionEvent.removeListener( RegionEvent.LOAD, 		load );
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
				RegionEvent.create( RegionEvent.UNLOAD, 0, _s_currentRegion.guid );
			_s_currentRegion = this;
			VoxelModel.selectedModel = null;
			
			_modelCache = new ModelCache();
			
			Log.out( "Region.load - loading    GUID: " + guid + "  name: " +  name, Log.DEBUG );

			if ( !Globals.online )
				Player.player.createPlayer(Player.DEFAULT_PLAYER, Network.LOCAL );


			addLoadingEventListeners();
			RegionEvent.create( RegionEvent.LOAD_BEGUN, 0, guid );
			// old style uses region.
			setSkyColor( dbo.skyColor );
			_loaded = false;
			loadRegionObjects( dbo.models );

			Log.out( "Region.load - completed GUID: " + guid + "  name: " +  name, Log.DEBUG );
		}	
		
		// Makes sense, called from Region
		private var _objectCount:int = 0;
		public function loadRegionObjects( $models:Object ):int {
			//Log.out( "Region.loadRegionObjects - START =============================" );
			for each ( var v:Object in $models ) {
				if ( v ) {
					var instance:InstanceInfo = new InstanceInfo();
					instance.fromObject( v );
//					if ( !instance.instanceGuid )
//						instance.instanceGuid = Globals.getUID();
					_objectCount++;
					ModelMakerBase.load( instance );
				}
			}
			Log.out( "Region.loadRegionObjects - END " + "  count: " + _objectCount + "=============================" );
			if ( 0 == _objectCount ) {
				_loaded = true;
				RegionEvent.create( RegionEvent.LOAD_COMPLETE, 0, Region.currentRegion.guid );
				WindowSplashEvent.dispatch( new WindowSplashEvent( WindowSplashEvent.DESTORY ) );
			}

			return _objectCount;
		}

		private function addLoadingEventListeners():void {
			RegionEvent.addListener( ModelBaseEvent.CHANGED, 					regionChanged );
			RegionEvent.addListener( RegionEvent.UNLOAD, 						unload );
				
			LoadingEvent.addListener( LoadingEvent.LOAD_COMPLETE, 				onLoadingComplete );
			ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_FAILURE,removeFailedObjectFromRegion );
				
			ModelEvent.addListener( ModelEvent.CRITICAL_MODEL_DETECTED,			onCriticalModelDetected );
			ModelEvent.addListener( ModelEvent.PARENT_MODEL_ADDED,				parentModelAdded );
			ModelEvent.addListener( ModelEvent.PARENT_MODEL_REMOVED,			modelChanged );
		}

		private function removeLoadingEventListeners():void {
			RegionEvent.removeListener( ModelBaseEvent.CHANGED, 				regionChanged );
			RegionEvent.removeListener( RegionEvent.UNLOAD, 					unload );

			LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, 			onLoadingComplete );

			ModelLoadingEvent.removeListener( ModelLoadingEvent.MODEL_LOAD_FAILURE,	removeFailedObjectFromRegion );

			ModelEvent.removeListener( ModelEvent.CRITICAL_MODEL_DETECTED, 		onCriticalModelDetected );
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_ADDED,			parentModelAdded );
			ModelEvent.removeListener( ModelEvent.PARENT_MODEL_REMOVED,			regionChanged );
		}

		private function regionChanged( $re:RegionEvent):void  {
			if ( guid == $re.guid ) {
				Log.out( "Region.regionChanged" );
				changed = true;
			}
		}

		private function parentModelAdded( $me:ModelEvent ):void  {
			if ( 0 == _objectCount )
				changed = true;
			_objectCount--;
		}

		private function removeFailedObjectFromRegion( $e:ModelLoadingEvent ):void {
			// Do I need to remove this failed load?
			Log.out( "Region.removeFailedObjectFromRegion - failed to load: " + $e.data, Log.WARN );
			currentRegion.changedForce = true;
			_objectCount--;
		}

		private function modelChanged(e:ModelEvent):void {
			if ( Region.currentRegion.guid == guid ) {
				Log.out( "Region.modelChanged" );
				if ( 0 == _objectCount )
					changed = true;
			}
		}
		
		private function unload( $re:RegionEvent ):void {
			removeLoadingEventListeners();
			//Log.out( "Region.unload guid: " + guid + " complete modelCache.count: " + _modelCache, Log.DEBUG );
			_modelCache.unload();
			//release(); // Dont release it, memory is invalidated
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

		////////////////////////////////////////////////////////////////////////////////////////////////////
		// toPersistence
		////////////////////////////////////////////////////////////////////////////////////////////////////

		override public function save():Boolean {
			// The null owner check makes it to we dont save local loaded regions to persistance
			if ( null != owner && Globals.isGuid( guid ) ) {
				if (changed)
					return super.save();
			}
			return false;
		}
		
		override protected function toObject():void {
			//Log.out( "Region.toObject", Log.WARN );
			// modelCache will be true if this region has been loaded.
			// if it has not been loaded, just use the existing dbo.models oxelPersistence
			if ( _modelCache )
				dbo.models = _modelCache.toObject();
				
			//dbo.permissions.toObject();
		}
		
	} // Region
} // Package