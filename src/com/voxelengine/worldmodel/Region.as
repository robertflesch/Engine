/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.worldmodel.models.makers.ModelMaker;

import flash.geom.Vector3D;
import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.WindowSplashEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
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

	private var _loaded:Boolean;
	private var _unloading:Boolean;

	private var _criticalModelDetected:Boolean = false;
	private var _modelCache:ModelCache;
	private var _permissions:PermissionsRegion;
	// INSTANCE AND EXPORTED - Run time optimization
	private var _skyColor:Vector3D = new Vector3D();

	//public function get worldId():String { return dbo.worldId; }
	//public function set worldId(val:String):void { dbo.worldId = val; }
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
		super( $guid, RegionManager.BIGDB_TABLE_REGIONS );
		if( $dbo ) {
			dbo = $dbo;
		} else {
			assignNewDatabaseObject();
		}

		init();
	}

	private function init():void {
		// This creates and parses the permissions
		_permissions = new PermissionsRegion();
		_permissions.fromObject( this );
	}

	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		dbo.models = [];
		dbo.skyColor = {"x": 92, "y": 172, "z": 238};
		dbo.gravity = false;
		dbo.worldId = Globals.VOXELVERSE;
		dbo.owner = "local";
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

	public function load():void {
        Log.out( "Region.load - loading    GUID: " + guid + "  name: " +  name, Log.DEBUG );
		_s_currentRegion = this;
		_modelCache = new ModelCache();
		addLoadingEventListeners();
		RegionEvent.create( RegionEvent.LOAD_BEGUN, 0, guid );
		// old style uses region.
		setSkyColor( dbo.skyColor );
		_loaded = false;
		loadRegionObjects( dbo.models );

		Log.out( "Region.load - completed GUID: " + guid + "  name: " +  name, Log.DEBUG );
	}

    public function unload():void {
        //Log.out( "Region.unload guid: " + guid + " complete modelCache.count: " + _modelCache, Log.DEBUG );
        Log.out( "Region.unload guid: " + guid, Log.DEBUG );
        removeLoadingEventListeners();
        _unloading = true;
        _modelCache.unload();
        _unloading = false;
        //release(); // Dont release it, memory is invalidated
    }



    // Makes sense, called from Region
	private var _objectCount:int = 0;
	public function loadRegionObjects( $models:Object ):int {
		//Log.out( "Region.loadRegionObjects - START =============================" );
		for each ( var v:Object in $models ) {
			if ( v ) {
				var ii:InstanceInfo = new InstanceInfo();
				ii.fromObject( v );
//					if ( !instance.instanceGuid )
//						instance.instanceGuid = Globals.getUID();
				incrementObjectCount();
				new ModelMaker( ii );
			}
		}
		Log.out( "Region.loadRegionObjects - END " + "  count: " + getObjectCount() + "=============================" );
		if ( 0 == getObjectCount() ) {
			_loaded = true;
			RegionEvent.create( RegionEvent.LOAD_COMPLETE, 0, Region.currentRegion.guid );
			WindowSplashEvent.create( WindowSplashEvent.DESTORY );
		}

		return getObjectCount();
	}

	private function addLoadingEventListeners():void {
		RegionEvent.addListener( ModelBaseEvent.CHANGED, 					regionChanged );
		RegionEvent.addListener( RegionEvent.LOAD_COMPLETE, 				onLoadingComplete );

        ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_FAILURE,removeFailedObjectFromRegion );

		ModelEvent.addListener( ModelEvent.CRITICAL_MODEL_DETECTED,			onCriticalModelDetected );
		ModelEvent.addListener( ModelEvent.PARENT_MODEL_ADDED,				parentModelAdded );
		ModelEvent.addListener( ModelEvent.PARENT_MODEL_REMOVED,			modelChanged );
	}

	private function removeLoadingEventListeners():void {
		RegionEvent.removeListener( ModelBaseEvent.CHANGED, 				regionChanged );
		RegionEvent.removeListener( RegionEvent.LOAD_COMPLETE, 				onLoadingComplete );

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

	private function getObjectCount():int { return _objectCount;  }
	private function incrementObjectCount():void { _objectCount++;  }
	private function decrementObjectCount():void { if ( _objectCount > 0 ) _objectCount--;  }
	private function parentModelAdded( $me:ModelEvent ):void  {
		if ( 0 == getObjectCount() && _loaded )
			changed = true;
		decrementObjectCount();
	}

	private function removeFailedObjectFromRegion( $e:ModelLoadingEvent ):void {
		// Do I need to remove this failed load?
		Log.out( "Region.removeFailedObjectFromRegion - failed to load: " + $e.data, Log.WARN );
		currentRegion.changedForce = true;
		decrementObjectCount();
	}

	private function modelChanged(e:ModelEvent):void {
		if ( Region.currentRegion.guid == guid ) {
			if ( _unloading )
				return;
			Log.out( "Region.modelChanged" );
			if ( 0 == getObjectCount() )
				changed = true;
		}
	}

	private function onLoadingComplete( le:RegionEvent ):void {
		//Log.out( "Region.onLoadingComplete: regionId: " + guid, Log.WARN );
		_loaded = true;
		RegionEvent.removeListener( RegionEvent.LOAD_COMPLETE, onLoadingComplete );
		//RegionEvent.dispatch( new RegionEvent( RegionEvent.LOAD_COMPLETE, 0, guid ) );
	}
	public function toString():String {

		// This does not generate valid JSON
		var outString:String = "  name:" + name;
		outString += "  desc:" + desc;
		outString += "  owningModel:" + owner;
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

	override public function save( $validateGuid:Boolean = true ):Boolean {
		// The null owningModel check makes it to we dont save local loaded regions to persistence
		if ( null != owner && Globals.isGuid( guid ) ) {
			if (changed) {
				Log.out( "RegionManager.save saving region name: " + name, Log.WARN );
				return super.save( $validateGuid );
			}
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