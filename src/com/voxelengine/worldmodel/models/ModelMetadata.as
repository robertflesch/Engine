/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{

import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.TextureLoadingEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TextureBank;
import com.voxelengine.worldmodel.models.ModelMetadata;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.net.URLLoaderDataFormat;
import flash.utils.ByteArray;

import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.worldmodel.PermissionsModel;



public class ModelMetadata extends PersistenceObject
{
    static public const BIGDB_TABLE_MODEL_METADATA:String = "modelMetadata";
    static public const BIGDB_TABLE_MODEL_METADATA_INDEX_OWNER:String = "owner";
    static public const BIGDB_TABLE_MODEL_METADATA_INDEX_CREATOR:String = "creator";

	private const DEFAULT_BOUND:int                       = 10;
	private var _permissions:PermissionsModel;
	private var _thumbnail:BitmapData;
	
	public function get permissions():PermissionsModel 			{ return _permissions; }
	public function set permissions( $val:PermissionsModel):void	{ _permissions = $val; changed = true; }
	
	public function get name():String  						{ return dbo.name; }
	public function set name($val:String):void  			{ dbo.name = $val; changed = true; }
	
	public function get description():String  				{ return dbo.description; }
	public function set description($val:String):void  		{ dbo.description = $val; changed = true; }
	
	public function get owner():String  					{ return dbo.owner; }
	public function set owner($val:String):void  			{ dbo.owner = $val; changed = true; }
	
	public function get animationClass():String 			{ return dbo.animationClass; }
	public function set animationClass($val:String):void  	{ dbo.animationClass = $val; changed = true; }

	public function get childOf():String 					{ return dbo.childOf; }
	public function set childOf($val:String):void  			{ dbo.childOf = $val; changed = true; }

	public function modelScalingVec3D():Vector3D 			{ return new Vector3D( dbo.modelScaling.x, dbo.modelScaling.y, dbo.modelScaling.z ); }
	public function modelScalingInfo():Object 				{ return dbo.modelScaling }
	public function get modelScaling():Object 				{ return dbo.modelScaling; }
	public function set modelScaling($val:Object):void  	{ dbo.modelScaling = $val; changed = true; }

	public function modelPositionVec3D():Vector3D 			{ return new Vector3D( dbo.modelPosition.x, dbo.modelPosition.y, dbo.modelPosition.z ); }
	public function modelPositionInfo():Object 			{ return dbo.modelPosition }
	public function get modelPosition():Object 				{ return dbo.modelPosition; }
	public function set modelPosition($val:Object):void  	{ dbo.modelPosition = $val; changed = true; }

	public function get version():int 						{ return dbo.version; }
	public function set version( $val:int ):void			{ dbo.version = $val; }

	public function get bound():int 						{ return dbo.bound; }
	public function set bound( $val:int ):void				{
		if ( dbo.bound != $val ) {
			//changed = true;
			dbo.bound = $val;
		} }

	public function get hashTags():String 					{ return dbo.hashTags; }
	public function set hashTags($val:String):void			{ dbo.hashTags = $val; changed = true }

	public function get thumbnail():BitmapData 				{ return _thumbnail; }
	public function set thumbnail($val:BitmapData):void 	{ _thumbnail = $val; changed = true; }

	private var _thumbnailLoaded:Boolean;
	public function get thumbnailLoaded():Boolean 			{ return _thumbnailLoaded; }
	public function set thumbnailLoaded($val:Boolean):void  { _thumbnailLoaded = $val; }

	public function toString():String {
		return "name: " + name + "  description: " + description + "  guid: " + guid + "  owner: " + owner;
	}
	
	public function ModelMetadata( $guid:String, $dbo:DatabaseObject = null, $newData:Object = null ) {
		super( $guid, BIGDB_TABLE_MODEL_METADATA );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else {
			dbo = $dbo;
		}

        // Need this temp so that I can pass "this" in imageLoad function
        var myMetaInfo:ModelMetadata = this;

		init( $newData );

		if ( "EditCursor" != guid ) {
            ModelMetadataEvent.addListener( ModelBaseEvent.CHANGED, metadataChanged );
		}

		function init( $newData:Object = null ):void {

			if ( $newData )
				mergeOverwrite( $newData );

			// the permission object is just an encapsulation of the permissions section of the object
			_permissions = new PermissionsModel( dbo, guid );


			if ( dbo.thumbnail ) {
				try {
                    var bmd:BitmapData = new BitmapData(128,128,false);
                    bmd.setPixels(new Rectangle(0, 0, 128, 128), dbo.thumbnail);
                    _thumbnail = bmd;
                    thumbnailLoaded = true;
                    ModelMetadataEvent.create( ModelMetadataEvent.BITMAP_LOADED, 0, guid, myMetaInfo );
                }
				catch (e:Error) {
                    loadNoImage();
                }
			}
			else {
				loadNoImage();
			}

            function loadNoImage():void {
                TextureLoadingEvent.addListener( TextureLoadingEvent.LOAD_SUCCEED, noImageLoaded );
				TextureLoadingEvent.create( TextureLoadingEvent.REQUEST, TextureBank.NO_IMAGE_128 );
            }

            function noImageLoaded( $tle:TextureLoadingEvent ):void {
				if ( TextureBank.NO_IMAGE_128 == $tle.name ) {
                    TextureLoadingEvent.removeListener( TextureLoadingEvent.LOAD_SUCCEED, noImageLoaded );
                    //Log.out("ModelMetadata.init.noImageLoaded: " + TextureBank.NO_IMAGE_128 + "  for guid: " + guid, Log.WARN);
                    _thumbnail = ($tle.data as Bitmap).bitmapData;
                    thumbnailLoaded = true;
					changed = true;
                    ModelMetadataEvent.create(ModelMetadataEvent.BITMAP_LOADED, 0, guid, myMetaInfo );
                    //      Log.out( "ModelMetadata.init.imageLoaded complete isDebug: " + Globals.isDebug + " + Capabilities.isDebugger: " + Capabilities.isDebugger, Log.WARN );
                }
            }
		}
	}

	private function metadataChanged( $mme:ModelMetadataEvent ):void {
		if ( $mme.modelGuid == guid ) {
			changed = true;
		}
	}

	public function setGeneratedData( $name:String, $owner:String ): void {
		dbo.name = $name;
		dbo.description = $name + " - GENERATED";
		dbo.owner = $owner;
	}

	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		setToDefault();

		function setToDefault():void {
			dbo.hashTags 		= "#new";
			_thumbnail 			= null;
			dbo.animationClass 	= "";
			dbo.description 	= "Default";
			dbo.name 			= "Default";
			dbo.owner 			= "";
			dbo.version 		= Globals.VERSION;
			dbo.bound 			= DEFAULT_BOUND;
		}
	}

	override public function set guid( $newGuid:String ):void { 
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		ModelMetadataEvent.create( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null );
	}
	
	
	override public function release():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.SAVE, saveEvent );
		ModelMetadataEvent.addListener( ModelBaseEvent.CHANGED, metadataChanged );
	}

	// This was private, force a message to be sent to it.
	// But the voxelModel has a handle to it, seems silly to have to propgate it every where, so its public
	private function saveEvent( $mmde:ModelMetadataEvent ):void {
        Log.out( "ModelMetadata.saveEvent - my guid: " + guid + " target guid: " + $mmde.modelGuid, Log.WARN );
		if ( guid != $mmde.modelGuid ) {
			//Log.out( "ModelMetadata.saveEvent - Ignoring save meant for other model my guid: " + guid + " target guid: " + $vmd.modelGuid, Log.WARN );
			return;
		}
		save();
	}

    override protected function toObject():void {
		//Log.out( "ModelMetadata.toObject", Log.WARN );
		if ( thumbnail )
			//dbo.thumbnail 		= thumbnail.encode(new Rectangle(0, 0, 128, 128), new JPEGEncoderOptions() );
            dbo.thumbnail 		= thumbnail.getPixels(new Rectangle(0, 0, 128, 128));
		else
			dbo.thumbnail = null;

		dbo.permissions = _permissions.toObject();
    }


	override public function clone( $guid:String ):* {
        var oldObj:String = JSON.stringify( dbo );
		var newData:Object = JSON.parse( oldObj );

        newData.owner = Network.userId;
		newData.hashTags = this.hashTags + "#cloned";
        newData.name = this.name;
        //newData.createdDate = new Date().toUTCString();
        var newModelMetadata:ModelMetadata = new ModelMetadata( $guid, null, newData );

Log.out( "ModelMetadata.clone - fix thumbnail", Log.WARN );
// TODO fix this
//        if ( thumbnailLoaded ) {
//            var bmd:BitmapData = new BitmapData(128, 128, false);
//            var ba:ByteArray = thumbnail.getPixels(new Rectangle(0, 0, 128, 128));
//            bmd.setPixels(new Rectangle(0, 0, 128, 128), ba );
//            newModelMetadata._thumbnail = bmd;
//            newModelMetadata.thumbnailLoaded = true;
//        }
//		else {
//            newModelMetadata.thumbnail = null;
//		}

        return newModelMetadata;
	}


}
}

