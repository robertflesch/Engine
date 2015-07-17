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
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
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
	private var _dbo:DatabaseObject;
	private var _permissions:Permissions;
/*	private var _name:String 		= INVALID;
	private var _guid:String 		= INVALID;
	private var _aniType:String 	= INVALID;
	private var _description:String = INVALID;
	private var _owner:String 		= INVALID;
	private var _animationClass:String 	= AnimationCache.MODEL_UNKNOWN;
	private var _world:String		= Globals.VOXELVERSE;
	private var _modelGuid:String;
*/
	////////////
	public function get name():String { return _dbo.name; }
	public function get aniType():String { return _dbo.aniType; }
	public function get guid():String { return _dbo.key; }
//	public function set guid( $newGuid:String):void { _dbo.key = $newGuid; }
	public function get modelGuid():String { return _dbo.modelGuid; }
	public function set modelGuid( $val:String):void { _dbo.modelGuid = $val; }
	public function get animationClass():String { return _dbo.animationClass; }
	public function get description():String { return _dbo.description; }
	public function get owner():String { return _dbo.owner; }
	public function get dbo():DatabaseObject { return _dbo; }
	public function set dbo( $dbo:DatabaseObject ):void { _dbo = $dbo; }

	public function AnimationMetadata() {
	}
	
	public function fromImport( $guid:String, $aniType:String, $modelGuid:String ):void {
		//_name = $guid;
		//_aniType = $aniType;
		//_description = $guid + " - IMPORTED";
		//_guid = Globals.getUID();
		//_owner = Network.userId;
		//_modifiedDate = new Date();
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoResult );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, $modelGuid, null ) );
	}
	
	private function modelInfoResult(e:ModelInfoEvent):void {
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoResult );
		var modelClass:String = e.vmi.modelClass;
		_dbo.animationClass = AnimationCache.requestAnimationClass( modelClass );
	}

	public function save( $ba:ByteArray ):void {
		if ( Globals.online ) {
			//Log.out( "AnimationMetadata.save - Saving Animation Metadata guid: " + _guid + "  modelGuid: " + _modelGuid ); // + " vmd: " + $vmd.toString(), Log.WARN );
			addSaveEvents();
			toPersistance( $ba );
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.BIGDB_TABLE_ANIMATIONS, guid, _dbo, null ) );
		}
		else
			Log.out( "AnimationMetadata.save - Not saving metadata, either offline or NOT changed or locked - guid: " + modelGuid + "  name: " + name, Log.WARN );
	}
	
	//////////////////////////////////////////////////////////////////
	// TO Persistance
	//////////////////////////////////////////////////////////////////
	/*
	public function toObject( $ba:ByteArray ):Object {
		
		var metadataObj:Object =   { name: 			_name
								   , description: 	_description
								   , aniType: 		_aniType
								   , owner: 		_owner
								   , modifiedDate: 	_modifiedDate
								   , animationClass:	 _animationClass
								   , modelGuid: 	_modelGuid
								   , world: 		_world
								   , data: 			$ba }
		metadataObj = _permissions.addToObject( metadataObj );
		return metadataObj;						   
	}
	*/
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
		if ( Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "AnimationMetadata.saveSucceed - created: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		if ( $pe.dbo )
			_dbo = $pe.dbo;
		removeSaveEvents();
		//Log.out( "AnimationMetadata.createSuccess - created: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "AnimationMetadata.saveFail - ", Log.ERROR ); 
	}	

	public function toPersistance( $ba:ByteArray ):void {
		_dbo.data			= $ba;
		//_dbo.name 			= _name;
		//_dbo.description	= _description;
		//_dbo.aniType		= _aniType
		//_dbo.owner			= _owner;
		//_dbo.modifiedDate   = new Date();
		//_dbo.animationClass 	= _animationClass;
		//_dbo.modelGuid		= _modelGuid;
		//_dbo.world			= _world;
		//_permissions.toPersistance( _dbo );
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistance( $dbo:DatabaseObject ):ByteArray {
		
		_dbo			= $dbo;
		//_name 			= $dbo.name;
		//_description	= $dbo.description;
		//_aniType		= $dbo.aniType;
		//_owner			= $dbo.owner;
		//_modifiedDate   = $dbo.modifiedDate;
		//_modelGuid 		= $dbo.modelGuid;
		//_animationClass		= $dbo.animationClass;
		//_world			= $dbo.world;
		//_guid			= $dbo.key;
						
		if ( !$dbo.permissions )
			_dbo.permissions = new Object();
			
		_permissions = new Permissions( _dbo.permissions );
		
		var ba:ByteArray = $dbo.data;
		try { ba.uncompress(); }
		catch (error:Error) { ; }
		return ba;
	}	
}
}
