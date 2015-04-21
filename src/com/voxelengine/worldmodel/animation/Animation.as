/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import flash.utils.ByteArray;
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.events.AnimationMetadataEvent;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class Animation
{
	// This should be a list so that it can be added to easily, this is hard coded.
	static public const MODEL_BIPEDAL_10:String = "MODEL_BIPEDAL_10";
	static public const MODEL_DRAGON_9:String =  "MODEL_DRAGON_9";
	static public const MODEL_PROPELLER:String =  "MODEL_PROPELLER";
	static public const MODEL_UNKNOWN:String =  "MODEL_UNKNOWN";
	
	static private const BLANK_ANIMATION_TEMPLATE:Object = { "animation":[] };

	static private const ANIMATION_STATE:String = "ANIMATION_STATE";
	static private const ANIMATION_ACTION:String = "ANIMATION_ACTION";
	
	//private var _loaded:Boolean = false;
	private var _transforms:Vector.<AnimationTransform>;
	private var _attachments:Vector.<AnimationAttachment>;
	private var _metadata:AnimationMetadata = new AnimationMetadata();
	private var _sound:AnimationSound;

	public function get attachments():Vector.<AnimationAttachment> { return _attachments; }
	public function get transforms():Vector.<AnimationTransform> { return _transforms; }
	//public function get loaded():Boolean { return _loaded; }
	public function get metadata():AnimationMetadata { return _metadata; }
	
	public function Animation() {  }
	
	public function loadFromPersistance( $dbo:DatabaseObject ):void {
		metadata.fromPersistance( $dbo );
	}
	
	public function fromImport( $json:Object, $guid:String, $aniType:String ):void  {
		_metadata.fromImport( $guid, $aniType );
		fromJSON( $json );
	}
	
	public function fromJSON( $json:Object ):void  {
		if ( $json.sound ) {
			_sound = new AnimationSound();
			_sound.init( $json.sound );
		}
		if ( $json.attachment ) {
			_attachments = new Vector.<AnimationAttachment>;
			for each ( var attachmentJson:Object in $json.attachment )
			{
				_attachments.push( new AnimationAttachment( attachmentJson ) );				
			}
		}
		if ( $json.animation ) {
			_transforms = new Vector.<AnimationTransform>;
			for each ( var transformJson:Object in $json.animation )
			{
				_transforms.push( new AnimationTransform( transformJson ) );				
			}
		}
		//LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.ANIMATION_LOAD_COMPLETE, name ) );
	}
	
	public function fromPersistance( $dbo:DatabaseObject ):void {	
		var ba:ByteArray = _metadata.fromPersistance( $dbo );
		ba.position = 0;
		// how many bytes is the animation
		var strLen:int = ba.readInt();
		// read off that many bytes
		var json:String = ba.readUTFBytes( strLen );
		var jsonResult:Object = JSONUtil.parse( json, _metadata.guid, "Animation.fromPersistance" );
		fromJSON( jsonResult );
	}
	
	private function getJSON():String
	{
		var jsonString:String = "{";
		if ( _sound ) {
			jsonString += "\"sound\":";
			jsonString += _sound.getJSON();
		}
		if ( _attachments ) {
			if ( _sound )
				jsonString += ","
			jsonString += "\"attachment\":[";
			jsonString += attachmentsToJSON();
			jsonString += "]"
		}
		if ( _transforms ) {
			if ( _sound || _attachments )
				jsonString += ","
			jsonString += "\"animation\":[";
			jsonString += animationsToJSON();
			jsonString += "]"
		}
		jsonString += "}";
		//Log.out( Animation.getJSON - name + " = " + jsonString );
		return jsonString;
	}

	private function animationsToJSON():String {
		var animations:Vector.<String> = new Vector.<String>;
		var outString:String = new String();
		
		for each ( var at:AnimationTransform in _transforms ) {
			if ( at )
				animations.push( at.getJSON() );	
		}
		
		var len:int = animations.length;
		for ( var index:int; index < len; index++ ) {
			outString += animations[index];
			if ( index == len - 1 )
				continue;
			outString += ",";
		}
		return outString;
	}

	private function attachmentsToJSON():String {
		var attachments:Vector.<String> = new Vector.<String>;
		var outString:String = new String();
		
		for each ( var aa:AnimationAttachment in _attachments ) {
			if ( aa  )
				attachments.push( aa.getJSON() );	
		}
		
		var len:int = attachments.length;
		for ( var index:int; index < len; index++ ) {
			outString += attachments[index];
			if ( index == len - 1 )
				continue;
			outString += ",";
		}
		return outString;
	}
	
	public function play( $owner:VoxelModel, $val:Number ):void {
		//Log.out( "Animation.play - name: " + _name );
		if ( _sound )
			_sound.play( $owner, $val );
			
		if ( _attachments && 0 < _attachments.length ) {
			for each ( var aa:AnimationAttachment in _attachments ) {
				var cm:VoxelModel = $owner.childFindByName( aa.attachsTo );
				if ( cm )
					aa.create( cm );
			}
		}
	}
	
	public function stop( $owner:VoxelModel ):void {
		if ( _sound )
			_sound.stop();
			
		if ( _attachments && 0 < _attachments.length ) {
			for each ( var aa:AnimationAttachment in _attachments ) {
				var cm:VoxelModel = $owner.childFindByName( aa.attachsTo );
				if ( cm )
					aa.detach();
			}
		}
	}
	
	public function update( $val:Number ):void {
		if ( _sound )
			_sound.update( $val / 3 );
	}
	
	public function save():void {
		var ba:ByteArray = new ByteArray();
		ba = asByteArray( ba );
		metadata.save( ba );
	}
	
	public function asByteArray( $ba:ByteArray ):ByteArray {
		var json:String = getJSON();
		$ba.writeInt( json.length );
		$ba.writeUTFBytes( json );
		$ba.compress();
		return $ba;	
	}

	private	function createSuccess( dbo:DatabaseObject):void { 
		if ( dbo ) 
			metadata.dbo = dbo;
	}
}
}
