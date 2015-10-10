/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.PersistanceEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.JPEGEncoderOptions;
import flash.display.Loader;
import flash.display.LoaderInfo
import flash.events.Event;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.net.URLLoaderDataFormat;

import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.worldmodel.PermissionsBase;
import com.voxelengine.events.ModelBaseEvent;

/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class ModelMetadata extends PersistanceObject
{
	private var _permissions:PermissionsBase;
	private var _thumbnail:BitmapData;
	
	public function get permissions():PermissionsBase 			{ return _permissions; }
	public function set permissions( val:PermissionsBase):void	{ _permissions = val; changed = true; }
	
	public function get name():String  						{ return info.name; }
	public function set name(value:String):void  			{ info.name = value; changed = true; }
	
	public function get description():String  				{ return info.description; }
	public function set description(value:String):void  	{ info.description = value; changed = true; }
	
	public function get owner():String  					{ return info.owner; }
	public function set owner(value:String):void  			{ info.owner = value; changed = true; }
	
	public function get animationClass():String 			{ return info.animationClass; }
	public function set animationClass(value:String):void  	{ info.animationClass = value; changed = true; }
	
	public function get thumbnail():BitmapData 				{ return _thumbnail; }
	public function set thumbnail(value:BitmapData):void 	{ _thumbnail = value; changed = true; }

	private var			_thumbnailLoaded:Boolean
	public function get thumbnailLoaded():Boolean 			{ return _thumbnailLoaded; }
	
	public function toString():String {
		return "name: " + name + "  description: " + description + "  guid: " + guid + "  owner: " + owner;
	}
	
	static public function newObject():Object {
		var obj:Object = new DatabaseObject( Globals.BIGDB_TABLE_MODEL_METADATA, "0", "0", 0, true, null )
		obj.data = new Object()
		return obj
	}
	
	public function ModelMetadata( $newGuid:String ) {
		super( $newGuid, Globals.BIGDB_TABLE_MODEL_METADATA );
		if ( "EditCursor" != guid )
			ModelMetadataEvent.addListener( ModelBaseEvent.SAVE, saveEvent );
	}

	override public function set guid( $newGuid:String ):void { 
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null ) );
		changed = true;
	}
	
	
	override public function release():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.SAVE, saveEvent );
		//ModelMetadataEvent.removeListener( ModelBaseEvent.LOAD, 		load );
		
	}
	
	public function update( $vmm:ModelMetadata ):void {
		name 			= $vmm.name;
		description 	= $vmm.description;
		owner 			= $vmm.owner;
		thumbnail 		= $vmm.thumbnail;
		animationClass =  $vmm.animationClass;
Log.out( "ModelMetadata.update - How do I handle permissions here?", Log.WARN );
		//creator 		= $vmm.creator;
		//template		= $vmm.template;
		//templateGuid	= $vmm.templateGuid;
		//copy			= $vmm.copy;
		//copyCount		= $vmm.copyCount;
		//modify		= $vmm.modify;
		//transfer		= $vmm.transfer;
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

	override public function save():void {
		if ( Globals.isGuid( guid ) )
			return super.save();
		
		Log.out( "ModelMetadata.save - NOT Saving INVALID GUID: " + guid  + " in table: " + table, Log.WARN );
	}
	
	//////////////////////////////////////////////////////////////////
	// Persistance
	//////////////////////////////////////////////////////////////////
	override protected function toObject():void {
		//Log.out( "ModelMetadata.toObject", Log.WARN );
		if ( thumbnail )
			info.thumbnail 		= thumbnail.encode(new Rectangle(0, 0, 128, 128), new JPEGEncoderOptions() ); 
		else
			info.thumbnail = null;
	}
	

	// These two functions are slighting different in that the import uses
	// $dbo.data
	// and the read direct from persistance uses
	// $dbo directly
	// I abstract it away using the info object
	// it was needed to save the data in an abstract way.
	public function fromObjectImport( $dbo:Object ):void {
		dbo = $dbo as DatabaseObject;
		if ( !dbo.data ) {
			dbo.data = new Object();
			Log.out( "ModelMetaData.fromObjectImport - NO DBO or DBO data", Log.ERROR );
		}
		info = $dbo.data;	
		loadFromInfo( this );	
		changed = true;
	}

	public function fromObject( $dbo:DatabaseObject ):void {
		dbo = $dbo;
		info = $dbo;	
		
		loadFromInfo( this );	
	}
	
	private function loadFromInfo( $mm:ModelMetadata ):void {
		// the permission object is just an encapsulation of the permissions section of the object
		_permissions = new PermissionsBase( info );
		
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.INIT, bitmapLoaded );
		if ( info.thumbnail ) {
			loader.loadBytes( info.thumbnail );			
		}
		else {
			loader.load( new URLRequest( Globals.texturePath + "NoImage128.png" ) )
		}
		
		
		function bitmapLoaded(event:Event):void { 
			thumbnail = Bitmap( LoaderInfo(event.target).content).bitmapData 
			_thumbnailLoaded = true
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelMetadataEvent.BITMAP_LOADED, 0, guid, $mm ) )
		}
	}
	
	override public function clone( $newGuid:String ):* {
		toObject()
		var oldObj:String = JSON.stringify( info )

		var pe:PersistanceEvent = new PersistanceEvent( PersistanceEvent.LOAD_SUCCEED, 0, Globals.BIGDB_TABLE_MODEL_METADATA, $newGuid, null, oldObj, URLLoaderDataFormat.TEXT, guid )
		PersistanceEvent.dispatch( pe )
	}
}
}

