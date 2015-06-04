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
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.Region;
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

public class ModelInfo extends PersistanceObject implements IPersistance
{
	private var _childrenToBeLoaded:Vector.<InstanceInfo> 			= new Vector.<InstanceInfo>;// Child models and their relative positions
	private var _scripts:Vector.<String> 					= new Vector.<String>;		// Default scripts to be used with this model
	private var _animations:Vector.<Animation> 				= new Vector.<Animation>();	// Animations that this model has
			
	private var _fileName:String 							= "INVALID";				// Used for local loading and import of data from local file system
	private var _biomes:Biomes;															// used to generate terrain and apply other functions to oxel
	private var _modelClass:String 							= "VoxelModel";				// Class used to instaniate model
	private var _grainSize:int = 0;														// Used in model generatation
	private var _modelJson:Object;														// copy of json object used to create this
	private var _animationInfo:Vector.<Object> 				= new Vector.<Object>();	// ID and name of animations that this model has, before loading
	private var _animationCount:int;
	private var _series:int														// used to make sure animation is part of same series when loading
	private var _data:OxelPersistance;
	private var _firstLoadFailed:Boolean;
	private var _altId:String;													// used to handle loading from biome
	
	protected 	var	_animationsLoaded:Boolean					= true;
	public 	function get animationsLoaded():Boolean 				{ return _animationsLoaded; }
	public 	function set animationsLoaded(value:Boolean):void  	{ _animationsLoaded = value; }
	
	public function get altId():String 						{ return _altId; }
	public function get json():Object 						{ return _modelJson; }
	public function get fileName():String 					{ return _fileName; }
	public function set fileName(val:String):void 			{ _fileName = val; }
	public function get biomes():Biomes 					{ return _biomes; }
	public function get childrenToBeLoaded():Vector.<InstanceInfo> 	{ return _childrenToBeLoaded; }
	public function get scripts():Vector.<String> 			{ return _scripts; }
	public function get modelClass():String					{ return _modelClass; }
	public function set modelClass(val:String):void 		{ _modelClass ? _modelClass = val : _modelClass = "VoxelModel"; }
	public function get grainSize():int						{ return _grainSize; }
	public function set grainSize(val:int):void				{ _grainSize = val; }
	public function get animations():Vector.<Animation> 	{ return _animations; }
	public function set biomes(value:Biomes):void  			{ _biomes = value; }
	public function get oxel():Oxel 						{ return _data.oxel; }
	public function get data():OxelPersistance  					{ return _data; }
	
	
	public function ModelInfo( $guid:String ):void  { 
		super( $guid, Globals.BIGDB_TABLE_MODEL_INFO ); 
		_data = new OxelPersistance( guid );
	}
	
	override public function set guid(value:String):void { 
		super.guid = value;
		_data.guid = value;
	}
	
	public function toString():String {
		return "ModelInfo - guid: " + guid;
	}
	
	public function createEditCursor( $guid:String ):void {
		_data = new OxelPersistance( $guid );
		_data.createEditCursor();
	}
	
	public function oxelDataChanged():void {
		 _data.changed = true;
	}
	
