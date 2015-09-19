/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelEvent;
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
	public static const SOUND_INVALID:String = "SOUND_INVALID"
	private var _soundFile:String = SOUND_INVALID
	private var _pitch:MP3Pitch = null;
	private var _soundRangeMax:int = 2000;
	private var _soundRangeMin:int = 10;
	private var _hasValues:Boolean
//		private var _checked:Boolean = false; // Could be expensive, dont check more then once a frame

	private var _owner:VoxelModel = null;
	
	public function get soundFile():String  { return _soundFile; }
	public function set soundFile(value:String):void  { _soundFile = value; }
	
	public function get soundRangeMax():int { return _soundRangeMax; }
	public function set soundRangeMax(value:int):void { _soundRangeMax = value; }
	
	public function get soundRangeMin():int { return _soundRangeMin; }
	public function set soundRangeMin(value:int):void  { _soundRangeMin = value; }
	
	public function AnimationSound() { }

	public function reset():void {
		_soundFile		= SOUND_INVALID
		_soundRangeMax	= 2000
		_soundRangeMin	= 10
	}
	
	public function init( $soundInfo:Object ):void 
	{
		if ( $soundInfo.name && ( SOUND_INVALID != $soundInfo.name ) ) {
			_soundFile = $soundInfo.name
			SoundCache.getSound( _soundFile )
			_hasValues = true
		}
		if ( $soundInfo.soundRangeMax && ( $soundInfo.soundRangeMax != 2000 ) ) {
			_soundRangeMax = $soundInfo.soundRangeMax
			_hasValues = true
		}
		if ( $soundInfo.soundRangeMin && ( $soundInfo.soundRangeMin != 10 ) ) {
			_soundRangeMin = $soundInfo.soundRangeMin
			_hasValues = true
		}
	}
	
	public function toObject():Object {

		if ( _hasValues ) {
			var sound:Object = new Object();
			sound.name 			= _soundFile
			sound.soundRangeMax	= _soundRangeMax
			sound.soundRangeMin	= _soundRangeMin
		}
		return sound
	}

	public function play( $owner:VoxelModel, $val:Number ):void
	{
		ModelEvent.addListener( ModelEvent.MOVED, onModelMoved );
		_pitch = SoundCache.playSoundWithPitch( $val, _soundFile, _pitch  );
		_owner = $owner
	}
	
	public function stop():void
	{
		ModelEvent.removeListener( ModelEvent.MOVED, onModelMoved );
		SoundCache.stopSoundWithPitch( _pitch );
		_pitch = null;
		_owner = null;
	}
	
	public function update( $val:Number ):void
	{
		_pitch = SoundCache.playSoundWithPitch( $val, _soundFile, _pitch  );
	}
	
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
}
}
