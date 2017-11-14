/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import com.voxelengine.worldmodel.models.PersistenceObject;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;

import flash.media.Sound;
import flash.media.SoundTransform;

import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.SoundEvent;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.utils.MP3Pitch;

import playerio.DatabaseObject;

public class AnimationSound extends PersistenceObject
{
	static public const BIGDB_TABLE_SOUNDS:String = "sounds";
	static public const SOUND_EXT:String = ".mp3";

	private var _pitch:MP3Pitch = null;
	private var _pitchRate:Number;
	private var _owner:VoxelModel = null;
	private var _waitingOnLoad:Boolean;
//		private var _checked:Boolean = false; // Could be expensive, dont check more then once a frame

	private var _sound:Sound = new Sound();

	public function get sound():Sound 				{ return _sound }
	public function get name():String				{ return dbo.name }
	public function get length():Number				{ return dbo.length }
	public function get hashTags():String			{ return dbo.hashTags }
	public function set hashTags( $val:String):void	{ dbo.hashTags = $val }

	public function get soundRangeMax():int { return dbo.soundRangeMax; }
	public function set soundRangeMax(value:int):void { dbo.soundRangeMax = value; }
	
	public function get soundRangeMin():int { return dbo.soundRangeMin; }
	public function set soundRangeMin(value:int):void  { dbo.soundRangeMin = value; }

	override public function set guid( $newGuid:String ):void {
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		SoundEvent.create( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, this );
		changed = true
	}

	public function toAnimationData():Object {
		var obj:Object = {};
		obj.guid = guid;
		obj.name = name;
		return obj;
	}

	public function AnimationSound( $guid:String, $dbo:DatabaseObject, $initObj:Object ) {
		super( $guid, AnimationSound.BIGDB_TABLE_SOUNDS );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else {
			dbo = $dbo;
		}

		init( $initObj );
	}

	public function init( $newData:Object ):void {
		if ( $newData ){
			dbo.ba = $newData;
			soundRangeMax = 2000;
			soundRangeMin = 10;
			dbo.name = guid;
			dbo.hashTags = "#" + guid;
		}

		if ( !dbo.soundRangeMax )
			soundRangeMax = 2000;

		if ( !dbo.soundRangeMin )
			soundRangeMin = 10;

		try {
			sound.loadCompressedDataFromByteArray(dbo.ba, dbo.ba.length);
		} catch (error:Error) {
			Log.out( "AnimationSound.init - error trying to load sound from byteArray: " + error.message, Log.WARN);
		}
		dbo.length = int( sound.length );
	}

	override public function clone( $guid:String ):* {
		dbo.ba.position = 0;
		var newSnd:AnimationSound = new AnimationSound( $guid, null, dbo.ba );
		newSnd.dbo.name = name;
		newSnd.dbo.soundRangeMax = soundRangeMax;
		newSnd.dbo.soundRangeMin = soundRangeMin;
		newSnd.hashTags = hashTags +"#cloned";
		SoundEvent.create( ModelBaseEvent.CLONE, 0, newSnd.guid, newSnd );

		return newSnd;
	}

///////////////////////////////////////////////
	//override public function release():void {
		//throw new Error( "what to do here" )
	//}
	
	public function reset():void {
		stop();
		SoundEvent.removeListener( ModelBaseEvent.RESULT, added );
		SoundEvent.removeListener( ModelBaseEvent.UPDATE_GUID, updateGuid );
		if (soundRangeMax != 2000)
			soundRangeMax	= 2000;
		if (soundRangeMin != 10)
			soundRangeMin	= 10;
	}

	private function failed( $se:SoundEvent ):void {
		if ( $se.guid == guid ) {
			_waitingOnLoad = false;
			SoundEvent.removeListener(ModelBaseEvent.RESULT, added);
			SoundEvent.removeListener(ModelBaseEvent..REQUEST_FAILED, failed);
			Log.out("AnimationSound.failed - error: " + $se );
		}
	}

	private function added( $se:SoundEvent ):void {
		SoundEvent.removeListener( ModelBaseEvent.RESULT, added );
		SoundEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failed );

		if ( $se.guid == guid ) {
			if ($se.snd) {
				_waitingOnLoad = false;
				_pitch = new MP3Pitch(sound);
				_pitch.rate = _pitchRate;

				Log.out("AnimationSound.added - play animationSound: " + $se)
			}
		}
	}

	private function updateGuid( $se:SoundEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $se.guid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		if ( guid == oldGuid ) {
			guid = newGuid;
			SoundEvent.removeListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid );
		}
	}


	override protected function toObject():void {
		Log.out( "AnimationSound.toObject - Don't save default data to DB");
		if (soundRangeMax == 2000)
			delete dbo.soundRangeMax;
		if (soundRangeMin == 10)
			delete dbo.soundRangeMin;
	}

	private function createPitch():void {
		_pitch = new MP3Pitch(sound);
		_pitch.rate = _pitchRate;
	}

	private function requestSound():void {
		if ( !_waitingOnLoad ) {
			_waitingOnLoad = true;
			SoundEvent.addListener(ModelBaseEvent.RESULT, added);
			Log.out("AnimationSound.play - waiting on sound to load", Log.WARN);
		}
		Log.out("AnimationSound.play - _soundPersistance not loaded yet", Log.WARN);
	}

	public function play( $val:Number ):void {
//		ModelEvent.addListener( ModelEvent.MOVED, onModelMoved );
		// pitch is 0 to 1, but I find that values less then 0.5 don't work
//		_pitchRate = 0.5 + Math.abs($pitchRate) * 2;
		if ( !_sound ) {
			requestSound();
		} else if ( !_pitch ){
			_pitchRate = $val;
			createPitch();
		}
	}

	public function playSoundWithPitch( $pitchRate:Number = 1 ):void {
		if ( !_sound ) {
			requestSound();
			return;
		} else if ( !_pitch )
			createPitch();

		_pitch.rate = _pitchRate;
	}

	public function playSound( snd:Sound, $startTime:Number = 0, $loops:int = 0, $sndTransform:SoundTransform = null) : flash.media.SoundChannel {
		if ( snd && !Globals.muted )
			return snd.play( $startTime, $loops, $sndTransform );
		return null
	}

	public function stop():void {
//		ModelEvent.removeListener( ModelEvent.MOVED, onModelMoved );
		if ( _pitch )
			_pitch.stop();
		_pitch = null;
		_owner = null;
	}
	
	public function update( $val:Number ):void {
		//playSoundWithPitch( $val );
	}

	private function onModelMoved( event:ModelEvent ):void {
		if ( event.instanceGuid == VoxelModel.controlledModel.instanceInfo.instanceGuid && null != _pitch )
		{
			//trace( "AnimationSound.onModelMoved - Player moved" );
			// dont want to do this more then once per frame, really once every ten would be ok ??
			//_checked = true;
			
			// Timing check for early start up
			if (  _owner.instanceInfo.controllingModel )
			{
				var totalModelRotation:Number = _owner.getAccumulatedYRotation( _owner.instanceInfo.rotationGet.y );
				var effectiveRotation:Number = totalModelRotation + VoxelModel.controlledModel.instanceInfo.rotationGet.y;
				
				_pitch.adjustVolumeAndPan( _owner.instanceInfo.controllingModel.worldToModel( VoxelModel.controlledModel.instanceInfo.positionGet )
										 , effectiveRotation
										 , _owner.instanceInfo.positionGet.clone()
										 , soundRangeMax
										 , soundRangeMin );
			}
		}
	}
	
}
}
