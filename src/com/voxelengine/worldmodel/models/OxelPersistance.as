/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import playerio.DatabaseObject;

import com.adobe.utils.Hex;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.pools.GrainCursorPool;
import com.voxelengine.pools.LightingPool;
import com.voxelengine.pools.OxelPool;
import com.voxelengine.renderer.Chunk;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.FlowInfo;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.OxelBitfields;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;


/**
 * ...
 * @author Robert Flesch - RSF
 * OxelPersistance is the persistance wrapper for the oxel level data.
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
	private var _topMostChunk:Chunk;
	private var _parent:ModelInfo
	private var _ba:ByteArray
	
	private function get ba():ByteArray 						{ return _ba }
	
	public function get parent():ModelInfo						{ return _parent }
	public function set parent( $val:ModelInfo ):void			{ _parent = $val }
	public 	function get oxel():Oxel 							{ return _oxel; }
	public 	function get loaded():Boolean 						{ return _loaded; }
	public 	function set loaded( $val:Boolean):void 			{ _loaded = $val; }
	
	public function OxelPersistance( $guid:String ) {
		//Log.out( "OxelPersistance: " + $guid, Log.WARN );
		super( $guid, Globals.BIGDB_TABLE_OXEL_DATA );
		_loaded = false;
	}
	
	override public function release():void {
		_statisics.release();
		_oxel.release();
		_topMostChunk.release();
		super.release();
	}
	
	public function draw( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean, $isAlpha:Boolean ):void {
		if ( $isAlpha )
			_topMostChunk.drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		else
			_topMostChunk.drawNew( $mvp, $vm, $context, $selected, $isChild );
	}

	public function createEditCursor():void {
		_ba = compressedReferenceBA
		fromByteArray()
	}
	/*
	// creating a new copy of this
	override public function clone( $guid:String ):* {
		var vmd:OxelPersistance = new OxelPersistance( $guid );
		vmd._dbo = null; // Can I just reference this? They are pointing to same object
		var ba:ByteArray = toByteArray( oxel );
		vmd.fromByteArray( ba );
		return vmd;
	}
	*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Chunk operations
	public function refreshFaces():void {
		_topMostChunk.refreshFaces();
	}
	
	public function update():void {
		if ( _topMostChunk && _topMostChunk.dirty ) {
			//if ( guid != EditCursor.EDIT_CURSOR )
			//	Log.out( "OxelPersistance.update - calling refreshQuads guid: " + guid, Log.WARN );
			_topMostChunk.refreshFaces();
			_topMostChunk.refreshQuads();
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// oxel operations
	public function changeOxel( $modelGuid:String, $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean {
		var result:Boolean = _oxel.changeOxel( $modelGuid, $gc, $type, $onlyChangeType );
		if ( result )
			changed = true;
		return result;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// persistance operations
	override public function save():void {
		if ( false == loaded || !Globals.isGuid( guid ) ) {
				//Log.out( "OxelPersistance.save - NOT Saving INVALID GUID: " + guid  + " in table: " + table, Log.WARN );
				return;
		}
		super.save();
	}
	
	override protected function toObject():void {
		//Log.out( "OxelPersistance.toObject", Log.WARN );
		if ( dbo.data )
			dbo.data.ba			= toByteArray( oxel );
		else	
			dbo.ba			= toByteArray( oxel );
	}
				
	// FROM Persistance
	
	public function fromObjectImport( $dbo:DatabaseObject ):void {
		dbo			= $dbo;
		_ba = $dbo.data.ba
		//fromByteArray();
	}
	public function fromObject( $dbo:DatabaseObject ):void {
		dbo			= $dbo;
		_ba = $dbo.ba 
		//fromByteArray();
	}
	
	// Make sense, called from for Makers
	private function extractVersionInfo( $ba:ByteArray ):void {
		$ba.position = 0;
		// Read off first 3 bytes, the data format
		var format:String = readFormat($ba);
		if ("ivm" != format)
			throw new Error("OxelPersistance.extractVersionInfo - Exception - unsupported format: " + format );
		
		// Read off next 3 bytes, the data version
		_version = readVersion($ba);
		// Read off next byte, the manifest version
		$ba.readByte();
		//Log.out("OxelPersistance.extractVersionInfo - version: " + _version );

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
	
	public function fromByteArray():void {

		//Log.out( "OxelPersistance.fromByteArray - guid: " + guid, Log.WARN );
		var time:int = getTimer();
		
		try { ba.uncompress(); }
		catch (error:Error) { Log.out( "OxelPersistance.fromByteArray - Was expecting compressed data " + guid, Log.WARN ); }
		ba.position = 0;
		
		extractVersionInfo( ba );
		// how many bytes is the modelInfo
		var strLen:int = ba.readInt();
		// read off that many bytes, even though we are using the data from the modelInfo file
		var modelInfoJson:String = ba.readUTFBytes( strLen );
		
		// Read off 1 bytes, the root size
		var rootGrainSize:int = ba.readByte();
		if ( null == _oxel )
			_oxel = Oxel.initializeRoot( rootGrainSize, Lighting.defaultBaseLightAttn ); // Lighting should be model or instance default lighting
		else 
			Log.out( "OxelPersistance.fromByteArray - Why does oxel exist?", Log.WARN );
			
		//_statisics.gather( version, ba, rootGrainSize);
		
		// TODO - do I need to do this everytime? or could I use a static initializer? RSF - 7.16.2015
		registerClassAlias("com.voxelengine.worldmodel.oxel.FlowInfo", FlowInfo);	
		registerClassAlias("com.voxelengine.worldmodel.oxel.Brightness", Lighting);	
		var gct:GrainCursor = GrainCursorPool.poolGet(rootGrainSize);
		if ( parent )
			Lighting.defaultBaseLightAttn = parent.baseLightLevel
		gct.grain = rootGrainSize;
		if (Globals.VERSION_000 == _version)
			oxel.readData( null, gct, ba, _statisics );
		else
			oxel.readVersionedData( _version, null, gct, ba, _statisics );
		GrainCursorPool.poolDispose(gct);
		//Log.out( "OxelPersistance.fromByteArray - readVersionedData took: " + (getTimer() - time), Log.WARN );
		
		_statisics.gather();
		_statisics.statsPrint();
		
		//Log.out( "OxelPersistance.fromByteArray - _statisics took: " + (getTimer() - time), Log.WARN );
		
		_topMostChunk = Chunk.parse( oxel, null );
		_loaded = true;
		//Log.out( "OxelPersistance.fromByteArray - DONE guid: " + guid + " took: " + (getTimer() - time), Log.WARN );
		
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
			$ba.writeInt( 0 );
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
		if ( _version <= Globals.VERSION_006 )
			type = OxelBitfields.typeFromRawDataOld(faceData);
		else {  //_version > Globals.VERSION_006
			var typeData:uint = $ba.readUnsignedInt();
			type = OxelBitfields.type1FromData(typeData);
		}
		
		if (OxelBitfields.dataIsParent(faceData))
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

