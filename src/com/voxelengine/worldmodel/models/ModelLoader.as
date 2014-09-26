/*==============================================================================
  Copyright 2011-2014 Robert Flesch
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
		static private const MODEL_MANAGER_MODEL_EXT:String = ".mjson";
		static private const MANIFEST_VERSION:int = 100;
		
		// objects that are waiting on model data to load
		static private var _blocks:Dictionary = new Dictionary(true);
		// This is used only for loading local models into persistance
		static private var _s_mmd:VoxelModelMetadata;
		
		public function ModelLoader():void {
			Globals.g_app.addEventListener( ModelMetadataEvent.INFO_COLLECTED, localModelReadyToBeCreated );
		}
		
		static private function createInstanceFromTemplate( $vm:VoxelModel ):void {
			
			Log.out( "ModelLoader.createInstanceFromTemplate - Converting LOCAL to PERSISTANT - InstanceInfo: " + $vm.instanceInfo.toString() );
			Globals.modelInstancesChangeGuid( $vm.instanceInfo.guid, Globals.getUID() );
			var newLayerInfo:LayerInfo = new LayerInfo( "LoadModelFromBigDB", $vm.instanceInfo.guid );
			$vm.modelInfo.biomes.layerReset();
			$vm.modelInfo.biomes.add_layer( newLayerInfo );
			$vm.modelInfo.jsonReset();
			$vm.changed = true;
			$vm.complete = true;
		}
		
		static public function load( $ii:InstanceInfo, $vmm:VoxelModelMetadata = null ):void {
			Globals.instanceInfoAdd( $ii ); // Uses a name + guid as identifier
			if ( !Globals.isGuid( $ii.guid ) && $ii.guid != "LoadModelFromBigDB" )
				loadLocal( $ii, $vmm )
			else
				loadPersistant( $ii );
		}
		
		// If we want to preload the modelInfo, we dont need to block on it
		static public function modelInfoPreload( $fileName:String ):void {
			modelInfoFindOrCreate( $fileName, "", false );
		}
		
		static private function instantiate( $ii:InstanceInfo, $modelInfo:ModelInfo, $vmm:VoxelModelMetadata ):* {
			if ( !$ii )
				throw new Error( "ModelLoader.instantiate - InstanceInfo null" );
				
			var modelAsset:String = $modelInfo.modelClass;
			var modelClass:Class = ModelLibrary.getAsset( modelAsset )
			var vm:* = new modelClass( $ii, $modelInfo, $vmm );
			if ( null == vm )
				throw new Error( "ModelLoader.instantiate - Model failed in creation - modelClass: " + modelClass );
			
			if ( null == $vmm )
				Log.out( "ModelLoader.instantiate - null VoxelModelMetata" );
			else
				vm.metadata = $vmm;
				
			//Log.out( "ModelLoader.instantiate - modelClass: " + modelClass + "  instanceInfo: " + $ii.toString() );
			Globals.modelAdd( vm );
			return vm;
		}
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		static private function loadPersistant( $ii:InstanceInfo ):void {
			Log.out( "ModelLoader.loadPersistant - InstanceInfo: " + $ii.toString() );
			// land task controller, this tells task controller not to run until it is done loading all tasks
//			Globals.g_landscapeTaskController.activeTaskLimit = 0;
			// Create task group
			var taskGroup:TaskGroup = new TaskGroup("Download Model for " + $ii.guid, 2);
		
			// This loads the tasks into the LandscapeTaskQueue
			//var layer:LayerInfo = new LayerInfo( "LoadModelFromBigDB", $ii.guid ); 
			var task:ITask = new LoadModelFromBigDB( $ii.guid, null );
			taskGroup.addTask(task);
			
			//task = new CompletedPersistantModel( $ii.guid, null );
			//taskGroup.addTask(task);
			
			Globals.g_landscapeTaskController.addTask( taskGroup );
		}
		
		static public function loadFromManifestByteArray( $vmm:VoxelModelMetadata, controllingModelGuid:String = "" ):VoxelModel {
				
			var ba:ByteArray = $vmm.data as ByteArray;
			if ( null == ba )
			{
				Log.out( "VoxelModel.loadFromManifestByteArray - Exception - bad data in VoxelModelMetadata: " + $vmm.guid, Log.ERROR );
				return null;
			}
			
			ba.uncompress();

			var versionInfo:Object = modelMetaInfoRead( ba );
			if ( MANIFEST_VERSION != versionInfo.manifestVersion )
			{
				Log.out( "VoxelModel.loadFromManifestByteArray - Exception - bad version: " + versionInfo.manifestVersion, Log.ERROR );
				return null;
			}
			
			// how many bytes is the modelInfo
			var strLen:int = ba.readInt();
			// read off that many bytes
			var modelInfoJson:String = ba.readUTFBytes( strLen );
			
			if ( null != $vmm.guid && "" != $vmm.guid ) {
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
				if ( !ii ) {
					ii = new InstanceInfo();
					var viewDistance:Vector3D = new Vector3D(0, 0, -75);
					ii.positionSet = Globals.controlledModel.instanceInfo.worldSpaceMatrix.transformVector( viewDistance );
					ii.guid = $vmm.guid;
				}
				
			if ( "" != controllingModelGuid ) {
				var cvm:VoxelModel = Globals.getModelInstance( controllingModelGuid );
				ii.controllingModel = cvm;
			}
				
			var vm:* = instantiate( ii, mi, $vmm );
			vm.version = versionInfo.version;
			vm.loadOxelFromByteArray( ba );
			}

			return vm;
		}
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// END Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// local model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		static private function loadLocal( $ii:InstanceInfo, $vmm:VoxelModelMetadata ):void {
			Log.out( "ModelLoader.loadLocal - InstanceInfo: " + $ii.toString() );
			var modelInfo:ModelInfo = modelInfoFindOrCreate( $ii.guid, $ii.guid );
			if ( modelInfo )
			{
				instantiate( $ii, modelInfo, $vmm );
			}		
		}
		
		static public function modelInfoFindOrCreate( $guid:String, $name:String, $block:Boolean = true ):ModelInfo {
			var modelInfo:ModelInfo = Globals.modelInfoGet( $name );
			
			if ( null == $name )
			{
				Log.out( "ModelLoader.modelInfoFindOrCreate - ERROR fileName is NULL", Log.ERROR );
			}
			
			// if no model info found, we have to load a copy
			if ( !modelInfo )
			{
				// if we are already waiting for a copy to load, then add a $block if shouldBlock is true, else add a loader.
				if ( !_blocks[$name] )
				{
					//Log.out( "ModelLoader.modelInfoFindOrCreate - loading: " + Globals.appPath + modelNameAndLoc );
					var loader:CustomURLLoader = new CustomURLLoader( new URLRequest( Globals.modelPath + $guid + MODEL_MANAGER_MODEL_EXT ) );
					loader.addEventListener(Event.COMPLETE, onModelInfoLoaded);
					loader.addEventListener(IOErrorEvent.IO_ERROR, onModelInfoLoadError);
				}
				// If we want to preload the modelInfo, we dont need to block on it
				if ( $block )
					addBlock( $guid, $name );
			}
			
			return modelInfo;
			
			function onModelInfoLoadError(event:IOErrorEvent):void {
				Log.out("ModelLoader.onModelInfoLoadError: ERROR" );
				var req:URLRequest = CustomURLLoader(event.target).request;			
				var fileName:String = CustomURLLoader(event.target).fileName;			
				var guid:String = fileName.substr( 0, fileName.lastIndexOf( "." ) );
				clearBlock( guid );
				Log.out("----------------------------------------------------------------------------------" );
				Log.out("ModelLoader.onModelInfoLoadError: ERROR LOADING MODEL: " + event.text, Log.ERROR );
				Log.out("----------------------------------------------------------------------------------" );
			}	
				
			//
			function onModelInfoLoaded(event:Event):void {
				//var req:URLRequest = CustomURLLoader(event.target).request;			
				var fileName:String = CustomURLLoader(event.target).fileName;			
				var fileData:String = String(event.target.data);
				var jsonString:String = StringUtil.trim(fileData);
				
				try {
					var jsonResult:Object = JSON.parse(jsonString);
				}
				catch ( error:Error ) {
					Log.out("----------------------------------------------------------------------------------" );
					Log.out("ModelLoader.onModelInfoLoaded - ERROR PARSING: fileName: " + fileName + "  data: " + fileData, Log.ERROR );
					Log.out("----------------------------------------------------------------------------------" );
					return;
				}
				var mi:ModelInfo = new ModelInfo();
				var guid:String = fileName.substr( 0, fileName.lastIndexOf( "." ) );
				
				mi.initJSON( guid, jsonResult );
				Globals.modelInfoAdd( mi );
				
				//Log.out("ModelLoader.onModelInfoLoaded - loaded model $guid: " + mi.guid + MODEL_MANAGER_MODEL_EXT );

				clearBlock( guid );
				Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.INFO_LOADED, guid ) );
			}       
			
		}
		
		//

		// This is the last part of reading a local model
		static public function loadLocalModelFromByteArray( $vm:VoxelModel, $ba:ByteArray):void
		{
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
			
			var ii:InstanceInfo = new InstanceInfo();
			// hack to save it 
			_s_mmd = $e.vmm;
			//////////////////////
			_s_mmd.databaseObject = null;
			// all items from desktop are templates
			_s_mmd.template = true;
			// needed??
			//_s_mmd.guid = Globals.getUID();
			
			//////////////////////
			ii.guid = _s_mmd.guid;
			//ii.name = _s_mmd.name;
			
			var viewDistance:Vector3D = new Vector3D(0, 0, -75);
			ii.positionSet = Globals.controlledModel.instanceInfo.worldSpaceMatrix.transformVector( viewDistance );
			Log.out( "ModelLoader.localModelReadyToBeCreated - " + ii.toString() );
			
			Globals.g_app.addEventListener( LoadingEvent.MODEL_LOAD_COMPLETE, localModelLoaded );
			Globals.g_app.addEventListener( LoadingEvent.PLAYER_LOAD_COMPLETE, localModelLoaded );
			
			load( ii, _s_mmd );
		}
		
		static private function localModelLoaded( e:LoadingEvent ):void {
			
			if ( _s_mmd.guid == e.guid ) {
				Log.out( "ModelLoader.localModelLoaded - " + e.toString() );
				var vm:VoxelModel = Globals.getModelInstance( e.guid );
				createInstanceFromTemplate(vm);
				vm.metadata = _s_mmd;
				_s_mmd = null;
				vm.metadata.guid = vm.instanceInfo.guid;
				vm.changed = true;
				vm.save();
			}
		}
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// END local TO Persistant model
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
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
			function readVersion($ba:ByteArray):String
			{
				var version:String;
				var byteRead:int = 0;
				byteRead = $ba.readByte();
				version = String.fromCharCode(byteRead);
				byteRead = $ba.readByte();
				version += String.fromCharCode(byteRead);
				byteRead = $ba.readByte();
				version += String.fromCharCode(byteRead);
				
				return version;
			}
		}
		
		static public function loadRegionObjects( objects:Array ):int {
			Log.out( "ModelLoader.loadRegionObjects - START =============================" );
			
			var count:int = 0;
			for each ( var v:Object in objects )		   
			{
				var instance:InstanceInfo = new InstanceInfo();
				instance.initJSON( v.model );
				//trace( "ModelLoader.loadObjects: ----------------  fileName:" + v.model.fileName );
				
				//Log.out( "ModelLoader.loadRegionObjects - loading: " + instance.toString() );
				load( instance );
				count++;
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