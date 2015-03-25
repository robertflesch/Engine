/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.events.AnimationEvent;
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.worldmodel.animation.Animation;
	import com.voxelengine.worldmodel.biomes.Biomes;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	/**
	 * ...
	 * @author Bob
	 */
	public class ModelInfo 
	{
		private var _fileName:String 					= "INVALID";				// Used for local loading and import of data from local file system
		private var _biomes:Biomes;													// used to generate terrain and apply other functions to oxel
		private var _modelClass:String 					= "VoxelModel";				// Class used to instaniate model
		private var _children:Vector.<InstanceInfo> 	= new Vector.<InstanceInfo>;// Child models and their relative positions
		private var _scripts:Vector.<String> 			= new Vector.<String>;		// Default scripts to be used with this model
		private var _grainSize:int = 0;												// Used in model generatation
		private var _modelJson:Object;												// copy of json object used to create this
		private var _animations:Vector.<Animation> 		= new Vector.<Animation>();	// Animations that this model has
		private var _childCount:int // number of children this model has at start. Used to determine if animation can be played.
		
		public function get json():Object 						{ return _modelJson; }
		public function 	jsonReset():void 					{ _modelJson = toJSON(null); }
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

		public function ModelInfo():void  { ; }
		
		public function clone( newGuid:String = "" ):ModelInfo
		{
			throw new Error( "ModelInfo.clone - VERIFY THIS FUNCTION" );
			var newModelInfo:ModelInfo = new ModelInfo();
			if ( "" == newGuid )
				newModelInfo.fileName 			= Globals.getUID();
			else	
				newModelInfo.fileName 			= newGuid;
				
			newModelInfo._modelClass	= this.modelClass;
			newModelInfo._grainSize		= this.grainSize;
			// need to copy this?
			newModelInfo._modelJson		= this._modelJson;
			newModelInfo._childCount	= this._childCount;
			
			if ( _biomes )
				newModelInfo._biomes 		= _biomes.clone();
			
			// This clone is important, and it creates a unique instance for each child
			// otherwise the children all share the same instanceInfo, which is not good
			for each ( var ii:InstanceInfo in _children )
				newModelInfo.childAdd( ii.clone() );
			// The cloning here was overwriting changes I made during the repeat stage
			// I think that each ii is already unique, or SHOULD be.

			for each ( var script:String in _scripts )
				newModelInfo._scripts.push( script );
			
			for each ( var animation:Animation in _animations )
				newModelInfo._animations.push( animation );
			
				
			return newModelInfo;
		}
		
		public function childAdd( $instanceInfo:InstanceInfo):void {
			// Dont add child that already exist
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
		
		public function getJSON():String {
			return JSON.stringify( this );			
		}
	
		// this is called by the stringify method
		public function toJSON(k:*):*  { 
			return {
					animations:		_animations,
//					biomes:			_biomes,
					children:		"REPLACE_ME",
					grainSize:		_grainSize,
					modelClass:		_modelClass,
					script:			_scripts
					};
		} 	
		
		public function childrenReset():void {
			_children = null;
			_childCount = 0;
		}
		
		public function initJSON( $modelGuid:String, $json:Object ):void  {
			
			//Log.out( "ModelInfo.init - fileName: " + $modelGuid + "  $json: " + JSON.stringify( $json.model ) );
			if ( !$json.model  ) {
				Log.out( "ModelInfo.init - ERROR - unable to find model Info in : " + $modelGuid + "  containing: " + JSON.stringify($json), Log.ERROR );					
				return;
			}
				
			_fileName = $modelGuid;
			_modelJson = $json;
			
			// this is the json just for modelInfo
			var modelInfoJson:Object = $json.model;
			
			if ( modelInfoJson && modelInfoJson.guid  )
				Log.out( "ModelInfo.init - WARNING - FOUND OLD modelGuid in file: " + $modelGuid );					
				
			
			if ( modelInfoJson.grainSize )
				_grainSize = 	modelInfoJson.grainSize;
			else if ( modelInfoJson.GrainSize )
				_grainSize = 	modelInfoJson.GrainSize;
			else if ( modelInfoJson.grainsize )
				_grainSize = 	modelInfoJson.grainsize;
			
			if ( modelInfoJson.modelClass )
				_modelClass = modelInfoJson.modelClass;

			if ( modelInfoJson.script ) {
				for each ( var scriptObject:Object in modelInfoJson.script ) {
					if ( scriptObject.name ) {
						//trace( "ModelInfo.init - Model GUID:" + fileName + "  adding script: " + scriptObject.name );
						_scripts.push( scriptObject.name );
					}
				}
			}
			
			if ( modelInfoJson.biomes )
			{
				var biomes:Object = modelInfoJson.biomes;
				if ( !biomes  ) {
					throw new Error( "ModelInfo.init - WARNING - unable to find biomes in json file: " + fileName );					
					return;
				}
				
				// TODO this should only be true for new terrain models.
				const createHeightMap:Boolean = true;
				_biomes = new Biomes( createHeightMap  );
				if (  !modelInfoJson.biomes.layers ) {
					throw new Error( "ModelInfo.init - WARNING - unable to find layerInfo: " + fileName );					
					return;
				}
				var layers:Object = modelInfoJson.biomes.layers;
				_biomes.load_biomes_data(layers);
			}
			
			if ( modelInfoJson.children ) {
				var children:Object = modelInfoJson.children;
				for each ( var v:Object in children )		   
				{
					_childCount++;
					var ii:InstanceInfo = new InstanceInfo();
					ii.initJSON( v );
					// This adds the instanceInfo for the child models to our child list which is processed when object is initialized
					childAdd( ii );
				}
			}
			
			if ( modelInfoJson.animations ) {
				//Log.out( "ModelInfo.init - animations found" );
				var animationsObj:Object = modelInfoJson.animations;
				// i.e. animData = { "name": "Glide", "type": "state OR action", "guid":"Glide.ajson" }
				for each ( var animData:Object in animationsObj )		   
				{
					AnimationEvent.dispatch( new AnimationEvent( ModelBaseEvent.REQUEST, 0, $modelGuid, animData.name, null, false ) );
					/*
					var animation:Animation = new Animation();
//					throw new Error( "ModelInfo.initJSON - This needs to be modified to load the animation from persistance" );
					animation.loadFromLocalFile( animData, modelClass );
					// This adds the instanceInfo for the child models to our child list which is processed when object is initialized
					_animations.push( animation )
					*/
				}
			}
		}
	}
}