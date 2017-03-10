/*==============================================================================
Copyright 2011-2017 Robert Flesch
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
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.PermissionsBase;
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
	private var _permissions:PermissionsBase;
	private var _name:String 		= INVALID;
	private var _guid:String 		= INVALID;
	private var _aniType:String 	= INVALID;
	private var _description:String = INVALID;
	private var _owner:String 		= INVALID;
	private var _animationClass:String 	= AnimationCache.MODEL_UNKNOWN;
	private var _world:String		= Globals.VOXELVERSE;
	private var _modelGuid:String;

	protected var 	_info:Object;
	////////////

	public function AnimationMetadata() {
	}
	
	public function fromImport( $guid:String, $aniType:String, $modelGuid:String ):void {
		ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoResult );
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.REQUEST, 0, $modelGuid, null ) );
	}
	
	private function modelInfoResult(e:ModelInfoEvent):void {
		ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, modelInfoResult );
		var modelClass:String = e.vmi.modelClass;
		_info.animationClass = AnimationCache.requestAnimationClass( modelClass );
	}

	//////////////////////////////////////////////////////////////////
	// TO Persistence
	//////////////////////////////////////////////////////////////////

	public function toObject( $ba:ByteArray ):Object {

		var metadataObj:Object =   { name: 			_name
								   , description: 	_description
								   , aniType: 		_aniType
								   , owner: 		_owner
								   //, modifiedDate: 	_modifiedDate
								   , animationClass:	 _animationClass
								   , modelGuid: 	_modelGuid
								   , world: 		_world
								   , data: 			$ba }
		//metadataObj = _permissions.addToObject( metadataObj );
		return metadataObj;

	}
}
}
