/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.worldmodel.models.makers.ModelLibrary;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.utils.ByteArray;
import flash.geom.Matrix3D;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.pools.OxelPool;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.biomes.Biomes;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.utils.transitions.properties.SoundShortcuts;

public class ModelInfo extends PersistanceObject
{
	private var _childrenInstanceInfo:Vector.<InstanceInfo> 		= new Vector.<InstanceInfo>;// Child models and their relative positions
	//private var _scripts:Vector.<String> 							= new Vector.<String>;		// Default scripts to be used with this model
	private var _animations:Vector.<Animation> 						= new Vector.<Animation>();	// Animations that this model has
	
	private var _data:OxelPersistance;
	private var _associatedGrain:GrainCursor;						// associates the model with a grain in the parent model
	
	public function get altGuid():String 							{ return _altGuid; }
	public function get fileName():String 							{ return _fileName; }
	public function set fileName(val:String):void 					{ _fileName = val; }
	public function get biomes():Biomes 							{ return _biomes; }
	public function get childrenInstanceInfo():Vector.<InstanceInfo>{ return _childrenInstanceInfo; }
	public function get scripts():Vector.<String> 					{ return _info.scripts; }
	public function get modelClass():String							{ return _info.modelClass; }
	public function set modelClass(val:String):void 				{ _info.modelClass = val; }
	public function get grainSize():int								{ return _info.grainSize; }
	public function set grainSize(val:int):void						{ _info.grainSize = val; }
	public function get animations():Vector.<Animation> 			{ return _animations; }
	public function set biomes(value:Biomes):void  					{ _biomes = value; }
	public function get oxel():Oxel 								{ return _data.oxel; }
	public function get data():OxelPersistance  					{ return _data; }
	public function get associatedGrain():GrainCursor 				{ return _associatedGrain; }
	public function set associatedGrain(value:GrainCursor):void 	{ _associatedGrain = value; }
	
	public function ModelInfo( $guid:String ):void  { 
		super( $guid, Globals.BIGDB_TABLE_MODEL_INFO ); 
		//_data = new OxelPersistance( guid );
	}

