/*==============================================================================
  Copyright 2011-2013 Robert Flesch
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
import com.voxelengine.worldmodel.models.makers.ModelLoader;
import com.voxelengine.worldmodel.TypeInfo;

public class Ammo
{
	protected var _dbo:DatabaseObject;
	protected var _type:int = 1;
	protected var _count:int = 1;
	protected var _grain:int = 2;
	protected var _accuracy:Number = 0.1;
	protected var _velocity:int = 200;
	protected var _life:int = 5;
	protected var _oxelType:int = TypeInfo.STEEL;
	protected var _model:String = "CannonBall";
	protected var _launchSoundFile:String = "Cannon.mp3";		
	protected var _impactSoundFile:String = "CannonBallExploding.mp3";		
	protected var _contactScript:String = "";
	protected var _name:String = "No Name";
	
	public function get type():int  				{ return _type; }
	public function set type(val:int):void			{ _type = val; }
	public function get count():int  				{ return _count; }
	public function set count(val:int):void			{ _count = val; }
	public function get grain():int 				{ return _grain; }
	public function set grain(val:int):void 		{ _grain = val; }
	public function get accuracy():Number 			{ return _accuracy; }
	public function set accuracy(val:Number):void 	{ _accuracy = val; }
	public function get velocity():Number 			{ return _velocity; }
	public function set velocity(val:Number):void 	{ _velocity = val; }
	public function get life():Number 				{ return _life; }
	public function set life(val:Number):void 		{ _life = val; }
	public function get launchSoundFile():String  	{ return _launchSoundFile; }
	public function get impactSoundFile():String  	{ return _impactSoundFile; }
	public function get contactScript():String  	{ return _contactScript; }
	public function get model():String 				{ return _model; }
	public function get name():String 				{ return _name; }
	public function get oxelType():int 				{ return _oxelType; }
	
	public function Ammo( $name:String ) {
		_name = $name;
	}
	
	public function processClassJson( $ammoJson:Object ):void {		

		if ( $ammoJson.name )
			_name = $ammoJson.name;
		if ( $ammoJson.accuracy )
			_accuracy = $ammoJson.accuracy;
		if ( $ammoJson.velocity )
			_velocity = $ammoJson.velocity;
		if ( $ammoJson.type )
			_type = $ammoJson.type;
		if ( $ammoJson.count )
			_count = $ammoJson.count;
		if ( $ammoJson.oxelType )
			_oxelType = TypeInfo.getTypeId( $ammoJson.oxelType );
		if ( $ammoJson.life )
			_life = $ammoJson.life;
		if ( $ammoJson.grain )
			_grain = $ammoJson.grain;
		if ( $ammoJson.model )
			_model = $ammoJson.model;
		if ( $ammoJson.launchSoundFile )
			_launchSoundFile = $ammoJson.launchSoundFile;
		if ( $ammoJson.impactSoundFile )
			_impactSoundFile = $ammoJson.impactSoundFile;
		if ( $ammoJson.contactScript )
			_contactScript = $ammoJson.contactScript;
		//Log.out( "Ammo.processClassJson" );
		SoundBank.getSound( _impactSoundFile ); // Preload the sound file
		SoundBank.getSound( _launchSoundFile );
		//ModelLoader.modelInfoFindOrCreate( _model, null, false );
//		ModelLoader.modelInfoFindOrCreate( _model, _model, false );
	}
	
	public function buildExportObject():Object {
		var ammoData:Object = new Object();
		ammoData.name				= _name;
		ammoData.accuracy			= _accuracy;
		ammoData.velocity			= _velocity;
		ammoData.type				= _type;
		ammoData.count				= _count;
		ammoData.oxelType			= _oxelType;
		ammoData.life				= _life;
		ammoData.grain				= _grain;
		ammoData.model				= _model;
		ammoData.launchSoundFile	= _launchSoundFile;
		ammoData.impactSoundFile 	= _impactSoundFile;
		ammoData.contactScript		= _contactScript;
		return ammoData;
	}
	
	
	public function clone():Ammo {
		var ammo:Ammo = new Ammo( _name );
		
		ammo._type = _type;
		ammo._count = _count;
		ammo._grain = _grain;
		ammo._accuracy = _accuracy;
		ammo._velocity = _velocity;
		ammo._life = _life;
		ammo._oxelType = _oxelType;
		ammo._model = _model;
		ammo._launchSoundFile = _launchSoundFile;
		ammo._impactSoundFile = _impactSoundFile;
		ammo._contactScript = _contactScript;
		
		return ammo;
	}
	
	public function addToMessage( $msg:Message ):void {
		$msg.add( type );
		$msg.add( count );
		$msg.add( grain );
		$msg.add( accuracy );
		$msg.add( velocity );
		$msg.add( life );
		$msg.add( oxelType );
		$msg.add( model );
		$msg.add( launchSoundFile );
		$msg.add( impactSoundFile );
		$msg.add( contactScript );
		$msg.add( name );
	}
	
	public function fromMessage( $msg:Message, $index:int ):int	{
		type 				= $msg.getInt( $index++ );
		count 				= $msg.getInt( $index++ );
		grain 				= $msg.getInt( $index++ );
		accuracy 			= $msg.getNumber( $index++ );
		velocity 			= $msg.getNumber( $index++ );
		life 				= $msg.getInt( $index++ );
		_oxelType 			= $msg.getInt( $index++ );
		_model 				= $msg.getString( $index++ );
		_launchSoundFile 	= $msg.getString( $index++ );
		_impactSoundFile 	= $msg.getString( $index++ );
		_contactScript 		= $msg.getString( $index++ );
		_name 				= $msg.getString( $index++ );
		return $index;
	}
	
	public function toString():String
	{
		var ammos:String;
		ammos = "Ammo accuracy: " + accuracy;
		ammos += "  grain: " + grain;
		ammos += "  oxelType: " + _oxelType;
		ammos += "  type " + _type;
		ammos += "  count " + _count;
		ammos += "  accuracy " + _accuracy;
		ammos += "  velocity " + _velocity;
		ammos += "  life " + _life;
		ammos += "  model " + _model;
		ammos += "  launchSoundFile " + _launchSoundFile;
		ammos += "  impactSoundFile " + _impactSoundFile;
		ammos += "  contactScript " + _contactScript;
		ammos += "  name " + _name;
		return ammos;
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistance( $dbo:DatabaseObject ):void {
		
		_name 				= $dbo.key;
		_type				= $dbo.type;
		_count				= $dbo.count;
		_grain				= $dbo.grain;
		_accuracy			= $dbo.accuracy;
		_velocity			= $dbo.velocity;
		_life				= $dbo.life;
		_oxelType			= $dbo.oxelType;
		_model				= $dbo.model;
		_launchSoundFile	= $dbo.launchSoundFile;
		_impactSoundFile	= $dbo.impactSoundFile;
		_contactScript		= $dbo.contactScript;
	}
	
	public function save():void {
		if ( Globals.online ) {
			//Log.out( "AnimationMetadata.save - Saving Animation Metadata guid: " + _guid + "  modelGuid: " + _modelGuid ); // + " vmd: " + $vmd.toString(), Log.WARN );
			addSaveEvents();
			if ( _dbo )
				toPersistance();
			else {
				var obj:Object = toObject();
			}
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.DB_TABLE_AMMO, name, _dbo, obj ) );
		}
		else
			Log.out( "Ammo.save - Not saving ammo, offline", Log.WARN );
	}
	
	public function toPersistance():void {
		
		//_dbo.key = _name;
		_dbo.type = _type;
		_dbo.count = _count;
		_dbo.grain = _grain;
		_dbo.accuracy = _accuracy;
		_dbo.velocity = _velocity;
		_dbo.life = _life;
		_dbo.oxelType = _oxelType;
		_dbo.model = _model;
		_dbo.launchSoundFile = _launchSoundFile;
		_dbo.impactSoundFile = _impactSoundFile;
		_dbo.contactScript = _contactScript;
	}
	
	public function toObject():Object {
		
		var metadataObj:Object =   { type:			    _type			
								   , count:			    _count			
								   , grain:			    _grain			
								   , accuracy:		    _accuracy		
								   , velocity:		    _velocity		
								   , life:			    _life			
								   , oxelType:		    _oxelType		
								   , model:			    _model			
								   , launchSoundFile:   _launchSoundFile
								   , impactSoundFile:   _impactSoundFile
								   , contactScript:	    _contactScript	};
		return metadataObj;						   
	}
	
	private function addSaveEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, saveFailed );
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.CREATE_FAILED, createFailed );
	}
	
	private function removeSaveEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, saveFailed );
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_FAILED, createFailed );
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_TABLE_AMMO != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "Ammo.saveSucceed" );
	}
	
	private function saveFailed( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_TABLE_AMMO != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "Ammo.saveFailed - MAY BE (error #2032)  The method SaveObjectChanges can only be called when connected to a game", Log.ERROR );
	}
	
	private function createFailed( $pe:PersistanceEvent ):void
	{
		if ( Globals.DB_TABLE_AMMO != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "Ammo.createFailed - Failed to create new Ammo object for this object.", Log.ERROR );
	}	
	
	
}
}
