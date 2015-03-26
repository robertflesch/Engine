/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import com.voxelengine.utils.JSONUtil;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.net.URLLoaderDataFormat;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistanceEvent;

/**
 * ...
 * @author Bob
 */
public class AnimationCache
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _animatedModels:Array = new Array();
	
	public function AnimationCache() {}
	
	static public function init():void {
		AnimationEvent.addListener( ModelBaseEvent.REQUEST, request );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, 	loadFailed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_NOT_FOUND, 	loadNotFound );		
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
			if ( true == Globals.online && $ame.fromTables )
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $ame.series, Globals.DB_TABLE_ANIMATIONS, $ame.aniGuid ) );
			else	
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, $ame.series, Globals.ANI_EXT, $ame.aniGuid, null, null, URLLoaderDataFormat.TEXT, $ame.modelGuid ) );
		}
		else
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.RESULT, $ame.series, $ame.modelGuid, $ame.aniGuid, ani ) );
	}
	
	static private function loadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.DB_TABLE_ANIMATIONS != $pe.table )
			return;
		if ( $pe.dbo || $pe.data ) {
			Log.out( "AnimationCache.loadSucceed guid: " + $pe.guid, Log.INFO );
			var ani:Animation = new Animation();
			if ( $pe.dbo )
				ani.fromPersistance( $pe.dbo );
			else {
				var jsonResult:Object = JSONUtil.parse( $pe.data, $pe.guid + $pe.table, "AnimationCache.loadSucceed" );
				if ( null == jsonResult ) {
					//(new Alert( "VoxelVerse - Error Parsing: " + $pe.guid + $pe.table, 500 ) ).display();
					AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
					return;
				}
				ani.fromImport( jsonResult, $pe.guid, $pe.other );
				ani.save();
			}
				
			add( $pe, ani );
		}
		else {
			Log.out( "AnimationCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR );
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
		}
	}
	
	static private function add( $pe:PersistanceEvent, $ani:Animation ):void 
	{ 
		if ( null == $ani || null == $pe.guid ) {
			Log.out( "AnimationCache.modelDataAdd trying to add NULL modelData or guid", Log.WARN );
			return;
		}
		// check to make sure this is new data
		var animationGuid:String = $ani.metadata.guid;
		var modelGuid:String = $ani.metadata.modelGuid;
		var modelAnimations:Array =  _animatedModels[modelGuid];
		if ( null ==  modelAnimations ) {
			// we need to create a new array for this model
			modelAnimations = new Array();
			_animatedModels[modelGuid] = modelAnimations;
		}
		
		// model already has a list of animations, check to make sure this one is not already in it.
		if ( null == modelAnimations[animationGuid] ) {
			modelAnimations[animationGuid] = $ani;
			AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.ADDED, $pe.series, $pe.guid, $pe.data, $ani ) );
		}
	}
	
	static private function loadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.DB_TABLE_ANIMATIONS != $pe.table )
			return;
		Log.out( "AnimationCache.loadFailed " + $pe.toString(), Log.ERROR );
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
	}
	
	static private function loadNotFound( $pe:PersistanceEvent):void 
	{
		if ( Globals.ANI_EXT != $pe.table && Globals.DB_TABLE_ANIMATIONS != $pe.table )
			return;
		Log.out( "AnimationCache.loadNotFound " + $pe.toString(), Log.ERROR );
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null ) );
	}
	
}
}