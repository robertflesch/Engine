/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;
import com.voxelengine.worldmodel.models.makers.ModelMakerLocal;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import flash.geom.Vector3D;

import com.voxelengine.Log;
import com.voxelengine.Globals;

/**
 * ...
 * @author Bob
 */
public class ModelLoader 
{
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// local model
	///////////////////////////////////////////////////////////////////////////////////////////////////
	// This is the last part of reading a local model
	/*
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
	*/
	// This is the final step in model creation. All of the info needed to create the model is here.
	// the oxel is still not build, but all of the other information is complete.
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// If we want to preload the modelInfo, we dont need to block on it
	
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

	
	// objects that are waiting on model data to load
	//static private var _blocks:Dictionary = new Dictionary(true);
	
	
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
