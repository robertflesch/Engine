/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;
import flash.net.URLLoaderDataFormat;

import org.as3commons.collections.Map;
import org.as3commons.collections.iterators.FilterIterator;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.makers.OxelLoadAndBuildManager;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateOxel;

public class OxelPersistenceCache
{
	// this acts as a holding spot for all model objects loaded from persistence
	// don't use weak keys since this is THE spot that holds things.
	// static private var _oxelDataDic:Dictionary = new Dictionary(false);
	static private var _loadingCount:int;
	static private var _oxelDataMap:Map = new Map();
	static private var _block:Block = new Block();
	
	public function OxelPersistenceCache() {}
	
	static public function init():void {
		// These are the events that this object listens for.
		OxelDataEvent.addListener( ModelBaseEvent.REQUEST, 				request );
		OxelDataEvent.addListener( ModelBaseEvent.DELETE, 				deleteHandler );
		OxelDataEvent.addListener( ModelBaseEvent.UPDATE_GUID, 			updateGuid );
		OxelDataEvent.addListener( ModelBaseEvent.SAVE, 				save );

		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.GENERATE_SUCCEED,generateSucceed );
        PersistenceEvent.addListener( PersistenceEvent.CLONE_SUCCEED,   cloneSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}

	static private function save(e:OxelDataEvent):void {
		var iterator:FilterIterator = new FilterIterator( _oxelDataMap, filter );
		var op:OxelPersistence;
		while (iterator.hasNext()) {
			op = iterator.next() as OxelPersistence;
			if ( op ) {
				trace("OP.saving " + op.guid);
				op.save();
			}
		}

		function filter(item :OxelPersistence ): Boolean {
			return item.changed && !item.doNotPersist && EditCursor.EDIT_CURSOR != item.guid ;
		}
	}

