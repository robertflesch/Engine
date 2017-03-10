/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons 
{
/**
 * ...
 * @author Bob
 */
import playerio.DatabaseObject;
import playerio.Message;

import org.flashapi.swing.Alert;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.SoundCache;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.SoundEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.PersistenceObject;

public class Ammo extends PersistenceObject
{
	private var saving:Boolean
	public function get name():String  				{ return dbo.name; }
	public function get type():int  				{ return dbo.type; }
	public function set type(val:int):void			{ dbo.type = val; }
	public function get count():int  				{ return dbo.count; }
	public function set count(val:int):void			{ dbo.count = val; }
	public function get grain():int 				{ return dbo.grain; }
	public function set grain(val:int):void 		{ dbo.grain = val; }
	public function get accuracy():Number 			{ return dbo.accuracy; }
	public function set accuracy(val:Number):void 	{ dbo.accuracy = val; }
	public function get velocity():Number 			{ return dbo.velocity; }
	public function set velocity(val:Number):void 	{ dbo.velocity = val; }
	public function get life():Number 				{ return dbo.life; }
	public function set life(val:Number):void 		{ dbo.life = val; }
	public function get launchSound():String  		{ return dbo.launchSound; }
	public function get impactSound():String  		{ return dbo.impactSound; }
	public function get contactScript():String  	{ return dbo.contactScript; }
	public function get model():String 				{ return dbo.model; }
	public function get oxelType():int 				{ return dbo.oxelType; }


	public function Ammo( $guid:String, $dbo:DatabaseObject, $newData:Object ) {
		super( $guid, Globals.BIGDB_TABLE_AMMO );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else {
			dbo = $dbo;
		}

		init( $newData );
	}

	// Only attributes that need additional handling go here.
	private function init( $newData:Object = null ):void {

		if ($newData)
			mergeOverwrite($newData);

		if ( !dbo.type )
			dbo.type = 1;
		if ( !dbo.count )
			dbo.count = 1;
		if ( !dbo.grain )
			dbo.grain = 2;
		if ( !dbo.accuracy )
			dbo.accuracy = 0.1;
		if ( !dbo.velocity )
			dbo.velocity = 200;
		if ( !dbo.life )
			dbo.life = 5;

		if ( !dbo.model )
			dbo.model = "CannonBall";

		if ( dbo.oxelType ) {
			if ( dbo.oxelType is String )
				dbo.oxelType = TypeInfo.getTypeId( dbo.oxelType );
		}
		else
			dbo.oxelType = TypeInfo.STEEL;

		if ( !dbo.contactScript )
			dbo.contactScript = "";


		if ( !dbo.launchSound )
			dbo.launchSound = "Cannon";
		if ( !Globals.isGuid( dbo.launchSound ) )
			SoundEvent.addListener( ModelBaseEvent.UPDATE_GUID, updateSoundGuid )

		if ( !dbo.impactSound )
			dbo.impactSound = "CannonBallExploding";

		if ( !Globals.isGuid( dbo.impactSound ) || !Globals.isGuid( dbo.launchSound ) ) {
			SoundEvent.addListener( ModelBaseEvent.UPDATE_GUID, updateSoundGuid )
			SoundEvent.addListener( ModelBaseEvent.ADDED, verifySoundData )
			SoundEvent.addListener( ModelBaseEvent.RESULT, verifySoundData )
		}

		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST, 0, dbo.launchSound, null, Globals.isGuid( dbo.launchSound ) ? true : false ) )
		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST, 0, dbo.impactSound, null, Globals.isGuid( dbo.impactSound ) ? true : false ) )
	}


	private function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		setToDefault();

