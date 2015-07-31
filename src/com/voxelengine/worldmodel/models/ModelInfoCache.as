/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.InventoryEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.models.makers.ModelDestroyer;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import flash.utils.Dictionary;
import playerio.DatabaseObject;

import com.voxelengine.utils.StringUtils;

import com.voxelengine.Log;
import com.voxelengine.Globals;

import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.utils.JSONUtil;

/**
 * ...
 * @author Bob
 */
public class ModelInfoCache
{
	// this only loaded ModelInfo from the local files system.
	// for the online system this information is embedded in the data segment.
	static private var _modelInfo:Dictionary = new Dictionary(false);
	static private var _block:Block = new Block();
	
	public function ModelInfoCache() {}
	
	static public function init():void {
		ModelInfoEvent.addListener( ModelBaseEvent.REQUEST, 			request );
		ModelInfoEvent.addListener( ModelBaseEvent.DELETE, 				deleteHandler );
		ModelInfoEvent.addListener( ModelBaseEvent.GENERATION, 			generated );
		ModelInfoEvent.addListener( ModelBaseEvent.SAVE, 				save );
		ModelInfoEvent.addListener( ModelInfoEvent.DELETE_RECURSIVE, 	deleteRecursive );
		ModelInfoEvent.addListener( ModelBaseEvent.UPDATE_GUID, 		updateGuid );		
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	static private function save(e:ModelInfoEvent):void {
		for each ( var modelInfo:ModelInfo in _modelInfo )
			if ( modelInfo )
				modelInfo.save();
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  ModelInfoEvent
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function request( $mie:ModelInfoEvent ):void {   
		if ( null == $mie.modelGuid ) {
			Log.out( "ModelInfoCache.request requested guid is NULL: ", Log.WARN );
			return;
		}
		
		//Log.out( "ModelInfoCache.modelInfoRequest guid: " + $mie.modelGuid, Log.INFO );
		var mi:ModelInfo = _modelInfo[$mie.modelGuid]; 
		if ( null == mi ) {
			if ( _block.has( $mie.modelGuid ) )
				return;
			else
				_block.add( $mie.modelGuid );
				
			if ( true == Globals.online && $mie.fromTables )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mie.series, Globals.BIGDB_TABLE_MODEL_INFO, $mie.modelGuid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $mie.series, Globals.MODEL_INFO_EXT, $mie.modelGuid ) );
		}
		else
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.RESULT, $mie.series, $mie.modelGuid, mi ) );
	}
	
	static private function deleteHandler( $mie:ModelInfoEvent ):void {
		var mi:ModelInfo = _modelInfo[$mie.modelGuid]; 
		if ( null != mi ) {
			_modelInfo[$mie.modelGuid] = null; 
			// TODO need to clean up eventually
			mi = null;
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, $mie.series, Globals.BIGDB_TABLE_MODEL_INFO, $mie.modelGuid, null ) );
			InventoryEvent.dispatch( new InventoryEvent( InventoryEvent.DELETE, $mie.modelGuid, null ) );
		}
	}
	
	// TODO NOTE: This doesnt not work the first time the object is imported - why?
	// You have to close app and restart to get guids correct.
	static private function deleteRecursive( $mie:ModelInfoEvent ):void {
		// first delete any children
		// Should always be an entry in the modelInfo table, since a request for it went out first.
		// And this was called only after the request returned.
		var mi:ModelInfo = _modelInfo[$mie.modelGuid]; 
		if ( mi ) {
			for each ( var childii:Object in mi.info.model.children ) {
				if ( childii && childii.modelGuid ) {
					// Using the fromTables to handle the recursive flag
					new ModelDestroyer( childii.modelGuid, $mie.fromTables );		
				}
			}
		} else 
			Log.out( "ModelInfoCache.deleteRecursive - ModelInfo not found $mie" + $mie, Log.ERROR )
		
		// Now delete the parents data
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null ) );
		OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null ) );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.DELETE, 0, $mie.modelGuid, null ) );
	}
	
	
	
	static private function generated( $mie:ModelInfoEvent ):void  {
		add( 0, $mie.vmi );
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  ModelInfoEvent
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Persistance Events
	/////////////////////////////////////////////////////////////////////////////////////////////
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
	
	static private function loadSucceed( $pe:PersistanceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_INFO != $pe.table && Globals.MODEL_INFO_EXT != $pe.table )
			return;
		//Log.out( "ModelInfoCache.modelInfoLoadSucceed guid: " + $pe.guid, Log.INFO );
		// $pe.dbo is valid for loading from persistance, $pe.data is valid on imports
		if ( $pe.dbo || $pe.data ) {
			// need to check we don't have this info already
			var mi:ModelInfo = _modelInfo[$pe.guid]; 
			if ( null == mi ) {
				mi = new ModelInfo( $pe.guid );
				if ( $pe.dbo )
					mi.fromObject( $pe.dbo );
				else {
					var dbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_MODEL_INFO, "0", "0", 0, true, null );
					dbo.data = new Object();
					// This is for import from local only.
					var fileData:String = String( $pe.data );
					fileData = StringUtils.trim(fileData);
					dbo.data = JSONUtil.parse( fileData, $pe.guid + $pe.table, "ModelInfoCache.loadSucceed" );
					if ( null == dbo.data ) {
						Log.out( "ModelInfoCache.loadSucceed - error parsing modelInfo on import. guid: " + $pe.guid, Log.ERROR );
						ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
						return;
					}
					mi.fromObjectImport( dbo );
					// On import save it.
					mi.save();
				}
				
				add( $pe.series, mi );
				if ( _block.has( $pe.guid ) )
					_block.clear( $pe.guid )
			}
			else {
				ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.ADDED, $pe.series, $pe.guid, mi ) );
				Log.out( "ModelInfoCache.loadSucceed - attempting to add duplicate ModelInfo guid: " + $pe.guid, Log.WARN );
			}
		}
		else {
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, null, null ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void {
		if ( Globals.BIGDB_TABLE_MODEL_INFO != $pe.table && Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoCache.loadFailed PersistanceEvent: " + $pe.toString(), Log.ERROR );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void {
		if ( Globals.BIGDB_TABLE_MODEL_INFO != $pe.table && Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoCache.loadNotFound PersistanceEvent: " + $pe.toString(), Log.ERROR );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid, null ) );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End - Persistance Events
	/////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Internal Methods
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function add( $series:int, $mi:ModelInfo ):void { 
		if ( null == $mi || null == $mi.guid ) {
			Log.out( "ModelInfoCache.add trying to add NULL modelInfo or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _modelInfo[$mi.guid] ) {
			Log.out( "ModelInfoCache.add modelInfo: " + $mi.toString(), Log.DEBUG );
			_modelInfo[$mi.guid] = $mi; 
			
			if ( _block.has( $mi.guid ) )
				_block.clear( $mi.guid )
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.ADDED, $series, $mi.guid, $mi ) );
		}
	}
}
}