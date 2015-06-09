/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.adobe.utils.Hex;
import com.voxelengine.pools.LightingPool;
import com.voxelengine.pools.OxelPool;
import flash.utils.ByteArray;
import flash.net.registerClassAlias;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.FlowInfo;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.OxelBitfields;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.TypeInfo;


/**
 * ...
 * @author Robert Flesch - RSF
 * OxelData is the byte level representation of the oxel
 */
public class OxelPersistance extends PersistanceObject
{
	// 1 meter stone cube is reference
	static private const compressedReferenceBA:ByteArray		= Hex.toArray( "78:da:cb:2c:cb:35:30:b0:48:61:00:02:96:7f:0c:60:90:c1:90:c0:c0:f0:1f:0a:18:a0:80:11:42:00:45:8c:a1:00:00:e2:da:10:a2" );
	//static private const referenceBA:ByteArray 					= Hex.toArray( "69:76:6d:30:30:38:64:00:00:00:00:04:fe:00:00:00:00:00:00:68:00:60:00:00:ff:ff:ff:ff:ff:ff:ff:ff:00:00:00:00:00:00:00:00:01:00:00:00:00:01:00:ff:ff:ff:33:33:33:33:33:33:33:33" );
	private	var	_statisics:ModelStatisics 						= new ModelStatisics();
	private var _oxel:Oxel;
	private var _loaded:Boolean;
	private	var _version:int;
	
	public	function set version(value:int):void  				{ _version = value; }
	public	function get version():int  						{ return _version; }
	public 	function get oxel():Oxel 							{ return _oxel; }
	public 	function get loaded():Boolean 						{ return _loaded; }
	public 	function set loaded(value:Boolean):void 			{ _loaded = value; }
	
	public function OxelPersistance( $guid:String ) {
		super( $guid, Globals.BIGDB_TABLE_OXEL_DATA );
		_loaded = false;
	}
	
