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

import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import playerio.DatabaseObject;

import com.adobe.utils.Hex;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
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
	static private const compressedReferenceBA:ByteArray		= Hex.toArray( "78:da:cb:2c:cb:35:30:b0:48:61:00:02:96:7f:0c:60:90:c1:90:c0:c0:f0:1f:0a:18:a0:80:11:42:00:45:8c:a1:00:00:e2:da:10:a2" );
	//static private const referenceBA:ByteArray 					= Hex.toArray( "69:76:6d:30:30:38:64:00:00:00:00:04:fe:00:00:00:00:00:00:68:00:60:00:00:ff:ff:ff:ff:ff:ff:ff:ff:00:00:00:00:00:00:00:00:01:00:00:00:00:01:00:ff:ff:ff:33:33:33:33:33:33:33:33" );
	private	var	_statisics:ModelStatisics						= new ModelStatisics();
	private var _oxels:Vector.<Oxel> 							= new Vector.<Oxel>();
	private var _version:int;
	private var _topMostChunks:Vector.<Chunk>					= new Vector.<Chunk>();
	private function get topMostChunk():Chunk					{ return _topMostChunks[_lod]; }
	private var _parent:ModelInfo
	private var _ba:ByteArray
	private var firstTime:Boolean								= true;
	private var _lod:int;
	public function set setLOD( $lod:int ):void 				{ _lod = $lod; }
	public function get lod():int			 					{ return _lod; }
	public function incrementLOD():void 						{ _lod++; }
	public function lodModelCount():int 						{ return _oxels.length; }

	private var _baseLightLevel:int;
	public function get baseLightLevel():int 					{ return _baseLightLevel; }
	public function set baseLightLevel( value:int ):void		{ _baseLightLevel = value; }

	private var _lightInfo:LightInfo 							= null;

	public function get ba():ByteArray 							{ return _ba }
	public function set ba( $ba:ByteArray):void 				{ _ba = $ba; }

	public function get parent():ModelInfo						{ return _parent }
	public function set parent( $val:ModelInfo ):void			{ _parent = $val }
	public 	function get statisics():ModelStatisics				{ return _statisics; }
	public 	function get oxel():Oxel 							{ return _oxels[_lod]; }
	public 	function get oxelCount():int 						{ return _oxels.length; }

	public function OxelPersistance( $guid:String, $baseLightIllumination:int ) {
		//Log.out( "OxelPersistance: " + $guid + " baseLightIllumination: " + $baseLightIllumination, Log.WARN );
		super( $guid, Globals.BIGDB_TABLE_OXEL_DATA );
		// This should all come from model, so I could give the whole model a tint if I liked.
		_lightInfo = LightInfoPool.poolGet();
		_lightInfo.setInfo( Lighting.DEFAULT_LIGHT_ID, Lighting.DEFAULT_COLOR, Lighting.DEFAULT_ATTN, $baseLightIllumination );
	}
	
	override public function release():void {
		_statisics.release();
		for each ( var o:Oxel in _oxels )
			o.release();
		// TODO how to handle this?
		//_topMostChunk.release();
		for each ( var c:Chunk in _topMostChunks )
			c.release();
		super.release();
		LightInfoPool.poolReturn(_lightInfo)
	}

	public function createTaskToLoadFromByteArray($guid:String, $taskPriority:int, $parent:ModelInfo, $isDynObj:Boolean, $altGuid:String ):void {
        _parent = $parent;
		FromByteArray.addTask( $guid, $taskPriority, this, $altGuid )
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

	public function createEditCursor():void {
		_ba = compressedReferenceBA;
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
	
	public function update( $vm:VoxelModel ):void {
		if ( topMostChunk && topMostChunk.dirty ) {
			if ( EditCursor.EDIT_CURSOR == guid ) {
				oxel.facesBuild()
				oxel.quadsBuild()
			}
			else {
				//Log.out( "OxelPersistance.update ------------ calling refreshQuads guid: " + guid, Log.DEBUG );
				topMostChunk.refreshFacesAndQuads( guid, $vm, firstTime );
				if ( firstTime )
					firstTime = false
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
	// persistance operations
	override public function save():void {
		if ( 0 == oxelCount || !Globals.isGuid( guid ) ) {
				//Log.out( "OxelPersistance.save - NOT Saving GUID: " + guid  + " oxel: " + (oxel?oxel:"No oxel") + " in table: " + table, Log.WARN );
				return;
		}
		//Log.out( "OxelPersistance.save - Saving GUID: " + guid, Log.DEBUG );
		if ( changed )
			super.save();
	}

	override public function set changed(value:Boolean):void {
		if ( parent )
			parent.changed = value;
		super.changed = value;
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

	public function fromByteArray():void {
		_lightInfo.setIlluminationLevel( baseLightLevel );
		_oxels[_lod] = Oxel.initializeRoot( 31 ); // Lighting should be model or instance default lighting
		lodFromByteArray( ba );
		OxelDataEvent.create( ModelBaseEvent.RESULT_COMPLETE, 0, guid, this );
	}

	public function lodFromByteArray( $ba:ByteArray ):void {
		//Log.out( "OxelPersistance.lodFromByteArray - guid: " + guid, Log.INFO );
		var time:int = getTimer();

		oxel.decompressAndExtractMetadata( $ba, this );
		//Log.out( "OxelPersistance.lodFromByteArray-decompressAndExtractMetadata - lod: " + _lod + "  newOxel: " + newOxel.toString() + " took: " + (getTimer() - time) );

		time = getTimer();
		oxel.readOxelData($ba, this );
		//Log.out("OxelPersistance.lodFromByteArray - readOxelData took: " + (getTimer() - time), Log.INFO);

		statisics.gather();

		time = getTimer();
		_topMostChunks[_lod] = oxel.chunk = Chunk.parse( oxel, null, _lightInfo );
		//Log.out( "OxelPersistance.lodFromByteArray oxel.chunkGet(): " + oxel.chunkGet() +  "  lod: " + _lod + " _topMostChunks[_lod] " + _topMostChunks[_lod]  );
		//Log.out( "OxelPersistance.lodFromByteArray - Chunk.parse lod: " + _lod + "  guid: " + guid + " took: " + (getTimer() - time), Log.INFO );
	}

	
	static public function toByteArray( $oxel:Oxel ):ByteArray {
		var ba:ByteArray = new ByteArray();
		writeVersionedHeader( ba );
		ba = $oxel.toByteArray( ba );
		ba.compress();
		return ba;
		
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

	public function generateLOD	( $vm:VoxelModel ): void {
		/////////////
		// the model with all detail is model 0
		// first level of detail is level 1 - min grain 4? 5? - distance unknown
		// ... continue until max - 2?

		LevelOfDetailEvent.addListener( LevelOfDetailEvent.MODEL_CLONE_COMPLETE, lodCloneCompleteEvent )
		new OxelCloner( $vm.modelInfo.data );
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

	public function get version():int {
		return _version;
	}

	public function set version(value:int):void {
		_version = value;
	}

	public function cloneNew( $guid:String ):OxelPersistance {
		// this adds the version header, need for the persistanceEvent
		var ba:ByteArray = toByteArray( oxel );

		var od:OxelPersistance = new OxelPersistance( $guid, Lighting.defaultBaseLightIllumination );
		var dbo:DatabaseObject = new DatabaseObject( Globals.BIGDB_TABLE_OXEL_DATA, "0", "0", 0, true, null );
		dbo.data = new Object();
		dbo.data.ba = ba;
		od.fromObjectImport( dbo );

		return od;
	}
}
}

