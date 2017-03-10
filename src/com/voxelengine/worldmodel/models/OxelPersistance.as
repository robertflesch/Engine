/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{

import com.voxelengine.pools.LightInfoPool;
import com.voxelengine.worldmodel.oxel.FlowInfo;

import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.LevelOfDetailEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.renderer.Chunk;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.OxelBitfields;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.EditCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.makers.OxelCloner;
import com.voxelengine.worldmodel.tasks.renderTasks.FromByteArray;


/**
 * ...
 * @author Robert Flesch - RSF
 * OxelPersistance is the persistance wrapper for the oxel level data.
 */
public class OxelPersistance extends PersistanceObject
{
	// 1 meter stone cube is reference
	static private var 	 _aliasInitialized:Boolean				= false; // used to only register class names once
	private var _initializeFacesAndQuads:Boolean				= true;
	
	public function get baseLightLevel():int 					{ return dbo.baseLightLevel; }
	public function set baseLightLevel( value:int ):void		{ dbo.baseLightLevel = value; }

	public function get bound():int 							{ return dbo.bound; }
	public function set bound( value:int ):void					{ dbo.bound = value; }

	public function get type():String 							{ return dbo.type; }
	public function set type( value:String ):void				{ dbo.type = value; }

	public function get ba():ByteArray 							{ return dbo.ba }
	public function set ba( $ba:ByteArray):void 				{ dbo.ba = $ba; }

	private var _lightInfo:LightInfo 							= LightInfoPool.poolGet();

	private	var	_statistics:ModelStatisics						= new ModelStatisics();
	public 	function get statistics():ModelStatisics			{ return _statistics; }

	private var _topMostChunks:Vector.<Chunk>					= new Vector.<Chunk>();
	private function get topMostChunk():Chunk					{ return _topMostChunks[_lod]; }

	private var _lod:int;
	public function set setLOD( $lod:int ):void 				{ _lod = $lod; }
	public function get lod():int			 					{ return _lod; }
	public function incrementLOD():void 						{ _lod++; }
	public function lodModelCount():int 						{ return _oxels.length; }

	private var _oxels:Vector.<Oxel> 							= new Vector.<Oxel>();
	public 	function get oxel():Oxel 							{ return _oxels[_lod]; }
	public 	function get oxelCount():int 						{ return _oxels.length; }

	public function OxelPersistance( $guid:String, $dbo:DatabaseObject, $importedData:ByteArray, $generated:Boolean = false ):void {
		super($guid, Globals.BIGDB_TABLE_OXEL_DATA);

		if (!_aliasInitialized) {
			_aliasInitialized = true;
			registerClassAlias("com.voxelengine.worldmodel.oxel.FlowInfo", FlowInfo);
			registerClassAlias("com.voxelengine.worldmodel.oxel.Brightness", Lighting);
		}

		if ( null == $dbo ) {
			assignNewDatabaseObject();
			if ( $generated )
				ba = $importedData;
			else
				stripDataFromImport( $importedData );
			baseLightLevel = Lighting.defaultBaseLightIllumination;
		} else {
			dbo = $dbo;
			//Log.out( "OxelPersistance: " + guid + "  compressed size: " + dbo.ba.length );
			dbo.ba.uncompress();
			//Log.out( "OxelPersistance: " + guid + "  UNcompressed size: " + dbo.ba.length );
		}

		_lightInfo.setInfo( Lighting.DEFAULT_LIGHT_ID, Lighting.DEFAULT_COLOR, Lighting.DEFAULT_ATTN, baseLightLevel );

	}

	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		ba		= null;
		bound		= -1;
	}

	private function stripDataFromImport( $importedData:ByteArray ):void {
		try {
			$importedData.uncompress();
		} catch (error:Error) {
			Log.out("OxelPersistance.stripDataFromImport - Was expecting compressed data " + guid, Log.WARN);
		}

		try {
			$importedData.position = 0;
			extractVersionInfo( $importedData );
			var manifestVersion:int = $importedData.readByte();
			if (version >= 4) {
				var strLen:int = $importedData.readInt();
				// read off that many bytes, even though we are using the data from the modelInfo file
				var modelInfoJson:String = $importedData.readUTFBytes(strLen);
			} else {
				Log.out("OxelPersistance.stripDataFromImport - REALLY OLD VERSION " + guid, Log.WARN);
				// need to read off one dummy byte
				$importedData.readByte();
				// next byte is root grain size
			}

			// Read off 1 bytes, the root size
			bound = $importedData.readByte();

			// Copy just the oxel data into the ba
			ba = new ByteArray();
			ba.writeBytes( $importedData, $importedData.position );
			ba.position = 0;
		}
		catch (error:Error) {
			Log.out("OxelPersistence.stripDataFromImport - exception stripping imported data " + guid, Log.WARN);
		}
	}

/////////////////
	// Make sense, called from for Makers
	private function extractVersionInfo( $ba:ByteArray ):void {
		// Read off first 3 bytes, the data format
		type = readFormat($ba);
		if ("ivm" != type )
			throw new Error("OxelPersistance.extractVersionInfo - Exception - unsupported format: " + type );

		// Read off next 3 bytes, the data version
		version = readVersion($ba);

		// This reads the format info and advances position on byteArray
		function readFormat($ba:ByteArray):String {
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
		function readVersion($ba:ByteArray):int {
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
/////////////////


	override public function release():void {
		_statistics.release();
		for each ( var o:Oxel in _oxels )
			o.release();
		// TODO how to handle this?
		//_topMostChunk.release();
		for each ( var c:Chunk in _topMostChunks )
			c.release();
		super.release();
		LightInfoPool.poolReturn(_lightInfo)
	}

	static public const NORMAL_BYTE_LOAD_PRIORITY:int = 5;
	public function createTaskToLoadFromByteArray($guid:String, $taskPriority:int ):void {
		FromByteArray.addTask( $guid, $taskPriority, this )
	}
	
	public function draw( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean, $isAlpha:Boolean ):void {
		//var time:int = getTimer();
		if ( !oxel || null == topMostChunk )
			return; // I see this when the chunk is getting generated
			
		if ( $isAlpha )
			topMostChunk.drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		else
			topMostChunk.drawNew( $mvp, $vm, $context, $selected, $isChild );
		//Log.out( "OxelPersistance.draw guid: " + $vm.instanceInfo.instanceGuid + " TOOK: " + (getTimer()-time) );
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Chunk operations
	
	public function update( $vm:VoxelModel ):void {
		if ( topMostChunk && topMostChunk.dirty ) {
			if ( EditCursor.EDIT_CURSOR == guid ) {
				oxel.facesBuild();
				oxel.quadsBuild();
			}
			else {
				//Log.out( "OxelPersistance.update ------------ calling refreshQuads guid: " + guid, Log.DEBUG );
				topMostChunk.buildQuadsRecursively( guid, $vm, _initializeFacesAndQuads );
				if ( _initializeFacesAndQuads )
					_initializeFacesAndQuads = false
			}
		}
	}
	
	public function visitor( $func:Function, $functionName:String = "" ):void {
		changed = true;
		topMostChunk.visitor( guid, $func, $functionName )
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// oxel operations
	public function changeOxel( $instanceGuid:String, $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean {
		var result:Boolean = oxel.changeOxel( $instanceGuid, $gc, $type, $onlyChangeType );
		if ( result )
			changed = true;
		return result;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// persistence operations
	override public function save():void {
		if ( 0 == oxelCount ) {
			//Log.out( "OxelPersistence.save - NOT Saving GUID: " + guid  + " oxel: " + (oxel?oxel:"No oxel") + " in table: " + table, Log.WARN );
			return;
		}
		super.save();
	}

	override public function set changed(value:Boolean):void {
//		if ( parent )
//			parent.changed = value;
		super.changed = value;
	}

//	private function versionGlobal():String {
//		return zeroPad( Globals.VERSION, 3 );
//		function zeroPad(number:int, width:int):String {
//			var ret:String = ""+number;
//			while( ret.length < width )
//				ret="0" + ret;
//			return ret;
//		}
//	}

	override protected function toObject():void {
		type 	= "ivm";
		version = Globals.VERSION;
		ba		= toByteArray();
		if (oxel && oxel.gc )
			bound	= oxel.gc.bound;
		else
			bound = 4;

		function zeroPad(number:int, width:int):String {
			var ret:String = ""+number;
			while( ret.length < width )
				ret="0" + ret;
			return ret;
		}
	}
				
	// FROM Persistance
	
	public function loadFromByteArray():void {
		//Log.out( "OxelPersistance.lodFromByteArray - guid: " + guid, Log.INFO );

		_oxels[_lod] = Oxel.initializeRoot(bound);
		oxel.readOxelData(ba, this );
		//Log.out("OxelPersistance.lodFromByteArray - readOxelData took: " + (getTimer() - time), Log.INFO);

		_statistics.gather();

		_topMostChunks[_lod] = oxel.chunk = Chunk.parse( oxel, null, _lightInfo );
		//Log.out( "OxelPersistance.lodFromByteArray oxel.chunkGet(): " + oxel.chunkGet() +  "  lod: " + _lod + " _topMostChunks[_lod] " + _topMostChunks[_lod]  );
		//Log.out( "OxelPersistance.lodFromByteArray - Chunk.parse lod: " + _lod + "  guid: " + guid + " took: " + (getTimer() - time), Log.INFO );
	}

	public function toByteArray():ByteArray {
		ba = oxel.toByteArray();
		Log.out( "OxelPersistance.toByteArray - guid: " + guid + "  Precompressed size: " + ba.length );
		ba.compress();
		Log.out( "OxelPersistance.toByteArray - guid: " + guid + "  POSTcompressed size: " + ba.length );
		return ba;
	}

	static public function toByteArrayOld( $oxel:Oxel ):ByteArray {
		var ba:ByteArray = new ByteArray();
		writeVersionedHeaderOld( ba );
		throw new Error("Refactor");
		//ba = $oxel.toByteArray( ba );
		ba.compress();
		return ba;

	}

	static private function writeVersionedHeaderOld( $ba:ByteArray):void {
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

		writeManifest( $ba );

		function zeroPad(number:int, width:int):String {
		   var ret:String = ""+number;
		   while( ret.length < width )
			   ret="0" + ret;
		   return ret;
		}
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
	
	private function validateOxel( $ba:ByteArray, $currentGrain:int):ByteArray {
		var faceData:uint = $ba.readUnsignedInt();
		var type:uint;
		if ( version <= Globals.VERSION_006 )
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

	public function generateLOD	( $vm:VoxelModel ): void {
		/////////////
		// the model with all detail is model 0
		// first level of detail is level 1 - min grain 4? 5? - distance unknown
		// ... continue until max - 2?

		LevelOfDetailEvent.addListener( LevelOfDetailEvent.MODEL_CLONE_COMPLETE, lodCloneCompleteEvent )
		new OxelCloner( $vm.modelInfo.oxelPersistance );
	}

	private function lodCloneCompleteEvent(event:LevelOfDetailEvent):void {
		LevelOfDetailEvent.removeListener( LevelOfDetailEvent.MODEL_CLONE_COMPLETE, lodCloneCompleteEvent );


		var size:uint = oxel.findSmallest();
		Log.out( "OxelPersistance.lodCloneCompleteEvent smallest on new oxel: " + size );
		if ( _oxels[0] && _oxels[0].gc.grain > 4 && size < _oxels[0].gc.grain - 2) {
			LevelOfDetailEvent.addListener( LevelOfDetailEvent.MODEL_CLONE_COMPLETE, lodCloneCompleteEvent )
			new OxelCloner( this );
		}
	}

	private function lodCloneFailureEvent(event:ModelLoadingEvent):void {
		Log.out( "lodCloneFailureEvent event: " + event, Log.ERROR );
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

	public function cloneNew( $guid:String ):OxelPersistance {
		throw new Error( "REFACTOR = 2.22.17");
/*
		// this adds the version header, need for the persistanceEvent
		var ba:ByteArray = toByteArray( oxel );

		var od:OxelPersistance = new OxelPersistance( $guid, null, ba, Lighting.defaultBaseLightIllumination );
		return od;
		*/
		return null;
	}
}
}

