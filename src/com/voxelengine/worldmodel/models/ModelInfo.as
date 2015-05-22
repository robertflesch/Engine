/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;
//import flash.sampler.NewObjectSample;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.utils.transitions.properties.SoundShortcuts;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.biomes.Biomes;
import playerio.DatabaseObject;
/**
 * ...
 * @author Bob
 */
public class ModelInfo extends PersistanceObject
{
	private var _children:Vector.<InstanceInfo> 	= new Vector.<InstanceInfo>;// Child models and their relative positions
	private var _scripts:Vector.<String> 			= new Vector.<String>;		// Default scripts to be used with this model
	private var _animations:Vector.<Animation> 		= new Vector.<Animation>();	// Animations that this model has
	
	private var _fileName:String 					= "INVALID";				// Used for local loading and import of data from local file system
	private var _biomes:Biomes;													// used to generate terrain and apply other functions to oxel
	private var _modelClass:String 					= "VoxelModel";				// Class used to instaniate model
	private var _grainSize:int = 0;												// Used in model generatation
	private var _modelJson:Object;												// copy of json object used to create this
	private var _animationInfo:Vector.<Object> 		= new Vector.<Object>();	// ID and name of animations that this model has, before loading
	private var _childCount:int // number of children this model has at start. Used to determine if animation can be played.
	private var _owner:VoxelModel;
	private var _animationCount:int;
	private var _series:int														// used to make sure animation is part of same series when loading
	
	public function get json():Object 						{ return _modelJson; }
	public function get fileName():String 					{ return _fileName; }
	public function set fileName(val:String):void 			{ _fileName = val; }
	public function get biomes():Biomes 					{ return _biomes; }
	public function get children():Vector.<InstanceInfo> 	{ return _children; }
	public function get scripts():Vector.<String> 			{ return _scripts; }
	public function get modelClass():String					{ return _modelClass; }
	public function set modelClass(val:String):void 		{ _modelClass = val; }
	public function get grainSize():int						{ return _grainSize; }
	public function set grainSize(val:int):void				{ _grainSize = val; }
	
	public function get animations():Vector.<Animation> 	{ return _animations; }
	public function get childCount():int 					{ return _childCount; }
	
	public function set biomes(value:Biomes):void  			{ _biomes = value; }
	
	private function get owner():VoxelModel { return _owner; }

	public function get hasInventory():Boolean { return _hasInventory; }
	public function set hasInventory(value:Boolean):void  { _hasInventory = value; }
	
	protected var _hasInventory:Boolean 					= false
	
	public function ModelInfo( $guid:String ):void  { 
		super( $guid, Globals.BIGDB_TABLE_MODEL_INFO ); 
	}
	
	
	public function boimeHas():Boolean {
		if ( _biomes && _biomes.layers && 0 < _biomes.layers.length )
			return true;
		return false;
	}
	
	override public function release():void {
		_owner = null
		_biomes = null;
		_children = null;
		_scripts = null;
		_modelJson = null;
		_animations = null;
		_animationInfo = null;
	}

	override public function clone():* {
		throw new Error( "ModelInfo.clone - USE CLONE FROM VOXELMODEL METHOD" );
	}

	public function cloneFromVoxelModel( $vm:VoxelModel ):ModelInfo {
		var obj:Object = new Object();
		$vm.buildExportObject( obj );
		var mi:ModelInfo = new ModelInfo( $vm.instanceInfo.modelGuid );
		mi.initJSON( $vm.modelInfo.guid, obj );
		return mi;
	}
	
	// remove the children after they are loaded, so that when the object is saved
	// the active children from the voxel model are used.
	// Applies to the "REPLACE_ME" above
	public function childrenReset():void {
		_children = null;
		_childCount = 0;
	}
	
