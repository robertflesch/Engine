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
import com.voxelengine.worldmodel.SoundBank;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.PersistanceObject;
import com.voxelengine.worldmodel.models.IPersistance;

public class Ammo extends PersistanceObject
{
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
	public function get launchSoundFile():String  	{ return info.launchSoundFile; }
	public function get impactSoundFile():String  	{ return info.impactSoundFile; }
	public function get contactScript():String  	{ return info.contactScript; }
	public function get model():String 				{ return info.model; }
	public function get oxelType():int 				{ return info.oxelType; }
	
	public function Ammo( $name:String ) {
		super( $name, Globals.BIGDB_TABLE_AMMO );
	}
	
	public function addToMessage( $msg:Message ):void {
		throw new Error( "Ammo.addToMessage - REFACTOR" );
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
		//$msg.add( launchSoundFile );
		//$msg.add( impactSoundFile );
		//$msg.add( contactScript );
		//$msg.add( guid );
	
	public function fromMessage( $msg:Message, $index:int ):int	{
		throw new Error( "Ammo.fromMessage - REFACTOR" );
		return 0;
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
		//launchSoundFile 	= $msg.getString( $index++ );
		//impactSoundFile 	= $msg.getString( $index++ );
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
		ammos += "  launchSoundFile " + launchSoundFile;
		ammos += "  impactSoundFile " + impactSoundFile;
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
	
	public function toObject():void {
		// No special handling needed
	}

	override public function save():void {
		// Watch how the guid is saved.
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
			if ( info.oxelTypeId is String )
				info.oxelType = TypeInfo.getTypeId( info.oxelType );
		}
		else
			info.oxelType = TypeInfo.STEEL;
			
		if ( !info.contactScript )
			info.contactScript = "";
			
		if ( !info.launchSoundFile )
			info.launchSoundFile = "Cannon.mp3";
		SoundBank.getSound( info.launchSoundFile ); // Preload the sound file
		
		if ( !info.impactSoundFile )
			info.impactSoundFile = "CannonBallExploding.mp3";
		SoundBank.getSound( info.impactSoundFile );
			
		//ModelLoader.modelInfoFindOrCreate( _model, null, false );
		//ModelLoader.modelInfoFindOrCreate( _model, _model, false );
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
		info.launchSoundFile = "";
		info.impactSoundFile = "";
	}
}
}
