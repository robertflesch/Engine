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
	
	public function fromImport( $json:Object, $guid:String, $aniType:String, $modelGuid:String ):void  {
		_metadata.fromImport( $guid, $aniType, $modelGuid );
		fromJSON( $json );
	}
	
	public function fromJSON( $json:Object ):void  {
		if ( $json.sound ) {
			_sound = new AnimationSound();
			_sound.init( $json.sound );
		}
		if ( $json.attachments ) {
			_attachments = new Vector.<AnimationAttachment>;
			for each ( var attachmentJson:Object in $json.attachment )
			{
				_attachments.push( new AnimationAttachment( attachmentJson ) );				
			}
		}
		if ( $json.animations ) {
			_transforms = new Vector.<AnimationTransform>;
			for each ( var transformJson:Object in $json.animations )
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
		Log.out( "Animation.fromPersistance - name: " + metadata.name + "   "  + json );
		var jsonResult:Object = JSONUtil.parse( json, _metadata.guid, "Animation.fromPersistance" );
		fromJSON( jsonResult );
	}
	
	private function getJSON( obj:Object ):void {
		if ( _sound )
			_sound.getJSON( obj );
		if ( _attachments )
			getAttachmentsJSON( obj );
		if ( _transforms )
			getTransformsJSON( obj );

		function getAttachmentsJSON( obj:Object ):void {
			var oa:Vector.<Object> = new Vector.<Object>();
			for each ( var aa:AnimationAttachment in _attachments ) {
				var ao:Object = new Object();
				aa.buildExportObject( ao );
				oa.push( ao );
			}
			if ( oa.length )
				obj.attachments = oa;
		}
		
		function getTransformsJSON( obj:Object ):void {
			var ot:Vector.<Object> = new Vector.<Object>();
			for each ( var at:AnimationTransform in _transforms ) {
				var ao:Object = new Object();
				at.buildExportObject( ao );
				ot.push( ao );
			}
			if ( ot.length )
				obj.animations = ot;
		}
	}
	
	public function play( $owner:VoxelModel, $val:Number ):void {
		//Log.out( "Animation.play - name: " + _name );
		if ( _sound )
			_sound.play( $owner, $val );
			
		if ( _attachments && 0 < _attachments.length ) {
			for each ( var aa:AnimationAttachment in _attachments ) {
				var cm:VoxelModel = $owner.modelInfo.childFindByName( aa.attachsTo );
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
				var cm:VoxelModel = $owner.modelInfo.childFindByName( aa.attachsTo );
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
		ba = toByteArray( ba );
		metadata.save( ba );
	}
	
	public function toByteArray( $ba:ByteArray ):ByteArray {
		var obj:Object = new Object();
		getJSON( obj );
		var json:String = JSON.stringify( obj );
		$ba.writeInt( json.length );
		$ba.writeUTFBytes( json );
		$ba.compress();
		return $ba;	
	}

	private	function createSuccess( dbo:DatabaseObject):void { 
		if ( dbo ) 
			metadata.dbo = dbo;
	}
	
	public function toString():String {
		var obj:Object = new Object();
		getJSON( obj );
		return 	_metadata.name + "  " + JSON.stringify( obj );

	}
}
}