	// From JSON to modelInfo
	public function initJSON( $modelGuid:String, $json:Object ):void  {
		
		//Log.out( "ModelInfo.init - fileName: " + $modelGuid + "  $json: " + JSON.stringify( $json.model ) );
		if ( !$json.model  ) {
			Log.out( "ModelInfo.init - ERROR - unable to find model Info in : " + $modelGuid + "  containing: " + JSON.stringify($json), Log.ERROR );					
			return;
		}
			
		_fileName = $modelGuid;
		guid = $modelGuid;
		_modelJson = $json;
		
		// this is the json just for modelInfo
		var modelInfoJson:Object = $json.model;
		
		if ( modelInfoJson.grainSize )
			_grainSize = 	modelInfoJson.grainSize;
		else if ( modelInfoJson.GrainSize )
			_grainSize = 	modelInfoJson.GrainSize;
		else if ( modelInfoJson.grainsize )
			_grainSize = 	modelInfoJson.grainsize;
		
		if ( modelInfoJson.modelClass )
			_modelClass = modelInfoJson.modelClass;

		if ( modelInfoJson.hasInventory )
			hasInventory = true;
			
		// This is an artifact from the old mjson files, new system saves all as "scripts"
		if ( modelInfoJson.script ) {
			for each ( var scriptObject:Object in modelInfoJson.script ) {
				if ( scriptObject.name ) {
					//trace( "ModelInfo.init - Model GUID:" + fileName + "  adding script: " + scriptObject.name );
					_scripts.push( scriptObject.name );
				}
			}
		}
		if ( modelInfoJson.scripts ) {
			for each ( var so:Object in modelInfoJson.scripts ) {
				if ( so.name ) {
					//trace( "ModelInfo.init - Model GUID:" + fileName + "  adding script: " + scriptObject.name );
					_scripts.push( so.name );
				}
			}
		}
		
		if ( modelInfoJson.biomes ) {
			var biomesObj:Object = modelInfoJson.biomes;
			// TODO this should only be true for new terrain models.
			const createHeightMap:Boolean = true;
			_biomes = new Biomes( createHeightMap  );
			if (  !modelInfoJson.biomes.layers ) {
				throw new Error( "ModelInfo.init - WARNING - unable to find layerInfo: " + fileName );					
				return;
			}
			var layers:Object = modelInfoJson.biomes.layers;
			_biomes.layersLoad(layers);
		}
		if ( modelInfoJson.scripts )
			scriptsFromJSON( modelInfoJson.scripts );
		
		if ( modelInfoJson.children )
			childrenFromJSON( modelInfoJson.children );
		
		if ( modelInfoJson.animations )
			animationsFromJSON( modelInfoJson.animations );
	}
	
	private function scriptsFromJSON( $scripts:Object ):void {
		for each ( var so:Object in $scripts ) {
			if ( so.name ) {
				//trace( "ModelInfo.init - Model GUID:" + fileName + "  adding script: " + scriptObject.name );
				_scripts.push( so.name );
			}
		}
	}

	private function animationsFromJSON( $animations:Object ):void {
	// i.e. animData = { "name": "Glide", "type": "state OR action", "guid":"Glide.ajson" }
		for each ( var animData:Object in $animations ) {
			Log.out( "ModelInfo.init - _animationInfo.push animData: " + animData.name );	
			_animationInfo.push( animData );
		}
	}
	
	private function childrenFromJSON( $children:Object ):void {
		for each ( var v:Object in $children ) {
			_childCount++;
			var ii:InstanceInfo = new InstanceInfo();
			ii.initJSON( v );
			// This adds the instanceInfo for the child models to our child list which is processed when object is initialized
			childAdd( ii );
		}
	}
	
	private function cloneObject( obj:Object ):Object {
		var ba:ByteArray = new ByteArray();
		ba.writeObject( obj );
		ba.position = 0;
		var newObj:Object = ba.readObject();
		return newObj;
	}
	
	public function childAdd( $instanceInfo:InstanceInfo):void {
		// Dont add child that already exist
		//Log.out( "ModelInfo.childAdd  fileName: " + fileName + " child ii: " + $instanceInfo, Log.WARN );
		for each ( var child:InstanceInfo in _children ) {
			if ( child === $instanceInfo ) {
				return;
			}
		}
		_children.push( $instanceInfo );
	}
		
	public function childRemove( $instanceInfo:InstanceInfo):void {
		var index:int = 0;
		for each ( var child:InstanceInfo in _children ) {
			if ( child === $instanceInfo ) {
				_children.splice( index, 1 );
				return;
			}
			
			index++;
		}
	}
	
	// Dont load the animations until the model is instaniated
	public function animationsLoad( $owner:VoxelModel ):void {
		_owner = $owner;
		owner.animationsLoaded = true;
		//throw new Error( "ModelInfo.animationsLoad - Check this out, why pass in guid here?" );
		// first test is showed to be the same? RSF
		guid = $owner.instanceInfo.modelGuid;
		
		AnimationEvent.addListener( ModelBaseEvent.DELETE, deleteHandler );
		AnimationEvent.addListener( ModelBaseEvent.ADDED, animationAdd );
		_series = 0;
		for each ( var animData:Object in _animationInfo ) {
			owner.animationsLoaded = false;
			_animationCount++; 
			
			// AnimationEvent( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $ani:Animation, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
			var ae:AnimationEvent;
			if ( Globals.isGuid( animData.guid ) )
				ae = new AnimationEvent( ModelBaseEvent.REQUEST, _series, guid, animData.guid, null, true );
			else
				ae = new AnimationEvent( ModelBaseEvent.REQUEST, _series, guid, animData.name, null, false );
				
			_series = ae.series;
			AnimationEvent.dispatch( ae );
		}
	}
			
	public function animationAdd( $ae:AnimationEvent ):void {
		//Log.out( "ModelInfo.addAnimation " + $ae, Log.WARN );
		if ( _series == $ae.series ) {
			$ae.ani.metadata.modelGuid = guid;
			_animations.push( $ae.ani );
			_animationCount--;
			if ( 0 == _animationCount ) {
				_owner.animationsLoaded = true;
				Log.out( "ModelInfo.addAnimation calling save on owner: " + _owner.metadata.name, Log.WARN );
				_owner.save();
			}
		}
	}
	
