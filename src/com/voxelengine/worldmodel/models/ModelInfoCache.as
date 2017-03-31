/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.Dictionary;

import com.voxelengine.Log;
import com.voxelengine.Globals;

import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.utils.StringUtils;
import com.voxelengine.worldmodel.models.makers.ModelDestroyer;

public class ModelInfoCache
{
	static private var _modelInfo:Dictionary = new Dictionary(false);
	static private var _block:Block = new Block();
	
	// This is required to be public.
	public function ModelInfoCache() {}
	
	static public function init():void {
		// These are the requests that are handled
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST, 			request );
		ModelInfoEvent.addListener( ModelBaseEvent.EXISTS_REQUEST, 		checkIfExists );
		ModelInfoEvent.addListener( ModelBaseEvent.SAVE, 				save );
		ModelInfoEvent.addListener( ModelBaseEvent.DELETE, 				deleteHandler );
		ModelInfoEvent.addListener( ModelInfoEvent.DELETE_RECURSIVE, 	deleteRecursive );
		ModelInfoEvent.addListener( ModelBaseEvent.GENERATION, 			generated );
		ModelInfoEvent.addListener( ModelBaseEvent.UPDATE_GUID, 		updateGuid );
		ModelInfoEvent.addListener( ModelBaseEvent.UPDATE, 				update );

		// These are the events at the persistence layer
		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  ModelInfoEvents
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function request( $mie:ModelInfoEvent ):void {
		if ( null == $mie || null == $mie.modelGuid ) { // Validator
			Log.out( "ModelInfoCache.request requested event or guid is NULL: ", Log.ERROR );
			ModelInfoEvent.create( ModelBaseEvent.EXISTS_ERROR, ( $mie ? $mie.series: -1 ), "MISSING", null );
		} else {
			Log.out( "ModelInfoCache.modelInfoRequest guid: " + $mie.modelGuid, Log.INFO );
			var mi:ModelInfo = _modelInfo[$mie.modelGuid];
			if (null == mi) {
				if (_block.has($mie.modelGuid))
					return;
				_block.add($mie.modelGuid);

				if (true == Globals.online && $mie.fromTables)
					PersistenceEvent.dispatch(new PersistenceEvent(PersistenceEvent.LOAD_REQUEST, $mie.series, Globals.BIGDB_TABLE_MODEL_INFO, $mie.modelGuid));
				else
					PersistenceEvent.dispatch(new PersistenceEvent(PersistenceEvent.LOAD_REQUEST, $mie.series, Globals.MODEL_INFO_EXT, $mie.modelGuid));
			}
			else {
				if ($mie)
					ModelInfoEvent.create(ModelBaseEvent.RESULT, $mie.series, $mie.modelGuid, mi);
				else
					Log.out("ModelInfoCache.request ModelInfoEvent is NULL: ", Log.WARN);
			}
		}
	}

	static private function save(e:ModelInfoEvent):void {
		for each ( var modelInfo:ModelInfo in _modelInfo )
			if ( modelInfo && modelInfo.changed )
				modelInfo.save();
	}

	static private function checkIfExists( $mie:ModelInfoEvent ):void {
		if ( null == $mie || null == $mie.modelGuid ) { // Validator
			Log.out( "ModelInfoCache.checkIfExists requested event or guid is NULL: ", Log.ERROR );
			ModelInfoEvent.create( ModelBaseEvent.EXISTS_ERROR, ( $mie ? $mie.series: -1 ), "MISSING", null );
		} else {
			var mi:ModelInfo = _modelInfo[$mie.modelGuid];
			if (null != mi)
				ModelInfoEvent.create( ModelBaseEvent.EXISTS, $mie.series, $mie.modelGuid, mi);
			else
				ModelInfoEvent.create( ModelBaseEvent.EXISTS_FAILED, $mie.series, $mie.modelGuid, null);
		}
	}

