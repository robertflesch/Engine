/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{

import flash.net.URLLoaderDataFormat;
import flash.utils.Dictionary;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.events.SoundEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.Block;
import com.voxelengine.worldmodel.models.makers.ModelLibrary;
import com.voxelengine.utils.StringUtils;

/**
 * ...
 * @author Bob
 */
public class AnimationCache
{
	// This should be a list so that it can be added to easily, this is hard coded.
	static public const MODEL_DRAGON_12:String =  "MODEL_DRAGON_12";
	static public const MODEL_PROPELLER:String =  "MODEL_PROPELLER";
	static public const MODEL_QUADRUPED:String =  "MODEL_QUADRUPED";

    static public const BIGDB_TABLE_ANIMATIONS:String = "animations";
    static public const BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER:String = "owner";


    static public const MODEL_UNKNOWN:String =  "MODEL_UNKNOWN";
	
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _animations:Dictionary = new Dictionary();
	static private var _block:Block = new Block();

	public function AnimationCache() {}
	
	static public function init():void {
		AnimationEvent.addListener( ModelBaseEvent.REQUEST, 		request );
        AnimationEvent.addListener( ModelBaseEvent.REQUEST_TYPE,	requestType );
		AnimationEvent.addListener( ModelBaseEvent.DELETE, 			deleteHandler );
		AnimationEvent.addListener( ModelBaseEvent.UPDATE_GUID, 	updateGuid );		
		AnimationEvent.addListener( ModelBaseEvent.SAVE, 			save );
		AnimationEvent.addListener( ModelBaseEvent.CLONE, 			clone );

		PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
		PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  public function AnimationEvent( $type:String, $series:int, $modelGuid:String, , $aniGuid:String, $ani:Animation, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
	/////////////////////////////////////////////////////////////////////////////////////////////
    static private var _initializedPublic:Boolean;
    static private var _initializedPrivate:Boolean;

    // This loads the first 100 objects from the users inventory OR the public inventory
    // TODO - NEED TO ADD HANDLER WHEN MORE THAN 100 ARE NEEDED - RSF 9.14.2017
    static private function requestType( $mme:AnimationEvent ):void {

        //Log.out( "ModelMetadataCache.requestType  owningModel: " + $mme.modelGuid, Log.WARN );
        // For each one loaded this will send out a new ModelMetadataEvent( ModelBaseEvent.ADDED, $vmm.guid, $vmm ) event
        if ( false == _initializedPublic && $mme.modelGuid == Network.PUBLIC ) {
            PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, $mme.series, BIGDB_TABLE_ANIMATIONS, Network.PUBLIC, null, BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER ) );
            _initializedPublic = true;
        }

        if ( false == _initializedPrivate && $mme.modelGuid == Network.userId ) {
            PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST_TYPE, $mme.series, BIGDB_TABLE_ANIMATIONS, Network.userId, null, BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER ) );
            _initializedPrivate = true;
        }

        // This will return models already loaded.
        for each ( var ani:Animation in _animations ) {
            if ( ani && ani.owner == $mme.modelGuid ) {
                //Log.out( "ModelMetadataCache.requestType RETURN  " +  ani.owner + " ==" + $mme.modelGuid + "  guid: " + ani.guid + "  desc: " + ani.description , Log.WARN );
                AnimationEvent.create( ModelBaseEvent.RESULT, $mme.series, "", ani.guid, ani );
            }
            else {
                if ( ani )
                    Log.out( "AnimationCache.requestType REJECTING  " +  ani.owner + " !=" + $mme.modelGuid + "  guid: " + ani.guid + "  desc: " + ani.description , Log.WARN );
                else
                    Log.out( "AnimationCache.requestType REJECTING null object: ", Log.WARN );
            }
        }
    }



	static private function request( $ame:AnimationEvent ):void 
	{   
		if ( null == $ame.aniGuid || null == $ame.modelGuid ) {
			Log.out( "AnimationCache.request guid rquested is NULL: ", Log.WARN );
			return;
		}
		//Log.out( "AnimationCache.request modelGuid: " + $ame.modelGuid + "  aniGuid: " + $ame.aniGuid, Log.INFO );
		var ani:Animation = _animations[$ame.aniGuid];
		if ( null == ani ) {
			if (_block.has($ame.aniGuid))
				return;
			_block.add($ame.aniGuid);

			if ( true == Globals.online && $ame.fromTable )
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ame.series, BIGDB_TABLE_ANIMATIONS, $ame.aniGuid, null, null, URLLoaderDataFormat.TEXT, $ame.modelGuid ) );
			else	
				PersistenceEvent.dispatch( new PersistenceEvent( PersistenceEvent.LOAD_REQUEST, $ame.series, Globals.ANI_EXT, $ame.aniGuid, null, null, URLLoaderDataFormat.TEXT, $ame.modelGuid ) );
		}
		else
			AnimationEvent.create( ModelBaseEvent.RESULT, $ame.series, $ame.modelGuid, $ame.aniGuid, ani );
	}

	static private function loadSucceed( $pe:PersistenceEvent):void
	{
		if ( Globals.ANI_EXT != $pe.table && BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;

		var ani:Animation =  _animations[$pe.guid];
		if ( null != ani ) {
			// we already have it, publishing this results in duplicate items
			//AnimationEvent.create( ModelBaseEvent.RESULT, $pe.series, $pe.other, $pe.guid, ani );
			Log.out( "AnimationCache.loadSucceed - attempting to load duplicate AnimationC guid: " + $pe.guid, Log.WARN );
			return;
		}

		if ( $pe.dbo ) {
			ani = new Animation($pe.guid, $pe.dbo, null);
			add( $pe, ani );
		} else if ( $pe.data ) {
			var fileData:String = String( $pe.data );
			fileData = StringUtils.trim(fileData);
			var newObjData:Object = JSONUtil.parse( fileData, $pe.guid + $pe.table, "AnimationCache.loadSucceed" );
			if ( null == newObjData ) {
				Log.out( "AnimationCache.loadSucceed - error parsing animation info on import. guid: " + $pe.guid, Log.ERROR );
				AnimationEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.other, $pe.guid, null );
				return;
			}
			ani = new Animation($pe.guid, null, newObjData );
			add( $pe, ani );
			if ( _block.has( $pe.guid ) )
				_block.clear( $pe.guid )
		} else {
			Log.out( "AnimationCache.loadSucceed ERROR NO DBO OR DATA " + $pe.toString(), Log.ERROR );
			AnimationEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null );
		}
	}

	static private function clone( $ae:AnimationEvent ):void {
		var ani:Animation =  _animations[$ae.aniGuid];
		if ( null == ani ) {
			_animations[$ae.aniGuid] = $ae.ani;
            $ae.ani.changed = true;
            $ae.ani.save();
			//AnimationEvent.create( ModelBaseEvent.ADDED, $ae.series, $ae.modelGuid, $ae.aniGuid, $ae.ani );
		}
	}

	static private function add($pe:PersistenceEvent, $ani:Animation ):void
	{ 
		if ( null == $ani || null == $pe.guid ) {
			Log.out( "AnimationCache.Add trying to add NULL animations or guid", Log.WARN );
			return;
		}
        //Log.out( "AnimationCache.add name: " + $ani.name + "\t Owner: " + $ani.owner + "\t Desc: " + $ani.description  + "\t Class: " + $ani.animationClass + "  guid: " + $ani.guid );

		var ani:Animation =  _animations[$ani.guid];
		if ( null == ani ) {
			_animations[$ani.guid] = $ani;
			AnimationEvent.create( ModelBaseEvent.RESULT, $pe.series, $pe.other, $ani.guid, $ani );
		}
	}
	
	static private function loadFailed( $pe:PersistenceEvent ):void
	{
		if ( Globals.ANI_EXT != $pe.table && BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		Log.out( "AnimationCache.loadFailed " + $pe.toString(), Log.ERROR );
		AnimationEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null );
	}
	
	static private function loadNotFound( $pe:PersistenceEvent):void
	{
		if ( Globals.ANI_EXT != $pe.table && BIGDB_TABLE_ANIMATIONS != $pe.table )
			return;
		if ( _block.has( $pe.guid ) )
			_block.clear( $pe.guid );
		Log.out( "AnimationCache.loadNotFound " + $pe.toString(), Log.ERROR );
		AnimationEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.series, $pe.table, $pe.guid, null );
	}

	static private function save(e:AnimationEvent):void {
		for each ( var ani:Animation in _animations )
			if ( ani )
				ani.save();
	}

	static public function requestAnimationClass( $modelClass:String ):String {
		var modelClass:Class = ModelLibrary.getAsset( $modelClass );
		return modelClass.getAnimationClass();
	}

	static private function deleteHandler( $ae:AnimationEvent ):void {
		var anim:Animation = _animations[$ae.aniGuid];
		if ( anim ) {
			_animations[$ae.aniGuid] = null;
			if ( anim.animationSound ) {
				anim.animationSound.reset();
				SoundEvent.create( ModelBaseEvent.DELETE, 0, anim.animationSound.guid, null );
			}
		}
		PersistenceEvent.create( PersistenceEvent.DELETE_REQUEST, 0, BIGDB_TABLE_ANIMATIONS, $ae.aniGuid, null );
	}

	static private function updateGuid( $ae:AnimationEvent ):void {
		// Make sure this is saved correctly
		var guidArray:Array = $ae.aniGuid.split( ":" );
		var oldGuid:String = guidArray[0];
		var newGuid:String = guidArray[1];
		//Log.out( "AnimationCache.updateGuid - oldGuid: " + oldGuid + "  newGuid: " + newGuid, Log.WARN );
		var ani:Animation = _animations[oldGuid];
		if ( ani ) {
			_animations[oldGuid] = null;
			_animations[newGuid] = ani;
			//Log.out( "AnimationCache.updateGuid - updating oldGuid: " + oldGuid + "  newGuid: " + newGuid, Log.WARN );
		}
		else {
			_animations[newGuid] = ani;
			Log.out("AnimationCache.updateGuid - animation not found oldGuid: " + oldGuid + "  newGuid: " + newGuid, Log.ERROR);
		}
	}


}
}