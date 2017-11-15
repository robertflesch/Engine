/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.display.Bitmap;

import flash.display.BitmapData;

import flash.display3D.Context3D;
import flash.geom.Rectangle;
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
import com.voxelengine.events.TextureLoadingEvent;
import com.voxelengine.events.ObjectHierarchyData;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.animation.Animation;
import com.voxelengine.worldmodel.biomes.Biomes;
import com.voxelengine.worldmodel.biomes.LayerInfo;
import com.voxelengine.worldmodel.models.types.Avatar;
import com.voxelengine.worldmodel.oxel.Oxel;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.PermissionsModel;
import com.voxelengine.worldmodel.TextureBank;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerClone;
import com.voxelengine.worldmodel.oxel.OxelBad;

public class ModelInfo extends PersistenceObject
{
    static public const MODEL_INFO_EXT:String = ".mjson";
    static public const BIGDB_TABLE_MODEL_INFO:String = "modelInfo";
    static public const BIGDB_TABLE_MODEL_INFO_INDEX_OWNER:String = "owner";
    static public const BIGDB_TABLE_MODEL_INFO_INDEX_CREATOR:String = "creator";
	private const DEFAULT_BOUND:int                       = 10;

    public function get name():String  						{ return dbo.name; }
    public function set name($val:String):void  			{ dbo.name = $val; changed = true; }

    public function get description():String  				{ return dbo.description; }
    public function set description($val:String):void  		{ dbo.description = $val; changed = true; }

    public function get animationClass():String 			{ return dbo.animationClass; }
    public function set animationClass($val:String):void  	{ dbo.animationClass = $val; changed = true; }

    public function get childOf():String 					{ return dbo.childOf; }
    public function set childOf($val:String):void  			{ dbo.childOf = $val; changed = true; }

    public function modelScalingVec3D():Vector3D 			{ return new Vector3D( dbo.modelScaling.x, dbo.modelScaling.y, dbo.modelScaling.z ); }
    public function modelScalingInfo():Object 				{ return dbo.modelScaling }
    public function get modelScaling():Object 				{ return dbo.modelScaling; }
    public function set modelScaling($val:Object):void  	{ dbo.modelScaling = $val; changed = true; }

    public function modelPositionVec3D():Vector3D 			{ return new Vector3D( dbo.modelPosition.x, dbo.modelPosition.y, dbo.modelPosition.z ); }
    public function modelPositionInfo():Object 			{ return dbo.modelPosition }
    public function get modelPosition():Object 				{ return dbo.modelPosition; }
    public function set modelPosition($val:Object):void  	{ dbo.modelPosition = $val; changed = true; }

    public function get version():int 						{ return dbo.version; }
    public function set version( $val:int ):void			{ dbo.version = $val; }

    public function get bound():int 						{ return dbo.bound; }
    public function set bound( $val:int ):void				{
        if ( dbo.bound != $val ) {
            //changed = true;
            dbo.bound = $val;
        } }

    public function get hashTags():String 					{ return dbo.hashTags; }
    public function set hashTags($val:String):void			{ dbo.hashTags = $val; changed = true }

    public function get scripts():Array 					{ return dbo.scripts; }
    public function get modelClass():String					{ return dbo.modelClass; }
    public function get childOfGuid():String				{ return dbo.childOfGuid; }
    public function set childOfGuid( $val:String ):void		{ dbo.childOfGuid = $val; changed = true; }
//	public function set modelClass(val:String):void 		{ dbo.modelClass = val;  changed = true; }
    public function set modelClass(val:String):void 		{
        if ( val == null )
            throw new Error( "ModelInfo.modelClass CAN NOT BE NULL");
        dbo.modelClass = val;
        changed = true;
    }

    public function get owner():String  					{ return dbo.owner; }
    public function set owner($val:String):void  			{ dbo.owner = $val; changed = true; }

    public function get animationInfo():Object				{ return dbo.animations; }
    // This stores the instantiated objects
    private var 		_animations:Vector.<Animation> 		= new Vector.<Animation>();	// Animations that this model has
    public function get animations():Vector.<Animation> 	{ return _animations; }

