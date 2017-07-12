/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.pools 
{

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.models.*
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateOxel;
import com.voxelengine.worldmodel.weapons.Projectile


public final class ProjectilePoolType 
{ 
	private var _currentPoolSize:uint;
	private var _growthValue:uint;
	private var _counter:uint;
	private var _pool:Vector.<Projectile>;
	private var _modelInfo:ModelInfo;
	private var _modelMetadata:ModelMetadata;
	
	public function remaining():uint { return _counter }
	public function total():uint { return _pool.length }
	public function totalUsed():uint { return _pool ? _pool.length - _counter : _growthValue }

	public function ProjectilePoolType( $type:uint, $initialPoolSize:uint, $growthValue:uint ):void {
		_currentPoolSize = $initialPoolSize;
		_growthValue = $growthValue;
		_counter = $initialPoolSize;
		
		var i:uint = _counter;
		_pool = new Vector.<Projectile>(_counter);
		_counter = 0;
		//Log.out( "ProjectilePoolType.onModelInfoLoaded: counter: " + _counter + "  _currentPoolSize: " + _currentPoolSize + " poolsize: " + _pool.length )
		generateData( $type );
		// This creates many instances of the same projectileGuid
		// maybe some issues of grain size is different...
		while( --i > -1 ) 
			addToPool( newModel() )
	}

    static private const 		PROJECTILE:String 					= "PROJECTILE";
	private function generateData( $type:uint ):void {
		
		// I dont like that I create new metadata and _modelInfo for each projectile.
		// I should be able to create instances
		//throw new Error( "Need to refactor this, I broke it when I added the island generation" );
		// This is a special case for _modelInfo, the _modelInfo its self is contained in the generate script

        _modelMetadata = new ModelMetadata( PROJECTILE + $type );
        _modelMetadata.permissions.modify = false;
        _modelMetadata.doNotPersist = true;
        _modelMetadata.name = PROJECTILE  + $type;
        _modelMetadata.description = PROJECTILE + $type + " - GENERATED";
        _modelMetadata.owner = "";

        //creationInfo.name = "EDIT_CURSOR";
        //_modelInfo = new ModelInfo( _projectileGuid, null, GenerateOxel.cubeScript( 2, TypeInfo.BLUE ) );
        //_modelInfo = new ModelInfo( PROJECTILE, null, creationInfo );
        _modelInfo = new ModelInfo( PROJECTILE + $type, null, {} );
        _modelInfo.doNotPersist = true;

		var creationInfo:Object = GenerateCube.script( 4, TypeInfo.BLUE );
		creationInfo.modelClass = "PROJECTILE";
        OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, _modelInfo.guid, null, true, true, creationInfo );

		if ( Globals.isGuid( _modelInfo.guid ) )
				Log.out( "IsGuid");
//		var ba:ByteArray  = Oxel.generateCube( _projectileGuid, _modelInfo.biomes.layers[0], false );
//		_modelInfo.oxelPersistence = new OxelPersistence( _projectileGuid, null, ba );
//		_modelInfo.oxelPersistence.loadFromByteArray();

	}
		
	private function newModel():Projectile {	
		var ii:InstanceInfo = new InstanceInfo();
		ii.instanceGuid = Globals.getUID();
		ii.modelGuid = _modelInfo.guid;
		ii.usesCollision = true;
		ii.dynamicObject = true;
		var vm:Projectile = new Projectile( ii );
		if ( null == vm ) {
			Log.out( "Projectile.newModel - failed to create Projectile", Log.ERROR );
			return null
		}
		vm.init( _modelInfo, _modelMetadata );
		return vm
	}

	public function poolGet():Projectile { 
		if ( _counter > 0 ) 
			return _pool[--_counter];
			 
		Log.out( "ProjectilePoolType.poolGet - Allocating more Projectiles: " + _currentPoolSize );
//		var timer:int = getTimer()

		_currentPoolSize += _growthValue;
		_pool = null;
		_pool = new Vector.<Projectile>(_currentPoolSize);
		for ( var newIndex:int = 0; newIndex < _growthValue; newIndex++ ) 
			_pool[newIndex] = newModel()
		_counter = newIndex - 1;
		
//		Log.out( "ProjectilePoolType.poolGet - Done allocating more Projectiles: " + _currentPoolSize  + " took: " + (getTimer() - timer) )
		
		return poolGet() 
	} 

	public function poolDispose( $disposedProjectile:Projectile):void { 
		$disposedProjectile.dead = false;
		$disposedProjectile.instanceInfo.removeAllTransforms();
		
		addToPool( $disposedProjectile ) 
	} 
	
	private function addToPool( $projectile:Projectile ):void {
		_pool[_counter++] = $projectile 
	}
}
}