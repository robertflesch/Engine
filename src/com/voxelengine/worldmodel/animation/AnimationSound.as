/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import flash.media.Sound;
import flash.media.SoundTransform;
import flash.utils.ByteArray;
import playerio.DatabaseObject;


import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.SoundEvent;
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.worldmodel.models.PersistenceObject;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.SoundCache;
import com.voxelengine.utils.MP3Pitch;
	
/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class AnimationSound
{
	static public var DEFAULT_OBJECT:Object = { 
		name: SOUND_INVALID,
		soundRangeMax: 2000,
	    soundRangeMin: 10
	}
	
	public static const SOUND_INVALID:String = "SOUND_INVALID"
	
	//////////////////////////////////////
	
	private var _hasValues:Boolean
	private var _guid:String = SOUND_INVALID
	private var _ani:Animation
	private var _pitch:MP3Pitch = null;
	private var _soundRangeMax:int = 2000;
	private var _soundRangeMin:int = 10;
	private var _owner:VoxelModel = null;
//		private var _checked:Boolean = false; // Could be expensive, dont check more then once a frame

	public function get soundRangeMax():int { return _soundRangeMax; }
	public function set soundRangeMax(value:int):void { _soundRangeMax = value; }
	
	public function get soundRangeMin():int { return _soundRangeMin; }
	public function set soundRangeMin(value:int):void  { _soundRangeMin = value; }
	
	public function get guid():String  { return _guid; }
	public function set guid(value:String):void  { _guid = value; }
	
	public function AnimationSound( $parentAnimation:Animation, $intiObj:Object ) {
		_ani = $parentAnimation
		
		if ( $intiObj.guid )
			guid = $intiObj.guid
		else	
			guid = $intiObj.name
		
		if ( AnimationSound.DEFAULT_OBJECT.name != guid ) {
			if (!Globals.isGuid(guid))
				SoundEvent.addListener(ModelBaseEvent.UPDATE_GUID, updateGuid)
			SoundEvent.dispatch(new SoundEvent(ModelBaseEvent.REQUEST, 0, guid, null, Globals.isGuid(guid) ? true : false))
		}

		if ( $intiObj.soundRangeMax && ( $intiObj.soundRangeMax != 2000 ) ) {
			_soundRangeMax = $intiObj.soundRangeMax
			_hasValues = true
		}
		if ( $intiObj.soundRangeMin && ( $intiObj.soundRangeMin != 10 ) ) {
			_soundRangeMin = $intiObj.soundRangeMin
			_hasValues = true
		}
	}
	
	//override public function release():void {
		//throw new Error( "what to do here" )
	//}
	
	public function reset():void {
		SoundEvent.removeListener( ModelBaseEvent.ADDED, added )
		SoundEvent.removeListener( ModelBaseEvent.RESULT, added )
		SoundEvent.removeListener( ModelBaseEvent.UPDATE_GUID, updateGuid )		
		guid		= SOUND_INVALID
		_soundRangeMax	= 2000
		_soundRangeMin	= 10
	}
	
	private function updateGuid( $se:SoundEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $se.guid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		if ( guid == oldGuid ) {
			guid = newGuid
			SoundEvent.removeListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid )		
			_hasValues = true
		}
		_ani.changed = true
	}
	
	
	public function toObject():Object {

		if ( _hasValues ) {
			var sound:Object = new Object();
			sound.guid 			= _guid
			sound.soundRangeMax	= _soundRangeMax
			sound.soundRangeMin	= _soundRangeMin
		}
		return sound
	}
	
				
	// FROM Persistance
	
	public function play( $owner:VoxelModel, $val:Number ):void
	{
//		ModelEvent.addListener( ModelEvent.MOVED, onModelMoved );
		SoundEvent.addListener( ModelBaseEvent.ADDED, added )
		SoundEvent.addListener( ModelBaseEvent.RESULT, added )
		//_pitch = SoundCache.playSoundWithPitch( $val, guid, _pitch  );
		//_owner = $owner
	}
	
	private function added( $se:SoundEvent ):void {
//		_pitch = $se.snd.playSoundWithPitch( $val, guid, _pitch  );
		
	}
	
	public function stop():void
	{
//		ModelEvent.removeListener( ModelEvent.MOVED, onModelMoved );
//		SoundCache.stopSoundWithPitch( _pitch );
		_pitch = null;
		_owner = null;
	}
	
	public function update( $val:Number ):void
	{
		//_pitch = SoundCache.playSoundWithPitch( $val, guid, _pitch  );
	}
	/*
	private function onModelMoved( event:ModelEvent ):void
	{
		if ( event.instanceGuid == Player.player.instanceInfo.instanceGuid && null != _pitch )
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
										 , _soundRangeMax
										 , _soundRangeMin );
			}
		}
	}
	
	static public function playSoundWithPitch( $pitchRate:Number, $soundFile:String, $pitch:MP3Pitch  ):MP3Pitch {
		if ( null == $soundFile || "INVALID" == $soundFile )
			return null
			
		// pitch is 0 to 1, but I find that values less then 0.5 dont work
		var pitchRate:Number = 0.5 + Math.abs($pitchRate) * 2 
		if ( $pitch ) {
			//_pitch.volume = volume
			$pitch.rate = pitchRate
		}
		else {
			var snd:Sound = SoundCache.getSound( $soundFile )
			if ( snd ) {
				//Log.out( "Ship.playSoundwWithPitch - play sound: " + snd.url )
				$pitch = new MP3Pitch( snd )
				$pitch.rate = pitchRate
			}
		}
		return $pitch
	}
	
	static public function stopSoundWithPitch( $pitch:MP3Pitch ): void {
		if ( $pitch )
			$pitch.stop()
	}
	
*/
	static public function playSound( snd:Sound, $startTime:Number = 0, $loops:int = 0, $sndTransform:SoundTransform = null) : flash.media.SoundChannel
	{
		if ( snd && !Globals.muted )
			return snd.play( $startTime, $loops, $sndTransform )
		return null	
	}
}
}
