/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import flash.utils.Dictionary
import flash.net.URLLoaderDataFormat

import com.voxelengine.Log
import com.voxelengine.Globals

import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.PersistenceEvent
import com.voxelengine.events.SoundEvent
import com.voxelengine.worldmodel.animation.AnimationSound;
import com.voxelengine.worldmodel.models.Block;

public class SoundCache
{
	static private var _sounds:Dictionary = new Dictionary(true);
	static private var _block:Block = new Block();
	
	static public function init():void {
		SoundEvent.addListener( ModelBaseEvent.REQUEST, 		request );
		SoundEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler );
		SoundEvent.addListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid );
		SoundEvent.addListener( ModelBaseEvent.CLONE, 			clone );

		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	static private function request( $se:SoundEvent ):void {   
		if ( null == $se.guid ) {
			Log.out( "SoundCache.request guid requested is NULL: ", Log.WARN );
			return;
		}
		var snd:AnimationSound = _sounds[$se.guid];

		if ( null == snd ) {
			if ( _block.has( $se.guid ) ) {
				//Log.out( "SoundCache.request blocking on : " + $se.guid, Log.WARN )
				return;
			}
			//Log.out( "SoundCache.request add block on : " + $se.guid, Log.WARN )
			_block.add( $se.guid );

            Log.out( "SoundCache.request guid: " + $se.guid, Log.INFO );
			if ( true == Globals.online && $se.fromTables )
				PersistenceEvent.create( PersistenceEvent.LOAD_REQUEST, $se.series, AnimationSound.BIGDB_TABLE_SOUNDS, $se.guid, null, null, URLLoaderDataFormat.BINARY, $se.guid );
			else
				PersistenceEvent.create( PersistenceEvent.LOAD_REQUEST, $se.series, AnimationSound.SOUND_EXT, $se.guid, null, null, URLLoaderDataFormat.BINARY, $se.guid );
		}
		else
			SoundEvent.create( ModelBaseEvent.RESULT, $se.series, $se.guid, snd );
	}
	
	static private function loadSucceed( $pe:PersistenceEvent ):void {
		if ( AnimationSound.SOUND_EXT != $pe.table && AnimationSound.BIGDB_TABLE_SOUNDS != $pe.table )
			return;

		Log.out( "SoundCache.loadSucceed guid: " + $pe.guid, Log.INFO );

			// dbo is loading from table, data if loading from import
		if ( $pe.dbo || $pe.data ) {
			var sndPer:AnimationSound = new AnimationSound( $pe.guid, $pe.dbo, $pe.data );
			if ( _block.has( $pe.guid ) )
				_block.clear( $pe.guid );
			add( $pe, sndPer );
			if ( !Globals.isGuid( $pe.guid ) )
				sndPer.guid = Globals.getUID();
			sndPer.save();
		}
		else {
			Log.out( "SoundCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR );
			SoundEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid );
		}
	}

	static private function clone( $as:SoundEvent):void {
		var ani:AnimationSound =  _sounds[$as.guid];
		if ( null == ani ) {
			_sounds[$as.guid] = $as.snd;
			//SoundEvent.create( ModelBaseEvent.ADDED, $ae.series, $ae.modelGuid, $ae.aniGuid, $ae.ani );
		}
	}


	static private function add($pe:PersistenceEvent, $sp:AnimationSound ):void {
		if ( null == $sp || null == $pe.guid ) {
			Log.out( "SoundCache.Add trying to add NULL AnimationSounds or guid", Log.WARN );
			return
		}
		//Log.out( "SoundCache.Add adding: sp.guid: " + $sp.guid + "  sp.info.name: " +  $sp.info.name, Log.WARN )
		if ( null == _sounds[$sp.guid] )
			_sounds[$sp.guid] = $sp;
		
		SoundEvent.create( ModelBaseEvent.RESULT, $pe.series, $pe.guid, $sp );
	}
	
	static private function loadFailed( $pe:PersistenceEvent ):void {
		if ( AnimationSound.SOUND_EXT != $pe.table && AnimationSound.BIGDB_TABLE_SOUNDS != $pe.table )
			return;
		Log.out( "SoundCache.loadFailed " + $pe.toString(), Log.ERROR );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		SoundEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void {
		if ( AnimationSound.SOUND_EXT != $pe.table && AnimationSound.BIGDB_TABLE_SOUNDS != $pe.table )
			return;
		Log.out( "SoundCache.loadNotFound " + $pe.toString(), Log.ERROR );
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		SoundEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid );
	}

	static private function deleteHandler( $ae:SoundEvent ):void {
		if ( _sounds[$ae.guid] ) {
			Log.out("SoundCache.deleteHandler guid: " + $ae.guid, Log.WARN);
			_sounds[$ae.guid] = null;
		}
		// Delete regardless of whether or not is it already loaded.
		PersistenceEvent.create( PersistenceEvent.DELETE_REQUEST, 0, AnimationSound.BIGDB_TABLE_SOUNDS, $ae.guid, null );
	}
	
	static private function updateGuid( $ae:SoundEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $ae.guid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		var snd:AnimationSound = _sounds[oldGuid];
		if ( snd ) {
			_sounds[newGuid] = snd; // This leaves the old one, but it will only be there during import.
			SoundEvent.create( ModelBaseEvent.UPDATE_GUID_COMPLETE, 0, $ae.guid, snd );
		}
		else
			Log.out( "SoundCache.updateGuid - animationSound not found oldGuid: " + oldGuid + "  newGuid: " + newGuid, Log.WARN );

	}

	static public function playSound( $guid:String ):void {
		var snd:AnimationSound = _sounds[ $guid ];
		if ( !snd ) {
			SoundEvent.addListener( ModelBaseEvent.RESULT, addSoundAndPlay );
			SoundEvent.create( ModelBaseEvent.REQUEST, 0, $guid, null, Globals.isGuid( $guid ) );
			return;
		}
		
		playSoundInternal( snd )
	}
	
	static private function addSoundAndPlay( $se:SoundEvent ):void {
		SoundEvent.removeListener( ModelBaseEvent.RESULT, addSoundAndPlay );
		playSoundInternal( $se.snd );
	}
	
	static private function playSoundInternal( $snd:AnimationSound ):void {
	
		// playSound( snd:Sound, $startTime:Number = 0, $loops:int = 0, $sndTransform:SoundTransform = null) : flash.media.SoundChannel
		if ( $snd && !Globals.muted && $snd.sound )
			// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/SoundTransform.html
			// return $snd.play( $startTime, $loops, $sndTransform )
			$snd.sound.play( 0, 1, null )
	}
}
}
