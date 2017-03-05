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
	public function get name():String				{ return dbo.name }
	public function get length():Number				{ return dbo.length }
	public function get hashTags():String			{ return dbo.hashTags }
	public function set hashTags( $val:String):void	{ dbo.hashTags = $val }
	
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
		if ( false == _loaded ) {
				//Log.out( "SoundPersistance.save - NOT Saving INVALID GUID: " + guid  + " in table: " + table, Log.WARN )
			return;
		}
		super.save()
	}
	
	override protected function toObject():void {
		// Just leave the raw mp3 oxelPersistance alone
		//Log.out( "SoundPersistance.toObject size:" + dbo.oxelPersistance.ba.length, Log.WARN )
	}
	
					
	public function fromObject( $pe:PersistanceEvent ):void {
		dbo			= $pe.dbo;
//		info 		= $pe.dbo;

		sound.loadCompressedDataFromByteArray( dbo.ba, dbo.ba.length );
		loaded = true
	}

	public function fromObjectImport( $pe:PersistanceEvent ):void {
		assignNewDatabaseObject();
		sound.loadCompressedDataFromByteArray( $pe.data, $pe.data.length );
		// On import mark it as changed.
		loaded = true;
		dbo.name = $pe.guid;
		dbo.length = sound.length;
		guid = Globals.getUID(); // do this last so that the rest of the data is filled in
		save()
	}

	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
	}

}
}

