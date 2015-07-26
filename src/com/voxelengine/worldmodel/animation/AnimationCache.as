/*==============================================================================
Copyright 2011-2015 Robert Flesch
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
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.utils.StringUtils;

/**
 * ...
 * @author Bob
 */
public class AnimationCache
{
	// This should be a list so that it can be added to easily, this is hard coded.
	static public const MODEL_BIPEDAL_10:String = "MODEL_BIPEDAL_10";
	static public const MODEL_DRAGON_9:String =  "MODEL_DRAGON_9";
	static public const MODEL_PROPELLER:String =  "MODEL_PROPELLER";
	static public const MODEL_UNKNOWN:String =  "MODEL_UNKNOWN";
	
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _animatedModels:Array = new Array();
	
	public function AnimationCache() {}
	
	static public function init():void {
		AnimationEvent.addListener( ModelBaseEvent.REQUEST, 		request );
		AnimationEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler );
		AnimationEvent.addListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid );		

		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );		
	}
	
	static public function requestAnimationClass( $modelClass:String ):String {
		if ( $modelClass == "Dragon" )
			return MODEL_DRAGON_9;
		if ( $modelClass == "Avatar" )
			return MODEL_BIPEDAL_10;
		if ( $modelClass == "Player" )
			return MODEL_BIPEDAL_10;
		if ( $modelClass == "Propeller" )
			return MODEL_PROPELLER;
		
		return "";
	}

	static private function deleteHandler( $ae:AnimationEvent ):void {
		var modelAnis:Array = _animatedModels[$ae.modelGuid]; 
		var ani:Animation;
		if ( modelAnis ) {
			if ( modelAnis[$ae.aniGuid] );
				modelAnis[$ae.aniGuid] = null;
			// TODO need to clean up eventually
		}
		//else if its not in the cache, we can still delete it.
		PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_ANIMATIONS, $ae.aniGuid, null ) );
	}
	
	static private function updateGuid( $ae:AnimationEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $ae.aniGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var modelAnis:Array = _animatedModels[$ae.modelGuid]; 
		if ( null == modelAnis ) {
			Log.out( "AnimationCache.updateGuid - model not found: " + $ae.modelGuid, Log.ERROR );
			return; 
		}
		else {
			var ani:Animation = modelAnis[oldGuid];
			if ( ani ) {
				modelAnis[oldGuid] = null;
				modelAnis[newGuid] = ani;
			}
			else
				Log.out( "AnimationCache.updateGuid - animation not found oldGuid: " + oldGuid + "  newGuid: " + newGuid, Log.ERROR );
		}
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
		Log.out( "AnimationCache.request modelGuid: " + $ame.modelGuid + "  aniGuid: " + $ame.aniGuid, Log.INFO );
		var modelAnis:Array = _animatedModels[$ame.modelGuid]; 
		var ani:Animation;
		if ( modelAnis )
			ani = modelAnis[$ame.aniGuid];
		if ( null == ani ) {
			if ( true == Globals.online && $ame.fromTable )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $ame.series, Globals.BIGDB_TABLE_ANIMATIONS, $ame.aniGuid, null, null, URLLoaderDataFormat.TEXT, $ame.modelGuid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $ame.series, Globals.ANI_EXT, $ame.aniGuid, null, null, URLLoaderDataFormat.TEXT, $ame.modelGuid ) );
		}
		else
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.RESULT, $ame.series, $ame.modelGuid, $ame.aniGuid, ani ) );
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		if ( $pe.dbo || $pe.data ) {
			var ani:Animation = new Animation( $pe.guid );
			if ( $pe.dbo ) {
				ani.fromObject( $pe.dbo );
			}
			else {
				// This is for import from local only.
				var dbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_ANIMATIONS, "0", "0", 0, true, null );
				dbo.data = new Object();
				var fileData:String = String( $pe.data );
				fileData = StringUtils.trim(fileData);
				dbo.data = JSONUtil.parse( fileData, $pe.guid + $pe.table, "AnimationCache.loadSucceed" );
				if ( null == dbo.data ) {
					Log.out( "AnimationCache.loadSucceed - error parsing animation on import. guid: " + $pe.guid, Log.ERROR );
					AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
					return;
				}
				ani.fromObjectImport( dbo );
				// On import mark it as changed.
				ani.changed = true;
				ani.save();
			}
			add( $pe, ani );
			
//			if ( _block.has( $pe.guid ) )
//				_block.clear( $pe.guid )
				
		}
		else {
			Log.out( "AnimationCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR );
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
		}
	}
	
	
	
	static private function add( $pe:PersistanceEvent, $ani:Animation ):void 
	{ 
		if ( null == $ani || null == $pe.guid ) {
			Log.out( "AnimationCache.Add trying to add NULL animations or guid", Log.WARN );
			return;
		}
		// check to make sure this is new data
		var animationGuid:String = $ani.guid;
		var modelGuid:String = $ani.modelGuid;
		var modelAnimations:Array =  _animatedModels[modelGuid];
		if ( null ==  modelAnimations ) {
			// we need to create a new array for this model
			modelAnimations = new Array();
			_animatedModels[modelGuid] = modelAnimations;
		}
		
		// model already has a list of animations, check to make sure this one is not already in it.
		if ( null == modelAnimations[animationGuid] ) {
			modelAnimations[animationGuid] = $ani;
			// AnimationEvent( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $aniType:String, $ani:Animation, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.ADDED, $pe.series, $pe.other, $ani.guid, $ani ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		Log.out( "AnimationCache.loadFailed " + $pe.toString(), Log.ERROR );
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		Log.out( "AnimationCache.loadNotFound " + $pe.toString(), Log.ERROR );
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
	}
	
}
}