/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class ModelLoader 
	{
		// objects that are waiting on model data to load
		//static private var _blocks:Dictionary = new Dictionary(true);
		
		// Make sense, called from Region
		static public function modelMetaInfoRead( $ba:ByteArray ):Object {
			$ba.position = 0;
			// Read off first 3 bytes, the data format
			var format:String = readFormat($ba);
			if ("ivm" != format)
				throw new Error("ModelLoader.modelMetaInfoRead - Exception - unsupported format: " + format );
			
			var metaInfo:Object = new Object();
			// Read off next 3 bytes, the data version
			metaInfo.version = readVersion($ba);

			// Read off next byte, the manifest version
			metaInfo.manifestVersion = $ba.readByte();
			//Log.out("VoxelModel.readMetaInfo - version: " + metaInfo.version + "  manifestVersion: " + metaInfo.manifestVersion );
			return metaInfo;

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
		
		// Make sense, called from Region
		static public function loadRegionObjects( objects:Array ):int {
			Log.out( "ModelLoader.loadRegionObjects - START =============================" );
			var count:int = 0;
			for each ( var v:Object in objects ) {
				if ( v.model ) {
					var instance:InstanceInfo = new InstanceInfo();
					instance.initJSON( v.model );
					load( instance );
					count++;
				}
			}
			Log.out( "ModelLoader.loadRegionObjects - END " + "  count: " + count + "=============================" );
			return count;
		}
		
		
		static public function load( $ii:InstanceInfo, $vmm:ModelMetadata = null ):void {
			//Log.out( "ModelLoader.load - InstanceInfo: " + $ii.toString(), Log.DEBUG );
//			Globals.instanceInfoAdd( $ii ); // Uses a name + guid as identifier
			if ( !Globals.isGuid( $ii.guid ) && $ii.guid != "LoadModelFromBigDB" )
				new ModelMakerLocal( $ii );
			else
				new ModelMaker( $ii );
		}
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// persistent model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		static public function createFromMakerInfo( $ii:InstanceInfo, $vmd:ModelData, $mmd:ModelMetadata = null ):VoxelModel {
				
			var $ba:ByteArray = $vmd.ba;
			if ( null == $ba )
			{
				Log.out( "VoxelModel.loadFromManifestByteArray - Exception - bad data in VoxelModelMetadata: " + $vmd.guid, Log.ERROR );
				return null;
			}
			$ba.position = 0;
			
			var versionInfo:Object = modelMetaInfoRead( $ba );
			if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "VoxelModel.loadFromManifestByteArray - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return null;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var modelInfoJson:String = $ba.readUTFBytes( strLen );
			
			// create the modelInfo object from embedded metadata
			modelInfoJson = decodeURI(modelInfoJson);
			var jsonResult:Object = JSON.parse(modelInfoJson);
			var mi:ModelInfo = new ModelInfo();
			mi.initJSON( $vmd.guid, jsonResult );
			
			// add the modelInfo to the repo
			// is the still needed TODO - RSF 9.23.14
//			Globals.modelInfoAdd( mi );
			// needs to be name + guid??
			
			//var vm:* = instantiate( $ii, mi, $vmm );
			var vm:* = instantiate( $ii, mi, $mmd );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.fromByteArray( $ba );
			}

			vm.data = $vmd;
			vm.complete = true;
			return vm;
		}
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// local model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// This is the last part of reading a local model
		static public function loadLocalModelFromByteArray( $vm:VoxelModel, $ba:ByteArray):void 	{
			
			// the try catch here allows me to treat all models as compressed
			// if the uncompress fails, it simply continues
			// This sequence of bytes shows it is compressed ???
			try {  $ba.uncompress(); }
			catch (error:Error) { ; }
			$ba.position = 0;

			var versionInfo:Object = modelMetaInfoRead( $ba );
			$vm.version = versionInfo.version;
			//Log.out( "VoxelModel.IVMLoadUncompressed version: " + _version + "  manifestVersion: " + versionInfo.manifestVersion );
			if ( 0 != versionInfo.manifestVersion ) {
				// this local file has manifest information
				// so load it but throw away the embedded info
				// how should I handle if there is a mismatch?
				// do I use the local or the network? hm...
				
				// how many bytes is the modelInfo
				var strLen:int = $ba.readInt();
				// read off that many bytes
				var modelInfoJson:String = $ba.readUTFBytes( strLen );
				modelInfoJson = decodeURI( modelInfoJson );
				//Log.out( "VoxelModel.IVMLoadUncompressed - modelInfoJson: " + modelInfoJson );
			}
			
			$vm.metadata.name = $vm.modelInfo.fileName;
			
			// now just load the model like any other
			$vm.fromByteArray($ba);
		}
		
		// This is the final step in model creation. All of the info needed to create the model is here.
		// the oxel is still not build, but all of the other information is complete.
		static public function instantiate( $ii:InstanceInfo, $modelInfo:ModelInfo, $vmm:ModelMetadata ):* {
			var modelAsset:String = $modelInfo.modelClass;
			var modelClass:Class = ModelLibrary.getAsset( modelAsset )
			var vm:VoxelModel = new modelClass( $ii );
			if ( null == vm )
				throw new Error( "ModelLoader.instantiate - Model failed in creation - modelClass: " + modelClass );
				
			vm.init( $modelInfo, $vmm );

			// The avatar is loaded outside of the region
			Globals.modelAdd( vm );

			//Log.out( "ModelLoader.instantiate - modelClass: " + modelClass + "  instanceInfo: " + $ii.toString() );
			return vm;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// MAY BE NEEDED
		static public function modelInfoPreload( $fileName:String ):void {
			throw new Error( "This is not needed online" );
			modelInfoFindOrCreate( $fileName, "", false );
		}
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// If we want to preload the modelInfo, we dont need to block on it
		
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		static public function loadFromManifestByteArray( $vmm:ModelMetadata, $ba:ByteArray, controllingModelGuid:String = "" ):VoxelModel {
				
			if ( null == $ba )
			{
				Log.out( "VoxelModel.loadFromManifestByteArray - Exception - bad data in VoxelModelMetadata: " + $vmm.guid, Log.ERROR );
				return null;
			}
			$ba.position = 0;
			
			var versionInfo:Object = modelMetaInfoRead( $ba );
			if ( Globals.MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "VoxelModel.loadFromManifestByteArray - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return null;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var modelInfoJson:String = $ba.readUTFBytes( strLen );
			
			// create the modelInfo object from embedded metadata
			modelInfoJson = decodeURI(modelInfoJson);
			var jsonResult:Object = JSON.parse(modelInfoJson);
			var mi:ModelInfo = new ModelInfo();
			mi.initJSON( $vmm.guid, jsonResult );
			
			// add the modelInfo to the repo
			// is the still needed TODO - RSF 9.23.14
			Globals.modelInfoAdd( mi );
			// needs to be name + guid??
			var ii:InstanceInfo = Globals.instanceInfoGet( $vmm.guid );
			// Templates dont have instanceInfo.
			if ( !ii ) {
				ii = new InstanceInfo();
				var viewDistance:Vector3D = new Vector3D(0, 0, -75);
				ii.positionSet = Globals.controlledModel.instanceInfo.worldSpaceMatrix.transformVector( viewDistance );
				//ii.guid = Globals.getUID();
				ii.guid = $vmm.guid;
			}
			
			if ( "" != controllingModelGuid ) {
				var cvm:VoxelModel = Globals.modelGet( controllingModelGuid );
				ii.controllingModel = cvm;
			}
				
			var vm:* = instantiate( ii, mi, $vmm );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.fromByteArray( $ba );
			}

			vm.complete = true;
			return vm;
		}

		///////////////////////////////////////////////////////////////////////////////////////////////////
		// END Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// END local model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		

		///////////////////////////////////////////////////////////////////////////////////////////////////
		// END local TO Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		
		static private function addBlock( $guid:String, $name:String ):void {
			//Log.out( "ModelLoader.addBlock - instanceGIUD: " + $guid + "  fileName: " + fileName );
			if ( _blocks[$guid] )
			{
				var block:Vector.<String> = _blocks[$guid];
				// check to make sure its not in more then once
				for each ( var name:String in block )
				{
					if ( name == $name )
						return;
				}
				block.push( $name );
			}
			else
			{
				var newBlock:Vector.<String> = new Vector.<String>;
				newBlock.push( $name );
				_blocks[$guid] = newBlock;
			}
		}
		
		static private function clearBlock( $guid:String, $error:Boolean = false ):void {
			//Log.out( "ModelLoader.clearBlock " + $guid  );
			if ( _blocks[$guid] )
			{
				var block:Vector.<String> = _blocks[$guid];
				if ( !$error )
				{
					var instanceInfo:InstanceInfo = null;
					for each ( var name:String in block )
					{
						instanceInfo = Globals.instanceInfoGet( $guid );
						//Log.out( "CLEAR BLOCK " + instanceInfo.toString() + " for guid: " + guid  );
						if ( instanceInfo )
						{
							//Log.out( "CLEAR BLOCK " + instanceInfo.toString()  );
							instantiate( instanceInfo, Globals.modelInfoGet($guid), _s_mmd );
						}
					}
				}
				// TODO This should create a new _blocks that doesnt include the $guid, rather then it being null
				// but whats the saving vs creating new memory...
				_blocks[$guid] = null;
			}
		}
		*/
		
	}
}
