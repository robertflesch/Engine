/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelDataEvent;
import com.voxelengine.events.PersistanceEvent;
import flash.utils.ByteArray;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class ModelData
{
	private var _modelGuid:String;
	private var _dbo:DatabaseObject;
	private var _ba:ByteArray;
	
	public function ModelData( $guid:String ) {
		_modelGuid = $guid;
		if ( "EditCursor" != $guid )
			ModelDataEvent.addListener( ModelBaseEvent.SAVE, saveEvent );
	}

	public function release():void {
		ModelDataEvent.removeListener( ModelBaseEvent.SAVE, saveEvent );
	}
	
	public function get modelGuid():String  { return _modelGuid; }
	public function set modelGuid(value:String):void { _modelGuid = value; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function get ba():ByteArray  { return _ba;  }
	public function set ba( $ba:ByteArray ):void  { _ba = $ba; }
	
	
	// This was private, force a message to be sent to it. 
	// But the voxelModel has a handle to it, seems silly to have to propgate it every where, so its public
	private function saveEvent( $mde:ModelDataEvent ):void {
		if ( modelGuid != $mde.modelGuid ) {
			Log.out( "ModelData.saveEvent - Ignoring save meant for other model my guid: " + modelGuid + " target guid: " + $mde.modelGuid, Log.WARN );
			return;
		}
		save( _ba );
	}
	
	public function save( $ba:ByteArray ):void {
		_ba = $ba;
		if ( Globals.online ) {
			Log.out( "ModelData.save - Saving Model Metadata: " + modelGuid ); // + " vmd: " + $vmd.toString(), Log.WARN );
			addSaveEvents();
			if ( _dbo )
				toPersistance();
			else {
				var obj:Object = toObject();
			}
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.DB_TABLE_MODELS_DATA, modelGuid, _dbo, obj ) );
		}
		else
			Log.out( "ModelData.save - Not saving data, either offline or NOT changed or locked - guid: " + modelGuid, Log.WARN );
	}
	
	private function addSaveEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, 	saveFail );
	}
	
	private function removeSaveEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, 		saveFail );
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "ModelData.saveSucceed - save: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		if ( $pe.dbo )
			_dbo = $pe.dbo;
		removeSaveEvents();
		Log.out( "ModelData.createSuccess - created: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_MODELS_DATA != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "ModelData.saveFail - ", Log.ERROR ); 
	}	
	
	public function toPersistance():void {
		var ba:ByteArray = _ba;
		try {  ba.compress(); }
		catch (error:Error) { ; }
		_dbo.ba			= ba;
	}
	
	private function toObject():Object {
		var ba:ByteArray = _ba;
		try {  ba.compress(); }
		catch (error:Error) { ; }
		return { ba: ba }
	}

	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistance( $dbo:DatabaseObject ):void {
		_dbo			= $dbo;
		
		var ba:ByteArray = $dbo.ba;
		try {  ba.uncompress(); }
		catch (error:Error) { ; }
		ba.position = 0;
		_ba = ba;
	}
	
}
}

