/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import flash.media.Sound

import playerio.DatabaseObject

import com.voxelengine.Log
import com.voxelengine.Globals
import com.voxelengine.events.PersistanceEvent
import com.voxelengine.worldmodel.models.PersistanceObject
import com.voxelengine.events.SoundEvent
import com.voxelengine.events.ModelBaseEvent


/**
 * ...
 * @author Robert Flesch - RSF
 * SoundPersistance is the persistance wrapper for the sound data.
 */
public class SoundPersistance extends PersistanceObject
{
	private var _sound:Sound = new Sound();
	private var _loaded:Boolean;
	
	public function get loaded():Boolean  			{ return _loaded }
	public function set loaded(value:Boolean):void  { _loaded = value }
	public function get sound():Sound 				{ return _sound }
	public function get name():String				{ return info.name }
	public function get length():Number				{ return info.length }
	public function get hashTags():String			{ return info.hashTags }
	public function set hashTags( $val:String):void	{ info.hashTags = $val }
	
	public function SoundPersistance( $guid:String ) {
		super( $guid, Globals.BIGDB_TABLE_SOUNDS );
		_loaded = false;
	}
	
	override public function set guid( $newGuid:String ):void { 
		var oldGuid:String = super.guid
		super.guid = $newGuid
		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, this ) )
		changed = true
	}
	
	override public function save():void {
		if ( false == _loaded || !Globals.isGuid( guid ) ) {
				//Log.out( "SoundPersistance.save - NOT Saving INVALID GUID: " + guid  + " in table: " + table, Log.WARN )
				return
		}
		super.save()
	}
	
	override protected function toObject():void {
		// Just leave the raw mp3 data alone
		//Log.out( "SoundPersistance.toObject size:" + dbo.data.ba.length, Log.WARN )
	}
	
					
	public function fromObject( $pe:PersistanceEvent ):void {
		dbo			= $pe.dbo;
		info 		= $pe.dbo;

		sound.loadCompressedDataFromByteArray( dbo.ba, dbo.ba.length );
		loaded = true
	}

	public function fromObjectImport( $pe:PersistanceEvent ):void {
		dbo = new DatabaseObject( Globals.BIGDB_TABLE_SOUNDS, "0", "0", 0, true, null );
		dbo.data = new Object();
		dbo.data.ba = $pe.data;
		sound.loadCompressedDataFromByteArray( dbo.data.ba, dbo.data.ba.length );
		// On import mark it as changed.
		loaded = true;
		changed = true;
		info = dbo.data;
		info.name = $pe.guid;
		info.length = sound.length;
		info.hashTags = "#dragon";
		guid = Globals.getUID(); // do this last so that the rest of the data is filled in
		save()
	}
}
}

