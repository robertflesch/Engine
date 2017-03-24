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
import com.voxelengine.events.PersistenceEvent
import com.voxelengine.worldmodel.models.PersistenceObject
import com.voxelengine.events.SoundEvent
import com.voxelengine.events.ModelBaseEvent


/**
 * ...
 * @author Robert Flesch - RSF
 * SoundPersistence is the persistance wrapper for the sound data.
 */
public class SoundPersistence extends PersistenceObject
{
	private var _sound:Sound = new Sound();

	public function get sound():Sound 				{ return _sound }
	public function get name():String				{ return dbo.name }
	public function get length():Number				{ return dbo.length }
	public function get hashTags():String			{ return dbo.hashTags }
	public function set hashTags( $val:String):void	{ dbo.hashTags = $val }

	public function SoundPersistence( $guid:String, $dbo:DatabaseObject, $newData:Object ):void  {
		super( $guid, Globals.BIGDB_TABLE_SOUNDS );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else {
			dbo = $dbo;
		}

		init( $newData );

	}

	public function init( $newData:Object ):void {
		if ( $newData )
			dbo.ba = $newData;

		sound.loadCompressedDataFromByteArray( dbo.ba, dbo.ba.length );
		dbo.length = sound.length;
	}

	override public function set guid( $newGuid:String ):void { 
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		SoundEvent.create( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, this );
		changed = true
	}
}
}

