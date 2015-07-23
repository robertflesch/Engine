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
import com.voxelengine.events.AmmoEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.PersistanceObject;
import com.voxelengine.worldmodel.models.IPersistance;

public class Ammo extends PersistanceObject
{
	private var _info:Object;
	
	public function get type():int  				{ return _info.type; }
	public function set type(val:int):void			{ _info.type = val; }
	public function get count():int  				{ return _info.count; }
	public function set count(val:int):void			{ _info.count = val; }
	public function get grain():int 				{ return _info.grain; }
	public function set grain(val:int):void 		{ _info.grain = val; }
	public function get accuracy():Number 			{ return _info.accuracy; }
	public function set accuracy(val:Number):void 	{ _info.accuracy = val; }
	public function get velocity():Number 			{ return _info.velocity; }
	public function set velocity(val:Number):void 	{ _info.velocity = val; }
	public function get life():Number 				{ return _info.life; }
	public function set life(val:Number):void 		{ _info.life = val; }
	public function get launchSoundFile():String  	{ return _info.launchSoundFile; }
	public function get impactSoundFile():String  	{ return _info.impactSoundFile; }
	public function get contactScript():String  	{ return _info.contactScript; }
	public function get model():String 				{ return _info.model; }
	public function get oxelType():int 				{ return _info.oxelType; }
	
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
	public function save():void {
		if ( Globals.online ) {
			Log.out( "Ammo.save - Saving Ammo: " + guid  + " in table: " + table, Log.WARN );
			addSaveEvents();
			toObject();
				
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, table, guid, dbo, null ) );
		}
		else
			Log.out( "Ammo.save - Not saving data, either offline or NOT changed or locked - guid: " + guid );
	}
	
	public function fromObjectImport( $dbo:DatabaseObject ):void {
		_dbo = $dbo;
		// The data is needed the first time it saves the object from import, after that it goes away
		if ( !dbo.data.model )
			return;
		
		_info = $dbo.data.model;
		loadFromInfo();
	}
	
	public function fromObject( $dbo:DatabaseObject ):void {
		_dbo = $dbo;
		if ( !dbo.model )
			return;
		
		_info = $dbo.model;
		loadFromInfo();
	}
	
	public function toObject():void {
		// No special handling needed
	}

	// Only attributes that need additional handling go here.
	public function loadFromInfo():void {
		if ( !_info.type )
			_info.type = 1;
		if ( !_info.count )
			_info.count = 1;
		if ( !_info.grain )
			_info.grain = 2;
		if ( !_info.accuracy )
			_info.accuracy = 0.1;
		if ( !_info.velocity )
			_info.velocity = 200;
		if ( !_info.life )
			_info.life = 5;
		
		if ( !_info.model )
			_info.model = "CannonBall";
			
		if ( _info.oxelType )
			if ( _info.oxelTypeId is String )
				_info.oxelType = TypeInfo.getTypeId( _info.oxelType );
		else
			_info.oxelType = TypeInfo.STEEL;
			
		if ( !_info.contactScript )
			_info.contactScript = "";
			
		if ( !_info.launchSoundFile )
			_info.launchSoundFile = "Cannon.mp3";
		SoundBank.getSound( _info.launchSoundFile ); // Preload the sound file
		
		if ( !_info.impactSoundFile )
			_info.impactSoundFile = "CannonBallExploding.mp3";
		SoundBank.getSound( _info.impactSoundFile );
			
		//ModelLoader.modelInfoFindOrCreate( _model, null, false );
		//ModelLoader.modelInfoFindOrCreate( _model, _model, false );
	}
}
}