	static private function add( $series:int, $op:OxelPersistence ):void {
		if ( null ==getOP( $op.guid ) ) { // check to make sure this is new data
			//Log.out( "OxelDataCache.add adding: " + $op.guid, Log.INFO );
			_oxelDataMap.add( $op.guid, $op );
			if ( _block.has( $op.guid ) )
				_block.clear( $op.guid );
			_loadingCount--;
			OxelDataEvent.create( ModelBaseEvent.ADDED, $series, $op.guid, $op );
			new OxelLoadAndBuildManager( $op.guid, $op );
		} else {
			Log.out("OxelDataCache.Add trying to add duplicate OxelData", Log.WARN);
			OxelDataEvent.create(ModelBaseEvent.ADDED, $series, $op.guid, $op);
		}
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  OxelDataEvents
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function updateGuid( $ode:OxelDataEvent ):void {
		var guidArray:Array = $ode.modelGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var oxelData:OxelPersistence = getOP(oldGuid);
		if ( null == oxelData ) {
			Log.out( "OxelPersistenceCache.updateGuid - guid not found: " + oldGuid, Log.ERROR );
		} else {
			_oxelDataMap.removeKey( oldGuid );
			_oxelDataMap.add( newGuid, oxelData );
		}
	}

	static private function getOP( $guid:String ):OxelPersistence {
		return _oxelDataMap.itemFor($guid) as OxelPersistence;
	}

	static private function request( $ode:OxelDataEvent ):void {   
		if ( null == $ode.modelGuid ) {
			Log.out( "OxelDataCache.modelDataRequest guid requested is NULL: ", Log.WARN );
			return;
		}
		
		//Log.out( "OxelDataCache.request guid: " + $ode.modelGuid, Log.DEBUG );
		var op:OxelPersistence = getOP( $ode.modelGuid );
		if ( null == op ) {
			if ( _block.has( $ode.modelGuid ) )	
				return;
			_block.add( $ode.modelGuid );
				
			_loadingCount++;
			if ( true == $ode.generated ) {
				var genClass:Class = GenerateOxel.resolveGenerationType( $ode.generationData.biomes.layers[0].functionName );
				// TODO need to add Locked to new OP here
				genClass.addTask($ode.modelGuid, LayerInfo.fromObject($ode.generationData));
			}
			else if ( !$ode.fromTables )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ode.series, Globals.IVM_EXT, $ode.modelGuid, null, null, URLLoaderDataFormat.BINARY ) );
			else if ( true == Globals.online && $ode.fromTables )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ode.series, Globals.BIGDB_TABLE_OXEL_DATA, $ode.modelGuid ) );
			else
				Log.out( "OxelPersistenceCache.request - Trying to load an asset from tables when not online guid: " + $ode.modelGuid, Log.ERROR);
		}
		else
			OxelDataEvent.create( ModelBaseEvent.RESULT, $ode.series, $ode.modelGuid, op );
	}
	
	static private function deleteHandler( $ode:OxelDataEvent ):void {
		//Log.out( "OxelDataCache.deleteHandler $ode: " + $ode, Log.WARN );
		var od:OxelPersistence = getOP( $ode.modelGuid );
		if ( null != od ) {
			_oxelDataMap.removeKey( $ode.modelGuid );
		}
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, $ode.series, Globals.BIGDB_TABLE_OXEL_DATA, $ode.modelGuid, null ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - OxelDataEvents
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function loadSucceed( $pe:PersistenceEvent):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;

		var op:OxelPersistence = getOP( $pe.guid );
		if ( null != op ) {
			// we already have it, publishing this results in duplicate items being sent to inventory window.
			OxelDataEvent.create( ModelBaseEvent.RESULT, $pe.series, $pe.guid, op );
			Log.out( "OxelPersistenceCache.loadSucceed - attempting to load duplicate OxelPersistence guid: " + $pe.guid, Log.WARN );
			return;
		}

		if ( $pe.dbo ) {
			op = new OxelPersistence( $pe.guid, $pe.dbo, null );
			add( $pe.series, op );
		} else if ( $pe.data ) {
			op = new OxelPersistence( $pe.guid, null, $pe.data as ByteArray );
			add( $pe.series, op ); // This rebuilds the faces and scaling of the imported models
		} else {
			Log.out( "OxelDataCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.WARN );
			OxelDataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
		}
	}

    // This is similar to load succeed.
    static private function cloneSucceed( $pe:PersistenceEvent ):void {
        if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
            return;
        //Log.out( "OxelDataCache.generateSucceed " + $pe.toString(), Log.INFO );
        var op:OxelPersistence = new OxelPersistence( $pe.guid, null, $pe.data, true );
        if ( $pe.other )
            op.bound = parseInt($pe.other);
        else {
            Log.out( "OxelDataCache.cloneSucceed - BUT with unknown bound. Assigning bound of 0" + $pe.toString(), Log.WARN );
            op.bound = 0;
        }
        add( $pe.series, op );
    }

	// This is similar to load succeed.
	static private function generateSucceed( $pe:PersistenceEvent ):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		//Log.out( "OxelDataCache.generateSucceed " + $pe.toString(), Log.INFO );
		var op:OxelPersistence = new OxelPersistence( $pe.guid, null, $pe.data, true );
		if ( $pe.other )
			op.bound = parseInt($pe.other);
		else {
			Log.out( "OxelDataCache.generateSucceed - BUT with unknown bound. Assigning bound of 0" + $pe.toString(), Log.WARN );
			op.bound = 0;
		}
		add( $pe.series, op );
	}

	static private function loadFailed( $pe:PersistenceEvent ):void {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		//Log.out( "OxelDataCache.loadFailed " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		OxelDataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void  {
		if ( Globals.IVM_EXT != $pe.table && Globals.BIGDB_TABLE_OXEL_DATA != $pe.table )
			return;
		//Log.out( "OxelDataCache.loadNotFound " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		//OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
		OxelDataEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
}
}