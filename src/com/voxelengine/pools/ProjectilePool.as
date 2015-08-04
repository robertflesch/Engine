/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.pools 
{

import com.voxelengine.events.LoadingEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ProjectileEvent;
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube;
import com.voxelengine.worldmodel.weapons.Projectile;
import playerio.DatabaseObject;
     
public final class ProjectilePool 
{ 
	private static var _currentPoolSize:uint; 
	private static var _growthValue:uint; 
	private static var _counter:uint; 
	private static var _pool:Vector.<Projectile>; 
	//private static const CLASS_NAME:String = "CannonBall";
	
	static public function remaining():uint { return _counter; }
	static public function total():uint { return _pool.length; }
	static public function totalUsed():uint { return _pool ? _pool.length - _counter : _growthValue; }

	
	public static function initialize( $initialPoolSize:uint, $growthValue:uint ):void 
	{ 
		_currentPoolSize = $initialPoolSize; 
		_growthValue = $growthValue; 
		_counter = $initialPoolSize; 
		// We have to wait until types are loading before we can start our process
		LoadingEvent.addListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
	} 
	
	private static function onTypesLoaded( $event:LoadingEvent ):void {
		// So types are done, now we have to preload the CLASS_NAME.mjson file
		LoadingEvent.removeListener( LoadingEvent.LOAD_TYPES_COMPLETE, onTypesLoaded );
		projectilesGenerate();
	}
	
	static private function projectilesGenerate():void {
		var i:uint = _counter; 
		_pool = new Vector.<Projectile>(_counter);
		_counter = 0;
		//Log.out( "ProjectilePool.onModelInfoLoaded: counter: " + _counter + "  _currentPoolSize: " + _currentPoolSize + " poolsize: " + _pool.length );
		while( --i > -1 ) 
			addToPool( newModel() );
	}
	
	static private function newModel():Projectile {
		
		var CLASS_NAME:String = Globals.getUID();
		var obj:DatabaseObject = GenerateCube.script();
		obj.model.grainSize = 2;
		// This is a special case for modelInfo, the modelInfo its self is contained in the generate script
		var modelInfo:ModelInfo = new ModelInfo( CLASS_NAME );
		modelInfo.fromObject( obj );
		//ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.GENERATION, 0, CLASS_NAME, modelInfo ) );

		var modelMetadata:ModelMetadata = new ModelMetadata( CLASS_NAME );
		var newDbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_MODEL_METADATA, "0", "0", 0, true, null );
		newDbo.data = new Object();
		modelMetadata.fromObjectImport( newDbo );
		modelMetadata.name = CLASS_NAME;
		modelMetadata.description = CLASS_NAME + " - GENERATED";
		modelMetadata.owner = "";
		//ModelMetadataEvent.dispatch( new ModelMetadataEvent ( ModelBaseEvent.GENERATION, 0, CLASS_NAME, modelMetadata ) );
		modelInfo.oxelLoadData();		
		
		var ii:InstanceInfo = new InstanceInfo();
		ii.instanceGuid = CLASS_NAME;
		ii.modelGuid = CLASS_NAME;
		ii.usesCollision = true;
		ii.dynamicObject = true;
		ii.baseLightLevel = 255;
		var vm:Projectile = new Projectile( ii );
		if ( null == vm ) {
			Log.out( "Projectile.newModel - failed to create Projectile", Log.ERROR );
			return null;
		}
		vm.init( modelInfo, modelMetadata );
		return vm;
	}

	public static function poolGet():Projectile { 
		if ( _counter > 0 ) 
			return _pool[--_counter]; 
			 
		Log.out( "ProjectilePool.poolGet - Allocating more Projectiles: " + _currentPoolSize );
//		var timer:int = getTimer();

		_currentPoolSize += _growthValue;
		_pool = null
		_pool = new Vector.<Projectile>(_currentPoolSize);
		for ( var newIndex:int = 0; newIndex < _growthValue; newIndex++ ) 
			_pool[newIndex] = newModel();
		_counter = newIndex - 1; 
		
//		Log.out( "ProjectilePool.poolGet - Done allocating more Projectiles: " + _currentPoolSize  + " took: " + (getTimer() - timer) );
		
		return poolGet(); 
	} 

	public static function poolDispose( $disposedProjectile:Projectile):void { 
		$disposedProjectile.dead = false;
		$disposedProjectile.instanceInfo.removeAllTransforms();
		
		addToPool( $disposedProjectile ); 
	} 
	
	private static function addToPool( $projectile:Projectile ):void {
		_pool[_counter++] = $projectile; 
	}
}
}