    private var _permissions:PermissionsModel;
    public function get permissions():PermissionsModel 		{ return _permissions; }
    public function set permissions( $val:PermissionsModel):void	{ _permissions = $val; changed = true; }

    private var _thumbnail:BitmapData;
    public function get thumbnail():BitmapData 				{ return _thumbnail; }
    public function set thumbnail($val:BitmapData):void 	{ _thumbnail = $val; changed = true; }

    private var _thumbnailLoaded:Boolean;
    public function get thumbnailLoaded():Boolean 			{ return _thumbnailLoaded; }
    public function set thumbnailLoaded($val:Boolean):void  { _thumbnailLoaded = $val; }

	private var 		_oxelPersistence:OxelPersistence;
	public function get oxelPersistence():OxelPersistence  	{ return _oxelPersistence; }
	public function set oxelPersistence($oxel:OxelPersistence ):void { _oxelPersistence = $oxel; }


    private var			_owningModel:VoxelModel;
	public function get owningModel():VoxelModel 			{ return _owningModel; }
	public function set owningModel(value:VoxelModel):void 	{ _owningModel = value; }

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
		super( $guid, BIGDB_TABLE_MODEL_INFO );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else {
			dbo = $dbo;
		}

        if ( $newData )
            mergeOverwrite( $newData );
	}

    public function init():void {

        if ( dbo.biomes )
            biomesFromObject( dbo.biomes );

        if ( dbo.thumbnail ) {
            try {
                var bmd:BitmapData = new BitmapData(128,128,false);
                bmd.setPixels(new Rectangle(0, 0, 128, 128), dbo.thumbnail);
                _thumbnail = bmd;
                thumbnailLoaded = true;
                ModelInfoEvent.create( ModelInfoEvent.BITMAP_LOADED, 0, guid, this );
            }
            catch (e:Error) {
                loadNoImage();
            }
        }
        else {
            loadNoImage();
        }

        // the permission object is just an encapsulation of the permissions section of the object
        _permissions = new PermissionsModel();
        _permissions.fromObject( this as PersistenceObject );

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

        function loadNoImage():void {
            TextureLoadingEvent.addListener( TextureLoadingEvent.LOAD_SUCCEED, noImageLoaded );
            TextureLoadingEvent.create( TextureLoadingEvent.REQUEST, TextureBank.NO_IMAGE_128 );
        }
    }

    private function noImageLoaded( $tle:TextureLoadingEvent ):void {
        if ( TextureBank.NO_IMAGE_128 == $tle.name ) {
            TextureLoadingEvent.removeListener( TextureLoadingEvent.LOAD_SUCCEED, noImageLoaded );
            //Log.out("ModelMetadata.init.noImageLoaded: " + TextureBank.NO_IMAGE_128 + "  for guid: " + guid, Log.WARN);
            _thumbnail = ($tle.data as Bitmap).bitmapData;
            thumbnailLoaded = true;
            ModelInfoEvent.create( ModelInfoEvent.BITMAP_LOADED, 0, guid, this );
            //      Log.out( "ModelMetadata.init.imageLoaded complete isDebug: " + Globals.isDebug + " + Capabilities.isDebugger: " + Capabilities.isDebugger, Log.WARN );
        }
    }


    public function setGeneratedData( $name:String, $owner:String ): void {
        dbo.name = $name;
        dbo.description = $name + " - GENERATED";
        dbo.owner = $owner;
    }

    override protected function assignNewDatabaseObject():void {
		super.assignNewDatabaseObject();
		dbo.modelClass = DEFAULT_CLASS;
        setToDefault();

        function setToDefault():void {
            dbo.hashTags 		= "#new";
            _thumbnail 			= null;
            dbo.animationClass 	= "";
            dbo.description 	= "Default";
            dbo.name 			= "Default";
            dbo.owner 			= "";
            dbo.version 		= Globals.VERSION;
            dbo.bound 			= DEFAULT_BOUND;
        }
	}

	// Only used when importing object from disk
	public function toGenerationObject():Object {
		var obj:Object = {};
		obj.modelClass = modelClass;
		obj.biomes = _biomes.toGenerationObject();
		return obj;
	}

	override public function set guid( $newGuid:String ):void {
		Log.out( "ModelInfo.guid  oldGuid: " + super.guid + " new Guid: " + $newGuid );
		var oldGuid:String = super.guid;
		super.guid = $newGuid;
		ModelInfoEvent.dispatch( new ModelInfoEvent( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null ) );
		if ( oxelPersistence ) {
			oxelPersistence.guid = $newGuid;
			OxelDataEvent.create( ModelBaseEvent.UPDATE_GUID, 0, oldGuid + ":" + $newGuid, null );
		}
        changed = true;
		if ( null != _owningModel.instanceInfo.controllingModel )
            _owningModel.instanceInfo.controllingModel.modelInfo.changed = true;
	}

	public function update( $context:Context3D, $elapsedTimeMS:int ):void {
		if ( oxelPersistence && oxelPersistence.oxelCount && oxelPersistence.oxel.chunkGet() ) {
			oxelPersistence.update();
		}
			
		for each (var cm:VoxelModel in childVoxelModels ) {
			cm.update($context, $elapsedTimeMS);
		}
	}
	
	public function draw( $mvp:Matrix3D, $vm:VoxelModel, $context:Context3D, $selected:Boolean, $isChild:Boolean, $isAlpha:Boolean ):void {
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
		return  ( _biomes && _biomes.layers && 0 < _biomes.layers.length );
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
			for ( var index:int = 0; index < len; index++ ) {
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
	public function animationsLoad( $buildState:String ):void {
		_series = 0;
		animationsLoaded = true;
		if ( animationInfo ) {
			for each ( var animData:Object in animationInfo ) {
				if ( animationsLoaded ){
					animationsLoaded = false;
                    AnimationEvent.addListener( ModelBaseEvent.RESULT, animationResult );
					AnimationEvent.addListener( ModelBaseEvent.DELETE, animationDeleteHandler );
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

        function animationResult( $ae:AnimationEvent ):void {
            if ( guid == $ae.modelGuid ) {
                //Log.out( "ModelInfo.addAnimation " + $ae, Log.WARN );
                if (_series == $ae.series) {
                    if ( !Globals.isGuid($ae.ani.guid))
                        $ae.ani.guid = Globals.getUID();
                    _animations.push($ae.ani);
                    if ( $buildState == ModelMakerBase.IMPORTING )
                    	$ae.ani.save();

                    _animsRemainingToLoad--;
                    if (0 == _animsRemainingToLoad) {
                        animationsLoaded = true;
                        AnimationEvent.removeListener( ModelBaseEvent.RESULT, animationResult );
                        AnimationEvent.removeListener( ModelBaseEvent.DELETE, animationDeleteHandler );
                        if ( $buildState == ModelMakerBase.IMPORTING )
							save();
                        //Log.out( "ModelInfo.addAnimation safe to save now: " + guid, Log.WARN );
                    }
                }
            }
        }

	}
			
	public function animationsDelete():void {
		if ( animationInfo ) {
			Log.out( "ModelInfo.animationsDelete - animations found" );
			// Don't worry about removing the animations, since the modelInfo is being deleted.
			for each ( var animData:Object in animationInfo ) {
				Log.out( "ModelInfo.animationsDelete - deleting animation: " + animData.name + "  guid: " + animData.guid );
				AnimationEvent.create( ModelBaseEvent.DELETE, 0, guid, animData.guid, null );
			}
		}
	}


	public function animationDeleteHandler( $ae:AnimationEvent ):void {
		//Log.out( "ModelInfo.animationDelete $ae: " + $ae, Log.WARN );
		if ( $ae.modelGuid == guid ) {
			for ( var i:int=0; i < _animations.length; i++ ) {
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
		for ( var i:int=0; i < _animations.length; i++ ) {
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
    private 	function	 get childCount():uint 							{ return _childCount; }
    private 	function	 set childCount($val:uint):void 				{ _childCount = $val; }

	private 	var			 _childVoxelModels:Vector.<VoxelModel>			= new Vector.<VoxelModel>; 	// INSTANCE NOT EXPORTED
	public		function get childVoxelModels():Vector.<VoxelModel>			{ return _childVoxelModels; }
	public		function 	 childVoxelModelsGet():Vector.<VoxelModel>		{ return _childVoxelModels; } // This is so the function can be passed as parameter

	private 	var			_childrenLoaded:Boolean;
	public		function get childrenLoaded():Boolean 				{ return _childrenLoaded; }
	public		function set childrenLoaded(value:Boolean):void  	{ _childrenLoaded = value; }
	/////////////////////
	public		function 	 unloadedChildCount():int		{
		var count:int = 0;
		for each ( var unused:Object in dbo.children )
			count++;
		return count;
	}

	public function childrenLoad( $vm:VoxelModel, $buildState:String ):void {
		childrenLoaded	= true;
		if ( !dbo || !dbo.children )
			return;
		
		//Log.out( "ModelInfo.childrenLoad - loading for model: " + guid );
		for each ( var v:Object in dbo.children ) {
			// Only want to add the listener once
			if ( true == childrenLoaded ) {
				childrenLoaded	= false;
                //Log.out( "VoxelModel.childrenLoad - guid: " + guid + " is addListener( ModelEvent.CHILD_MODEL_ADDED)" );
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
			childCount = childCount + 1;
			//Log.out( "VoxelModel.childrenLoad - the " + guid + " is loading child guid: " + ii.modelGuid + "  childCount: " + childCount );
            if ( $buildState == ModelMakerBase.IMPORTING )
                new ModelMakerImport( ii, false );
            if ( $buildState == ModelMakerBase.CLONING ) {
                ii.controllingModel = owningModel;
                new ModelMakerClone( ii );
            } else
				new ModelMaker( ii, true, false );
		}
		//Log.out( "VoxelModel.childrenLoad - addListener for ModelLoadingEvent.CHILD_LOADING_COMPLETE  -  model name: " + $vm.metadata.name );
		//Log.out( "VoxelModel.childrenLoad - loading child models END" );
		if ( $buildState== ModelMakerBase.IMPORTING )
			delete dbo.children;
	}

    protected function onChildAdded( $me:ModelEvent ):void {
		// does the child's parent guid == this objects guid, if so its our child
		if ( $me.vm && $me.vm.instanceInfo.controllingModel && $me.vm.instanceInfo.controllingModel.modelInfo.guid == guid ) {
			childCount = childCount - 1;
			Log.out( "ModelInfo.onChildAdded - MY CHILD - parent guid: " + guid + "  childGuid: " + $me.vm.modelInfo.guid + "  children remaining: " + _childCount, Log.WARN );
            checkChildCountForZero( $me.vm, $me.vm.modelInfo.guid );
		}
		else {
            Log.out( "ModelInfo.onChildAdded - NOT MY CHILD - parent guid: " + guid + "  childGuid: " + $me.vm.modelInfo.guid, Log.WARN );
		}
	}

    public function onChildAddFailure( $childGuid:String ):void {
        	Log.out( "ModelInfo.onChildAddFailure - this model: " + guid + "  childModel.modelGuid: " + $childGuid );
        	childCount = childCount - 1;
            checkChildCountForZero( null, $childGuid );
    }

	private function checkChildCountForZero( $vm:VoxelModel, $childModelGuid:String ):void {
        if (0 == childCount) {
//			Log.out( "ModelInfo.checkChildCountForZero - modelInfo: " + guid + "  children COMPLETE", Log.WARN );
            ModelEvent.removeListener( ModelEvent.CHILD_MODEL_ADDED, onChildAdded);
            childrenLoaded = true;
            var ohd:ObjectHierarchyData = new ObjectHierarchyData();
			// If the child load failed
            if ( null == $vm )
                ohd.fromNullChildModel( _owningModel, $childModelGuid );
			else
                ohd.fromModel( $vm );

            ModelLoadingEvent.create( ModelLoadingEvent.CHILD_LOADING_COMPLETE, ohd, $vm );
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
				if ( oxel == OxelBad.INVALID_OXEL )
					return false;
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
		$child.instanceInfo.modelGuidChain( modelGuidChain );
		for each ( var modelGuid:String in modelGuidChain ) {
			if ( $child.modelInfo.guid == modelGuid )
				return
		}
		
		// templates would like to add the child for each instance, that is a no no..
		if ( !childExists( $child ) ) {
			childVoxelModels.push($child);
			// this is the wrong place to do this. I should set it in the GUI rather than here.
			//if ( !$child.instanceInfo.dynamicObject && Globals.isGuid( $child.modelInfo.guid) )
			//	changed = true;
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
			if (child.modelInfo.name ==  $name )
				return child;
		}
		// didn't find it at first level, lets look recursively
		if ( $recursive ) {
			for each (var child1:VoxelModel in childVoxelModels) {
				var result:VoxelModel = child1.modelInfo.childModelFindByName($name);
				if ( result )
					return result;
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
		// didn't find it at first level, lets look recursively
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
	private var _series:int;											// used to make sure animation is part of same series when loading

	// These are temporary used for loading local objects
	public function get biomes():Biomes 							{ return _biomes; }
	public function set biomes(value:Biomes):void  					{ _biomes = value;  changed = true; }
	
	override public function save( $validateGuid:Boolean = true ):Boolean {

		if ( false == animationsLoaded || false == childrenLoaded) {
			Log.out("ModelInfo.save - NOT guid: " + guid + " NEEDs " + (animationsLoaded?"":"Animations ") + (childrenLoaded?"":"Children") + " to complete", Log.WARN);
			return false;
		}

        if ( oxelPersistence ) {
            oxelPersistence.save();
        }

        Log.out("ModelInfo.save -     guid: " + guid, Log.WARN);
		if ( !super.save( $validateGuid ) )
			return false;

		if ( _animations && 0 < _animations.length )
				for each ( var ani:Animation in _animations )
					ani.save();

		for ( var i:int=0; i < childVoxelModels.length; i++ ) {
			var child:VoxelModel = childVoxelModels[i];
			child.save();
		}
		return true;
	}

	override protected function toObject():void {
		owningModel.buildExportObject();

		// this updates the original positions, to the current positions...
		// how do I get original location and position, on animated objects?
		if ( childrenLoaded )
			childrenGet();
		else
			Log.out( "ModelInfo.toObject - creating object with children still loading.", Log.WARN);

		animationsGetSummary();

        if ( thumbnail )
        //dbo.thumbnail 		= thumbnail.encode(new Rectangle(0, 0, 128, 128), new JPEGEncoderOptions() );
            dbo.thumbnail 		= thumbnail.getPixels(new Rectangle(0, 0, 128, 128));
        else
            dbo.thumbnail = null;

        dbo.permissions = _permissions.toObject();
	}

	public function childrenGet():Object {
		// Same code that is in modelCache to build models in region
		// this is just models in models
		//delete dbo.children;
		// Child models have not been loaded, so just return the lists of child Objects
		if ( 0 == _childVoxelModels.length)
			return dbo.children;

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
		return dbo.children = children;
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
	
	override public function clone( $guid:String ):* {
		var newModelInfo:ModelInfo = new ModelInfo( $guid, null, dbo );
        newModelInfo.init();
		for each ( var ani:Animation in _animations ) {
			var newAni:Animation = ani.clone( guid );
			newModelInfo._animations.push(newAni);
		}
		// these will be rebuilt when it is saved
		delete newModelInfo.dbo.animations;
		newModelInfo.animationsLoaded = true;
		newModelInfo.oxelPersistence = oxelPersistence.cloneNew( $guid );


/////////////////////////
//        var oldObj:String = JSON.stringify( dbo );
//        var newData:Object = JSON.parse( oldObj );
//
//        newData.owner = Network.userId;
//        newData.hashTags = this.hashTags + "#cloned";
//        newData.name = this.name;
//        //newData.createdDate = new Date().toUTCString();
//        var newModelMetadata:ModelMetadata = new ModelMetadata( $guid, null, newData );

////////////////////////
		return newModelInfo;
	}

    public function toString():String {
        return "name: " + name + "  description: " + description + "  guid: " + guid;
    }

}
}