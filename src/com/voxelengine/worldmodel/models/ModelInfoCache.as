/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.server.Network;

import flash.utils.Dictionary;

import com.voxelengine.Log;
import com.voxelengine.Globals;

import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.InventoryEvent;
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
        ModelInfoEvent.addListener( ModelBaseEvent.REQUEST, 			request );				// ModelBaseEvent.RESULT
																								// ModelBaseEvent.REQUEST_FAILED - object returned was invalid
																								// ModelBaseEvent.EXISTS_ERROR - Malformed
        ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_TYPE, 		requestType );			// ModelBaseEvent.RESULT_RANGE
        ModelInfoEvent.addListener( ModelBaseEvent.UPDATE, 				update );				// ModelBaseEvent.EXISTS_ERROR - Malformed
		ModelInfoEvent.addListener( ModelBaseEvent.EXISTS_REQUEST, 		checkIfExists );
		ModelInfoEvent.addListener( ModelBaseEvent.SAVE, 				save );
		ModelInfoEvent.addListener( ModelBaseEvent.DELETE, 				deleteHandler );
		ModelInfoEvent.addListener( ModelInfoEvent.DELETE_RECURSIVE, 	deleteRecursive );
		ModelInfoEvent.addListener( ModelBaseEvent.GENERATION, 			generationComplete );
		ModelInfoEvent.addListener( ModelBaseEvent.UPDATE_GUID, 		updateGuid );
        ModelInfoEvent.addListener( ModelInfoEvent.REASSIGN_STORE, 		reassignToStore );
        ModelInfoEvent.addListener( ModelInfoEvent.REASSIGN_PUBLIC,		reassignToPublic );



        // These are the events at the persistence layer
		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  ModelInfoEvents
	/////////////////////////////////////////////////////////////////////////////////////////////
    // This loads the first 100 objects from the users inventory OR the public inventory
    // TODO - NEED TO ADD HANDLER WHEN MORE THAN 100 ARE NEEDED - RSF 9.14.2017
    static private var _initializedPublic:Boolean;
    static private var _initializedPrivate:Boolean;
    static private var _currentSeries:int;
    static private function requestType( $mme:ModelInfoEvent ):void {

        _currentSeries = $mme.series;
        //Log.out( "ModelInfoCache.requestType  owningModel: " + $mme.modelGuid, Log.WARN );
        // For each one loaded this will send out a new ModelMetadataEvent( ModelBaseEvent.ADDED, $mi.guid, $mi ) event
        if ( false == _initializedPublic && $mme.modelGuid == Network.PUBLIC ) {
            PersistenceEvent.create( PersistenceEvent.LOAD_REQUEST_TYPE, $mme.series, ModelInfo.BIGDB_TABLE_MODEL_INFO, Network.PUBLIC, null, ModelInfo.BIGDB_TABLE_MODEL_INFO_INDEX_OWNER );
            _initializedPublic = true;
        }

        if ( false == _initializedPrivate && $mme.modelGuid == Network.userId ) {
            PersistenceEvent.create( PersistenceEvent.LOAD_REQUEST_TYPE, $mme.series, ModelInfo.BIGDB_TABLE_MODEL_INFO, Network.userId, null, ModelInfo.BIGDB_TABLE_MODEL_INFO_INDEX_OWNER );
            _initializedPrivate = true;
        }

        // This will return models already loaded.
        for each ( var mi:ModelInfo in _modelInfo ) {
            if ( mi && mi.owner == $mme.modelGuid ) {
                //Log.out( "ModelInfoCache.requestType RETURN  " +  mi.owner + " ==" + $mme.modelGuid + "  guid: " + mi.guid + "  desc: " + mi.description , Log.WARN );
                ModelInfoEvent.create( ModelBaseEvent.RESULT_RANGE, $mme.series, mi.guid, mi );
            }
            else {
                if ( mi ) {
                    //Log.out("ModelInfoCache.requestType REJECTING  " + mi.owner + " !=" + $mme.modelGuid + "  guid: " + mi.guid + "  desc: " + mi.description, Log.INFO);
					continue;
                } else {
                    Log.out("ModelInfoCache.requestType REJECTING null object: ", Log.WARN);
                    continue;
                }
            }
        }
    }
	
	static private function request( $mie:ModelInfoEvent ):void {
		if ( null == $mie || null == $mie.modelGuid ) { // Validator
			Log.out( "ModelInfoCache.request requested event or guid is NULL: ", Log.ERROR );
			ModelInfoEvent.create( ModelBaseEvent.EXISTS_ERROR, ( $mie ? $mie.series: -1 ), "MISSING", null );
		} else {
			//Log.out( "ModelInfoCache.modelInfoRequest guid: " + $mie.modelGuid, Log.INFO );
			var mi:ModelInfo = _modelInfo[$mie.modelGuid];
			if (null == mi) {
				if (_block.has($mie.modelGuid))
					return;
				_block.add($mie.modelGuid);

				if (true == Globals.online && $mie.fromTables)
					PersistenceEvent.create( PersistenceEvent.LOAD_REQUEST, $mie.series, ModelInfo.BIGDB_TABLE_MODEL_INFO, $mie.modelGuid );
				else
					PersistenceEvent.create( PersistenceEvent.LOAD_REQUEST, $mie.series, ModelInfo.MODEL_INFO_EXT, $mie.modelGuid );
			}
			else {
				if ($mie)
					ModelInfoEvent.create( ModelBaseEvent.RESULT, $mie.series, $mie.modelGuid, mi);
				else
					Log.out("ModelInfoCache.request ModelInfoEvent is NULL: ", Log.WARN);
			}
		}
	}

    static private function reassignToStore( $mie:ModelInfoEvent ):void {
        var mi:ModelInfo = _modelInfo[$mie.modelGuid];
        if ( mi ) {
            mi.owner = Network.storeId;
            mi.save();
        }
    }

    static private function reassignToPublic( $mie:ModelInfoEvent ):void {
        var mi:ModelInfo = _modelInfo[$mie.modelGuid];
        if ( mi ) {
            mi.owner = Network.PUBLIC;
            mi.save();
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
			mi.release();
			_modelInfo[$mie.modelGuid] = null; 
			// TODO need to clean up eventually
			mi = null;
			PersistenceEvent.create( PersistenceEvent.DELETE_REQUEST, $mie.series, ModelInfo.BIGDB_TABLE_MODEL_INFO, $mie.modelGuid, null );
			InventoryEvent.create( InventoryEvent.DELETE, $mie.modelGuid, null );
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
			Log.out( "ModelInfoCache.deleteRecursive - ModelInfo not found $mie" + $mie, Log.ERROR );
		
		// Now delete the parents oxelPersistence
		OxelDataEvent.create( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null );
		ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null );
	}

    static private function generationComplete( $mie:ModelInfoEvent ):void  {
		add( 0, $mie.modelInfo );
	}

	static private function update($mie:ModelInfoEvent):void {
		if ( null == $mie || null == $mie.modelGuid ) { // Validator
			Log.out("ModelInfoCache.update - event or guid is NULL: ", Log.ERROR);
			ModelInfoEvent.create(ModelBaseEvent.EXISTS_ERROR, ( $mie ? $mie.series : -1 ), "MISSING", null);
		} else {
			var mi:ModelInfo = _modelInfo[$mie.modelGuid];
			if ( null ==  mi ) {
				Log.out( "ModelInfoCache.update trying update NULL metadata or guid, adding instead", Log.WARN );
				add( 0, $mie.modelInfo );
			} else {
				_modelInfo[$mie.modelGuid] = $mie.modelInfo;
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
		}
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
		// check to make sure is not already there
		if ( null ==  _modelInfo[$mi.guid] ) {
			//Log.out( "ModelInfoCache.add modelInfo: " + $mi.toString(), Log.DEBUG );
			_modelInfo[$mi.guid] = $mi;
			if ( $series == _currentSeries )
                ModelInfoEvent.create( ModelBaseEvent.RESULT_RANGE, $series, $mi.guid, $mi );
			else
				ModelInfoEvent.create( ModelBaseEvent.RESULT, $series, $mi.guid, $mi );
		} else {
            Log.out( "ModelInfoCache.add - ModelInfo already exists", Log.ERROR );
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function loadSucceed( $pe:PersistenceEvent):void {
		if ( ModelInfo.BIGDB_TABLE_MODEL_INFO != $pe.table && ModelInfo.MODEL_INFO_EXT != $pe.table )
			return;

		var mi:ModelInfo = _modelInfo[$pe.guid];
		if ( null != mi ) {
			// we already have it, publishing this results in duplicate items being sent to inventory window.
            if ( $pe.series == _currentSeries )
                ModelInfoEvent.create( ModelBaseEvent.RESULT_RANGE, $pe.series, $pe.guid, mi );
            else
                ModelInfoEvent.create( ModelBaseEvent.RESULT, $pe.series, $pe.guid, mi );
			Log.out( "ModelInfoCache.loadSucceed - attempting to load duplicate ModelInfo guid: " + $pe.guid, Log.WARN );
			return;
		}

		if ( $pe.dbo ) {
			mi = new ModelInfo( $pe.guid, $pe.dbo, null );
            mi.init();
			add( $pe.series, mi );
		} else if ( $pe.data ) {
			var fileData:String = String( $pe.data );
			fileData = StringUtils.trim(fileData);
			var newObjData:Object = JSONUtil.parse( fileData, $pe.guid + $pe.table, "ModelInfoCache.loadSucceed" );
			if ( null == newObjData ) {
				Log.out( "ModelInfoCache.loadSucceed - error parsing modelInfo on import. guid: " + $pe.guid, Log.ERROR );
				ModelInfoEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null );
				return;
			}
            if ( newObjData.model ) {
				mi = new ModelInfo($pe.guid, null, newObjData.model);
				mi.init();
				Log.out( "ModelInfoCache.loadSucceed - OLD MODEL FOUND IN INFO.", Log.WARN);
			}
            else {
                mi = new ModelInfo($pe.guid, null, newObjData);
                mi.init();
            }
			mi.save();

			add( $pe.series, mi );
			if ( _block.has( $pe.guid ) )
				_block.clear( $pe.guid )
		} else {
			ModelInfoEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null );
		}
	}

	static private function loadFailed( $pe:PersistenceEvent ):void {
		if ( ModelInfo.BIGDB_TABLE_MODEL_INFO != $pe.table && ModelInfo.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoCache.loadFailed PersistenceEvent: " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		ModelInfoEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void {
		if ( ModelInfo.BIGDB_TABLE_MODEL_INFO != $pe.table && ModelInfo.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoCache.loadNotFound PersistenceEvent: " + $pe.toString(), Log.WARN );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		ModelInfoEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistence Events
	/////////////////////////////////////////////////////////////////////////////////////////////

    static private var _vectorOfTreeModels:Vector.<ModelInfo> = null;
    static public function getRandomTree():ModelInfo {
        if ( null == _vectorOfTreeModels )
            _vectorOfTreeModels = getTrees();
        if ( 0 == _vectorOfTreeModels.length )
            return null;
        var index:int = int( Math.random() ) * _vectorOfTreeModels.length;
        var mmd:ModelInfo = _vectorOfTreeModels[index];
        return mmd;

        function getTrees():Vector.<ModelInfo> {
            var vectorOfTreeModels:Vector.<ModelInfo> = new Vector.<ModelInfo>();
            for each( var mmd:ModelInfo in _modelInfo ){
                if ( mmd && (0 <= mmd.hashTags.indexOf("tree")) ) {
                    vectorOfTreeModels.push(mmd);
                }
            }
            return vectorOfTreeModels;
        }
    }

}
}