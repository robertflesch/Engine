/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{
import com.voxelengine.worldmodel.animation.SoundPersistence;
import com.voxelengine.worldmodel.models.Block;
import flash.events.Event
import flash.events.IOErrorEvent
import flash.media.Sound
import flash.media.SoundTransform
import flash.net.URLRequest
import flash.utils.Dictionary
import flash.net.URLLoaderDataFormat

import playerio.DatabaseObject;

import com.voxelengine.Globals
import com.voxelengine.Log
import com.voxelengine.utils.MP3Pitch
import com.voxelengine.events.ModelBaseEvent
import com.voxelengine.events.PersistenceEvent
import com.voxelengine.events.SoundEvent
import com.voxelengine.worldmodel.animation.AnimationSound

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class SoundCache 
{
	static private var _sounds:Dictionary = new Dictionary(true)
	static private var _soundsByName:Dictionary = new Dictionary(true)
	static private var _block:Block = new Block();
	
	static public function init():void {
		SoundEvent.addListener( ModelBaseEvent.REQUEST, 		request )
		SoundEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler )
		//SoundEvent.addListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid )		
		//SoundEvent.addListener( ModelBaseEvent.SAVE, 			save )		

		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed )
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed )
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound )
	}
	
	static private function request( $se:SoundEvent ):void {   
		if ( null == $se.guid ) {
			Log.out( "SoundCache.request guid requested is NULL: ", Log.WARN )
			return
		}
		//Log.out( "SoundCache.request guid: " + $se.guid, Log.INFO )
		var snd:SoundPersistence
		if ( Globals.isGuid( $se.guid ) )
			snd = _sounds[$se.guid]
		else
			snd = _soundsByName[$se.guid]
			
		if ( null == snd ) {
			if ( _block.has( $se.guid ) ) {
				//Log.out( "SoundCache.request blocking on : " + $se.guid, Log.WARN )
				return;
			}
			//Log.out( "SoundCache.request add block on : " + $se.guid, Log.WARN )
			_block.add( $se.guid );
			
			if ( true == Globals.online && $se.fromTables )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $se.series, Globals.BIGDB_TABLE_SOUNDS, $se.guid, null, null, URLLoaderDataFormat.BINARY, $se.guid ) )
			else	
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $se.series, Globals.SOUND_EXT, $se.guid, null, null, URLLoaderDataFormat.BINARY, $se.guid ) )
		}
		else
			SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.RESULT, $se.series, $se.guid, snd ) )
	}
	
	static private function loadSucceed( $pe:PersistenceEvent ):void {
		if ( Globals.SOUND_EXT != $pe.table && Globals.BIGDB_TABLE_SOUNDS != $pe.table )
			return
			// dbo is loading from table, data if loading from import
		if ( $pe.dbo || $pe.data ) {
			var sndPer:SoundPersistence = new SoundPersistence( $pe.guid )
			if ( null == sndPer ) {
				Log.out( "SoundCache.loadSucceed - SoundPersistence error on creation: " + $pe.guid, Log.ERROR )
				return
			}
			if ( $pe.dbo ) {
				sndPer.fromObject( $pe )
			}
			else {
				// This is for import from local only.
				sndPer.fromObjectImport( $pe )
			}
			add( $pe, sndPer )
			
			if ( _block.has( $pe.guid ) )
				_block.clear( $pe.guid )
				
		}
		else {
			Log.out( "SoundCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR )
			SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid ) )
		}
	}
	
	static private function add($pe:PersistenceEvent, $sp:SoundPersistence ):void {
		if ( null == $sp || null == $pe.guid ) {
			Log.out( "SoundCache.Add trying to add NULL AnimationSounds or guid", Log.WARN )
			return
		}
		//Log.out( "SoundCache.Add adding: sp.guid: " + $sp.guid + "  sp.info.name: " +  $sp.info.name, Log.WARN )
		if ( null == _sounds[$sp.guid] )
			_sounds[$sp.guid] = $sp
		
		if ( null == _soundsByName[$sp.dbo.name] )
			_soundsByName[$sp.dbo.name] = $sp
			
		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.ADDED, $pe.series, $pe.guid, $sp ) )
	}
	
	static private function loadFailed( $pe:PersistenceEvent ):void {
		if ( Globals.SOUND_EXT != $pe.table && Globals.BIGDB_TABLE_SOUNDS != $pe.table )
			return
		Log.out( "SoundCache.loadFailed " + $pe.toString(), Log.ERROR )
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid ) )
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void {
		if ( Globals.SOUND_EXT != $pe.table && Globals.BIGDB_TABLE_SOUNDS != $pe.table )
			return
		Log.out( "SoundCache.loadNotFound " + $pe.toString(), Log.ERROR )
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid )
		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.guid ) )
	}
	
	
	static private function deleteHandler( $ae:SoundEvent ):void {
		if ( _sounds[$ae.guid] ) 
			_sounds[$ae.guid] = null
		PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.DELETE_REQUEST, 0, Globals.BIGDB_TABLE_SOUNDS, $ae.guid, null ) )
	}
	
	//static private function updateGuid( $ae:SoundEvent ):void {
		//// Make sure this is saved correctly
		//var guidArray:Array = $ae.guid.split( ":" )
		//var oldGuid:String = guidArray[0]
		//var newGuid:String = guidArray[1]
		//var snd:AnimationSound = _sounds[$ae.guid] 
		//if ( snd ) {
			//_sounds[oldGuid] = null
			//_sounds[newGuid] = snd
		//}
		//else
			//Log.out( "SoundCache.updateGuid - animationSound not found oldGuid: " + oldGuid + "  newGuid: " + newGuid, Log.ERROR )
	//}
	
	//static private function save(e:SoundEvent):void {
		//for each ( var snd:SoundPersistence in _sounds )
			//if ( snd )
				//snd.save()
	//}
