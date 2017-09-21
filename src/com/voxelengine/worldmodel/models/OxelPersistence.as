/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models {
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
import com.voxelengine.pools.LightInfoPool;
import com.voxelengine.utils.StringUtils;
import com.voxelengine.worldmodel.oxel.FlowInfo;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.oxel.OxelBitfields;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.makers.OxelCloner;

/**
 * ...
 * @author Robert Flesch - RSF
 * OxelPersistence is the persistence wrapper for the oxel level data.
 */
public class OxelPersistence extends PersistenceObject
{
	// 1 meter stone cube is reference
	static private var 	 _aliasInitialized:Boolean				= false; // used to only register class names once

	//public function get baseLightLevel():int 					{ return dbo.baseLightLevel; }
	public function baseLightLevel( $value:int, $markChanged:Boolean = true ):void		{
		if ( !_lightInfo.locked ) {
			_lightInfo.setIlluminationLevel($value);
			if ( $markChanged )
				changed = true;
			forceQuads = true;
		}
	}

	public function get bound():int 							{ return dbo.bound; }
	public function set bound( value:int ):void					{ dbo.bound = value; }

	public function get ba():ByteArray 							{ return dbo.ba }
	public function set ba( $ba:ByteArray):void 				{ dbo.ba = $ba; }

	public function get version():int							{ return dbo.version; }
	public function set version($val:int):void					{ dbo.version = $val; }

	private var _lightInfo:LightInfo 							= LightInfoPool.poolGet();
	public function get lightInfo():LightInfo 					{ return _lightInfo; }

	private  var _forceQuads:Boolean;
	public function get forceQuads():Boolean 					{ return _forceQuads; }
	public function set forceQuads( value:Boolean ):void		{  _forceQuads = value; }

	private  var _forceFaces:Boolean;
	public function get forceFaces():Boolean 					{ return _forceFaces; }
	public function set forceFaces( value:Boolean ):void		{  _forceFaces = value; }

	private	var	_statistics:ModelStatisics						= new ModelStatisics();
	public 	function get statistics():ModelStatisics			{ return _statistics; }

	private var _topMostChunks:Vector.<Chunk>					= new Vector.<Chunk>();
	public function get topMostChunk():Chunk					{ return _topMostChunks[_lod]; }

	private var _lod:int;
	public function set setLOD( $lod:int ):void 				{ _lod = $lod; }
	public function get lod():int			 					{ return _lod; }
	public function incrementLOD():void 						{ _lod++; }
	public function lodModelCount():int 						{ return _oxels.length; }

	private var _oxels:Vector.<Oxel> 							= new Vector.<Oxel>();
	public 	function get oxel():Oxel 							{ return _oxels[_lod]; }
	public 	function get oxelCount():int 						{ return _oxels.length; }

	public function OxelPersistence($guid:String, $dbo:DatabaseObject, $importedData:ByteArray, $generated:Boolean = false ):void {
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
		} else {
			dbo = $dbo;
			//Log.out( "OxelPersistence: " + guid + "  compressed size: " + dbo.ba.length );
			dbo.ba.uncompress();
			//Log.out( "OxelPersistence: " + guid + "  UNcompressed size: " + dbo.ba.length );
		}

		// need to set the id and levels the first time
		_lightInfo.setInfo( Lighting.DEFAULT_LIGHT_ID, Lighting.DEFAULT_COLOR, Lighting.DEFAULT_ATTN, Lighting.DEFAULT_ILLUMINATION );
		forceQuads = true;
		//Log.out( "OxelPersistence - setting RANDOM Base light level" );
		//baseLightLevel = Math.random() * 255;
	}

	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		ba		= null;
		bound		= -1;
		version = Globals.VERSION;
	}

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

	public function draw( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean, $isAlpha:Boolean ):void {
		//var time:int = getTimer();
		if ( !oxel || null == topMostChunk )
			return; // I see this when the chunk is getting generated
			
		if ( $isAlpha )
			topMostChunk.drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		else
			topMostChunk.drawNew( $mvp, $vm, $context, $selected, $isChild );
		//Log.out( "OxelPersistence.draw guid: " + $vm.instanceInfo.instanceGuid + " TOOK: " + (getTimer()-time) );
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Chunk operations

	public function update():void {
		if ( topMostChunk ) {
			if ( topMostChunk.isBuilding )
					return;
			topMostChunk.markToSendToGPU();
			if ( topMostChunk.dirtyFacesOrQuads || forceFaces || forceQuads ) {
//				if ( "EditCursor" != guid )
//					Log.out("OxelPersistence.update ------------ calling facesAndQuadsBuild guid: " + guid + "  with forceFaces: " + forceFaces + "  forceQuads: " + forceQuads + "  dirtyFacesOrQuads: " + topMostChunk.dirtyFacesOrQuads, Log.DEBUG);
//				if ( forceFaces || forceQuads )
//						changed = true;
				var buildFaces:Boolean = true;
				topMostChunk.faceAndQuadsBuild(buildFaces, forceFaces, forceQuads);
				forceFaces = false;
				forceQuads = false;
			}
		}
	}
	
	public function visitor( $func:Function, $functionName:String = "" ):void {
		changed = true;
		topMostChunk.visitor( guid, $func, $functionName )
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// oxel operations
	public function change( $instanceGuid:String, $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean {
		var result:Boolean = oxel.change( $instanceGuid, $gc, $type, $onlyChangeType );
		if ( result ) {
			// Do immediate build, if we schedule task then faces are empty for a few frames.
			changed = true;
			oxel.facesBuild();
			oxel.quadsBuild();
		}
		return result;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// persistence operations
	override public function save( $validateGuid:Boolean = true ):Boolean {
		if ( 0 == oxelCount ) {
			//Log.out( "OxelPersistence.save - NOT Saving GUID: " + guid  + " oxel: " + (oxel?oxel:"No oxel") + " in table: " + table, Log.WARN );
			return false;
		}

		version = Globals.VERSION;
		var result:Boolean = super.save( $validateGuid );
		//Log.out( "OxelPersistence.save: " + ( result ? "Succeeded" : "Failed" ), Log.WARN );
		return result;
	}

	override protected function toObject():void {
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
				
	// FROM Persistence
	
	public function loadFromByteArray():void {
		//Log.out( "OxelPersistence.loadFromByteArray - guid: " + guid, Log.INFO );
		ba.position = 0;
		_oxels[_lod] = Oxel.initializeRoot(bound);
		oxel.readOxelData(ba, this );
		_statistics.gather();

		var chunk:Chunk = new Chunk( this, null, bound, guid, _lightInfo );
		chunk.parse( oxel );
		_topMostChunks[_lod] = oxel.chunk = chunk;

		//Log.out( "OxelPersistence.loadFromByteArray oxel.chunkGet(): " + oxel.chunkGet() +  "  lod: " + _lod + " _topMostChunks[_lod] " + _topMostChunks[_lod]  );
		//Log.out( "OxelPersistence.loadFromByteArray - Chunk.parse lod: " + _lod + "  guid: " + guid + " took: " + (getTimer() - time), Log.INFO );
	}

	public function toByteArray():ByteArray {
		ba = oxel.toByteArray();
		//Log.out( "OxelPersistence.toByteArray - guid: " + guid + "  Precompressed size: " + ba.length );
		ba.compress();
		if ( ba.length > 500000 ) {
			Log.out( "OxelPersistence.toByteArray -- Over max size for model, how is this possible? ", Log.ERROR );
			throw new Error("Error 1000, Over max size for model, how is this possible? ");
		}
		//Log.out( "OxelPersistence.toByteArray - guid: " + guid + "  POSTcompressed size: " + ba.length );
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
		var outVersion:String = StringUtils.zeroPad( Globals.VERSION, 3 );
		$ba.writeByte(outVersion.charCodeAt(0));
		$ba.writeByte(outVersion.charCodeAt(1));
		$ba.writeByte(outVersion.charCodeAt(2));

		writeManifest( $ba );

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

		LevelOfDetailEvent.addListener( LevelOfDetailEvent.MODEL_CLONE_COMPLETE, lodCloneCompleteEvent );
		new OxelCloner( $vm.modelInfo.oxelPersistence );
	}

	private function lodCloneCompleteEvent(event:LevelOfDetailEvent):void {
		LevelOfDetailEvent.removeListener( LevelOfDetailEvent.MODEL_CLONE_COMPLETE, lodCloneCompleteEvent );


		var size:uint = oxel.findSmallest();
		Log.out( "OxelPersistence.lodCloneCompleteEvent smallest on new oxel: " + size );
		if ( _oxels[0] && _oxels[0].gc.grain > 4 && size < _oxels[0].gc.grain - 2) {
			LevelOfDetailEvent.addListener( LevelOfDetailEvent.MODEL_CLONE_COMPLETE, lodCloneCompleteEvent );
			new OxelCloner( this );
		}
	}

	private function lodCloneFailureEvent(event:ModelLoadingEvent):void {
		Log.out( "lodCloneFailureEvent event: " + event, Log.ERROR );
	}

	//////////////////////////////////////////////////////////////////
	/* OxelPersistence - owns - top chunk - owns other chunks - owns oxels
	* Three cases of rebuilding quads with options
	* rebuild just ONE oxel (real-time) - NO CHUNK VERSION
	* rebuild one chunk (one hierarchy of oxels) (real-time OR threaded)
	* rebuild DIRTY chunks (all oxels in a model) threaded
	* rebuild ALL chunks (all oxels in a model) threaded
	 */

	public function cloneNew( $guid:String ):OxelPersistence {
		//toObject();
		//var newOP:OxelPersistence = new OxelPersistence( $guid, null, dbo.ba, Lighting.defaultBaseLightIllumination );
//		newOP.dbo.ba.uncompress();
		var newOP:OxelPersistence = new OxelPersistence( $guid, null, oxel.toByteArray(), Lighting.defaultBaseLightIllumination );
		newOP.bound = bound;
		newOP.changed = true;
		return newOP;
	}

/////////////////
	// Make sense, called from for Import Maker

	private function stripDataFromImport( $importedData:ByteArray ):void {
		try {
			$importedData.uncompress();
		} catch (error:Error) {
			Log.out("OxelPersistence.stripDataFromImport - Was expecting compressed data " + guid, Log.WARN);
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
				Log.out("OxelPersistence.stripDataFromImport - REALLY OLD VERSION " + guid, Log.WARN);
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

	private function extractVersionInfo( $ba:ByteArray ):void {
		// Read off first 3 bytes, the data format
		var type:String = readFormat($ba);
		if ("ivm" != type )
			throw new Error("OxelPersistence.extractVersionInfo - Exception - unsupported format: " + type );

		// Read off next 3 bytes, the data version
		version = readVersion($ba);

		// This reads the format info and advances position on byteArray
		function readFormat($ba:ByteArray):String {
			var format:String;
			var byteRead:int;
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
			var byteRead:int;
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


}
}

