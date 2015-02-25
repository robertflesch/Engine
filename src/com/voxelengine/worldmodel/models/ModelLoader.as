/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.ByteArray;
	
	import mx.utils.StringUtil;
	
	import com.developmentarc.core.tasks.tasks.ITask;
	import com.developmentarc.core.tasks.groups.TaskGroup;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.events.ModelMetadataEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.utils.CustomURLLoader;
	import com.voxelengine.worldmodel.biomes.LayerInfo;
	import com.voxelengine.worldmodel.tasks.landscapetasks.CompletedModel;
	import com.voxelengine.worldmodel.tasks.landscapetasks.LoadModelFromBigDB;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class ModelLoader 
	{
		// objects that are waiting on model data to load
		static private var _blocks:Dictionary = new Dictionary(true);
		// This is used only for loading local models into persistance
		static private var _s_mmd:VoxelModelMetadata;
		
		public function ModelLoader():void {
			// replaced by ModelMaker
			//ModelMetadataEvent.addListener( ModelMetadataEvent.ADDED, localModelReadyToBeCreated );
		}
		
		// Make sense, called from Region
		static public function modelMetaInfoRead( $ba:ByteArray ):Object
		{
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
			for each ( var v:Object in objects )		   
			{
				if ( v.model ) {
					var instance:InstanceInfo = new InstanceInfo();
					instance.initJSON( v.model );
					load( instance );
					count++;
				}
			}

			Log.out( "ModelLoader.loadRegionObjects - END =============================" );

			// why is defaultRegion special?
			//if ( 0 == count && name != "defaultRegion" ) {
			if ( 0 == count )
				Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.LOAD_COMPLETE ) );
			else	
				Globals.g_landscapeTaskController.activeTaskLimit = 1;
				
			return count;
		}
		
		
		static public function load( $ii:InstanceInfo, $vmm:VoxelModelMetadata = null ):void {
			//Log.out( "ModelLoader.load - InstanceInfo: " + $ii.toString(), Log.DEBUG );
			Globals.instanceInfoAdd( $ii ); // Uses a name + guid as identifier
			if ( !Globals.isGuid( $ii.guid ) && $ii.guid != "LoadModelFromBigDB" )
				new ModelMakerLocal( $ii );
			else
				new ModelMaker( $ii );
		}
		
		static public function instantiate( $ii:InstanceInfo, $modelInfo:ModelInfo, $vmm:VoxelModelMetadata ):* {
			if ( !$ii )
				throw new Error( "ModelLoader.instantiate - InstanceInfo null" );

			var vm:VoxelModel = Globals.getModelInstance( $ii.guid );
			if ( null != vm ) {
				// a pre model was made. copy over the modelInfo.
				vm.modelInfo = $modelInfo;
				return vm;
			}
				
			var modelAsset:String = $modelInfo.modelClass;
			var modelClass:Class = ModelLibrary.getAsset( modelAsset )
			if ( "Player" == modelAsset ) {
				if ( null != Globals.player )
					return Globals.player;
			}
			vm = new modelClass( $ii );
			if ( null == vm )
				throw new Error( "ModelLoader.instantiate - Model failed in creation - modelClass: " + modelClass );
				
			vm.init( $modelInfo, $vmm );
			// if we were given metadata, use it.
			if ( null != $vmm )
				vm.metadata = $vmm;

			if ( !(vm is Avatar) )
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
		static public function loadFromManifestByteArray( $vmm:VoxelModelMetadata, $ba:ByteArray, controllingModelGuid:String = "" ):VoxelModel {
				
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
				var cvm:VoxelModel = Globals.getModelInstance( controllingModelGuid );
				ii.controllingModel = cvm;
			}
				
			var vm:* = instantiate( ii, mi, $vmm );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.loadOxelFromByteArray( $ba );
			}

			vm.complete = true;
			return vm;
		}
		
		static public function loadFromManifestByteArrayNew( $ii:InstanceInfo, $vmd:VoxelModelData ):VoxelModel {
				
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
			Globals.modelInfoAdd( mi );
			// needs to be name + guid??
			
			//var vm:* = instantiate( $ii, mi, $vmm );
			var vm:* = instantiate( $ii, mi, null );
			if ( vm ) {
				vm.version = versionInfo.version;
				vm.loadOxelFromByteArray( $ba );
			}

			vm.complete = true;
			return vm;
		}
		

		///////////////////////////////////////////////////////////////////////////////////////////////////
		// END Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
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
			$vm.loadOxelFromByteArray($ba);
		}
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// END local model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// local TO Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		static private function localModelReadyToBeCreated( $e:ModelMetadataEvent ):void {
			
			Log.out( "ModelLoader.localModelReadyToBeCreated - " + $e.toString() );
			var ii:InstanceInfo = new InstanceInfo();
			// no easy way to pass the VoxelModelMetadata thru loader, so save it off here, and reapply after it is loaded
			_s_mmd = $e.vmm;
			ii.guid = $e.vmm.guid; // Since it used the file name to load locally, this has to be the same 
			
			// this will occur after the oxel data has been loaded
			Globals.g_app.addEventListener( LoadingEvent.MODEL_LOAD_COMPLETE, localModelLoaded );
			Globals.g_app.addEventListener( LoadingEvent.PLAYER_LOAD_COMPLETE, localModelLoaded );
			
			load( ii, _s_mmd );
		}
		
		// We have to wait for the oxel data to be loaded before we can convert this to a template.
		static private function localModelLoaded( e:LoadingEvent ):void {
			
			if ( null == _s_mmd )
				Log.out( "ModelLoader.localModelLoaded - _s_mmd is null " + e.toString() );
				
			if ( _s_mmd.guid == e.guid ) {
				Log.out( "ModelLoader.localModelLoaded - " + e.toString() );
				//var vm:VoxelModel = TemplateManager.templateGet( e.guid );
				var vm:VoxelModel = Globals.getModelInstance( e.guid );
				
				if ( vm ) {
					// Convert this from a locally loaded model, to a persistance loaded model
					var newLayerInfo:LayerInfo = new LayerInfo( "LoadModelFromBigDB", vm.instanceInfo.guid );
					vm.modelInfo.biomes.layerReset();
					vm.modelInfo.biomes.add_layer( newLayerInfo );
					vm.modelInfo.jsonReset();
					vm.changed = true;
					vm.instanceInfo.guid = vm.metadata.guid = Globals.getUID();
					_s_mmd = null;
					vm.save();
//					PlanManager.templateAdd( vm.metadata );
					Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.TEMPLATE_MODEL_COMPLETE, vm.metadata.guid ) );
					// clear out any evidence that we loaded this model (modelInfo too?)
					Globals.markDead( e.guid );
					Globals.instanceInfoRemove( e.guid );
				}
				else
					Log.out( "ModelLoader.localModelLoaded - Failed to find template in template manager guid: " + vm.metadata.guid );
			}
		}

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
		
		
	}
}