	public function deleteHandler( $ae:AnimationEvent ):void {
		//Log.out( "ModelInfo.animationDelete $ae: " + $ae, Log.WARN );
		if ( $ae.modelGuid == guid ) {
			for ( var i:int; i < _animations.length; i++ ) {
				var anim:Animation = _animations[i];
				if ( anim.metadata.guid == $ae.aniGuid ) {
					_animations.splice( i, 1 );
					return;
				}
			}
		}
	}
	
	public function animationGet( $animName:String ):Animation {
		for ( var i:int; i < _animations.length; i++ ) {
			var anim:Animation = _animations[i];
			if ( anim.metadata.name == $animName ) {
				return anim;
			}
		}
		return null;
	}
	
	static public function animationsDelete( modelInfoObject:Object, $modelGuid:String ):void {
		if ( modelInfoObject.model.animations ) {
			Log.out( "ModelInfo.animationsDelete - animations found" );
			var animationsObj:Object = modelInfoObject.model.animations;
			
			for each ( var animData:Object in animationsObj ) {
				AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.DELETE, 0, $modelGuid, animData.guid, null ) );
			}
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function saveVMData( $children:Object ):void {
		_obj = new Object();
		buildExportObject( _obj );
		_obj.model.children = $children;
		//_fileName = guid;
		//guid = $modelGuid;
		_modelJson = _obj;
		
		_obj = _obj.model;
		save();
	}
	
	public function buildExportObject( obj:Object ):void {
		obj.model = new Object();
		obj.model.modelClass = _modelClass;
		obj.model.hasInventory = _hasInventory;
		// biomes:			_biomes,      // Biomes are only used in object generation, once the object has been completed they are removed.
		// children:		_children   // We want the currect children, not the ones loaded in the modelInfo. So we get that from instanceInfo later.
		if ( _grainSize )
			obj.model.grainSize =  _grainSize;
		
		modelsScriptOnly( obj.model );
		animationsGet( obj.model );
				
		function animationsGet( obj:Object ):void {
			var len:int = _animations.length;
			var oa:Vector.<Object> = new Vector.<Object>();
			for ( var index:int; index < len; index++ ) {
				var ao:Object = new Object();
				ao.name = _animations[index].metadata.name;
				ao.type = _animations[index].metadata.aniType;
				ao.guid = _animations[index].metadata.guid;
				Log.out( "ModelInfo.animationsGet - animation.metadata: " + _animations[index].metadata );
				oa.push( ao );
			}
			if ( 0 < oa.length ) obj.animations = oa;
			else                 oa = null;
		}
		
		function modelsScriptOnly( obj:Object ):void {
			var oa:Vector.<Object> = new Vector.<Object>();
			var len:int = _scripts.length;
			for ( var index:int; index < len; index++ ) {
				var so:Object = new Object();
				so.name = _scripts[index];
				Log.out( "ModelInfo.modelsScriptOnly - script: " + _scripts[index] );
				oa.push( so );
			}
			if ( 0 < oa.length ) obj.scripts = oa;
			else                 oa = null;
		}
	} 	

	override public function fromPersistance( $dbo:DatabaseObject ):void {
		_dbo				= $dbo;
		modelClass			= $dbo.modelClass;
		hasInventory 		= $dbo.hasInventory;
		if ( $dbo.children )
			childrenFromJSON( JSONUtil.parse( $dbo.children, Globals.BIGDB_TABLE_MODEL_INFO, "fromPersistance.children" ) );
		if ( $dbo.scripts )
			scriptsFromJSON( JSONUtil.parse( $dbo.scripts, Globals.BIGDB_TABLE_MODEL_INFO, "fromPersistance.scripts" ) );
		if ( $dbo.animations )
			animationsFromJSON( JSONUtil.parse( $dbo.animations, Globals.BIGDB_TABLE_MODEL_INFO, "fromPersistance.animations" ) );
	}

	override protected function toPersistance():void {
		
		dbo.modelClass = _obj.modelClass;
		dbo.hasInventory = _obj.hasInventory;
		
		dbo.children = null; // Need to null it since if we lose our last child, we want to save that state
		if ( _obj.children && _obj.children.length )
			dbo.children = JSON.stringify( _obj.children );
			
		dbo.animations = null;
		if ( _obj.animations && _obj.animations.length )
			dbo.animations = JSON.stringify( _obj.animations );
		
		dbo.scripts = null;
		if ( _obj.scripts && _obj.scripts.length )
			dbo.scripts = JSON.stringify( _obj.scripts );
			
		//_obj.model.editable =  _grainSize;			
		//_obj.model.grainSize =  _grainSize;			
	}

	override protected function toObject():Object {
		return _obj;
	}
}
}