/*
	static public function getSound( soundName:String ):Sound {
		var snd:Sound = _sounds[ soundName ]
		if ( snd )
			return snd
			
		var isLoading:Boolean = _soundsLoading[ soundName ]
		if ( true == isLoading )
			return null

		// its not loading, and its not in bank, load it!
		loadSound( soundName )
		
		return null
	}
	
	
	////////////////////////////////
	// old loading
	/////////////////////////////////
	
	// Need to use different loader here then customLoader since this is a static class. So 
	// I cant keep a reference to the loader around.
	static private function loadSound( soundName:String ):void 
	{
		var snd:Sound = new Sound()
		//Log.out( "SoundBank.loadSound - loading: " + Globals.appPath + soundName, Log.WARN )
		
		//Log.out("SoundBank.loadSound: " + Globals.soundPath + soundName )
		snd.load( new URLRequest( Globals.soundPath + soundName ) )
		snd.addEventListener(Event.COMPLETE, onSoundLoadComplete, false, 0, true)
		snd.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError)
		
		_soundsLoading[soundName] = true
		_sounds[soundName] = snd
	}

	
	static public function onSoundLoadComplete (event:Event):void 
	{
		var fileNameAndPath:String = event.target.url
		//Log.out( "SoundBank.onSoundLoadComplete: " + fileNameAndPath, Log.WARN )		
		var soundName:String = removeGlobalAppPath(fileNameAndPath)
		_soundsLoading[soundName] = false

		//Log.out("SoundBank.onSoundLoadComplete: " + Globals.soundPath + soundName )
		function removeGlobalAppPath( completePath:String ):String 
		{
			var lastIndex:int = completePath.lastIndexOf( Globals.soundPath )
			var fileName:String = completePath
			if ( -1 != lastIndex )
				fileName = completePath.substr( Globals.soundPath.length )
				
			return fileName	
		}
	}			
	
	static private function onFileLoadError(event:IOErrorEvent):void
	{
		Log.out("----------------------------------------------------------------------------------" )
		Log.out("SoundBank.onFileLoadError - FILE LOAD ERROR, DIDNT FIND: " + event.target.url, Log.ERROR )
		Log.out("----------------------------------------------------------------------------------" )
	}	
	*/
	//////////////////////////////////////////////////////////////////////////////
	
	static public function playSound( $guid:String ):void {
		var snd:SoundPersistence = _sounds[ $guid ]
		if ( !snd ) {
			SoundEvent.addListener( ModelBaseEvent.ADDED, addSoundAndPlay )
			SoundEvent.addListener( ModelBaseEvent.RESULT, addSoundAndPlay )
			SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST, 0, $guid, null, Globals.isGuid( $guid ) ? true : false ) )
			return
		}
		
		playSoundInternal( snd )
	}
	
	static private function addSoundAndPlay( $se:SoundEvent ):void {
		playSoundInternal( $se.snd );
	}
	
	static private function playSoundInternal( $snd:SoundPersistence ):void {
	
		// playSound( snd:Sound, $startTime:Number = 0, $loops:int = 0, $sndTransform:SoundTransform = null) : flash.media.SoundChannel
		if ( $snd && !Globals.muted && $snd.sound )
			//return $snd.play( $startTime, $loops, $sndTransform )
			$snd.sound.play( 0, 1, null )
	}
}
}
