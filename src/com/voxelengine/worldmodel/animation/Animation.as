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
import com.voxelengine.events.SoundEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.PermissionsBase;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.animation.AnimationCache;
import com.voxelengine.worldmodel.animation.AnimationSound;
import com.voxelengine.worldmodel.models.SecureNumber;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;

import playerio.DatabaseObject;
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.PersistenceObject;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class Animation extends PersistenceObject
{
	static private const ANIMATION_STATE:String = "state";
	static private const ANIMATION_ACTION:String = "action";
	
	//private var _loaded:Boolean = false;
	private var _transforms:Vector.<AnimationTransform>;
	private var _animationSound:AnimationSound;
	private var _permissions:PermissionsBase;
	private var  _clipVelocity:SecureNumber 		= new SecureNumber( 0.95 );
	private var  _speedMultiplier:SecureNumber 		= new SecureNumber( 0.95 );

	public function get clipVelocity():Number  					{ return _clipVelocity.val; }
	public function set clipVelocity($value:Number):void  		{ _clipVelocity.val = $value; }

	public function get speedMultiplier():Number  					{ return _speedMultiplier.val; }
	public function set speedMultiplier($value:Number):void  		{ _speedMultiplier.val = $value; }

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
	public function get animationSound():AnimationSound { return _animationSound; }
	public function set animationSound($val:AnimationSound ):void  { _animationSound = $val; }
	override public function set guid( $newGuid:String ):void {
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		AnimationEvent.create( ModelBaseEvent.UPDATE_GUID, 0, animationClass, oldGuid + ":" + $newGuid, null );
		changed = true;
	}

	override public function clone( $modelGuid:String ):* {
		var newAni:Animation = new Animation( Globals.getUID(), null, dbo, _animationSound );
		AnimationEvent.create( ModelBaseEvent.CLONE, 0, $modelGuid, newAni.guid, newAni );
		return newAni;
	}

	public function Animation( $guid:String, $dbo:DatabaseObject, $importedData:Object, $animationSound:AnimationSound = null ):void {
		super( $guid, AnimationCache.BIGDB_TABLE_ANIMATIONS );
		if ( null == $dbo ) {
			assignNewDatabaseObject();
		} else {
			dbo = $dbo;
		}
		if ( $animationSound ) {
			_animationSound = $animationSound.clone(Globals.getUID());
			if ( $importedData.sound )
				delete $importedData.sound;
		}

		init( $importedData );

	}

	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		dbo.name = "Default";
		dbo.description = "Enter description here";
		dbo.type =  ANIMATION_STATE;
		dbo.owner = Network.userId;
	}

	override public function save( $validateGuid:Boolean = true ):Boolean {
		var result:Boolean = super.save( $validateGuid );
		if ( _animationSound )
			_animationSound.save();
		return result;
	}
	private function init( $newData:Object = null ):void {

		if ($newData) {
			mergeOverwrite($newData);
		}

		if ( !owner )
			dbo.owner = Network.PUBLIC;

		// These don't appear to DO anything... they gather data that is not used
		//Region.currentRegion.modelCache.requestModelInfoByModelGuid( owningModel );
		//Region.currentRegion.modelCache.instancesOfModelGet( owningModel );

		if ( dbo.sound ) {
            _animationSound = null;
            SoundEvent.addListener( ModelBaseEvent.ADDED, soundAdded );
            SoundEvent.addListener( ModelBaseEvent.RESULT, soundAdded );
            if ( dbo.sound.guid )
                SoundEvent.create( ModelBaseEvent.REQUEST, 0, dbo.sound.guid );
            else
                SoundEvent.create( ModelBaseEvent.REQUEST, 0, dbo.sound.name, null, false );
        }

		if ( dbo.clipVelocity )
			clipVelocity = dbo.clipVelocity;
		if ( dbo.speedMultiplier )
			speedMultiplier = dbo.speedMultiplier;

		if ( dbo.animations ) {
			_transforms = new Vector.<AnimationTransform>;
			for each ( var transformObj:Object in dbo.animations )
				_transforms.push( new AnimationTransform( transformObj ) );
		}

		// the permission object is just an encapsulation of the permissions section of the object
		_permissions = new PermissionsBase();
		_permissions.fromObject( this );
	}

    private function soundAdded( $se:SoundEvent ):void {
        if ( ModelMakerBase.isImporting )
            SoundEvent.addListener( ModelBaseEvent.UPDATE_GUID_COMPLETE, updateSoundGuid );
        SoundEvent.removeListener( ModelBaseEvent.ADDED, soundAdded );
        SoundEvent.removeListener( ModelBaseEvent.RESULT, soundAdded );
        _animationSound = $se.snd;
        if ( dbo.sound.soundRangeMax )
            _animationSound.soundRangeMax = dbo.sound.soundRangeMax;
        if ( dbo.sound.soundRangeMin )
            _animationSound.soundRangeMin = dbo.sound.soundRangeMin;
    }

	private function updateSoundGuid( $se:SoundEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $se.guid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		if ( _animationSound ){
			if ( _animationSound.guid == oldGuid || _animationSound.guid == newGuid ) {
				SoundEvent.removeListener( ModelBaseEvent.UPDATE_GUID, 	updateSoundGuid );
				changed = true;
				save();
			}
		}
	}

	public function createBackCopy():Object {
		// force the data from the dynamic classes into the object
		// this give me an object that holds all of the data for the animation
		var backupInfo:Object = {};
		backupInfo.name 			= String( dbo.name );
		backupInfo.description 		= String( dbo.description );
		backupInfo.owner 			= String( dbo.owner );
		backupInfo.type 			= String( dbo.type );
		backupInfo.animationClass 	= String( dbo.animationClass );
		if ( _animationSound )
			backupInfo.sound = _animationSound.sound;
		if ( _transforms && _transforms.length )
			backupInfo.animations = getAnimations();
		// TODO - add clip velocity and speed multiplier
//		dbo.clipVelocity = clipVelocity;
//		dbo.speedMultiplier = speedMultiplier;
		return backupInfo
	}
	
	public function restoreFromBackup( $info:Object ):void {
		// if you just assign name, then it shares the same object
		// we want a new object in this case
		dbo.name 			= String( $info.name );
		dbo.description 	= String( $info.description );
		dbo.owner 			= String( $info.owner );
		dbo.type 			= String( $info.type );
		dbo.animationClass = String( $info.animationClass );
		changed = false;
		throw new Error( "Animation.restoreFromBackup - REFACTOR");
//		loadFromInfo( $info )
	}
	
	override protected function toObject():void {
		// just use the dbo as it is at base level
		// but need to refresh
		// permissions?

		if ( _animationSound )
			dbo.sound = _animationSound.toAnimationData();
		if ( _transforms && _transforms.length )
			dbo.animations = getAnimations();

		dbo.clipVelocity = clipVelocity;
		//Log.out( "Animation.toObject - clipVelocity: " + clipVelocity);
		dbo.speedMultiplier = speedMultiplier;
		//Log.out( "Animation.toObject - speedMultiplier: " + speedMultiplier);
	}
	
	private function getAnimations():Object {
		var transforms:Array = [];
		for ( var i:int=0; i < _transforms.length; i++ ) {
			var at:AnimationTransform = _transforms[i];
			var ato:Object = at.toObject();
			transforms.push( ato );
		}
		return transforms;
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
		if ( $json.animationSound ) {
			_animationSound = new AnimationSound();
			_animationSound.init( $json.animationSound );
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

	public function fromPersistence( $dbo:DatabaseObject ):void {
		var ba:ByteArray = _metadata.fromPersistence( $dbo );
		ba.position = 0;
		// how many bytes is the animation
		var strLen:int = ba.readInt();
		// read off that many bytes
		var json:String = ba.readUTFBytes( strLen );
		Log.out( "Animation.fromPersistence - name: " + metadata.name + "   "  + json );
		var jsonResult:Object = JSONUtil.parse( json, _metadata.guid, "Animation.fromPersistence" );
		fromJSON( jsonResult );
	}
*/
	/*
	private function getJSON( obj:Object ):void {
		if ( _animationSound )
			_animationSound.getJSON( obj );
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
		if ( _animationSound )
			_animationSound.play( $scale );

		// TODO thinking for each transform, add attachments

//		if ( _attachments && 0 < _attachments.length ) {
//			for each ( var aa:AnimationAttachment in _attachments ) {
//				var cm:VoxelModel = $owningModel.childFindByName( aa.attachsTo );
//				if ( cm )
//					aa.create( cm );
//			}
//		}
	}
	
	public function stop( $owner:VoxelModel ):void {
		if ( _animationSound )
			_animationSound.stop();
			
//		if ( _attachments && 0 < _attachments.length ) {
//			for each ( var aa:AnimationAttachment in _attachments ) {
//				var cm:VoxelModel = $owningModel.childFindByName( aa.attachsTo );
//				if ( cm )
//					aa.detach();
//			}
//		}
	}
	
	public function update( $val:Number ):void {
		if ( _animationSound )
			_animationSound.update( $val / 3 );
	}


}
}
