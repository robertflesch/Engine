/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{

import flash.geom.Vector3D;
import flash.geom.Matrix3D;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.TransformEvent;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.scripts.ScriptLibrary;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.pools.GrainCursorPool;

public class InstanceInfo extends Location	{
	
	private var _speedMultiplier:Number							= 4;
	public function setSpeedMultiplier ( v:Number ):Number { 	// this is a scalar magnitude in g0 units
		//Log.out( "InstanceInfo.setSpeedMultiplier - was: " + _s_speedMultiplier + " will be: " + v );
		return _speedMultiplier = v;
	}

	private var	_moveSpeed:SecureNumber 						= new SecureNumber( 0.02 );
//	public function get moveSpeed():Number  					{ return _moveSpeed.val; }
	public function set moveSpeed(value:Number):void  			{ _moveSpeed.val = value; }
	public function speed( $time:Number ):Number 				{
		//Log.out( "InstanceInfo.speed - _moveSpeed.val: " + _moveSpeed.val + " _speedMultiplier: " + _speedMultiplier + " timeElapsed: " + $time );
		return _moveSpeed.val * _speedMultiplier * $time; }


	private var _usesCollision:Boolean 							= false;                        // toObject
	public function get usesCollision():Boolean 				{ return _usesCollision; }
	public function set usesCollision(val:Boolean):void 		{ _usesCollision = val; }

	private var _collidable:Boolean 							= true;							// toObject
	public function get collidable():Boolean 					{ return _collidable; }
	public function set collidable(val:Boolean):void 			{ _collidable = val; }

	private var _critical:Boolean 								= false;						// toObject
	public function get critical():Boolean 						{ return _critical; }
	public function set critical(val:Boolean):void 				{
		_critical = val;
        ModelEvent.create( ModelEvent.CRITICAL_MODEL_DETECTED, modelGuid );
	}
	private var _transforms:Vector.<ModelTransform> 			= new Vector.<ModelTransform>;	// toObject
	public function get transforms():Vector.<ModelTransform>	{ return _transforms; }
//	public function set transforms(val:Vector.<ModelTransform>):void {
//		for each ( var mt:ModelTransform in val )
//			addTransformMT( mt );
//	}

	private var _modelGuid:String;											                    // toObject
	public function get modelGuid():String 						{ return _modelGuid; }
	public function set modelGuid(val:String):void 				{ _modelGuid = val; changed = true; }

	private var _instanceGuid:String;															// toObject
	public function get instanceGuid():String 					{ return _instanceGuid; }
	public function set instanceGuid(val:String):void 			{ _instanceGuid = val; }

	private var _name:String									= "";							// toObject
	public function set	name( $val:String):void 				{ _name = $val; changed = true; }
	public function get name():String 							{ return _name; }

	private var _dynamicObject:Boolean 							= false;						// INSTANCE NOT EXPORTED
	public function get dynamicObject():Boolean 				{ return _dynamicObject; }
	public function set dynamicObject(val:Boolean):void 		{ _dynamicObject = val; }

	// this is the voxel model which controls the parent of the instanceInfo.
	private var _controllingModel:VoxelModel 					= null;    						// INSTANCE NOT EXPORTED
	public function get controllingModel():VoxelModel  			{ return _controllingModel; }
	public function set controllingModel(val:VoxelModel):void   {
		if ( val && this == val.instanceInfo )
			Log.out( "Instance	Info.controllingModel SET - trying to set this to itself" );
		_controllingModel = val;
	}
	private var _info:Object 									= null;                         // INSTANCE NOT EXPORTED
	private var _state:String 									= "";							// INSTANCE NOT EXPORTED
	public function get state():String 							{ return _state; }
	public function set state(val:String):void					{ _state = val; }

	private	var	_visible:Boolean 								= true;  // Should be exported/ move to instance
	public	function get visible():Boolean 						{ return _visible; }
	public	function set visible(val:Boolean):void 				{ _visible = val; }
	
	private var 		_life:Vector3D 							= new Vector3D(1, 1, 1);		// INSTANCE NOT EXPORTED
	public function get life():Vector3D 						{ return _life; }
	
	// this is the VoxelModel that the instanceInfo belongs to.
	// mainly used to identify owner and send info backup the chain.
	private var _owner:VoxelModel 								= null;               			// INSTANCE NOT EXPORTED
	public function get owner():VoxelModel  					{ return _owner; }
	public function set owner(val:VoxelModel):void 				{
		_owner = val;
		// make sure we have a previous position
		positionSet = positionGet;
	}

	// if this model is a child of a larger model
	private		var _associatedGrain:GrainCursor;
	public  function get associatedGrain():GrainCursor			{ return _associatedGrain; }
	public  function associatedGrainReset():void { _associatedGrain = null; }
	public  function set associatedGrain( $val:GrainCursor ):void {
		if ( null == _associatedGrain )
			_associatedGrain = new GrainCursor();
		_associatedGrain.copyFrom( $val ); }

	private var _baseLightLevel:uint 							= 0;
	public function get baseLightLevel():int 					{ return _baseLightLevel; }
	public function set baseLightLevel( value:int ):void		{ _baseLightLevel = value; changed = true; }

	private var _scripts:Array 									= [];							// toObject
	public function get scripts():Array							{ return _scripts; }

	public function InstanceInfo() {}

	public function release():void {
		_moveSpeed 			= null;
		_transforms 		= null;
		_modelGuid			= null;
		_instanceGuid		= null;
		_scripts			= null;
		_controllingModel	= null;
		_owner				= null;
		_info				= null;
		_state				= null;
		_life				= null;
	}
	
	public function clone():InstanceInfo {
		var ii:InstanceInfo = new InstanceInfo();
		var obj:Object = toObject();
		ii.fromObject( obj );
		ii.instanceGuid = Globals.getUID();
		return ii;
	}
	
	static private function vector3DToObject( $vec:Vector3D ):Object {
		return { x:$vec.x, y:$vec.y, z:$vec.z };
	}

//	static private function vector3DIntToObject( $vec:Vector3D ):Object {
//		return { x:int($vec.x), y:int($vec.y), z:int($vec.z) };
//	}
	
	override public function toObject():Object {	
		
		var obj:Object 		= super.toObject();
		obj.instanceGuid	= instanceGuid;
		obj.modelGuid 		= modelGuid;
		obj.name 			= name;
		obj.baseLightLevel	= _baseLightLevel;

		if ( associatedGrain )
			obj.associatedGrain	= associatedGrain.toObject();

		if ( velocityGet.length )
			obj.velocity		= vector3DToObject( velocityGet );
		if ( usesCollision )
			obj.usesCollision 	= usesCollision;
		if ( collidable )
			obj.collidable 		= collidable;
		if ( _critical )
			obj.critical		= _critical;
//		if ( "" != _state )
//			obj.state			= _state;
		instanceScriptOnly( obj );  //
		
		return obj;
		
		function instanceScriptOnly( obj:Object ):void {
			if ( _scripts.length ) {
				var scriptsArray:Array = [];
				for ( var i:int = 0; i < _scripts.length; i++ ) {
					if ( _scripts[i]  && !_scripts[i].modelScript ) {
						//Log.out( "InstanceInfo.instanceScriptOnly - script: " + Script.getCurrentClassName( _scripts[i] ) );
						//scripts["script" + i] = Script.getCurrentClassName( _scripts[i] );
						scriptsArray[i] = _scripts[i].toObject();
				}	}
				// Dont want to add empty arrays
				if ( scriptsArray.length )
					obj.scripts = scriptsArray;
			}
			else {
				if ( obj.scripts )
					delete obj.scripts
		}	}
	}

//	public function explosionClone():InstanceInfo {
//		var obj:InstanceInfo = new InstanceInfo();
//		if ( null != _info )
//			obj.fromObject( _info );
//
//		obj.dynamicObject = true;
//
//		return obj;
//	}

	public function toString():String {
		var cmString:String = "";
		if ( null != controllingModel) 
			cmString = "   controllingModel: " + controllingModel.instanceInfo.toString();
		 
		return " modelGuid: " + modelGuid + 
		       "   instanceGuid: " + instanceGuid + 
			   //" pos: " + positionGet + 
			   cmString
			   ;
	}

	public function modelGuidChain( $models:Vector.<String> ):void {
		if ( controllingModel ) {
			$models.push( controllingModel.modelInfo.guid );
			return controllingModel.instanceInfo.modelGuidChain( $models );
		}
	}

	public function topmostModelGuid():String {
		if ( controllingModel )
			return controllingModel.instanceInfo.topmostModelGuid();
		return modelGuid;	
	}
	
	public function topmostInstanceGuid():String {
		if ( controllingModel )
			return controllingModel.instanceInfo.topmostInstanceGuid();
		return instanceGuid;	
	}
	
	override public function fromObject( $info:Object ):void {
		super.fromObject( $info );
		//Log.out( "InstanceInfo.fromObject - data: " + JSON.stringify( $info ) );
		// Save off a copy of this in case we need multiple instances
		if ( $info.model )
			_info = $info.model;
		else
			_info = $info;
		
		// fileName == templateName == guid ALL THE SAME
		if ( _info.fileName )
			_modelGuid = _info.fileName;

		if ( _info.modelGuid )
			_modelGuid = _info.modelGuid;

		if ( _info.instanceGuid )
			_instanceGuid = _info.instanceGuid;

		if ( !_info.instanceGuid && !_info.modelGuid && !_info.fileName )
			Log.out( "InstanceInfo.fromObject - INVALID DATA, check: " + JSON.stringify( $info ) );
		
		if ( _info.name )
			_name = _info.name;

		if ( _info.state )
			_state = _info.state;

		if ( _info.associatedGrain ) {
			_associatedGrain = GrainCursorPool.poolGet(0);
			_associatedGrain.fromObject( _info.associatedGrain );
		}

		if ( _info.baseLightLevel )
			_baseLightLevel = _info.baseLightLevel;

		setTransformInfo( _info );
		setScriptInfo( _info );
		setCollisionInfo( _info );
		setCriticalInfo( _info );
	}
	
	public function addScript( scriptName:String, $modelScript:Boolean, $params:Object = null ):Script
	{
		//Log.out( "InstanceInfo.add  - " + scriptName );
		var scriptClass:Class = ScriptLibrary.getAsset( scriptName );
		var script:Script = new scriptClass( $params );
		
		_scripts.push( script );
		
		if ( script ) {
			script.modelScript = $modelScript;
			script.instanceGuid = instanceGuid;
			script.vm		= owner;
			script.name     = Script.getCurrentClassName(script);
			//script.event( OxelEvent.CREATE );
			// Only person using this is the AutoControlObjectScript
			if ( owner )
				script.init();
		}
		if ( owner && owner.complete )
			Region.currentRegion.changed = true;

		return script;
	}
	
	public function setScriptInfo( $info:Object ):void {
		if ( $info.scripts ) {
			for each ( var scriptObject:Object in $info.scripts ) {
				//trace( "InstanceInfo.setScriptInfo - Model GUID:" + fileName + "  adding script: " + scriptObject.name );
				if ( scriptObject.param )
					addScript( scriptObject.name, false, scriptObject.param );
				else
					addScript( scriptObject.name, false );
			}
		}
	}
	
	public function setCriticalInfo( $info:Object ):void {
		if ( $info.critical ) {
			var criticalJson:String = $info.critical;
			if ( "true" == criticalJson.toLowerCase() )
				critical = true;
		}
	}
	
	public function setCollisionInfo( $info:Object ):void {
		// is this object able to be collided with 
		collidable = true;
		if ( $info.collidable ) {
			var collideableVal:String = $info.collidable;
			if ( "false" == collideableVal.toLowerCase() )
				collidable = false;
		}	
		
		// does this object attempt to collide with other objects?
		usesCollision = false;
		if ( $info.usesCollision )
		{
			var collisionVal:String = $info.usesCollision;
			if ( "true" == collisionVal.toLowerCase() )
				usesCollision = true;
		}
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Transformation functions
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TODO Do I need name for transformation here?
	public function setTransformInfo( $info:Object ):void {
		if ( $info.transforms ) {
			for each ( var modelTransform:Object in $info.transforms ) {
				Log.out( "InstanceInfo.setTransformInfo - modelTransform.type: " + modelTransform.type , Log.WARN );
				var transformType:int;
				if ( modelTransform.type is String )
					transformType = ModelTransform.stringToType( modelTransform.type );
				else	
					transformType = modelTransform.type;
					
				if ( "life" == modelTransform.type.toLowerCase() )
					addTransform( 0
								, 0
								, 0
								, modelTransform.time
								, transformType );
				else
					addTransform( modelTransform.delta.x
								, modelTransform.delta.y
								, modelTransform.delta.z
								, modelTransform.time
								, transformType );
			}
		}
	}

	public function update( $elapsedTimeMS:int ):Boolean { return advance( $elapsedTimeMS ); }

	public function advance( $elapsedTimeMS:int ):Boolean {
		var index:int = 0;
		for each ( var mt:ModelTransform in transforms ) {
			//Log.out( "InstanceInfo.update: " + trans );
			// Update transform, performing appropriate action and
			// check to see if there is time remaining on this transform
			if ( mt.update( $elapsedTimeMS, owner ) ) {
				if ( ModelTransform.LIFE == mt.type ) {
					owner.dead = true;
					//Log.out("InstanceInfo.update - marking expired instance as dead: " + instanceGuid );
					return true;
				}
					
				// this transform is now expired!
				//Log.out( "InstanceInfo.update - removing expired transform", Log.ERROR );
				transforms.splice( index, 1 );
			}
			index++;	
		}
		// due to the back door way I access the oxelPersistence, I have to force a matrix update here.
		if ( 0 < index )
			recalculateMatrix( true );
		return false;
	}
	
	public function removeNamedTransform( $type:int, name:String ):void {
		var index:int = 0;
		// see if the transformations contain one already with this name.
		for each ( var mt:ModelTransform in transforms ) {
			if ( mt.name == name && mt.type == $type ) {
				// this transform is now expired!
				//Log.out( "InstanceInfo.update - removing NAMED transform", Log.ERROR );
				transforms.splice( index, 1 );
				TransformEvent.dispatch( new TransformEvent( TransformEvent.ENDED, instanceGuid, mt.name ) );
				break;
			}
			index++;	
		}
	}
	
	public function removeAllTransforms():void { transforms.length = 0; }
	public function removeAllNamedTransforms():void {
		//Log.out( "InstanceInfo.removeAllNamedTransforms", Log.WARN );
		var index:int = 0;
		// see if the transformations contain one already with this name.
		for each ( var mt:ModelTransform in transforms ) {
			if ( "" != mt.name ) {
				//Log.out( "InstanceInfo.removeAllNamedTransforms - name:" + name, Log.ERROR );
				transforms.splice( index, 1 );
				TransformEvent.dispatch( new TransformEvent( TransformEvent.ENDED, instanceGuid, mt.name ) );
			}
			index++;	
		}
	}
	
	public function addNamedTransform( x:Number, y:Number, z:Number, time:Number, $type:int, name:String = "Default" ):void {
		removeNamedTransform( $type, name );
		addTransform( x, y, z, time, $type, name );
	}
	
	public function addNamedTransformMT( $mt:ModelTransform ):void {
		removeNamedTransform( $mt.type, $mt.name );
		addTransformMT( $mt );
	}
	
	public function updateNamedTransform( $mt:ModelTransform, $val:Number ):void {
		var index:int = 0;
		// see if the transformations contain one already with this name.
		for each ( var mt:ModelTransform in transforms ) {
			if ( mt.name == $mt.name && mt.type == $mt.type ) {
				mt.modify( $mt, $val );
				break;
			}
			index++;	
		}
	}
	
	public function addTransformMT( $mt:ModelTransform ):void {
		//Log.out( "InstanceInfo.addTransformMT " + mt.toString() );
		pushMT( $mt );
	}

	public function addTransform( $x:Number, $y:Number, $z:Number, $time:Number, $type:int, $name:String = "Default" ):void {
		var mt:ModelTransform = new ModelTransform( $x, $y, $z, $time, $type, $name );
		pushMT( mt );
	}
	
	private function pushMT( $mt:ModelTransform ):void {
		$mt.assignToInstanceInfo( this );
		transforms.push( $mt );
	}
	

	static public function reset():void {
		Region.resetPosition();
		resetCamera();
	}
	
	static public function resetCamera():void {
		if ( VoxelModel.controlledModel ) {
			VoxelModel.controlledModel.instanceInfo.rotationSet = new Vector3D( 0,0,0 );
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// WorldToModel and ModelToWorld
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	override public function worldToModel( v:Vector3D ):Vector3D {
		if ( changed )
			recalculateMatrix();
		if ( _controllingModel )
			return modelMatrix.transformVector( _controllingModel.worldToModel( v ) );
		else
			return modelMatrix.transformVector( v );
	}
	
	public function worldToModelNew( v:Vector3D, d:Vector3D ):void {
		if ( changed )
			recalculateMatrix();
		if ( _controllingModel ){ 
			var test:Vector3D = modelMatrix.transformVector( _controllingModel.worldToModel( v ) );
			_controllingModel.worldToModelNew( v, d );
			transformVec( modelMatrix, v, d );
			if ( test != d )
				Log.out( "InstanceInfo.worldToModelNew - ERROR" );
		} else
			transformVec( modelMatrix, v, d );
	}
	
	// http://blog.bengarney.com/category/flash/
	public static function transformVec(m:Matrix3D, i:Vector3D, o:Vector3D):void {
		const x:Number = i.x, y:Number = i.y, z:Number = i.z;
		const d:Vector.<Number> = m.rawData;

		o.x = x * d[0] + y * d[4] + z * d[8] + d[12];
		o.y = x * d[1] + y * d[5] + z * d[9] + d[13];
		o.z = x * d[2] + y * d[6] + z * d[10] + d[14];
		o.w = x * d[3] + y * d[7] + z * d[11] + d[15];
	}	
	
	override public function modelToWorld( v:Vector3D ):Vector3D {
		if ( changed )
			recalculateMatrix();
		if ( _controllingModel ) {
			var parentMS:Vector3D = _controllingModel.modelToWorld( v );
			var wsLoc:Vector3D = worldSpaceMatrix.transformVector( parentMS );
			
			return wsLoc;
		}
		else
			return worldSpaceMatrix.transformVector( v );
	}
}
}