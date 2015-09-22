/*==============================================================================
  Copyright 2011-2015 Robert Flesch
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
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.SoundEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.PersistanceObject;
//import com.voxelengine.worldmodel.models.IPersistance;

public class Ammo extends PersistanceObject
{
	private var saving:Boolean
	public function get name():String  				{ return info.name; }
	public function get type():int  				{ return info.type; }
	public function set type(val:int):void			{ info.type = val; }
	public function get count():int  				{ return info.count; }
	public function set count(val:int):void			{ info.count = val; }
	public function get grain():int 				{ return info.grain; }
	public function set grain(val:int):void 		{ info.grain = val; }
	public function get accuracy():Number 			{ return info.accuracy; }
	public function set accuracy(val:Number):void 	{ info.accuracy = val; }
	public function get velocity():Number 			{ return info.velocity; }
	public function set velocity(val:Number):void 	{ info.velocity = val; }
	public function get life():Number 				{ return info.life; }
	public function set life(val:Number):void 		{ info.life = val; }
	public function get launchSound():String  		{ return info.launchSound; }
	public function get impactSound():String  		{ return info.impactSound; }
	public function get contactScript():String  	{ return info.contactScript; }
	public function get model():String 				{ return info.model; }
	public function get oxelType():int 				{ return info.oxelType; }
	
	public function Ammo( $name:String ) {
		super( $name, Globals.BIGDB_TABLE_AMMO );
	}
	
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

	public function toString():String
	{
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
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	public function fromObjectImport( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		// The data is needed the first time it saves the object from import, after that it goes away
		if ( !dbo.data || !dbo.data.ammo ) {
			Log.out( "Ammo.fromObjectImport - Failed test !dbo.data || !dbo.data.ammo dbo: " + JSON.stringify( dbo ), Log.ERROR );
			return;
		}
		
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createdHandler ); 
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, endSaving )
		PersistanceEvent.addListener( PersistanceEvent.CREATE_FAILED, endSaving )
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, endSaving )
		
		info = $dbo.data.ammo;
		guid = $dbo.data.ammo.key;
		loadFromInfo();
	}
	
	public function fromObject( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		if ( !dbo.ammo ) {
			Log.out( "Ammo.fromObject - Failed test !dbo.data  dbo: " + JSON.stringify( dbo ), Log.ERROR );
			return;
		}
		
		info = $dbo.ammo;
		loadFromInfo();
	}
	
	override protected function toObject():void {
		Log.out( "Ammo.toObject guid: " + guid, Log.WARN );
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
		saving = true	
		super.save();
	}

	// Only attributes that need additional handling go here.
	public function loadFromInfo():void {
		if ( !info.type )
			info.type = 1;
		if ( !info.count )
			info.count = 1;
		if ( !info.grain )
			info.grain = 2;
		if ( !info.accuracy )
			info.accuracy = 0.1;
		if ( !info.velocity )
			info.velocity = 200;
		if ( !info.life )
			info.life = 5;
		
		if ( !info.model )
			info.model = "CannonBall";
			
		if ( info.oxelType ) {
			if ( info.oxelType is String )
				info.oxelType = TypeInfo.getTypeId( info.oxelType );
		}
		else
			info.oxelType = TypeInfo.STEEL;
			
		if ( !info.contactScript )
			info.contactScript = "";

			
		if ( !info.launchSound )
			info.launchSound = "Cannon";
		if ( !Globals.isGuid( info.launchSound ) )
			SoundEvent.addListener( ModelBaseEvent.UPDATE_GUID, updateSoundGuid )		
		
		if ( !info.impactSound )
			info.impactSound = "CannonBallExploding";
			
		if ( !Globals.isGuid( info.impactSound ) || !Globals.isGuid( info.launchSound ) ) {
			SoundEvent.addListener( ModelBaseEvent.UPDATE_GUID, updateSoundGuid )		
			SoundEvent.addListener( ModelBaseEvent.ADDED, verifySoundData )
			SoundEvent.addListener( ModelBaseEvent.RESULT, verifySoundData )
		}
			
		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST, 0, info.launchSound, null, Globals.isGuid( info.launchSound ) ? true : false ) )
		SoundEvent.dispatch( new SoundEvent( ModelBaseEvent.REQUEST, 0, info.impactSound, null, Globals.isGuid( info.impactSound ) ? true : false ) )

		//ModelLoader.modelInfoFindOrCreate( _model, null, false );
		//ModelLoader.modelInfoFindOrCreate( _model, _model, false );
	}
	
	private function updateSoundGuid( $se:SoundEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $se.guid.split( ":" );
		const oldGuid:String = guidArray[0];
		const newGuid:String = guidArray[1];

		Log.out( "Ammo.updateSoundGuid: " + guid 
		       + " ammo name: " + $se.snd.info.name 
			   + " ammo old guid: " + oldGuid 
			   + " ammo new guid: " + newGuid 
			   + " impactSound: " + impactSound 
			   + " launchSound: " + launchSound  )
		
		if ( info.impactSound == oldGuid ) {
			info.impactSound = newGuid
			changed = true
		}
		if ( info.launchSound == oldGuid ) {
			info.launchSound = newGuid
			changed = true
		}
		
		if ( changed )
			save()
	}
	
	private function verifySoundData( $se:SoundEvent ):void {
		Log.out( "Ammo.verifySoundData: " + guid 
		       + " ammo name: " + $se.snd.info.name 
			   + " ammo guid: " + $se.snd.guid 
			   + " impactSound: " + impactSound 
			   + " launchSound: " + launchSound  )
		if ( info.launchSound == $se.snd.info.name ) {
			info.launchSound = $se.snd.guid
			changed = true
		}
		if ( info.impactSound == $se.snd.info.name ) {
			info.impactSound = $se.snd.guid
			changed = true
		}
		if ( changed )
			save()
	}

	// Only attributes that need additional handling go here.
	public function createDefault():void {
		info = new Object();
		info.name = "Blank";
		info.type = 1;
		info.count = 1;
		info.grain = 2;
		info.accuracy = 0.1;
		info.velocity = 200;
		info.life = 5;
		info.model = "CannonBall";
		info.oxelType = TypeInfo.STEEL;
		info.contactScript = "";
		info.launchSound = "";
		info.impactSound = "";
	}
	
		
	// Just assign the dbo from the create to the region
	private function createdHandler( $pe:PersistanceEvent ):void {
		if ( Globals.BIGDB_TABLE_AMMO != $pe.table )
			return
		if ( guid != $pe.guid )
			return
		
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createdHandler ); 			
		// update the dbo with the saved version
		var oldInfo:Object = info
		dbo = $pe.dbo
		dbo.ammo = oldInfo
		Log.out( "Ammo.createdHandler: " + guid )
		saving = false;
	}	
	
	private function endSaving( $pe:PersistanceEvent ):void {
		if ( Globals.BIGDB_TABLE_AMMO != $pe.table )
			return
		if ( guid != $pe.guid )
			return
		
		Log.out( "Ammo.saved: " + guid )
		saving = false;
	}
}
}
