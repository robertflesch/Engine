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
import com.voxelengine.worldmodel.models.ModelMetadata;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.JPEGEncoderOptions;
import flash.display.Loader;
import flash.display.LoaderInfo
import flash.events.Event;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.net.URLLoaderDataFormat;

import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.worldmodel.PermissionsModel;


public class ModelMetadata extends PersistenceObject
{
	private const DEFAULT_BOUND:int                       = 10;
	private var _permissions:PermissionsModel;
	private var _thumbnail:BitmapData;
	
	public function get permissions():PermissionsModel 			{ return _permissions; }
	public function set permissions( val:PermissionsModel):void	{ _permissions = val; changed = true; }
	
	public function get name():String  						{ return dbo.name; }
	public function set name(value:String):void  			{ dbo.name = value; changed = true; }
	
	public function get description():String  				{ return dbo.description; }
	public function set description(value:String):void  	{ dbo.description = value; changed = true; }
	
	public function get owner():String  					{ return dbo.owner; }
	public function set owner(value:String):void  			{ dbo.owner = value; changed = true; }
	
	public function get animationClass():String 			{ return dbo.animationClass; }
	public function set animationClass(value:String):void  	{ dbo.animationClass = value; changed = true; }

	public function get version():int 							{ return dbo.version; }
	public function set version( value:int ):void				{ dbo.version = value; }

	public function get bound():int 							{ return dbo.bound; }
	public function set bound( value:int ):void					{
		if ( dbo.bound != value ) {
			changed = true;
			dbo.bound = value;
		} }

	public function get creator():int 							{ return dbo.creator; }

	public function get thumbnail():BitmapData 				{ return _thumbnail; }
	public function set thumbnail(value:BitmapData):void 	{ _thumbnail = value; changed = true; }

	private var _thumbnailLoaded:Boolean;
	public function get thumbnailLoaded():Boolean 			{ return _thumbnailLoaded; }
	public function set thumbnailLoaded($val:Boolean):void  { _thumbnailLoaded = $val; }

	public function toString():String {
		return "name: " + name + "  description: " + description + "  guid: " + guid + "  owner: " + owner;
	}
	
	public function ModelMetadata( $guid:String, $dbo:DatabaseObject = null, $newData:Object = null ) {
		super( $guid, Globals.BIGDB_TABLE_MODEL_METADATA );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else {
			dbo = $dbo;
		}

		init( this, $newData );

		if ( "EditCursor" != guid ) {
			ModelMetadataEvent.addListener(ModelBaseEvent.SAVE, saveEvent);
			OxelDataEvent.addListener( OxelDataEvent.OXEL_READY, oxelReady );
			ModelMetadataEvent.addListener( ModelBaseEvent.CHANGED, metadataChanged );
		}

		function oxelReady( $ode:OxelDataEvent ):void {
			if ( $ode.modelGuid == guid ) {
				if ($ode.oxelData && $ode.oxelData.bound) {
					bound = $ode.oxelData.bound;
				}
				save();
				OxelDataEvent.removeListener( OxelDataEvent.OXEL_READY, oxelReady );
			}
		}

		function init( $modelMetadata:ModelMetadata, $newData:Object = null ):void {

			if ( $newData )
				mergeOverwrite( $newData );

			// the permission object is just an encapsulation of the permissions section of the object
			_permissions = new PermissionsModel( dbo );

			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, bitmapLoaded );
			if ( dbo.thumbnail ) {
				loader.loadBytes( dbo.thumbnail );
			}
			else {
				loader.load( new URLRequest( Globals.texturePath + "NoImage128.png" ) )
			}

			function bitmapLoaded(event:Event):void {
				//Log.out( "ModelMetadata.init.bitmapLoaded for guid: " + guid, Log.WARN );
				loader.contentLoaderInfo.removeEventListener(Event.INIT, bitmapLoaded );
				// Bypass setter to keep it from getting marked as changed
				_thumbnail = Bitmap( LoaderInfo(event.target).content).bitmapData;
				thumbnailLoaded = true;
				ModelMetadataEvent.create( ModelMetadataEvent.BITMAP_LOADED, 0, guid, $modelMetadata );
			}
		}

	}

	private function metadataChanged( $mme:ModelMetadataEvent ):void {
		Log.out( "PanelModels.metaDataChanged - IS THIS NEEDED?", Log.WARN);
		if ( $mme.modelGuid == guid ) {
			Log.out( "ModelMetaData.changed - how to do update with new data?", Log.WARN );
			// or do I even need to?
		}
	}


	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		setToDefault();

		function setToDefault():void {
			dbo.hashTags = "#new";
			_thumbnail = null;
			animationClass = "";
			description = "Default";
			name = "Default";
			name = "Default";
			owner = "";
			version = Globals.VERSION;
			bound = DEFAULT_BOUND;
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
	private function saveEvent( $vmd:ModelMetadataEvent ):void {
		if ( guid != $vmd.modelGuid ) {
			//Log.out( "ModelMetadata.saveEvent - Ignoring save meant for other model my guid: " + guid + " target guid: " + $vmd.modelGuid, Log.WARN );
			return;
		}
		save();
	}

    override protected function toObject():void {
		//Log.out( "ModelMetadata.toObject", Log.WARN );
		if ( thumbnail )
			dbo.thumbnail 		= thumbnail.encode(new Rectangle(0, 0, 128, 128), new JPEGEncoderOptions() );
		else
			dbo.thumbnail = null;
	}


	public function cloneNew( $guid:String ):ModelMetadata {
		var newMM:ModelMetadata = new ModelMetadata( $guid, null, dbo );

		//TODO need handlers
		ModelMetadataEvent.create( ModelBaseEvent.CLONE, 0, newMM.guid, newMM );
		return newMM;
	}

	override public function clone( $newGuid:String ):* {
		var oldName:String = dbo.name;
		dbo.name = dbo.name + "_duplicate";
		var oldObj:String = JSON.stringify( dbo );
		dbo.name = oldName;

		var pe:PersistenceEvent = new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, 0, Globals.BIGDB_TABLE_MODEL_METADATA, $newGuid, null, oldObj, URLLoaderDataFormat.TEXT, guid )
		PersistenceEvent.dispatch( pe )
	}
}
}

