/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.server.Network;
import flash.utils.ByteArray;

import playerio.DatabaseObject;
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.PersistanceObject;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class Animation extends PersistanceObject
{
	static private const BLANK_ANIMATION_TEMPLATE:Object = { "animation":[] };

	static private const ANIMATION_STATE:String = "state";
	static private const ANIMATION_ACTION:String = "action";
	
	//private var _loaded:Boolean = false;
	private var _transforms:Vector.<AnimationTransform>;
	private var _attachments:Vector.<AnimationAttachment>;
	private var _sound:AnimationSound;

	public function get attachments():Vector.<AnimationAttachment> { return _attachments; }
	public function get transforms():Vector.<AnimationTransform> { return _transforms; }
	//public function get loaded():Boolean { return _loaded; }
	
	
	/////////////////
	public function get name():String { return info.name; }
	public function set name( $val:String ):void { info.name = $val; }
	public function get type():String { return info.type; }
	public function get animationClass():String { return info.animationClass; }
	public function get description():String { return info.description; }
	public function set description( $val:String ):void { info.description = $val; }
	public function get owner():String { return info.owner; }
	public function get sound():AnimationSound { return _sound; }
	public function set sound( $val:AnimationSound ):void  { _sound = $val; }
	override public function set guid( $newGuid:String ):void { 
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.UPDATE_GUID, 0, animationClass, oldGuid + ":" + $newGuid, null ) );
		changed = true;
	}
	
	////////////////
	public function Animation( $guid:String ) {
		super( $guid, Globals.BIGDB_TABLE_ANIMATIONS );		
	}
	
	public function fromObjectImport( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		// The data is needed the first time it saves the object from import, after that it goes away
		if ( !dbo.data || !dbo.data.animations ) {
			Log.out( "Animation.fromObjectImport - Failed test !dbo.data || !dbo.data.ani dbo: " + JSON.stringify( dbo ), Log.ERROR );
			return;
		}
		
		
		info = $dbo.data;
		loadFromInfo();
	}
	
	public function fromObject( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		if ( !dbo.animations ) {
			Log.out( "Animation.fromObject - Failed test !dbo.data  dbo: " + JSON.stringify( dbo ), Log.ERROR );
			return;
		}
		
		info = $dbo;
		loadFromInfo();
	}
	
	override public function save():void {
		if ( "0" == dbo.key )
			guid = Globals.getUID();
		super.save();
	}
	
	override protected function toObject():void {
		Log.out( "Animation.toObject", Log.WARN );
		// Only need to change these if the data has changed, and since there are not editing tools in app for animations yet
		// Not going to do it until it is needed
		
		//if ( _sound )
			//_sound.getJSON( info );
		//if ( _attachments )
			//getAttachments( info );
		//if ( _transforms )
			//getTransforms( info );
//
		//function getAttachments( info:Object ):void {
			//var oa:Vector.<Object> = new Vector.<Object>();
			//for each ( var aa:AnimationAttachment in _attachments ) {
				//var ao:Object = new Object();
				//aa.buildExportObject( ao );
				//oa.push( ao );
			//}
			//if ( oa.length )
				//info.attachments = oa;
		//}
		//
		//function getTransforms( info:Object ):void {
			//var ot:Vector.<Object> = new Vector.<Object>();
			//for each ( var at:AnimationTransform in _transforms ) {
				//var ao:Object = new Object();
				//at.buildExportObject( ao );
				//ot.push( ao );
			//}
			//if ( ot.length )
				//info.animations = ot;
		//}
	}

	// Only attributes that need additional handling go here.
	public function loadFromInfo():void {
		var type:String = ANIMATION_STATE;
		if ( info.type ) {
			if ( "action" == info.type )
				type = ANIMATION_ACTION;
			else if ( "state" == info.type ) 	
				type = ANIMATION_STATE;
			else
				Log.out( "Animation.fromJSON - ERROR unknown type: " + info.type, Log.ERROR );
		}
		if ( info.sound ) {
			_sound = new AnimationSound();
			_sound.init( info.sound );
		}
		if ( info.attachments ) {
			_attachments = new Vector.<AnimationAttachment>;
			for each ( var attachmentJson:Object in info.attachment )
			{
				_attachments.push( new AnimationAttachment( attachmentJson ) );				
			}
		}
		if ( info.animations ) {
			_transforms = new Vector.<AnimationTransform>;
			for each ( var transformJson:Object in info.animations )
			{
				_transforms.push( new AnimationTransform( transformJson ) );				
			}
		}
		if ( !info.owner )
			info.owner = Network.PUBLIC;
			
		//LoadingEvent.dispatch( new LoadingEvent( LoadingEvent.ANIMATION_LOAD_COMPLETE, name ) );
//		return type;
	}
/*
	public function fromJSON( $json:Object ):String  {
		var type:String = ANIMATION_STATE;
		if ( $json.type ) {
			if ( "action" == $json.type )
				type = ANIMATION_ACTION;
			else if ( "state" == $json.type ) 	
				type = ANIMATION_STATE;
			else
				Log.out( "Animation.fromJSON - ERROR unknown type: " + $json.type, Log.ERROR );
		}
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
		return type;
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
*/	
	/*
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
	*/
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
}
}