	public function oxelLoadData():void {
		if ( _data.loaded ) {
			Log.out( "ModelInfo.loadOxelData - returning loaded oxel guid: " + guid );
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.RESULT_COMPLETE, 0, guid, _data ) );
		} else { 
			addListeners();
			// try to load from tables first
			OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST, 0, guid, null, ModelBaseEvent.USE_PERSISTANCE ) );
		}
	}
	
	public function update( $context:Context3D, $elapsedTimeMS:int ):void {
		for each (var vm:VoxelModel in _children)
			vm.update($context, $elapsedTimeMS);
	}
	
	public function bringOutYourDead():void {
		for each (var deadCandidate:VoxelModel in _children) {
			if (true == deadCandidate.dead)
				childRemove(deadCandidate);
		}
	}
	
	public function draw( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean, $isAlpha:Boolean ):void {
		if ( $isAlpha )
			_data.oxel.vertMan.drawNewAlpha( $mvp, $vm, $context, $selected, $isChild );
		else
			_data.oxel.vertMan.drawNew( $mvp, $vm, $context, $selected, $isChild );
			
		for each (var vm:VoxelModel in _children) {
			if (vm && vm.complete)
				vm.draw($mvp, $context, true, $isAlpha );
		}
			
	}

	override public function release():void {
		_biomes = null;
		_childrenToBeLoaded = null;
		_scripts = null;
		_modelJson = null;
		_animations = null;
		_animationInfo = null;
	}

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
	
	private function getGrainSize():int {
		if ( _data && _data.loaded )
			return _data.oxel.gc.grain;
		else 
			return _grainSize;
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
		if ( guid == $ode.modelGuid || altId == $ode.modelGuid ) {
			removeListeners();
			Log.out( "ModelInfo.retrieveData - loaded oxel guid: " + guid );
			_data = $ode.oxelData;
			if ( null == _data.dbo ) {
				_data.changed = true;
				_data.guid = guid;
				_data.save();
			}
		}
	}
	
	private function failedData( $ode:OxelDataEvent):void {
		if ( guid == $ode.modelGuid || altId == $ode.modelGuid ) {
			if ( _firstLoadFailed ) {
				removeListeners();
				Log.out( "ModelInfo.failedData - unable to process request for guid: " + guid, Log.ERROR );
				OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST_FAILED, 0, guid, null ) );		
				return;
			}
			else {
				_firstLoadFailed = true;
				// this should generate the VMD
				if ( biomes ) {
					var layer1:LayerInfo = biomes.layers[0];
					if ( "LoadModelFromIVM" == layer1.functionName ) {
						_altId = layer1.data;
						Log.out( "ModelInfo.failedData - trying to load from local file with alternate name - guid: " + layer1.data, Log.DEBUG );
						OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.REQUEST, 0, layer1.data, null, ModelBaseEvent.USE_FILE_SYSTEM ) );		
					}
					else {
						Log.out( "ModelInfo.failedData - building bio from layer data", Log.DEBUG );
						
						biomes.addToTaskControllerUsingNewStyle( guid );
					}

				} else {
					removeListeners();
					Log.out( "ModelInfo.failedData - no alternative processing method: " + guid, Log.ERROR );
				}
			}
		}
	}

	public function boimeHas():Boolean {
		if ( _biomes && _biomes.layers && 0 < _biomes.layers.length )
			return true;
		return false;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start child operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	protected 	var	_childrenLoaded:Boolean						= true;
	public function get childrenLoaded():Boolean 				{ return _childrenLoaded; }
	public function set childrenLoaded(value:Boolean):void  	{ _childrenLoaded = value; }
	public function childrenLoad( $vm:VoxelModel ):void {
		if ( childrenToBeLoaded && 0 < childrenToBeLoaded.length)
		{
			Log.out( "ModelInfo.childrenLoad - loading " + childrenToBeLoaded.length );
			childrenLoaded	= false;
			ModelLoadingEvent.addListener( ModelLoadingEvent.CHILD_LOADING_COMPLETE, childLoadingComplete );
			//Log.out( "VoxelModel.processClassJson name: " + metadata.name + " - loading child models START" );
			for each (var childInstanceInfo:InstanceInfo in childrenToBeLoaded)
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
				Log.out( "VoxelModel.childrenLoad - calling load on ii: " + childInstanceInfo );
				ModelMakerBase.load( childInstanceInfo, true, false );
			}
			Log.out( "VoxelModel.childrenLoad - addListener for ModelLoadingEvent.CHILD_LOADING_COMPLETE  -  model name: " + $vm.metadata.name );
			childrenReset();
			//Log.out( "VoxelModel.processClassJson - loading child models END" );
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
		
		// remove the children after they are loaded, so that when the object is saved
		// the active children from the voxel model are used.
		// Applies to the "REPLACE_ME" above
		function childrenReset():void {
			_childrenToBeLoaded = null;
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start script operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// TODO add/remove script
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//  start animation operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Dont load the animations until the model is instaniated
	public function animationsLoad():void {
		if ( true == animationsLoaded )
			return;
		//throw new Error( "ModelInfo.animationsLoad - Check this out, why pass in guid here?" );
		
		AnimationEvent.addListener( ModelBaseEvent.DELETE, animationDeleteHandler );
		AnimationEvent.addListener( ModelBaseEvent.ADDED, animationAdd );
		_series = 0;
		if ( 0 < _animationInfo.length ) {
			for each ( var animData:Object in _animationInfo ) {
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
		else
			animationsLoaded = true;
	}
			
	public function animationsDelete():void {
		if ( _animationInfo ) {
			Log.out( "ModelInfo.animationsDelete - animations found" );
			for each ( var animData:Object in _animationInfo ) {
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
				Log.out( "ModelInfo.addAnimation safe to save now: " + guid, Log.WARN );
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
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start persistance
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function save():void {
		if ( Globals.online && changed ) {
			if (  true == animationsLoaded && true == childrenLoaded ) {
				Log.out( "ModelInfo.save - Saving ModelInfo: " + guid  + " in table: " + table, Log.WARN );
				changed = false;
				addSaveEvents();
				if ( _dbo )
					toPersistance();
				else
					toObject();
					
				PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, table, guid, _dbo, _obj ) );
			}
			Log.out( "ModelInfo.save - Not saving ModelInfo - children OR animations not loaded - guid: " + guid );
		}
		else
			Log.out( "ModelInfo.save - Not saving ModelInfo - either offline or NOT changed - guid: " + guid );
			
		_data.save();	
		
		for ( var i:int; i < _children.length; i++ ) {
			var child:VoxelModel = _children[i];
			child.save();
		}
	}
	
	public function fromPersistance( $dbo:DatabaseObject ):void {
		_dbo				= $dbo;
		if ( null == $dbo.modelClass )
			throw new Error( "ModelInfo.fromPersistance - no model class set, make sure its not an empty record" );
		modelClass			= $dbo.modelClass;
		if ( $dbo.children )
			childrenFromObject( JSONUtil.parse( $dbo.children, Globals.BIGDB_TABLE_MODEL_INFO, "fromPersistance.children" ) );
		if ( $dbo.scripts )
			scriptsFromObject( JSONUtil.parse( $dbo.scripts, Globals.BIGDB_TABLE_MODEL_INFO, "fromPersistance.scripts" ) );
		if ( $dbo.animations )
			animationsFromObject( JSONUtil.parse( $dbo.animations, Globals.BIGDB_TABLE_MODEL_INFO, "fromPersistance.animations" ) );
	}

	public function toPersistance():void {
		
		// This is complicated build process, let the toObject do the heavy lifting.
		toObject();
			
		dbo.modelClass = _obj.modelClass;
		dbo.grainSize =  getGrainSize();
		
		if ( _obj.children ) {
			if ( _obj.children.length )
				dbo.children = JSON.stringify( _obj.children );
			else	
				dbo.children = null;
		}
			
		if ( _obj.animations ) {
			if ( _obj.animations.length )
				dbo.animations = JSON.stringify( _obj.animations );
			else	
				dbo.animations = null;
		}
		
		if ( _obj.scripts ) { 
			if ( _obj.scripts.length )
				dbo.scripts = JSON.stringify( _obj.scripts );
			else	
				dbo.scripts = null;
		}
			
	}
	
	public function toObject():void {
		if ( null == _obj )
			_obj = new Object();
			
		_obj.modelClass = _modelClass;
		// biomes:			_biomes,      // Biomes are only used in object generation, once the object has been completed they are removed.
		_obj.grainSize =  getGrainSize();
		
		childrenGet();
		modelsScriptOnly();
		animationsGet();
				
		function childrenGet():void {
		// Same code that is in modelCache to build models in region
		// this is just models in models
			var oa:Vector.<Object> = new Vector.<Object>();
			for each ( var vm:VoxelModel in children ) {
				if ( vm is Player ) // Or Avatar
					continue;
				//Log.out( "ModelInfo.childrenGet - name: " + metadata.name + "  modelGuid: " + instanceInfo.modelGuid + "  child ii: " + vm.instanceInfo, Log.WARN );
				var io:Object = new Object();
				vm.instanceInfo.buildExportObject( io );
				oa.push( io );
			}
			if ( 0 < oa.length ) _obj.children = oa;
			else                 oa = null;
		}
		
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
			if ( 0 < oa.length ) _obj.animations = oa;
			else                 oa = null;
		}
		
		function modelsScriptOnly():void {
			var oa:Vector.<Object> = new Vector.<Object>();
			var len:int = _scripts.length;
			for ( var index:int; index < len; index++ ) {
				var so:Object = new Object();
				so.name = _scripts[index];
				Log.out( "ModelInfo.modelsScriptOnly - script: " + _scripts[index] );
				oa.push( so );
			}
			if ( 0 < oa.length ) _obj.scripts = oa;
			else                 oa = null;
		}
	} 	

	// From JSON to modelInfo
	public function fromObject( $object:Object, $ba:ByteArray ):void {		
		_obj = $object;
		if ( _obj.modelGuid )
			guid = _fileName = _obj.modelGuid;
		else if ( _obj.guid )
			guid = _fileName = _obj.guid;
		else
			Log.out( "ModelInfo.fromObject - no guid assigned", Log.WARN );
		
		if ( _obj.grainSize )
			grainSize = _obj.grainSize;
		else if ( _obj.GrainSize )
			Log.out( "ModelInfo.fromObject - invalid spelling on grainSize on import", Log.WARN );
		else if ( _obj.grainsize )
			Log.out( "ModelInfo.fromObject - invalid spelling on grainSize on import", Log.WARN );
		
		if ( _obj.modelClass )
			_modelClass = _obj.modelClass;

		if ( _obj.biomes )
			biomesFromObject( _obj.biomes );
		
		if ( _obj.scripts )
			scriptsFromObject( _obj.scripts );
		// This is an artifact from the old mjson files, new system saves all as "scripts"
		if ( _obj.script )
			scriptsFromObject( _obj.script );
		
		if ( _obj.children )
			childrenFromObject( _obj.children );
		
		if ( _obj.animations )
			animationsFromObject( _obj.animations );
	}
	
	public function fromByteArray( $ba:ByteArray ):void {;}
	public function toByteArray( $ba:ByteArray ):ByteArray { return null };
	
	private function biomesFromObject( $biomes:Object ):void {
		// TODO this should only be true for new terrain models.
		const createHeightMap:Boolean = true;
		_biomes = new Biomes( createHeightMap  );
		if ( !$biomes.layers )
			throw new Error( "ModelInfo.init - WARNING - unable to find layerInfo: " + fileName );					
		_biomes.layersLoad( $biomes.layers );
		// now remove the biome data from the object so it is not saved to persistance
		delete _obj.biomes;	
		
	}
	
	private function scriptsFromObject( $scripts:Object ):void {
		for each ( var so:Object in $scripts ) {
			if ( so.name ) {
				//trace( "ModelInfo.init - Model GUID:" + fileName + "  adding script: " + scriptObject.name );
				_scripts.push( so.name );
			}
		}
	}

	private function animationsFromObject( $animations:Object ):void {
	// i.e. animData = { "name": "Glide", "type": "state OR action", "guid":"Glide.ajson" }
		for each ( var animData:Object in $animations ) {
			Log.out( "ModelInfo.init - _animationInfo.push animData: " + animData.name );	
			_animationInfo.push( animData );
		}
	}
	
	private function childrenFromObject( $children:Object ):void {
		for each ( var v:Object in $children ) {
			var ii:InstanceInfo = new InstanceInfo();
			ii.initJSON( v );
			// This adds the instanceInfo for the child models to our child list which is processed when object is initialized
			childAdd( ii );
		}

		function childAdd( $instanceInfo:InstanceInfo ):void {
			// Dont add child that already exist
			//Log.out( "ModelInfo.childAdd  fileName: " + fileName + " child ii: " + $instanceInfo, Log.WARN );
			for each ( var child:InstanceInfo in _childrenToBeLoaded ) {
				if ( child === $instanceInfo ) {
					return;
				}
			}
			_childrenToBeLoaded.push( $instanceInfo );
		}
	}	
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Children functions
	/////////////////////////////////////////////////////////////////////////////////////////////
	protected 	var	_children:Vector.<VoxelModel> 				= new Vector.<VoxelModel>; 	// INSTANCE NOT EXPORTED
	public	function get children():Vector.<VoxelModel>			{ return _children; }
	public	function 	 childrenGet():Vector.<VoxelModel>		{ return _children; } // This is so the function can be passed as parameter
	
	public function childAdd( $child:VoxelModel):void
	{
		if ( null ==  $child.instanceInfo.instanceGuid )
			 $child.instanceInfo.instanceGuid = Globals.getUID();
		//Log.out(  "-------------- VoxelModel.childAdd -  $child: " +  $child.toString() );
		// remove parent level model
		Region.currentRegion.modelCache.changeFromParentToChild( $child);
		_children.push( $child);
		changed = true;
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
		
		//modelInfo.childRemove( $instanceInfo );
		// Need a message here?
		//var me:ModelEvent = new ModelEvent( ModelEvent.REMOVE, vm.instanceInfo.guid, instanceInfo.guid );
		//Globals.g_app.dispatchEvent( me );
	}
	
	public function childRemove(vm:VoxelModel):void {
		var index:int = 0;
		for each (var child:VoxelModel in _children) {
			if (child == vm) {
				Log.out(  "VoxelModel.childRemove - removing Model: " + child.toString() );
				_children.splice(index, 1);
				changed = true;				
				break;
			}
			index++;
		}
		
		//modelInfo.childRemove(vm.instanceInfo);
		// Need a message here?
		//var me:ModelEvent = new ModelEvent( ModelEvent.REMOVE, vm.instanceInfo.guid, instanceInfo.guid );
		//Globals.g_app.dispatchEvent( me );
	}
	
	// This leaves the model, but detaches it from parent.
	public function childDetach( $vm:VoxelModel, $vmParent:VoxelModel ):void
	{
		// removethis child from the parents info
		childRemove($vm);
		
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
	
}
}