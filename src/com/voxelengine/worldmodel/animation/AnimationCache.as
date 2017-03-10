/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import flash.events.DataEvent;
import flash.utils.ByteArray;
import flash.net.URLLoaderDataFormat;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.utils.StringUtils;

/**
 * ...
 * @author Bob
 */
public class AnimationCache
{
	// This should be a list so that it can be added to easily, this is hard coded.
	static public const MODEL_BIPEDAL_10:String = "MODEL_BIPEDAL_10";
	static public const MODEL_DRAGON_12:String =  "MODEL_DRAGON_12";
	static public const MODEL_PROPELLER:String =  "MODEL_PROPELLER";
	static public const MODEL_UNKNOWN:String =  "MODEL_UNKNOWN";
	
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _animations:Array = new Array();
	
	public function AnimationCache() {}
	
	static public function init():void {
		AnimationEvent.addListener( ModelBaseEvent.REQUEST, 		request );
		AnimationEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler );
		AnimationEvent.addListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid );		
		AnimationEvent.addListener( ModelBaseEvent.SAVE, 			save );		

		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	static private function save(e:AnimationEvent):void {
		for each ( var ani:Animation in _animations )
			if ( ani )
				ani.save();
	}
	
	static public function requestAnimationClass( $modelClass:String ):String {
		if ( $modelClass == "Dragon" )
			return MODEL_DRAGON_12;
		if ( $modelClass == "Avatar" )
			return MODEL_BIPEDAL_10;
		if ( $modelClass == "Player" )
			return MODEL_BIPEDAL_10;
		if ( $modelClass == "Propeller" )
			return MODEL_PROPELLER;
		
		return "";
	}

	static private function deleteHandler( $ae:AnimationEvent ):void {
		var anim:Animation = _animations[$ae.aniGuid]
		if ( anim ) {
			_animations[$ae.aniGuid] = null;
			if ( anim.sound )
                PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_SOUNDS, anim.sound.guid, null ) );

		}
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_ANIMATIONS, $ae.aniGuid, null ) );
	}
	
	static private function updateGuid( $ae:AnimationEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $ae.aniGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var ani:Animation = _animations[oldGuid];
		if ( ani ) {
			_animations[oldGuid] = null;
			_animations[newGuid] = ani;
		}
		else
			_animations[newGuid] = ani;
//			Log.out( "AnimationCache.updateGuid - animation not found oldGuid: " + oldGuid + "  newGuid: " + newGuid, Log.ERROR );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  public function AnimationEvent( $type:String, $series:int, $modelGuid:String, , $aniGuid:String, $ani:Animation, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function request( $ame:AnimationEvent ):void 
	{   
		if ( null == $ame.modelGuid ) {
			Log.out( "AnimationCache.request guid rquested is NULL: ", Log.WARN );
			return;
		}
		//Log.out( "AnimationCache.request modelGuid: " + $ame.modelGuid + "  aniGuid: " + $ame.aniGuid, Log.INFO );
		var ani:Animation = _animations[$ame.modelGuid]; 
		if ( null == ani ) {
			if ( true == Globals.online && $ame.fromTable )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ame.series, Globals.BIGDB_TABLE_ANIMATIONS, $ame.aniGuid, null, null, URLLoaderDataFormat.TEXT, $ame.modelGuid ) );
			else	
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ame.series, Globals.ANI_EXT, $ame.aniGuid, null, null, URLLoaderDataFormat.TEXT, $ame.modelGuid ) );
		}
		else
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.RESULT, $ame.series, $ame.modelGuid, $ame.aniGuid, ani ) );
	}

	static private function loadSucceed( $pe:PersistenceEvent):void
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;

		var ani:Animation =  _animations[$pe.guid];
		if ( null != ani ) {
			// we already have it, publishing this results in dulicate items being sent to inventory window.
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.ADDED, $pe.series, $pe.other, $pe.guid, ani ) );
			Log.out( "AnimationCache.loadSucceed - attempting to load duplicate AnimationC guid: " + $pe.guid, Log.WARN );
			return;
		}

		if ( $pe.dbo ) {
			ani = new Animation($pe.guid, $pe.dbo, null);
			add( $pe, ani );
		} else if ( $pe.data ) {
			var fileData:String = String( $pe.data );
			fileData = StringUtils.trim(fileData);
			var newObjData:Object = JSONUtil.parse( fileData, $pe.guid + $pe.table, "AnimationCache.loadSucceed" );
			if ( null == newObjData ) {
				Log.out( "AnimationCache.loadSucceed - error parsing animation info on import. guid: " + $pe.guid, Log.ERROR );
				AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.other, $pe.guid, null ) );
				return;
			}
			ani = new Animation($pe.guid, null, newObjData );
			ani.save();
			add( $pe, ani );
		} else {
			Log.out( "AnimationCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR );
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
		}
	}

	static private function add($pe:PersistenceEvent, $ani:Animation ):void
	{ 
		if ( null == $ani || null == $pe.guid ) {
			Log.out( "AnimationCache.Add trying to add NULL animations or guid", Log.WARN );
			return;
		}
		var ani:Animation =  _animations[$ani.guid];
		if ( null == ani ) {
			_animations[$ani.guid] = $ani;
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.ADDED, $pe.series, $pe.other, $ani.guid, $ani ) );
		}
	}
	
	static private function loadFailed( $pe:PersistenceEvent ):void
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		Log.out( "AnimationCache.loadFailed " + $pe.toString(), Log.ERROR );
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		Log.out( "AnimationCache.loadNotFound " + $pe.toString(), Log.ERROR );
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
	}
	
}
}