	static private function deleteHandler( $mie:ModelInfoEvent ):void {
		var mi:ModelInfo = _modelInfo[$mie.modelGuid]; 
		if ( null != mi ) {
			_modelInfo[$mie.modelGuid] = null; 
			// TODO need to clean up eventually
			mi = null;
			PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, $mie.series, Globals.BIGDB_TABLE_MODEL_INFO, $mie.modelGuid, null ) );
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.DELETE, $mie.modelGuid, null ) );
		}
	}
	
	static private function deleteRecursive( $mie:ModelInfoEvent ):void {
		// first delete any children
		// Should always be an entry in the modelInfo table, since a request for it went out first.
		// And this was called only after the request returned.
		var mi:ModelInfo = _modelInfo[$mie.modelGuid]; 
		if ( mi ) {
			for each ( var childii:Object in mi.dbo.children ) {
				if ( childii && childii.modelGuid ) {
					// Using the fromTables to handle the recursive flag
					new ModelDestroyer( childii.modelGuid, $mie.fromTables );		
				}
			}
		} else 
			Log.out( "ModelInfoCache.deleteRecursive - ModelInfo not found $mie" + $mie, Log.ERROR )
		
		// Now delete the parents oxelPersistence
		ModelMetadataEvent.create( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null );
		OxelDataEvent.create( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null ) );
	}


	static private function generated( $mie:ModelInfoEvent ):void  {
		add( 0, $mie.vmi );
	}

	static private function update($mie:ModelInfoEvent):void {
		if ( null == $mie || null == $mie.modelGuid ) { // Validator
			Log.out("ModelMetadataCache.update - event or guid is NULL: ", Log.ERROR);
			ModelInfoEvent.create(ModelBaseEvent.EXISTS_ERROR, ( $mie ? $mie.series : -1 ), "MISSING", null);
		} else {
			var mi:ModelInfo = _modelInfo[$mie.modelGuid];
			if ( null ==  mi ) {
				Log.out( "ModelInfoCache.update trying update NULL metadata or guid, adding instead", Log.WARN );
				add( 0, $mie.vmi );
			} else {
				_modelInfo[$mie.modelGuid] = $mie.vmi;
			}
		}
	}

	static private function updateGuid( $ode:ModelInfoEvent ):void {
		var guidArray:Array = $ode.modelGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var modelInfoExisting:ModelInfo = _modelInfo[oldGuid];
		if ( null == modelInfoExisting ) {
			Log.out( "ModelInfoCache.updateGuid - guid not found: " + oldGuid, Log.ERROR );
			return; }
		else {
			_modelInfo[oldGuid] = null;
			_modelInfo[newGuid] = modelInfoExisting;
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////////////
	//  ModelInfoEvent
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Internal Methods
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function add( $series:int, $mi:ModelInfo ):void {
		if ( null == $mi || null == $mi.guid ) {
			//Log.out( "ModelInfoCache.add trying to add NULL modelInfo or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _modelInfo[$mi.guid] ) {
			//Log.out( "ModelInfoCache.add modelInfo: " + $mi.toString(), Log.DEBUG );
			_modelInfo[$mi.guid] = $mi;

			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.ADDED, $series, $mi.guid, $mi ) );
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function loadSucceed( $pe:PersistenceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_INFO != $pe.table && Globals.MODEL_INFO_EXT != $pe.table )
			return;

		var mi:ModelInfo = _modelInfo[$pe.guid];
		if ( null != mi ) {
			// we already have it, publishing this results in duplicate items being sent to inventory window.
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.ADDED, $pe.series, $pe.guid, mi ) );
			Log.out( "ModelInfoCache.loadSucceed - attempting to load duplicate ModelInfo guid: " + $pe.guid, Log.WARN );
			return;
		}

		if ( $pe.dbo ) {
			mi = new ModelInfo( $pe.guid, $pe.dbo, null );
			add( $pe.series, mi );
		} else if ( $pe.data ) {
			var fileData:String = String( $pe.data );
			fileData = StringUtils.trim(fileData);
			var newObjData:Object = JSONUtil.parse( fileData, $pe.guid + $pe.table, "ModelInfoCache.loadSucceed" );
			if ( null == newObjData ) {
				Log.out( "ModelInfoCache.loadSucceed - error parsing modelInfo on import. guid: " + $pe.guid, Log.ERROR );
				ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
				return;
			}
            if ( newObjData.model ) {
				mi = new ModelInfo($pe.guid, null, newObjData.model);
				Log.out( "ModelInfoCache.loadSucceed - OLD MODEL FOUND IN INFO.", Log.WARN);
			}
            else
			    mi = new ModelInfo( $pe.guid, null, newObjData );
			mi.save();

			add( $pe.series, mi );
			if ( _block.has( $pe.guid ) )
				_block.clear( $pe.guid )
		} else {
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
		}
	}

	static private function loadFailed( $pe:PersistenceEvent ):void {
		if ( Globals.BIGDB_TABLE_MODEL_INFO != $pe.table && Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoCache.loadFailed PersistenceEvent: " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_INFO != $pe.table && Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoCache.loadNotFound PersistenceEvent: " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
}
}