	public function changeOxel( $modelGuid:String, $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean {
		var result:Boolean = _oxel.changeOxel( $modelGuid, $gc, $type, $onlyChangeType );
		if ( result )
			changed = true;
		return result;
	}
	
	public function save():void {
		if ( Globals.online && true == loaded && true == changed ) {
			//Log.out( "OxelData.save - Saving OxelData: " + guid  + " in table: " + table, Log.WARN );
			changed = false;
			addSaveEvents();
			if ( _dbo )
				toPersistance();
			else
				toObject();
				
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, table, guid, _dbo, _obj ) );
		}
		else
			Log.out( "OxelData.save - Not saving data, either offline or NOT changed or locked - guid: " + guid );
	}
	
	public function createEditCursor():void {
		fromByteArray( compressedReferenceBA );
	}
	
	// creating a new copy of this
	override public function clone( $guid:String ):* {
		var vmd:OxelPersistance = new OxelPersistance( $guid );
		vmd._dbo = null; // Can I just reference this? They are pointing to same object
		var ba:ByteArray = toByteArray( oxel );
		vmd.fromByteArray( ba );
		return vmd;
	}
	
	public function toPersistance():void { 
		_dbo.ba			= toByteArray( oxel );
	}
	public function toObject():void { 
		var ba:ByteArray = toByteArray( oxel );
		_obj = { ba: ba	}
	}
		
	// FROM Persistance
	public function fromPersistance( $dbo:DatabaseObject ):void {
		_dbo			= $dbo;
		fromByteArray( $dbo.ba );
	}
	
	// loading from file data
	public function fromObject( $object:Object, $ba:ByteArray ):void {		
		_dbo			= null;
		// $object data not used here
		fromByteArray( $ba );
	}
	
	
	// Make sense, called from for Makers
	private function extractVersionInfo( $ba:ByteArray ):void {
		$ba.position = 0;
		// Read off first 3 bytes, the data format
		var format:String = readFormat($ba);
		if ("ivm" != format)
			throw new Error("OxelData.extractVersionInfo - Exception - unsupported format: " + format );
		
		// Read off next 3 bytes, the data version
		_version = readVersion($ba);
		// Read off next byte, the manifest version
		$ba.readByte();
		Log.out("OxelData.extractVersionInfo - version: " + _version );

		// This reads the format info and advances position on byteArray
		function readFormat($ba:ByteArray):String
		{
			var format:String;
			var byteRead:int = 0;
			byteRead = $ba.readByte();
			format = String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			format += String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			format += String.fromCharCode(byteRead);
			
			return format;
		}
		
		// This reads the version info and advances position on byteArray
		function readVersion($ba:ByteArray):int
		{
			var version:String;
			var byteRead:int = 0;
			byteRead = $ba.readByte();
			version = String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			version += String.fromCharCode(byteRead);
			byteRead = $ba.readByte();
			version += String.fromCharCode(byteRead);
			
			return int(version);
		}
	}
		
	public function fromByteArray($ba:ByteArray):void {
	
		try { $ba.uncompress(); }
		catch (error:Error) { Log.out( "OxelDataCache.loadSucceed - Was expecting compressed data " + guid, Log.WARN ); }
		$ba.position = 0;
		
		extractVersionInfo( $ba );
		// how many bytes is the modelInfo
		var strLen:int = $ba.readInt();
		// read off that many bytes, even though we are using the data from the modelInfo file
		var modelInfoJson:String = $ba.readUTFBytes( strLen );
		if ( null == _oxel )
			_oxel = OxelPool.poolGet();
			
		// Read off 1 bytes, the root size
		var rootGrainSize:int = $ba.readByte();
		_statisics.gather( version, $ba, rootGrainSize);
		
		registerClassAlias("com.voxelengine.worldmodel.oxel.FlowInfo", FlowInfo);	
		registerClassAlias("com.voxelengine.worldmodel.oxel.Brightness", Lighting);	
		var gct:GrainCursor = GrainCursorPool.poolGet(rootGrainSize);
		gct.grain = rootGrainSize;
		if (Globals.VERSION_000 == version)
			oxel.readData( null, gct, $ba, _statisics );
		else
			oxel.readVersionedData( version, null, gct, $ba, _statisics );
		
		GrainCursorPool.poolDispose(gct);
		oxel.vertexMangerAssign( _statisics );
		oxel.lighting = LightingPool.poolGet( Lighting.defaultBaseLightAttn );
		oxel.buildQuadsFromLoadedData();
		_loaded = true;
		OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.RESULT_COMPLETE, 0, guid, this ) );
	}
	
	static public function toByteArray( $oxel:Oxel ):ByteArray {
		var ba:ByteArray = new ByteArray();
		writeVersionedHeader( ba );
		//writeManifest( ba );
		// VERSION_008 no longer uses embedded manifest.
		writeManifest( ba );
		ba = $oxel.toByteArray( ba );
		ba.compress();
		return ba;
		
		function writeManifest( $ba:ByteArray ):void {
			
			// Always write the manifest into the IVM.
			/* ------------------------------------------
			   0 unsigned char model info version - 100 currently
			   next byte is size of model json
			   n+1...  is model json
			   ------------------------------------------ */
			$ba.writeByte(Globals.MANIFEST_VERSION);
//			var obj:Object = new Object();
//			buildExportObject( obj );
//			var json:String = JSON.stringify( obj );
//			Log.out( "VoxelModel.writeManifest json: " + json, Log.WARN );			
			$ba.writeInt( 0 );
//			$ba.writeUTFBytes( json );
		}
	}
	
	static private function writeVersionedHeader( $ba:ByteArray):void {
		/* ------------------------------------------
		   0 char 'i'
		   1 char 'v'
		   2 char 'm'
		   3 char '0' (zero) major version
		   4 char '' (0-9) minor version
		   5 char '' (0-9) lesser version
		   ------------------------------------------ */
		$ba.writeByte('i'.charCodeAt());
		$ba.writeByte('v'.charCodeAt());
		$ba.writeByte('m'.charCodeAt());
		var outVersion:String = zeroPad( Globals.VERSION, 3 );
		$ba.writeByte(outVersion.charCodeAt(0));
		$ba.writeByte(outVersion.charCodeAt(1));
		$ba.writeByte(outVersion.charCodeAt(2));

		function zeroPad(number:int, width:int):String {
		   var ret:String = ""+number;
		   while( ret.length < width )
			   ret="0" + ret;
		   return ret;
		}
	}
	
	private function validateOxel( $ba:ByteArray, $currentGrain:int):ByteArray {
		var faceData:uint = $ba.readUnsignedInt();
		var type:uint;
		if ( version <= Globals.VERSION_006 )
			type = OxelBitfields.typeFromRawDataOld(faceData);
		else {  //_version > Globals.VERSION_006
			var typeData:uint = $ba.readUnsignedInt();
			type = OxelBitfields.type1FromData(typeData);
		}
		
		if (OxelBitfields.data_is_parent(faceData))
		{
			$currentGrain--;
			for (var i:int = 0; i < 8; i++)
			{
				validateOxel($ba, $currentGrain);
			}
			$currentGrain++;
		}
		else
		{
			if (!TypeInfo.typeInfo[type])
			{
				trace("unknown grain of - unknown key: " + type);
				$ba.position -= 4;
				$ba.writeInt(TypeInfo.RED);
				trace("set unknown grain to RED: " + type);
			}
		}
		
		return $ba;
	}
	/*
	// legacy function for reference
	static public function extractModelInfo( $ba:ByteArray ):Object {

		// how many bytes is the modelInfo
		var strLen:int = $ba.readInt();
		// read off that many bytes
		var modelInfoJson:String = $ba.readUTFBytes( strLen );
		//Log.out( "ModelMakerBase.modelInfoFromByteArray - STRING modelInfo: " + modelInfoJson,	Log.WARN );
		// create the modelInfo object from embedded metadata
		modelInfoJson = decodeURI(modelInfoJson);
		var jsonResult:Object = JSON.parse(modelInfoJson);
		return jsonResult;		
		
	}
	*/
	
}
}

