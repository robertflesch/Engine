/*==============================================================================
Copyright 2011-2013 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Permissions;
import flash.events.Event;
import flash.utils.ByteArray;
import playerio.DatabaseObject;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class AnimationMetadata
{
	static private const INVALID:String = "INVALID"
	private var _name:String 		= INVALID;
	private var _guid:String 		= INVALID;
	private var _description:String = INVALID;
	private var _owner:String 		= INVALID;
	private var _dbo:DatabaseObject;
	private var _modelClass:String 	= Animation.MODEL_UNKNOWN;
	private var _world:String		= Globals.VOXELVERSE;
	private var _modelGuid:String;
	private var _modifiedDate:Date;
	private var _permissions:Permissions = new Permissions();

	////////////
	public function get name():String { return _name; }
	public function get guid():String { return _guid; }
	public function set guid( $val:String):void { _guid = $val; }
	public function get modelGuid():String { return _modelGuid; }
	public function set modelGuid( $val:String):void { _modelGuid = $val; }
	public function get description():String { return _description; }
	public function get owner():String { return _owner; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function set dbo( $dbo:DatabaseObject ):void { _dbo = $dbo; }

	public function AnimationMetadata() {
	}
	
	public function fromImport( $guid:String, $modelGuid:String ):void {
		_name = $guid;
		_description = $guid + " - IMPORTED";
		guid = Globals.getUID();
		_owner = Network.userId;
		if ( "Dragon" == $modelGuid )
			_modelClass = Animation.MODEL_DRAGON_9;
		else if ( "Player" == $modelGuid )
			_modelClass	= Animation.MODEL_BIPEDAL_10;
		else if ( "Propeller" == $modelGuid )
			_modelClass	= Animation.MODEL_PROPELLER;
		
		//	Do I want model NAME or GUID?
		_modelGuid = $modelGuid;
		_modifiedDate = new Date();
	}

	public function save( $ba:ByteArray ):void {
		if ( Globals.online ) {
			Log.out( "Animation.save - Saving Animation Metadata guid: " + _guid + "  modelGuid: " + _modelGuid ); // + " vmd: " + $vmd.toString(), Log.WARN );
			addSaveEvents();
			if ( _dbo )
				toPersistance( $ba );
			else {
				var obj:Object = toObject( $ba );
			}
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.DB_TABLE_ANIMATIONS, _guid, _dbo, obj ) );
		}
		else
			Log.out( "ModelMetadata.save - Not saving metadata, either offline or NOT changed or locked - guid: " + modelGuid + "  name: " + name, Log.WARN );
	}
	
	//////////////////////////////////////////////////////////////////
	// TO Persistance
	//////////////////////////////////////////////////////////////////
	
	public function toObject( $ba:ByteArray ):Object {
		
		try {  $ba.compress(); }
		catch (error:Error) { ; }

		var metadataObj:Object =   { name: 			_name
								   , description: 	_description
								   , owner: 		_owner
								   , modifiedDate: 	_modifiedDate
								   , modelClass:	 _modelClass
								   , modelGuid: 	_modelGuid
								   , world: 		_world
								   , data: 			$ba }
		metadataObj = _permissions.addToObject( metadataObj );
		return metadataObj;						   
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
		if ( Globals.DB_TABLE_ANIMATIONS != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "AnimationMetadata.saveSucceed - created: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_ANIMATIONS != $pe.table )
			return;
		if ( $pe.dbo )
			_dbo = $pe.dbo;
		removeSaveEvents();
		Log.out( "AnimationMetadata.createSuccess - created: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_ANIMATIONS != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "AnimationMetadata.saveFail - ", Log.ERROR ); 
	}	

	public function toPersistance( $ba:ByteArray ):void {
		try { $ba.compress(); }
		catch (error:Error) { ; }
		
		_dbo.name 			= _name;
		_dbo.description	= _description;
		_dbo.owner			= _owner;
		_dbo.modifiedDate   = new Date();
		_dbo.modelClass 	= _modelClass;
		_dbo.modelGuid		= _modelGuid;
		_dbo.world			= _world;
		_dbo.data			= $ba;
		_permissions.dboSetInfo( _dbo );
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistance( $dbo:DatabaseObject ):ByteArray {
		
		_name 			= $dbo.name;
		_description	= $dbo.description;
		_owner			= $dbo.owner;
		_modifiedDate   = $dbo.modifiedDate;
		_modelGuid 		= $dbo.key;
		_modelClass		= $dbo.modelClass;
		_world			= $dbo.world;
		_dbo			= $dbo;
						
		_permissions.fromDbo( $dbo );
		
		var ba:ByteArray = $dbo.data;
		try { ba.uncompress(); }
		catch (error:Error) { ; }
		return ba;
	}	
}
}