	override public function set guid($newGuid:String):void { 
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null ) );
		if ( _data ) {
			_data.guid = $newGuid;
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null ) );
		}
		changed = true;
	}
	
	public function toString():String {
		return "ModelInfo - guid: " + guid;
	}
	
	public function createEditCursor( $guid:String ):void {
		_data = new OxelPersistance( $guid );
		_data.createEditCursor();
	}
	
	public function update( $context:Context3D, $elapsedTimeMS:int ):void {
		if ( data )
			data.update();
			
		for each (var vm:VoxelModel in _children)
			vm.update($context, $elapsedTimeMS);
	}
	
	public function draw( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean, $isAlpha:Boolean ):void {
		if ( _data )
			_data.draw(	$mvp, $vm, $context, $selected, $isChild, $isAlpha );
			
		for each (var vm:VoxelModel in _children) {
			if (vm && vm.complete)
				vm.draw($mvp, $context, true, $isAlpha );
		}
	}

	override public function release():void {
		super.release();
		_biomes = null;
		_childrenInstanceInfo = null;
		_animations = null;
		_data.release();
	}

	private function getGrainSize():int {
		if ( _data && _data.loaded )
			return _data.oxel.gc.grain;
		else 
			return _info.grainSize;
	}

	public function bringOutYourDead():void {
		for each (var deadCandidate:VoxelModel in _children) {
			if (true == deadCandidate.dead)
				childRemove(deadCandidate.instanceInfo);
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start data (oxel) operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private function addListeners():void {
		OxelDataEvent.addListener( ModelBaseEvent.ADDED, retrieveData );		
		OxelDataEvent.addListener( ModelBaseEvent.RESULT, retrieveData );		
		OxelDataEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedData );
	}
	
	private function removeListeners():void {
		OxelDataEvent.removeListener( ModelBaseEvent.ADDED, retrieveData );		
		OxelDataEvent.removeListener( ModelBaseEvent.RESULT, retrieveData );		
		OxelDataEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedData );
	}
	
	private function retrieveData( $ode:OxelDataEvent):void {
		if ( guid == $ode.modelGuid || altGuid == $ode.modelGuid ) {
			removeListeners();
			Log.out( "ModelInfo.retrieveData - loaded oxel guid: " + guid );
			_data = $ode.oxelData;
			if ( "0" == _data.dbo.key ) {
				_data.changed = true;
				_data.guid = guid;
				// When import objects, we have to update the cache so they have the correct info.
				if ( null != _altGuid )
					OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.UPDATE_GUID, 0, altGuid + ":" + guid, null ) );
				_data.save();
			}
		}
	}
	
	private function failedData( $ode:OxelDataEvent):void {
		if ( guid == $ode.modelGuid || altGuid == $ode.modelGuid ) {
			if ( _firstLoadFailed ) {
				removeListeners();
				Log.out( "ModelInfo.failedData - unable to process request for guid: " + guid, Log.ERROR );
				OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, 0, guid, null ) );		
			}
			else {
				_firstLoadFailed = true;
				if ( biomes ) // this should generate the VMD
					loadFromBiomeData();
				else {
					removeListeners();
					Log.out( "ModelInfo.failedData - no alternative processing method: " + guid, Log.ERROR );
					OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, 0, guid, null ) );		
				}
			}
		}
	}
	
	private function loadFromBiomeData():void {
		var layer1:LayerInfo = biomes.layers[0];
		if ( "LoadModelFromIVM" == layer1.functionName ) {
			_altGuid = layer1.data;
			Log.out( "ModelInfo.loadFromBiomeData - trying to load from local file with alternate name - guid: " + _altGuid, Log.DEBUG );
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST, 0, _altGuid, null, ModelBaseEvent.USE_FILE_SYSTEM ) );		
		}
		else {
			Log.out( "ModelInfo.loadFromBiomeData - building bio from layer data", Log.DEBUG );
			biomes.addToTaskControllerUsingNewStyle( guid );
		}
	}

	public function boimeHas():Boolean {
		if ( _biomes && _biomes.layers && 0 < _biomes.layers.length )
			return true;
		return false;
	}
	
	public function changeOxel( $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean {
		var result:Boolean = _data.changeOxel( guid, $gc, $type, $onlyChangeType );
		if ( TypeInfo.AIR == $type )
			childRemoveByGC( $gc );
		return result;
	}

	public function oxelDataChanged():void {
		 _data.changed = true;
	}
	
	public function oxelLoadData():void {
		if ( _data && _data.loaded ) {
			Log.out( "ModelInfo.loadOxelData - returning loaded oxel guid: " + guid );
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.RESULT_COMPLETE, 0, guid, _data ) );
		} else { 
			addListeners();
			// try to load from tables first
			Log.out( "ModelInfo.loadOxelData - requesting oxel guid: " + guid );
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST, 0, guid, null, ModelBaseEvent.USE_PERSISTANCE ) );
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start script operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// TODO add/remove script
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//  start animation operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	protected 	var	_animationsLoaded:Boolean						= true;
	public 	function get animationsLoaded():Boolean 				{ return _animationsLoaded; }
	public 	function set animationsLoaded(value:Boolean):void		{ _animationsLoaded = value; }
	private var _animationInfo:Vector.<Object> 						= new Vector.<Object>();	// ID and name of animations that this model has, before loading
	private var _animationCount:int;			
	
	// Dont load the animations until the model is instaniated
	public function animationsLoad():void {
		AnimationEvent.addListener( ModelBaseEvent.DELETE, animationDeleteHandler );
		AnimationEvent.addListener( ModelBaseEvent.ADDED, animationAdd );
		_series = 0;
		if ( _info. animationInfo && 0 < _info.animationInfo.length ) {
			for each ( var animData:Object in _info.animationInfo ) {
				animationsLoaded = false;
				_animationCount++; 
				
				// AnimationEvent( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $ani:Animation, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
				var ae:AnimationEvent;
				if ( Globals.isGuid( animData.guid ) )
					ae = new AnimationEvent( ModelBaseEvent.REQUEST, _series, guid, animData.guid, null, ModelBaseEvent.USE_PERSISTANCE );
				else
					ae = new AnimationEvent( ModelBaseEvent.REQUEST, _series, guid, animData.name, null, ModelBaseEvent.USE_FILE_SYSTEM );
					
				_series = ae.series;
				AnimationEvent.dispatch( ae );
			}
		}
	}
			
	public function animationsDelete():void {
		if ( _info.animationInfo ) {
			Log.out( "ModelInfo.animationsDelete - animations found" );
			for each ( var animData:Object in _info.animationInfo ) {
				AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.DELETE, 0, guid, animData.guid, null ) );
			}
		}
	}

	public function animationAdd( $ae:AnimationEvent ):void {
		//Log.out( "ModelInfo.addAnimation " + $ae, Log.WARN );
		if ( _series == $ae.series ) {
			$ae.ani.metadata.modelGuid = guid;
			_animations.push( $ae.ani );
			_animationCount--;
			if ( 0 == _animationCount ) {
				animationsLoaded = true;
				//Log.out( "ModelInfo.addAnimation safe to save now: " + guid, Log.WARN );
			}
		}
	}
	
	public function animationDeleteHandler( $ae:AnimationEvent ):void {
		//Log.out( "ModelInfo.animationDelete $ae: " + $ae, Log.WARN );
		if ( $ae.modelGuid == guid ) {
			for ( var i:int; i < _animations.length; i++ ) {
				var anim:Animation = _animations[i];
				if ( anim.metadata.guid == $ae.aniGuid ) {
					_animations.splice( i, 1 );
					changed = true;
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

	public function childRemove( $ii:InstanceInfo ):void	{
		for ( var i:int; i < _childrenInstanceInfo.length; i++ )
			if ( $ii == _childrenInstanceInfo[i] );
				_childrenInstanceInfo[i] = null;
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start persistance
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private static const DEFAULT_CLASS:String		= "VoxelModel";
	private var _info:Object;
	private var _fileName:String 					= "INVALID"; 	// Used for local loading and import of data from local file system
	private var _biomes:Biomes;										// used to generate terrain and apply other functions to oxel
	private var _series:int											// used to make sure animation is part of same series when loading
	private var _altGuid:String;									// used to handle loading from biome
	private var _firstLoadFailed:Boolean;							// true if load from biomes data is needed
	
	public function save():void {
		if ( Globals.online && changed ) {
			if (  true == animationsLoaded && true == childrenLoaded ) {
				if ( Globals.isGuid( guid ) ) {
					//Log.out( "ModelInfo.save - Saving ModelInfo: " + guid  + " in table: " + table, Log.WARN );
					changed = false;
					addSaveEvents();
					toObject();
						
					PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, table, guid, dbo, null ) );
				}
			}
			//else 
				//Log.out( "ModelInfo.save - Not saving ModelInfo - children OR animations not loaded - guid: " + guid );
		}
		//else
			//Log.out( "ModelInfo.save - Not saving ModelInfo - either offline or NOT changed - guid: " + guid );
			
		if ( _data )
			_data.save();	
		
		for ( var i:int; i < _children.length; i++ ) {
			var child:VoxelModel = _children[i];
			child.save();
		}
	}
	
	
	public function fromObjectImport( $dbo:DatabaseObject ):void {
		_dbo = $dbo;
		// The data is needed the first time it saves the object from import, after that it goes away
		if ( !dbo.data.model )
			return;
		
		_info = $dbo.data.model;
		loadFromInfo();
	}
	
	public function fromObject( $dbo:DatabaseObject ):void {
		_dbo = $dbo;
		if ( !dbo.model )
			return;
		
		_info = $dbo.model;
		loadFromInfo();
	}
	
	private function loadFromInfo():void {
		if ( !_info.modelClass )
			_info.modelClass = DEFAULT_CLASS;
		// Only attributes that need additional handling go here.
		if ( _info.biomes )
			biomesFromObject( _info.biomes );
		
		if ( _info.scripts )
			scriptsFromObject( _info.scripts );
		if ( _info.children )
			childrenFromObject( _info.children );
		if ( _info.animations )
			animationsFromObject( _info.animations );
	
	}

		public function toObject():void {
		// I am faking a heirarchy here, not good object oriented behavior but needs major redesign to do what I want.
		// so instead I just get the current setting from the class
		var modelClassPrototype:Class = ModelLibrary.getAsset( _info.modelClass );
		try {
			modelClassPrototype.buildExportObject( dbo );
		} catch ( e:Error ) {
			Log.out( "ModelInfo.toObject - Error with Class: " + _info.modelClass, Log.ERROR );
		}

		_info.grainSize =  getGrainSize();
		if ( null != associatedGrain )
			_info.associatedGrain = associatedGrain;
		
		var childrenAdded:int = childrenGet();
		if ( "Dragon" == modelClass )
			if ( 3 > childrenAdded ) {
				trace( "ModelInfo.toObject - DRAGON ERROR", Log.WARN );
				// lets retry this so I can watch it.
				childrenGet();
			}
		//modelsScriptOnly();
		//animationsGet();
		
		function childrenGet():int {
		// Same code that is in modelCache to build models in region
		// this is just models in models
			var oc:Vector.<Object> = new Vector.<Object>();
			for ( var i:int; i < _childrenInstanceInfo.length; i++ ) {
				if ( null != _childrenInstanceInfo[i] ) {
					var io:Object = new Object();
					_childrenInstanceInfo[i].buildExportObject( io );
					oc.push( io );
				}
			}

			var len:int = oc.length;
			if ( 0 < len )
				_info.children = JSON.stringify( oc );
			oc = null;
			return len;
		}
		/*
		function animationsGet():void {
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
			if ( 0 < oa.length ) 
				_info.animations = JSON.stringify( oa );
			oa = null;
		}
		*/
		/*
		function modelsScriptOnly():void {
			var os:Vector.<Object> = new Vector.<Object>();
			var len:int = _scripts.length;
			for ( var index:int; index < len; index++ ) {
				var so:Object = new Object();
				so.name = _scripts[index];
				Log.out( "ModelInfo.modelsScriptOnly - script: " + _scripts[index] );
				os.push( so );
			}
			if ( 0 < os.length ) 
				_info.scripts = JSON.stringify( os );
			os = null;
		}
		*/
	} 	

	private function biomesFromObject( $biomes:Object ):void {
		// TODO this should only be true for new terrain models.
		const createHeightMap:Boolean = true;
		_biomes = new Biomes( createHeightMap  );
		if ( !$biomes.layers )
			throw new Error( "ModelInfo.biomesFromObject - WARNING - unable to find layerInfo: " + fileName );					
		_biomes.layersLoad( $biomes.layers );
		// now remove the biome data from the object so it is not saved to persistance
		delete _info.biomes;	
		
	}
	private function scriptsFromObject( $scripts:Object ):void {
		for each ( var so:Object in $scripts ) {
			if ( so.name ) {
				Log.out( "===== >>> FIX FIX - ModelInfo.init - Model GUID:" + guid + "  adding script: " + so.name, Log.WARN );
				//_scripts.push( so.name );
			}
		}
	}
	private function animationsFromObject( $animations:Object ):void {
	// i.e. animData = { "name": "Glide", "guid":"Glide.ajson" }
		Log.out( "ModelInfo.animationsFromObject" );	
		for each ( var animData:Object in $animations ) {
			Log.out( "ModelInfo.animationsFromObject - _animationInfo.push animData: " + animData.name );	
			_animationInfo.push( animData );
		}
	}

	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Children functions
	/////////////////////////////////////////////////////////////////////////////////////////////
	protected 	var			 _children:Vector.<VoxelModel>			= new Vector.<VoxelModel>; 	// INSTANCE NOT EXPORTED
	public		function get children():Vector.<VoxelModel>			{ return _children; }
	public		function 	 childrenGet():Vector.<VoxelModel>		{ return _children; } // This is so the function can be passed as parameter
	
	protected 	var			_childrenLoaded:Boolean					= true;
	public 		function get childrenLoaded():Boolean 				{ return _childrenLoaded; }
	public 		function set childrenLoaded(value:Boolean):void  	{ _childrenLoaded = value; }
	/////////////////////
	private function childrenFromObject( $children:Object ):void {
		Log.out( "ModelInfo.childrenFromObject", Log.DEBUG );
		for each ( var v:Object in $children ) {
			var ii:InstanceInfo = new InstanceInfo();
			ii.initJSON( v.instanceInfo );
			// This adds the instanceInfo for the child models to our child list which is processed when object is initialized
			childrenInstanceInfoAdd( ii );
		}
	}
	
	private function childrenInstanceInfoAdd( $instanceInfo:InstanceInfo ):void {
		if ( guid == $instanceInfo.modelGuid ) {
			// TODO this needs to examine all of the children in that model guid.
			// Since this would allow B owns A, and you could add B to A, which would cause a recurvise error
			Log.out( "ModelInfo.childAddInstanceInfo - Rejecting child with same model guid as parent", Log.ERROR );
			return;
		}
		// Dont add child that already exist
		//Log.out( "ModelInfo.childAddInstanceInfo  fileName: " + fileName + " child ii: " + $instanceInfo, Log.WARN );
		for each ( var child:InstanceInfo in _childrenInstanceInfo ) {
			if ( child === $instanceInfo ) {
				//Log.out( "ModelInfo.childAddInstanceInfo - Rejecting child with same instance guid as sibling", Log.ERROR );
				return;
			}
		}
		_childrenInstanceInfo.push( $instanceInfo );
	}
	
	public function scriptsLoad( $instanceInfo:InstanceInfo ):void {
		// Both instanceInfo and modelInfo can have scripts. With each being persisted in correct location.
		// Currently both are persisted to instanceInfo, which is very bad...
		if ( scripts && 0 < scripts.length)
		{
			for each (var scriptName:String in scripts)
				$instanceInfo.addScript( scriptName, true );
		}
	}
	
	
	public function childrenLoad( $vm:VoxelModel ):void {
		if ( childrenInstanceInfo && 0 < childrenInstanceInfo.length)
		{
			Log.out( "ModelInfo.childrenLoad - loading for model: " + guid + childrenInstanceInfo.length );
			childrenLoaded	= false;
			ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childLoadingComplete );
			for each (var childInstanceInfo:InstanceInfo in childrenInstanceInfo)
			{
				// Add the parent model info to the child.
				childInstanceInfo.controllingModel = $vm;
				childInstanceInfo.baseLightLevel = $vm.instanceInfo.baseLightLevel;
				
				//Log.out( "VoxelModel.childrenLoad - create child of parent.instance: " + instanceInfo.guid + "  - child.instanceGuid: " + child.instanceGuid );					
				if ( null == childInstanceInfo.modelGuid )
					continue;
				// now load the child, this might load from the persistance
				// or it could be an import, or it could be a model for the toolbar.
				// we never want to prompt for imported children, since this only happens in dev mode.
				// to test if we are in the bar mode, we test of instanceGuid.
				// Since this is a child object, it automatically get added to the parent.
				// So add to cache just adds it to parent instance.
				//Log.out( "VoxelModel.childrenLoad - THIS CAUSES A CIRCULAR REFERENCE - calling maker on: " + childInstanceInfo.modelGuid + " parentGuid: " + instanceInfo.modelGuid, Log.ERROR );
				//Log.out( "VoxelModel.childrenLoad - calling load on ii: " + childInstanceInfo );
				ModelMakerBase.load( childInstanceInfo, true, false );
			}
			Log.out( "VoxelModel.childrenLoad - addListener for ModelLoadingEvent.CHILD_LOADING_COMPLETE  -  model name: " + $vm.metadata.name );
			//Log.out( "VoxelModel.childrenLoad - loading child models END" );
		}
		else
			childrenLoaded	= true;
		
		function childLoadingComplete(e:ModelLoadingEvent):void {
	//		Log.out( "VoxelModel.childLoadingComplete - e: " + e, Log.WARN );
			if ( e.parentModelGuid == guid ) {
				//Log.out( "VoxelModel.childLoadingComplete - for modelGuid: " + instanceInfo.modelGuid, Log.WARN );
				ModelLoadingEvent.removeListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childLoadingComplete );
				// if we save the model, before it is complete, we put bad child data into model info
				childrenLoaded = true;
			}
		}
	}
	

	public function childRemoveByGC( $gc:GrainCursor ):Boolean {
		
		var index:int = 0;
		var gc:GrainCursor;
		var result:Boolean;
		for each (var child:VoxelModel in _children) {
			if ( !child || !child.associatedGrain )
				continue;
			gc = child.associatedGrain;	
			if ( gc.is_equal( $gc ) ) {
				_children.splice(index, 1);
				result = true;
				break;
			}
			index++;
		}
		return result;
		// Need a message here?
		//var me:ModelEvent = new ModelEvent( ModelEvent.REMOVE, vm.instanceInfo.guid, instanceInfo.guid );
		//Globals.g_app.dispatchEvent( me );
	}

	public function childAdd( $child:VoxelModel):void
	{
		if ( null ==  $child.instanceInfo.instanceGuid )
			 $child.instanceInfo.instanceGuid = Globals.getUID();
		//Log.out(  "-------------- VoxelModel.childAdd -  $child: " +  $child.toString() );
		// remove parent level model
//		Region.currentRegion.modelCache.changeFromParentToChild( $child);
		_children.push( $child);
		changed = true;
		// Dont add the player to the instanceInfo, or you end up in a recursive loop
		if ( $child is Player )
			return;
		else
			childrenInstanceInfoAdd( $child.instanceInfo )
//		$child.instanceInfo.baseLightLevel = owner.instanceInfo.baseLightLevel;
	}
	
	public function childRemoveByInstanceInfo( $instanceInfo:InstanceInfo ):void {
		
		var index:int = 0;
		for each (var child:VoxelModel in _children) {
			if (child.instanceInfo.instanceGuid ==  $instanceInfo.instanceGuid ) {
				_children.splice(index, 1);
				changed = true;
				break;
			}
			index++;
		}
		
		// Need a message here?
		//var me:ModelEvent = new ModelEvent( ModelEvent.REMOVE, vm.instanceInfo.guid, instanceInfo.guid );
		//Globals.g_app.dispatchEvent( me );
	}
	
	// This leaves the model, but detaches it from parent.
	public function childDetach( $vm:VoxelModel, $vmParent:VoxelModel ):void
	{
		// removethis child from the parents info
		childRemove($vm.instanceInfo);
		
		// this make it belong to the world
		$vm.instanceInfo.controllingModel = null;
		//if ( !($vm is Player) )
		Region.currentRegion.modelCache.add( $vm );

		
		// now give it correct world space position and velocity
		//////////////////////////////////////////////////////
		// get the model space position of the object
		var newPosition:Vector3D = $vm.instanceInfo.positionGet.clone();
		// position is based on model space, but we want to rotate around the center of the object
		newPosition = newPosition.subtract($vmParent.instanceInfo.center);
		newPosition = $vmParent.instanceInfo.worldSpaceMatrix.deltaTransformVector(newPosition);
		// add the center back in
		newPosition = newPosition.add($vmParent.instanceInfo.center);
		
		$vm.instanceInfo.positionSet = newPosition.add($vmParent.instanceInfo.positionGet);
		$vm.instanceInfo.velocitySet = $vmParent.instanceInfo.velocityGet;
		
		// This model ($vm.instanceInfo.guid) is detaching (ModelEvent.DETACH) from root model (instanceInfo.guid)
		var me:ModelEvent = new ModelEvent(ModelEvent.DETACH, $vm.instanceInfo.instanceGuid, null, null, $vmParent.instanceInfo.instanceGuid);
		Globals.g_app.dispatchEvent(me);
		changed = true;				
	}
	
	public function childModelFind(guid:String):VoxelModel
	{
		for each (var child:VoxelModel in _children) {
			if (child.instanceInfo.instanceGuid == guid)
				return child;
		}
		// didnt find it at first level, lets look recurvsivly
		for each ( child in _children) {
			var cvm:VoxelModel = child.modelInfo.childModelFind( guid );
			if ( cvm )
				return cvm;
		}
		
		//Log.out(  "VoxelModel.childFind - not found for guid: " + guid, Log.WARN );
		return null
	}
	
	public function childFindByName($name:String):VoxelModel
	{
		for each (var child:VoxelModel in _children) {
			if (child.metadata.name == $name)
				return child;
		}
		throw new Error("VoxelModel.childFindByName - not found for name: " + $name);
	}
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  End Children functions
	/////////////////////////////////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Attic
	/////////////////////////////////////////////////////////////////////////////////////////////
	/*
	override public function clone( $guid:String ):* {
		_data.clone( $guid );
		throw new Error( "ModelInfo.clone - what to do here" );
	}

	private function cloneObject( obj:Object ):Object {
		var ba:ByteArray = new ByteArray();
		ba.writeObject( obj );
		ba.position = 0;
		var newObj:Object = ba.readObject();
		return newObj;
	}
	*/
	
}
}