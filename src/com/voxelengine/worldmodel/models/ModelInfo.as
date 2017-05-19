/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{

import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ObjectHierarchyData;
import com.voxelengine.worldmodel.models.types.Avatar;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.tasks.renderTasks.FromByteArray;

import flash.display3D.Context3D;
import flash.geom.Vector3D;
import flash.geom.Matrix3D;

import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.AnimationEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.biomes.Biomes;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.oxel.Lighting;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;
import com.voxelengine.worldmodel.models.makers.ModelLibrary;
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class ModelInfo extends PersistenceObject
{
	public function get animationInfo():Object						{ return dbo.animations; }
	
	// This stores the instantiated objects
	private var 		_animations:Vector.<Animation> 				= new Vector.<Animation>();	// Animations that this model has
	public function get animations():Vector.<Animation> 			{ return _animations; }
	
	private var 		_oxelPersistence:OxelPersistence;
	public function get oxelPersistence():OxelPersistence  			{ return _oxelPersistence; }
	public function set oxelPersistence($oxel:OxelPersistence ):void { _oxelPersistence = $oxel; }

	public function get scripts():Array 							{ return dbo.scripts; }
	public function get modelClass():String							{ return dbo.modelClass; }
	public function get childOfGuid():String						{ return dbo.childOfGuid; }
	public function set childOfGuid( $val:String ):void				{ dbo.childOfGuid = $val; changed = true; }
//	public function set modelClass(val:String):void 				{ dbo.modelClass = val;  changed = true; }
	public function set modelClass(val:String):void 				{
		if ( val == null )
				throw new Error( "ModelInfo.modelClass CAN NOT BE NULL");
		dbo.modelClass = val;
		changed = true;
	}

	public function get lockLight():Boolean { return dbo.lockLight; }
	public function set lockLight( $val:Boolean ):void { dbo.lockLight = $val; changed = true; }

	private var			_owner:VoxelModel;
	public function get owner():VoxelModel 							{ return _owner; }
	public function set owner(value:VoxelModel):void 				{ _owner = value; }

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// overrideable in instanceInfo
	// how to link this to instance info, when this is shared object???
	public function get grainSize():int								{
		if ( oxelPersistence && oxelPersistence.oxelCount )
			return oxelPersistence.oxel.gc.grain;
		else
			return dbo.grainSize;
	}
	public function set grainSize(val:int):void						{ dbo.grainSize = val;  changed = true; }

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function ModelInfo( $guid:String, $dbo:DatabaseObject, $newData:Object ):void  {
		super( $guid, Globals.BIGDB_TABLE_MODEL_INFO );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else {
			dbo = $dbo;
		}

		init( $newData );
	}

	override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		setToDefault();

		function setToDefault():void {
			modelClass = DEFAULT_CLASS;
		}
	}


	private function init( $newData:Object = null ):void {

		if ( $newData )
			mergeOverwrite( $newData );

		if ( dbo.biomes )
			biomesFromObject( dbo.biomes );

		if ( !$newData )
			changed = false;
		function biomesFromObject( $biomes:Object ):void {
			// TODO this should only be true for new terrain models.
			const createHeightMap:Boolean = true;
			_biomes = new Biomes( createHeightMap  );
			if ( !$biomes.layers )
				throw new Error( "ModelInfo.biomesFromObject - WARNING - unable to find layerInfo: " + guid );
			_biomes.layersLoad( $biomes.layers );
			// now remove the biome oxelPersistence from the object so it is not saved to persistance
			delete dbo.biomes;
		}

		OxelDataEvent.addListener( OxelDataEvent.OXEL_FBA_COMPLETE, assignOxelData );

	}

	// Only used when importing object from disk
	public function toGenerationObject():Object {
		var obj:Object = {};
		obj.modelClass = modelClass;
		obj.biomes = _biomes.toGenerationObject();
		return obj;
	}

	override public function set guid($newGuid:String):void { 
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null ) );
		if ( oxelPersistence ) {
			oxelPersistence.guid = $newGuid;
			OxelDataEvent.create( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null );
		}
		changed = true;
	}

	public function update( $context:Context3D, $elapsedTimeMS:int, $vm:VoxelModel ):void {
		if ( oxelPersistence && oxelPersistence.oxelCount && oxelPersistence.oxel.chunkGet() )
			oxelPersistence.update( $vm );
			
		for each (var cm:VoxelModel in childVoxelModels ) {
			cm.update($context, $elapsedTimeMS);
		}
	}
	
	public function draw( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean, $isAlpha:Boolean ):void {
//		var time:int = getTimer()

		if ( oxelPersistence && oxelPersistence.oxelCount )
			oxelPersistence.draw(	$mvp, $vm, $context, $selected, $isChild, $isAlpha );
//		var t:int = (getTimer() - time) 	
//		if ( t )
//			Log.out( "ModelInfo.draw time: " + t );
			
		for each (var vm:VoxelModel in childVoxelModels) {
			if (vm && vm.complete)
				vm.draw($mvp, $context, true, $isAlpha );
		}
	}

	override public function release():void {
		super.release();
		_biomes = null;
		_animations = null;
		if ( oxelPersistence ) {
			oxelPersistence.release();
			oxelPersistence = null;
		}
	}


	public function bringOutYourDead():void {
		for each (var deadCandidate:VoxelModel in childVoxelModels) {
			if (true == deadCandidate.dead) {
				if ( deadCandidate.instanceInfo.associatedGrain )
					changeOxel( deadCandidate.instanceInfo.instanceGuid, deadCandidate.instanceInfo.associatedGrain, TypeInfo.AIR );
				else
					childRemove(deadCandidate.instanceInfo);
			}
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start oxelPersistence (oxel) operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function assignOxelData( $ode:OxelDataEvent ):void {
		if ( guid == $ode.modelGuid ) {
			OxelDataEvent.removeListener( OxelDataEvent.OXEL_FBA_COMPLETE, assignOxelData );
			oxelPersistence = $ode.oxelPersistence;
			if ( lockLight ) {
				oxelPersistence.baseLightLevel = Lighting.MAX_LIGHT_LEVEL;
				oxelPersistence.lockLight = true;
			}
		}
	}

	public function loadFromBiomeData():void {
		var layer1:LayerInfo = biomes.layers[0];
		if ( "LoadModelFromIVM" == layer1.functionName ) {
			guid = layer1.data;
			//Log.out( "ModelInfo.loadFromBiomeData - trying to load from local file with alternate name - altGuid: " + _altGuid, Log.DEBUG );
			OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, guid, null, ModelBaseEvent.USE_FILE_SYSTEM );
		}
		else {
			//Log.out( "ModelInfo.loadFromBiomeData - building bio from layer oxelPersistence", Log.DEBUG );
			biomes.addToTaskControllerUsingNewStyle( guid );
		}
	}

	public function boimeHas():Boolean {
		if ( _biomes && _biomes.layers && 0 < _biomes.layers.length )
			return true;
		return false;
	}
	
	public function changeOxel( $instanceGuid:String , $gc:GrainCursor, $type:int, $onlyChangeType:Boolean = false ):Boolean {
		var result:Boolean = oxelPersistence.change( $instanceGuid, $gc, $type, $onlyChangeType );
		if ( TypeInfo.AIR == $type )
			childRemoveByGC( $gc );
		return result;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// start script operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public function scriptsLoad( $instanceInfo:InstanceInfo ):void {
		// Both instanceInfo and modelInfo can have scripts. With each being persisted in correct location.
		// Currently both are loaded into instanceInfo, which is not great, but it is quick, which is needed
		if ( scripts ) {
			var len:int = scripts.length;
			for ( var index:int; index < len; index++ ) {
				var scriptName:String = scripts[index].name;
				$instanceInfo.addScript( scriptName, true );
			}
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//  start animation operations
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	protected 	var		_animationsLoaded:Boolean;
	private 	var 	_animsRemainingToLoad:int;
	public 	function get animationsLoaded():Boolean 				{ return _animationsLoaded; }
	public 	function set animationsLoaded(value:Boolean):void		{ _animationsLoaded = value; }
	
	// Dont load the animations until the model is instaniated
	public function animationsLoad():void {
		_series = 0;
		animationsLoaded = true;
		if ( animationInfo ) {
			for each ( var animData:Object in animationInfo ) {
				if ( animationsLoaded ){
					animationsLoaded = false;
					AnimationEvent.addListener( ModelBaseEvent.DELETE, 		animationDeleteHandler );
					AnimationEvent.addListener( ModelBaseEvent.ADDED, 		animationAdd );
				}
				_animsRemainingToLoad++; 
				
				// AnimationEvent( $type:String, $series:int, $modelGuid:String, $aniGuid:String, $ani:Animation, $fromTable:Boolean = true, $bubbles:Boolean = true, $cancellable:Boolean = false )
				var ae:AnimationEvent;
				if ( Globals.isGuid( animData.guid ) )
					ae = new AnimationEvent( ModelBaseEvent.REQUEST, _series, guid, animData.guid, null, ModelBaseEvent.USE_PERSISTANCE );
				else
					ae = new AnimationEvent( ModelBaseEvent.REQUEST, _series, guid, animData.guid, null, ModelBaseEvent.USE_FILE_SYSTEM );
					
				_series = ae.series;
				// special case here since we need to use the series
				AnimationEvent.dispatch( ae );
			}
		}
	}
			
	public function animationsDelete():void {
		if ( animationInfo ) {
			Log.out( "ModelInfo.animationsDelete - animations found" );
			// Dont worry about removing the animations, since the modelInfo is being deleted.
			for each ( var animData:Object in animationInfo ) {
				Log.out( "ModelInfo.animationsDelete - deleting animation: " + animData.name + "  guid: " + animData.guid );
				AnimationEvent.create( ModelBaseEvent.DELETE, 0, guid, animData.guid, null );
			}
		}
	}

	public function animationAdd( $ae:AnimationEvent ):void {
		if ( guid == $ae.modelGuid ) {
			//Log.out( "ModelInfo.addAnimation " + $ae, Log.WARN );
			if (_series == $ae.series) {
				if ( !Globals.isGuid($ae.ani.guid))
						$ae.ani.guid = Globals.getUID();
				_animations.push($ae.ani);
				_animsRemainingToLoad--;
				if (0 == _animsRemainingToLoad) {
					animationsLoaded = true;
					AnimationEvent.removeListener(ModelBaseEvent.DELETE, animationDeleteHandler);
					AnimationEvent.removeListener(ModelBaseEvent.ADDED, animationAdd);
					//Log.out( "ModelInfo.addAnimation safe to save now: " + guid, Log.WARN );
				}
			}
		}
	}
	
	public function animationDeleteHandler( $ae:AnimationEvent ):void {
		//Log.out( "ModelInfo.animationDelete $ae: " + $ae, Log.WARN );
		if ( $ae.modelGuid == guid ) {
			for ( var i:int; i < _animations.length; i++ ) {
				var anim:Animation = _animations[i];
				if ( anim.guid == $ae.aniGuid ) {
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
			if ( anim.name == $animName ) {
				return anim;
			}
		}
		return null;
	}

	/////////////////////////////////////////////////////////////////////////////////////////////
	//  Children functions
	/////////////////////////////////////////////////////////////////////////////////////////////
	private 	var			 _childCount:uint;

	private 	var			 _childVoxelModels:Vector.<VoxelModel>			= new Vector.<VoxelModel>; 	// INSTANCE NOT EXPORTED
	public		function get childVoxelModels():Vector.<VoxelModel>			{ return _childVoxelModels; }
	public		function 	 childVoxelModelsGet():Vector.<VoxelModel>		{ return _childVoxelModels; } // This is so the function can be passed as parameter

	private 	var			_childrenLoaded:Boolean
	public		function get childrenLoaded():Boolean 				{ return _childrenLoaded; }
	public		function set childrenLoaded(value:Boolean):void  	{ _childrenLoaded = value; }
	/////////////////////
	public		function 	 unloadedChildCount():int		{
		var count:int = 0;
		for each ( var v:Object in dbo.children )
			count++;
		return count;
	}

	public function childrenLoad( $vm:VoxelModel ):void {
		childrenLoaded	= true;
		_childCount = 0;
		if ( !dbo || !dbo.children )
			return;
		
		//Log.out( "ModelInfo.childrenLoad - loading for model: " + guid );
		for each ( var v:Object in dbo.children ) {
			// Only want to add the listener once
			if ( true == childrenLoaded ) {
				childrenLoaded	= false;
				ModelEvent.addListener( ModelEvent.CHILD_MODEL_ADDED, onChildAdded );
			}
			var ii:InstanceInfo = new InstanceInfo();
			ii.fromObject( v );
			ii.controllingModel = $vm;

			//Log.out( "VoxelModel.childrenLoad - create child of parent.instance: " + instanceInfo.guid + "  - child.instanceGuid: " + child.instanceGuid );					
			if ( null == ii.modelGuid )
				continue;
			// now load the child, this might load from the persistance
			// or it could be an import, or it could be a model for the toolbar.
			// we never want to prompt for imported children, since this only happens in dev mode.
			// to test if we are in the bar mode, we test of instanceGuid.
			// Since this is a child object, it automatically get added to the parent.
			// So add to cache just adds it to parent instance.
			//Log.out( "VoxelModel.childrenLoad - THIS CAUSES A CIRCULAR REFERENCE - calling maker on: " + childInstanceInfo.modelGuid + " parentGuid: " + instanceInfo.modelGuid, Log.ERROR );
			_childCount++;
			//Log.out( "VoxelModel.childrenLoad - calling load on ii: " + ii + "  childCount: " + _childCount );
			ModelMakerBase.load( ii, true, false );
		}
		//Log.out( "VoxelModel.childrenLoad - addListener for ModelLoadingEvent.CHILD_LOADING_COMPLETE  -  model name: " + $vm.metadata.name );
		//Log.out( "VoxelModel.childrenLoad - loading child models END" );
		if ( ModelMakerImport.isImporting )
			delete dbo.children;
	}

	protected function onChildAdded( me:ModelEvent ):void {
		if ( me.vm && me.vm.instanceInfo.controllingModel && me.vm.instanceInfo.controllingModel.modelInfo.guid == guid ) {
			_childCount--;
			//Log.out( "ModelInfo.onChildAdded - modelInfo: " + guid + "  children remaining: " + _childCount, Log.WARN );
			if (0 == _childCount) {
				//Log.out( "ModelInfo.onChildAdded - modelInfo: " + guid + "  children COMPLETE", Log.WARN );
				ModelEvent.removeListener(ModelEvent.CHILD_MODEL_ADDED, onChildAdded);
				childrenLoaded = true;
				var ohd:ObjectHierarchyData = new ObjectHierarchyData();
				ohd.fromModel( me.vm );
				ModelLoadingEvent.create( ModelLoadingEvent.CHILD_LOADING_COMPLETE, ohd, me.vm );
			}
		}
	}

	public function brandChildren():void {
		for each ( var child:VoxelModel in childVoxelModels ) {
			child.modelInfo.childOfGuid = guid;
			child.modelInfo.brandChildren();
		}
	}


	public function childRemoveByGC( $gc:GrainCursor ):Boolean {
		
		var index:int = 0;
		var gc:GrainCursor;
		var result:Boolean;
		for each (var child:VoxelModel in childVoxelModels) {
			if ( !child || !child.instanceInfo.associatedGrain )
				continue;
			gc = child.instanceInfo.associatedGrain;
			if ( gc.is_equal( $gc ) ) {
				childVoxelModels.splice(index, 1);
                child.instanceInfo.associatedGrainReset();
				var oxel:Oxel = VoxelModel.selectedModel.modelInfo.oxelPersistence.oxel.childFind( $gc );
				if ( oxel && oxel.gc.is_equal( $gc ) )
					oxel.hasModel = false;
				else
					Log.out( "ModelInfo.childRemoveByGC - Can't find GC to mark for model");

				changed = true;
				child.dead = true;
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
	
	private function childExists( $child:VoxelModel ):Boolean {
		for each ( var vm:VoxelModel in childVoxelModels ) {
			if ( vm.instanceInfo.instanceGuid == $child.instanceInfo.instanceGuid )
				return true
		}
		return false
	}

	// This should only be called from voxelModel who can check permissions
	public function childAdd( $child:VoxelModel):void {
		//Log.out(  "-------------- VoxelModel.childAdd -  $child: " +  $child.toString() );
		if ( null ==  $child.instanceInfo.instanceGuid )
			 $child.instanceInfo.instanceGuid = Globals.getUID();

		// this examines all of the parents in that model guid.
		// Since this would allow B owns A, and you could add B to A, which would cause a recurvise error
		var modelGuidChain:Vector.<String> = new Vector.<String>;
		 $child.instanceInfo.modelGuidChain( modelGuidChain )
		for each ( var modelGuid:String in modelGuidChain ) {
			if ( $child.modelInfo.guid == modelGuid )
				return
		}
		
		// templates would like to add the child for each instance, that is a no no..
		if ( !childExists( $child ) ) {
			childVoxelModels.push($child);
			if ( !$child.instanceInfo.dynamicObject )
				changed = true;
		}
		
//		// Dont add child that already exist
//		if ( dbo.children ) {
//			for each ( var child:Object in dbo.children ) {
//				if ( child.instanceGuid === $child.instanceInfo.instanceGuid )
//					return;
//			}
//		}
//		else
//			dbo.children = new Array();
//
//
//		// Dont add the player to the dbo.children, or you end up in a recursive loop
//		if ( $child == VoxelModel.controlledModel )
//			return;
//
//		dbo.children[dbo.children.length] = $child.instanceInfo.toObject();
	}
	
	// This leaves the model, but detaches it from parent.
	public function childDetach( $vm:VoxelModel, $vmParent:VoxelModel ):void	{
		// remove this child from the parents info
		childRemove($vm.instanceInfo);
		
		// this make it belong to the world
		$vm.instanceInfo.controllingModel = null;
		//if ( !($vm is Player) )
		// we are adding the detached model to the region
		RegionEvent.create( RegionEvent.ADD_MODEL, 0, Region.currentRegion.guid, $vm );

		
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

	public function childModelFindByName( $name:String, $recursive:Boolean = true ):VoxelModel	{
		for each (var child:VoxelModel in childVoxelModels) {
			if (child.metadata.name ==  $name )
				return child;
		}
		// didnt find it at first level, lets look recurvsivly
		if ( $recursive ) {
			for each (child in childVoxelModels) {
				return child.modelInfo.childModelFindByName($name);
			}
		}
		//Log.out(  "VoxelModel.childFind - not found for guid: " + guid, Log.WARN );
		return null
	}

	public function childModelFind(guid:String, $recursive:Boolean = true ):VoxelModel	{
		for each (var child:VoxelModel in childVoxelModels) {
			if (child.instanceInfo.instanceGuid == guid)
				return child;
		}
		// didnt find it at first level, lets look recurvsivly
		for each ( child in childVoxelModels) {
			var cvm:VoxelModel = child.modelInfo.childModelFind( guid );
			if ( cvm )
				return cvm;
		}
		
		//Log.out(  "VoxelModel.childFind - not found for guid: " + guid, Log.WARN );
		return null
	}
	
	public function childRemove( $ii:InstanceInfo ):void	{
		// Must remove the model, and the child dependency
		for ( var j:int = 0; j < childVoxelModels.length; j++ ) {
			if ( childVoxelModels[j].instanceInfo ==  $ii ) {
				if (!childVoxelModels[j].instanceInfo.dynamicObject)
					changed = true;
				childVoxelModels.splice(j, 1);
			}
		}
//		var	newChildren:Object = new Object();
//		var i:int;
//		for each ( var obj:Object in  dbo.children ) {
//			if ( obj.instanceGuid != $ii.instanceGuid ) {
//				newChildren[i] = obj;
//				i++
//			}
//		}
//		delete dbo.children;
//		dbo.children = newChildren;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// persistence functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	private static const DEFAULT_CLASS:String		= "VoxelModel";
	
	private var _biomes:Biomes;										// used to generate terrain and apply other functions to oxel
	private var _series:int											// used to make sure animation is part of same series when loading
	private var _firstLoadFailed:Boolean;							// true if load from biomes oxelPersistence is needed
	
	// These are temporary used for loading local objects
	public function get biomes():Biomes 							{ return _biomes; }
	public function set biomes(value:Biomes):void  					{ _biomes = value;  changed = true; }
	
	override public function save():Boolean {
		if ( false == animationsLoaded || false == childrenLoaded) {
			Log.out("ModelInfo.save - NOT Saving guid: " + guid + " NEED Animations or children to complete", Log.WARN);
			return false;
		}

		if ( !super.save() )
			return false;

		// Parent saved, so we can save children.
		if ( oxelPersistence )
			oxelPersistence.save();

		if ( _animations && 0 < _animations.length )
				for each ( var ani:Animation in _animations )
					ani.save();

		for ( var i:int; i < childVoxelModels.length; i++ ) {
			var child:VoxelModel = childVoxelModels[i];
			child.save();
		}
		return true;
	}

	override protected function toObject():void {
		owner.buildExportObject();

		// this updates the original positions, to the current positions...
		// how do I get original location and position, on animated objects?
		if ( childrenLoaded )
			childrenGet();
		else
			Log.out( "ModelInfo.toObject - creating object with children still loading.", Log.WARN);

		animationsGetSummary();
		

	}

	private function childrenGet():void {
		// Same code that is in modelCache to build models in region
		// this is just models in models
		delete dbo.children;
		if ( 0 == _childVoxelModels.length )
			return;

		var children:Object = {};
		for ( var i:int=0; i < _childVoxelModels.length; i++ ) {
			var cm:VoxelModel = _childVoxelModels[i];
			if ( null != cm ) {
				// Don't save animation attachments!
				if ( cm.instanceInfo.dynamicObject )
					continue;
				// Don't save the player as a child model
				if ( cm is Avatar )
					continue;
				children[i]  = cm.instanceInfo.toObject();
			}
		}
		dbo.children = children;
	}

	private function animationsGetSummary():void {
		delete dbo.animations;
		var len:int = _animations.length;
		if ( 0 == len )
			return;

		dbo.animations = [];
		for ( var index:int=0; index < len; index++ ) {
			var ani:Animation = _animations[index];
			var ao:Object = {};
			ao.name = ani.name;
			ao.type = ani.type;
			ao.guid = ani.guid;
			//Log.out( "ModelInfo.animationsGetSummary - animation.metadata: " + ani.name + "  model guid: " + guid );
			dbo.animations.push( ao );
		}
	}

	/*
	private function animationsFromObject( $animations:Object ):void {
	// i.e. animData = { "name": "Glide", "guid":"Glide.ajson" }
		Log.out( "ModelInfo.animationsFromObject" );	
		for each ( var animData:Object in $animations ) {
			Log.out( "ModelInfo.animationsFromObject - _animationInfo.push animData: " + animData.name );	
			_animationInfo.push( animData );
		}
	}
*/
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  end persistence functions
	/////////////////////////////////////////////////////////////////////////////////////////////
	
	public function cloneNew( $guid:String ):ModelInfo {
		var newModelInfo:ModelInfo = new ModelInfo( $guid, null, dbo );
		for each ( var ani:Animation in _animations ) {
			var newAni:Animation = ani.clone( guid );
			newModelInfo._animations.push(newAni);
		}
		// these will be rebuilt when it is saved
		delete newModelInfo.dbo.animations;
		newModelInfo.animationsLoaded = true;
		newModelInfo.oxelPersistence = oxelPersistence.cloneNew( $guid );
		//TODO need handlers
		ModelInfoEvent.create( ModelBaseEvent.CLONE, 0, newModelInfo.guid, newModelInfo );
		return newModelInfo;
	}

	override public function clone( $guid:String ):* {
		var oldObj:String = JSON.stringify( dbo );

		var pe:PersistenceEvent = new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, 0, Globals.MODEL_INFO_EXT, $guid, null, oldObj )
		PersistenceEvent.dispatch( pe )

		// also need to clone the oxel
		throw new Error( "REFACTOR = 2.22.17");
		/*
		// this adds the version header, need for the persistanceEvent
		var ba:ByteArray = OxelPersistence.toByteArray( oxelPersistence.oxel );

		var ope:PersistenceEvent = new PersistenceEvent( PersistenceEvent.LOAD_SUCCEED, 0, Globals.IVM_EXT, $guid, null, ba )
		PersistenceEvent.dispatch( ope )
		*/
	}

	public function toString():String {  return "ModelInfo - guid: " + guid; }
}	
}