//		PersistenceEvent.addListener( PersistenceEvent.CREATE_SUCCEED, 	createdHandler );
//		PersistenceEvent.addListener( PersistenceEvent.SAVE_SUCCEED, endSaving )
//		PersistenceEvent.addListener( PersistenceEvent.CREATE_FAILED, endSaving )
//		PersistenceEvent.addListener( PersistenceEvent.SAVE_FAILED, endSaving )

		function setToDefault():void {
			dbo.name = "Blank";
			dbo.type = 1;
			dbo.count = 1;
			dbo.grain = 2;
			dbo.accuracy = 0.1;
			dbo.velocity = 200;
			dbo.life = 5;
			dbo.model = "CannonBall";
			dbo.oxelType = TypeInfo.STEEL;
			dbo.contactScript = "";
			dbo.launchSound = "";
			dbo.impactSound = "";
		}
	}

	// Only attributes that need additional handling go here.

	public function addToMessage( $msg:Message ):void {
		$msg.add( guid );
	}
		//Log.out( "Ammo.addToMessage - REFACTOR with new DBO scheme", Log.ERROR );
		//$msg.add( type );
		//$msg.add( count );
		//$msg.add( grain );
		//$msg.add( accuracy );
		//$msg.add( velocity );
		//$msg.add( life );
		//$msg.add( oxelType );
		//$msg.add( model );
		//$msg.add( launchSound );
		//$msg.add( impactSound );
		//$msg.add( contactScript );
		//$msg.add( guid );
	
	public function fromMessage( $msg:Message, $index:int ):int	{
		Log.out( "Ammo.fromMessage - REFACTOR with new DBO scheme" );
		var ammoGuid:String = $msg.getString( $index );
		return $index;
	}

		//Log.out( "Ammo.fromMessage - REFACTOR with new DBO scheme", Log.ERROR );
		//type 				= $msg.getInt( $index++ );
		//count 				= $msg.getInt( $index++ );
		//grain 				= $msg.getInt( $index++ );
		//accuracy 			= $msg.getNumber( $index++ );
		//velocity 			= $msg.getNumber( $index++ );
		//life 				= $msg.getInt( $index++ );
		//oxelType 			= $msg.getInt( $index++ );
		//model 				= $msg.getString( $index++ );
		//launchSound 	= $msg.getString( $index++ );
		//impactSound 	= $msg.getString( $index++ );
		//contactScript 		= $msg.getString( $index++ );
		//guid 				= $msg.getString( $index++ );
		//return $index;

	public function toString():String {
		var ammos:String;
		ammos = "Ammo accuracy: " + accuracy;
		ammos += "  grain: " + grain;
		ammos += "  oxelType: " + oxelType;
		ammos += "  type " + type;
		ammos += "  count " + count;
		ammos += "  accuracy " + accuracy;
		ammos += "  velocity " + velocity;
		ammos += "  life " + life;
		ammos += "  model " + model;
		ammos += "  launchSound " + launchSound;
		ammos += "  impactSound " + impactSound;
		ammos += "  contactScript " + contactScript;
		ammos += "  name " + guid;
		return ammos;
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistence
	////////////////////////////////////////////////////////////////
	override protected function toObject():void {
		Log.out( "Ammo.toObject guid: " + guid, Log.DEBUG );
		// No special handling needed
	}

	override public function save():void {
		// Watch how the guid is saved.
		if ( saving ) {
			Log.out( "Ammo.save - in process of saving:" + guid )
			return
		}
		if ( !Globals.isGuid( launchSound ) || !Globals.isGuid( impactSound ) ) {
			Log.out( "Ammo.save - sounds not guids:" + guid + " impactSound: " + impactSound + " launchSound: " + launchSound  )
			return
		}
		saving = true;
		super.save();
	}

	private function updateSoundGuid( $se:SoundEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $se.guid.split( ":" );
		const oldGuid:String = guidArray[0];
		const newGuid:String = guidArray[1];

		Log.out( "Ammo.updateSoundGuid: " + guid 
		       + " ammo name: " + $se.snd.dbo.name 
			   + " ammo old guid: " + oldGuid 
			   + " ammo new guid: " + newGuid 
			   + " impactSound: " + impactSound 
			   + " launchSound: " + launchSound  )
		
		if ( dbo.impactSound == oldGuid ) {
			dbo.impactSound = newGuid
			changed = true
		}
		if ( dbo.launchSound == oldGuid ) {
			dbo.launchSound = newGuid
			changed = true
		}
		
		if ( changed )
			save()
	}
	
	private function verifySoundData( $se:SoundEvent ):void {
		Log.out( "Ammo.verifySoundData: " + guid 
		       + " ammo name: " + $se.snd.dbo.name 
			   + " ammo guid: " + $se.snd.guid 
			   + " impactSound: " + impactSound 
			   + " launchSound: " + launchSound  )
		if ( dbo.launchSound == $se.snd.dbo.name ) {
			dbo.launchSound = $se.snd.guid
			changed = true
		}
		if ( dbo.impactSound == $se.snd.dbo.name ) {
			dbo.impactSound = $se.snd.guid
			changed = true
		}
		if ( changed )
			save()
	}

	// Just assign the dbo from the create to the region
	private function createdHandler( $pe:PersistenceEvent ):void {
		if ( Globals.BIGDB_TABLE_AMMO != $pe.table )
			return
		if ( guid != $pe.guid )
			return
		
		PersistenceEvent.removeListener( PersistenceEvent.CREATE_SUCCEED, 	createdHandler );
		// update the dbo with the saved version
//		var oldInfo:Object = info
		dbo = $pe.dbo
//		dbo.ammo = oldInfo
		Log.out( "Ammo.createdHandler: " + guid )
		saving = false;
	}	
	
	private function endSaving( $pe:PersistenceEvent ):void {
		if ( Globals.BIGDB_TABLE_AMMO != $pe.table )
			return
		if ( guid != $pe.guid )
			return
		
		Log.out( "Ammo.saved: " + guid )
		saving = false;
	}
}
}
