/*==============================================================================
Copyright 2011-2017 Robert Flesch
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
import com.voxelengine.worldmodel.PermissionsBase;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.models.SecureNumber;

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
	private var _permissions:PermissionsBase;
	private var  _clipVelocity:SecureNumber 		= new SecureNumber( 0.95 );
	private var  _speedMultiplier:SecureNumber 		= new SecureNumber( 0.95 );

	public function get clipVelocity():Number  					{ return _clipVelocity.val; }
	public function set clipVelocity($value:Number):void  		{ _clipVelocity.val = $value; }

	public function get speedMultiplier():Number  					{ return _speedMultiplier.val; }
	public function set speedMultiplier($value:Number):void  		{ _speedMultiplier.val = $value; }

	public function get attachments():Vector.<AnimationAttachment> { return _attachments; }
	public function get transforms():Vector.<AnimationTransform> { return _transforms; }
	//public function get loaded():Boolean { return _loaded; }
	
	
	public function get permissions():PermissionsBase 			{ return _permissions; }
	public function set permissions( val:PermissionsBase):void	{ _permissions = val; changed = true; }
	
	/////////////////
	public function get name():String { return dbo.name; }
	public function set name( $val:String ):void { dbo.name = $val; }
	public function get type():String { return dbo.type; }
	public function get animationClass():String { return dbo.animationClass; }
	public function get description():String { return dbo.description; }
	public function set description( $val:String ):void { dbo.description = $val; }
	public function get owner():String { return dbo.owner; }
	public function get sound():AnimationSound { return _sound; }
	public function set sound( $val:AnimationSound ):void  { _sound = $val; }
	override public function set guid( $newGuid:String ):void { 
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.UPDATE_GUID, 0, animationClass, oldGuid + ":" + $newGuid, null ) );
		changed = true;
	}
	
	static public function defaultObject( $modelGuid:String ):Animation {
		var obj:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_ANIMATIONS, "0", "0", 0, true, null )
		obj.data = Animation.DEFAULT_OBJECT
		// This is UGLY - TODO
		obj.data.animationClass = AnimationCache.requestAnimationClass( Region.currentRegion.modelCache.requestModelInfoByModelGuid( $modelGuid ).modelClass )
		var childNameList:Vector.<String> = new Vector.<String>
		VoxelModel.selectedModel.childNameList( childNameList )
		obj.data.animations = new Array()
		for each ( var name:String in childNameList ) {
			var at:AnimationTransform = new AnimationTransform( new Object() )
			at.attachmentName = name
			obj.data.animations.push( at.toObject() )
		}
		
		var ani:Animation = new Animation( Globals.getUID() );
		ani.fromObjectImport( obj )
		return ani
	}
	
	static private var DEFAULT_OBJECT:Object = { 
		name: "Default",
		description: "Enter description here",
		type : ANIMATION_STATE,
		owner : Network.userId
	}
	
	
	////////////////
	public function Animation( $guid:String ) {
		super( $guid, Globals.BIGDB_TABLE_ANIMATIONS );		
	}

	public function createBackCopy():Object {
		// force the data from the dynamic classes into the object
		// this give me an object that holds all of the data for the animation
		toObject() 
		var backupInfo:Object = new Object();
		backupInfo.name 			= String( dbo.name );
		backupInfo.description 	= String( dbo.description );
		backupInfo.owner 			= String( dbo.owner )
		backupInfo.type 			= String( dbo.type )
		backupInfo.animationClass 	= String( dbo.animationClass )
		if ( _sound )
			backupInfo.sound = _sound.toObject()
		if ( _transforms && _transforms.length )
			backupInfo.animations = getAnimations()
		if ( _attachments && _attachments.length )
			backupInfo.attachments = getAttachments()
		// TODO - add clip velocity and speed multiplier
		return backupInfo
	}
	
	public function restoreFromBackup( $info:Object ):void {
		// if you just assign name, then it shares the same object
		// we want a new object in this case
		dbo.name 			= String( $info.name );
		dbo.description 	= String( $info.description );
		dbo.owner 			= String( $info.owner )
		dbo.type 			= String( $info.type )
		dbo.animationClass = String( $info.animationClass )
		loadFromInfo( $info )
		changed = false
	}
	
	public function fromObjectImport( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		// The data is needed the first time it saves the object from import, after that it goes away
		if ( !dbo.animations ) {
			Log.out( "Animation.fromObjectImport - Failed test dbo.animations dbo: " + JSON.stringify( dbo ), Log.ERROR );
			return;
		}
		
		loadFromInfo( dbo );
	}
	
	public function fromObject( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		if ( !dbo.animations ) {
			Log.out( "Animation.fromObject - Failed test !dbo.animations dbo: " + JSON.stringify( dbo ), Log.ERROR );
			return;
		}
		
		loadFromInfo( dbo );
	}
	
	override public function save():void {
		if ( !Globals.isGuid( guid ) ) {
			Log.out( "Animation.save - NOT Saving INVALID GUID: " + guid, Log.WARN );
			return;
		}
		if ( changed )
			super.save();
	}
	
	override protected function toObject():void {
		// just use the dbo as it is at base level
		// but need to refresh
		// permissions?
		
		if ( _sound )
			dbo.sound = _sound.toObject()
		if ( _transforms && _transforms.length )
			dbo.animations = getAnimations()
		if ( _attachments && _attachments.length )
			dbo.attachments = getAttachments()

		dbo.clipVelocity = clipVelocity;
		//Log.out( "Animation.toObject - clipVelocity: " + clipVelocity);
		dbo.speedMultiplier = speedMultiplier;
		//Log.out( "Animation.toObject - speedMultiplier: " + speedMultiplier);
	}
	
	private function getAttachments():Object {
		var attachments:Array = new Array();
		for each ( var aa:AnimationAttachment in _attachments ) {
			var aao:Object = aa.toObject()
			attachments.push( aao )
		}
		return attachments
	}
	
	private function getAnimations():Object {
		var transforms:Array = new Array();
		for ( var i:int; i < _transforms.length; i++ ) {
			var at:AnimationTransform = _transforms[i]
			var ato:Object = at.toObject()
			transforms.push( ato )
		}
		return transforms
	}

	// Only attributes that need additional handling go here.
	public function loadFromInfo( $info:Object ):void {
		
		if ( $info.sound ) 
			_sound = new AnimationSound( this, $info.sound )

		
		if ( $info.attachments ) {
			_attachments = new Vector.<AnimationAttachment>;
			for each ( var attachmentObj:Object in $info.attachment )
			{
				_attachments.push( new AnimationAttachment( attachmentObj ) );				
			}
		}
		
		if ( $info.animations ) {
			_transforms = new Vector.<AnimationTransform>;
			for each ( var transformObj:Object in $info.animations )
				_transforms.push( new AnimationTransform( transformObj ) );				
		}
		
		if ( !$info.owner )
			$info.owner = Network.PUBLIC;

		if ( !$info.permissions )
			$info.permissions = new Object();
		
		// the permission object is just an encapsulation of the permissions section of the object
		_permissions = new PermissionsBase( dbo );

		if ( $info.clipVelocity )
			clipVelocity = $info.clipVelocity;
		if ( $info.speedMultiplier )
			speedMultiplier = $info.speedMultiplier;

		//Log.out( "Animation.loadFromInfo - clipVelocity: " + clipVelocity);
		//Log.out( "Animation.loadFromInfo - speedMultiplier: " + speedMultiplier);

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
	public function play( $owner:VoxelModel, $scale:Number ):void {
		//Log.out( "Animation.play - name: " + _name );
		if ( _sound )
			_sound.play( $owner, $scale );
			
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


}
}
