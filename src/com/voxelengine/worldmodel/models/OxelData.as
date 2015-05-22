/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
/**
 * ...
 * @author Robert Flesch - RSF
 * OxelData is the byte level representation of the oxel
 */
public class OxelData extends PersistanceObject
{
	private var _compressedBA:ByteArray;
	
	public function OxelData( $guid:String ) {
		super( $guid, Globals.BIGDB_TABLE_OXEL_DATA );
	}

	public function get compressedBA():ByteArray  { return _compressedBA;  }
	public function set compressedBA( $ba:ByteArray ):void  { _compressedBA = $ba; }
	
	override public function clone():* {
		var vmd:OxelData = new OxelData( guid );
		vmd._dbo = dbo; // Can I just reference this? They are pointing to same object
		var ba:ByteArray = new ByteArray();
		ba.writeBytes( _compressedBA, 0, _compressedBA.length );
		vmd._compressedBA = ba;
		return vmd;
	}
	
	public function saveOxelData( ba:ByteArray ):void {
		if ( Globals.online ) {
			Log.out( "OxelData.save - Saving OxelData: " + guid ); // + " vmd: " + $vmd.toString(), Log.WARN );
			_compressedBA = ba;
			_compressedBA.compress();
			super.save();
		}
	}
	
	override protected function toPersistance():void {
		_dbo.ba			= _compressedBA;
	}
	
	override protected function toObject():Object {
		return { ba: _compressedBA }
	}

	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	override public function fromPersistance( $dbo:DatabaseObject ):void {
		_dbo			= $dbo;
		_compressedBA = $dbo.ba;
	}
	
}
}

