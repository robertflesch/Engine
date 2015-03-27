/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.LoadingEvent;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;
import flash.geom.Vector3D;
import flash.geom.Matrix3D;
//import org.flintparticles.threeD.initializers.Rotation;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelEvent;
import com.voxelengine.events.RegionEvent;
import com.voxelengine.worldmodel.models.*;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.scripts.ScriptLibrary;
import com.voxelengine.worldmodel.scripts.Script;
import com.voxelengine.pools.GrainCursorPool;

/**
 * ...
 * @author Bob
 */
public class InstanceInfo extends Location	{
	
	static private const MAX_ROT_RATE:Number 		= 2.0;
	static protected var _s_speedMultipler:Number	= 4;
	
	private var _usesCollision:Boolean 				= false;                        // toJSON
	private var _collidable:Boolean 				= true;							// toJSON
	private var _critical:Boolean 					= false;						// toJSON
	private var	_moveSpeed:SecureNumber 				= new SecureNumber( 0.01 );
	private var _transforms:Vector.<ModelTransform> = new Vector.<ModelTransform>;	// toJSON
	private var _shader:String 						= "ShaderOxel";					// toJSON
	private var _modelGuid:String;								                        // toJSON
	private var _instanceGuid:String;												// toJSON
	
	private var _grainSize:int 						= 0;                            // toJSON
	private var _detailSize:int 					= 0;                            // INSTANCE NOT EXPORTED
	private var _type:int 							= -1;                           // toJSON - This type overrides a native task type.
	
	private var _dynamicObject:Boolean 				= false;						// INSTANCE NOT EXPORTED
	private var _scripts:Vector.<Script> 			= new Vector.<Script>			// INSTANCE NOT EXPORTED
	private var _controllingModel:VoxelModel 		= null;    						// INSTANCE NOT EXPORTED
	private var _owner:VoxelModel 					= null;               			// INSTANCE NOT EXPORTED
	private var _creationJSON:Object 				= null;                         // INSTANCE NOT EXPORTED
	private var _state:String 						= "";							// INSTANCE NOT EXPORTED
	public var	_repeat:int = 0;
	
	private var _life:Vector3D 						= new Vector3D(1, 1, 1);		// INSTANCE NOT EXPORTED
	
	private var	_baseLightLevel:uint				= 0x33;
	
	public function get baseLightLevel():uint 					{ return _baseLightLevel; }
	public function set baseLightLevel(val:uint):void 			{ _baseLightLevel = val; }
	
	public function speed( time:Number ):Number 				{ return _moveSpeed.val * _s_speedMultipler * time; }
	
	public function get life():Vector3D 						{ return _life; }
	public function get moveSpeed():Number  					{ return _moveSpeed.val; }
	public function set moveSpeed(value:Number):void  			{ _moveSpeed.val = value; }
	public function get dynamicObject():Boolean 				{ return _dynamicObject; }
	public function set dynamicObject(val:Boolean):void 		{ _dynamicObject = val; }
	public function get usesCollision():Boolean 				{ return _usesCollision; }
	public function set usesCollision(val:Boolean):void 		{ _usesCollision = val; }
	public function get collidable():Boolean 					{ return _collidable; }
	public function set collidable(val:Boolean):void 			{ _collidable = val; }
	public function get critical():Boolean 						{ return _critical; }
	public function set critical(val:Boolean):void 				
	{ 
		_critical = val; 
		ModelEvent.dispatch( new ModelEvent( ModelEvent.CRITICAL_MODEL_DETECTED, modelGuid ) );
	}
	public function 	modelGuidGet():String 						{ return _modelGuid; } // used by debug menu to monitor selected model
	public function get modelGuid():String 							{ return _modelGuid; }
	//public function set guid(val:String):void					{ _guid = val; }
	public function set modelGuid(val:String):void { 
		//Log.out( "InstanceInfo.GUID was: " + _guid + " is now: " + val );
		_modelGuid = val; 
	}
	public function get instanceGuid():String 					{ return _instanceGuid; }
	//public function set instanceGuid(val:String):void			{ _instanceGuid = val; }
	public function set instanceGuid(val:String):void 			{ _instanceGuid = val; }
	
	public function get grainSize():int  						{ return _grainSize; }
	public function get detailSize():int  						{ return _detailSize; }
	public function set detailSize(val:int):void				{ _detailSize = val; }  // This is used in the generation of spheres only
	public function get type():int  							{ return _type; }
	public function set type( val:int):void  					{ _type = val; }
	public function set grainSize(val:int):void					{ _grainSize = val; }
	public function get shader():String 						{ return _shader; }
	public function get controllingModel():VoxelModel  			{ return _controllingModel; }
	public function set controllingModel(val:VoxelModel):void 	
	{ 
		if ( val && this == val.instanceInfo )
			Log.out( "Instance	Info.controllingModel SET - trying to set this to itself" );
		_controllingModel = val; 
	}
	public function get owner():VoxelModel  					{ return _owner; }
	public function set owner(val:VoxelModel):void 				
	{ 
		_owner = val; 
		// make sure we have a previous position
		positionSet = positionGet;
	}
	public function get scripts():Vector.<Script>				{ return _scripts; }
	public function get state():String 							{ return _state; }
	public function set state(val:String):void						{ _state = val; }
	// I dont like that sometimes this is in World Space, and sometimes in Model Space
	public function get transforms():Vector.<ModelTransform>	{ return _transforms; }
	public function set transforms(val:Vector.<ModelTransform>):void
	{ 
		for each ( var mt:ModelTransform in val )
		{
			addTransformMT( mt );
		}
	}
	
	public function buildExportObject():Object {
		var instObject:Object = new Object();
		instObject.model = getJSON();
		return instObject;
	}
	
	public function getJSON():Object 
	{ 
		return {
				center: 		center,
				collision:		_usesCollision,
				collidable:     _collidable,
				critical:     	_critical,
				baseLightLevel: baseLightLevel,
				grainSize: 		_grainSize,
				instanceGuid: 	instanceGuid,
				location: 		positionGet,
				modelGuid: 		modelGuid,
				rotation: 		rotationGet,
				velocity: 		velocityGet,
				scale: 			scale,
				script: 		instanceScriptOnly(),
				state:			_state,
				transforms:		_transforms
//				shader:			_shader,
				};
	} 	
	
	private function instanceScriptOnly():Vector.<Object> {
		
		var oa:Vector.<Object> = new Vector.<Object>();
		var len:int = _scripts.length;
		for each ( var script:Script in _scripts ) {
		if ( !script.modelScript ) {
				var so:Object = new Object();
				so.name = Script.getCurrentClassName( script );
				Log.out( "InstanceInfo.instanceScriptOnly - script: " + script );
				oa.push( so );
			}
		}
		return oa;
	}
	
	
	public function InstanceInfo() 
	{ 
		//RegionEvent.addListener( RegionEvent.LOAD_COMPLETE, onLoadingComplete );
		LoadingEvent.addListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
	}

	public function clone():InstanceInfo
	{
		var ii:InstanceInfo = new InstanceInfo();
		ii.initJSON( _creationJSON );
		return ii;
	}
	
	public function explosionClone():InstanceInfo
	{
		var ii:InstanceInfo = new InstanceInfo();
		if ( null != _creationJSON )
			ii.initJSON( _creationJSON );
		
		ii.dynamicObject = true;
		
		return ii;
	}

	public function toString():String
	{
		var cmString:String = "";
		if ( null != controllingModel) 
			cmString = "   controllingModel: " + controllingModel.instanceInfo.toString();
		 
		return " modelGuid: " + modelGuid + 
		       "   instanceGuid: " + instanceGuid + 
			   //" pos: " + positionGet + 
			   cmString
			   ;
	}

	private function onLoadingComplete( le:LoadingEvent ):void
	{
		LoadingEvent.removeListener( LoadingEvent.LOAD_COMPLETE, onLoadingComplete );
	}
	
	public function topmostGuid():String {
		if ( controllingModel )
			return controllingModel.instanceInfo.topmostGuid();
		return modelGuid;	
	}
	
	public function initJSON( json:Object ):void {
		// Save off a copy of this in case we need multiple instances
		if ( json.model )
			_creationJSON = json.model;
		else
			_creationJSON = json;
		
		// fileName == templateName == guid ALL THE SAME
		if ( _creationJSON.fileName ) {
			modelGuid = _creationJSON.fileName;
		}
		if ( _creationJSON.modelGuid ) {
			modelGuid = _creationJSON.modelGuid;
		}
		
		if ( _creationJSON.instanceGuid ) {
			_instanceGuid = _creationJSON.instanceGuid;
		}
			
		if ( _creationJSON.name )
		{
			if ( owner && owner.metadata ) {
				owner.metadata.name = _creationJSON.name;
				Log.out( "InstanceInfo.initJSON - Setting Metadata Name from instance data: " + _creationJSON.name + "  guid: " + modelGuid );
			}
		}
		
		if ( _creationJSON.state )
			_state = _creationJSON.state;

		if ( _creationJSON.repeat )
			_repeat = _creationJSON.repeat;
			
		if ( _creationJSON.baseLightLevel )
			baseLightLevel = _creationJSON.baseLightLevel;
					
		setPositionalInfo( _creationJSON );
		setScaleInfo( _creationJSON );
		setCenterInfo( _creationJSON );
		setTypeInfo( _creationJSON );
		setTransformInfo( _creationJSON );
		// moved to shader
//			setTextureInfo( _creationJSON );
		setShaderInfo( _creationJSON );
		setScriptInfo( _creationJSON );
		setCollisionInfo( _creationJSON );
		setCriticalInfo( _creationJSON );
	}
	
	public function addScript( scriptName:String, $modelScript:Boolean, params:* = null ):Script
	{
		//Log.out( "InstanceInfo.addScript - " + scriptName );
		var scriptClass:Class = ScriptLibrary.getAsset( scriptName );
		var script:Script = null;
		if ( params )
			script = new scriptClass( params );
		else
			script = new scriptClass();
		
		script.modelScript = $modelScript;
		_scripts.push( script );
		
		if ( script )
		{
			script.instanceGuid = instanceGuid;
			script.vm		= owner;
			//script.event( OxelEvent.CREATE );
			// Only person using this is the AutoControlObjectScript
		}

		return script;
	}
	
	public function setScriptInfo( json:Object ):void
	{
		if ( json.script && ( 0 < json.script.length ) )
		{
			for each ( var scriptObject:Object in json.script ) {
				if ( scriptObject.name ) {
					//trace( "ModelInfo.init - Model GUID:" + fileName + "  adding script: " + scriptObject.name );
					addScript( scriptObject.name, false );
				}
			}
			
		}
	}
	
	public function setCriticalInfo( json:Object ):void
	{
		if ( json.critical )
		{
			var criticalJson:String = json.critical;
			if ( "true" == criticalJson.toLowerCase() )
			{
				critical = true;
			}
		}
	}
	public function setCollisionInfo( json:Object ):void
	{
		// is this object able to be collided with 
		_collidable = true;
		var collideable:String;
		if ( json.collidable )
		{
			collideable = json.collidable;
			if ( "false" == collideable.toLowerCase() )
				_collidable = false;
		}
		if ( json.collideable )
		{
			collideable = json.collideable;
			if ( "false" == collideable.toLowerCase() )
				_collidable = false;
		}
		
		// does this object attempt to collide with other objects?
		_usesCollision = false;
		if ( json.collision )
		{
			var collision:String = json.collision;
			if ( "true" == collision.toLowerCase() )
				_usesCollision = true;
		}
	}
	
	
	public function setShaderInfo( json:Object ):void
	{
		if ( json.shader )
			_shader = json.shader;
	}
	
	public function setTypeInfo( json:Object ):void
	{
	
		if ( json.type )
		{
			var typeString:String = "INVALID";
			typeString = json.type.toLowerCase();
			_type = TypeInfo.getTypeId( typeString );
			if ( TypeInfo.INVALID == type )
				Log.out( "LayerInfo.initJSON - WARNING - INVALID type found: " + typeString, Log.WARN );
		}
		
		if ( json.grainSize )
			_grainSize = 	json.grainSize;
		else if ( json.GrainSize )
			_grainSize = 	json.GrainSize;
		else if ( json.grainsize )
			_grainSize = 	json.grainsize;
	}
	
	// TODO Do I need name for transformation here?
	public function setTransformInfo( json:Object ):void
	{
		if ( json.transforms )
		{
			for each ( var modelTransform:Object in json.transforms )
			{
				var transformType:int = ModelTransform.stringToType( modelTransform.type.toLowerCase() );
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

	public function advance( $elapsedTimeMS:int ):Boolean
	{
		var index:int = 0;
		for each ( var trans:ModelTransform in transforms )
		{
			//Log.out( "InstanceInfo.update: " + trans );
			// Update transform, performing appropriate action and
			// check to see if there is time remaining on this transform
			if ( trans.update( $elapsedTimeMS, owner ) )
			{
				if ( ModelTransform.LIFE == trans.type )
				{
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
		// due to the back door way I access the data, I have to force a matrix update here.
		if ( 0 < index )
			recalculateMatrix( true );
		return false;
	}
	
	public function update( $elapsedTimeMS:int ):Boolean
	{
		return advance( $elapsedTimeMS );
	}
	
	public function removeNamedTransform( type:int, name:String ):void 
	{
		var index:int = 0;
		// see if the transformations contain one already with this name.
		for each ( var mt:ModelTransform in transforms )
		{
			if ( mt.name == name && mt.type == type )
			{
				// this transform is now expired!
				//Log.out( "InstanceInfo.update - removing NAMED transform", Log.ERROR );
				transforms.splice( index, 1 );
				break;
			}
			index++;	
		}
	}
	
	public function removeAllNamedTransforms():void 
	{
		var index:int = 0;
		// see if the transformations contain one already with this name.
		for each ( var mt:ModelTransform in transforms )
		{
			if ( "" != mt.name )
			{
				//Log.out( "InstanceInfo.removeAllNamedTransforms - name:" + name, Log.ERROR );
				transforms.splice( index, 1 );
			}
			index++;	
		}
	}
	
	public function removeAllTransforms():void 
	{
		transforms.length = 0;
	}
	
	public function addNamedTransform( x:Number, y:Number, z:Number, time:Number, type:int, name:String = "Default" ):void 
	{
		removeNamedTransform( type, name );
		addTransform( x, y, z, time, type, name );
	}
	
	public function addNamedTransformMT( $mt:ModelTransform ):void 
	{
		removeNamedTransform( $mt.type, $mt.name );
		addTransformMT( $mt );
	}
	
	public function updateNamedTransform( $mt:ModelTransform, $val:Number ):void 
	{
		var index:int = 0;
		// see if the transformations contain one already with this name.
		for each ( var mt:ModelTransform in transforms )
		{
			if ( mt.name == $mt.name && mt.type == $mt.type )
			{
				mt.modify( $mt, $val );
				break;
			}
			index++;	
		}
	}
	
	public function addTransformMT( $mt:ModelTransform ):void 
	{
		//Log.out( "InstanceInfo.addTransformMT " + mt.toString() );
		pushMT( $mt );
	}

	public function addTransform( $x:Number, $y:Number, $z:Number, $time:Number, $type:int, $name:String = "Default" ):void 
	{
		var mt:ModelTransform = new ModelTransform( $x, $y, $z, $time, $type, $name );
		pushMT( mt );
	}
	
	private function pushMT( $mt:ModelTransform ):void
	{
		$mt.assignToInstanceInfo( this );
		transforms.push( $mt );
	}
	

	// this is a scalar magnitude in g0 units
	public function setSpeedMultipler ( v:Number ):Number
	{
		Log.out( "InstanceInfo.setSpeedMultiper - was: " + _s_speedMultipler + " will be: " + v );
		return _s_speedMultipler = v;
	}
	
	public function reset():void
	{
		Region.resetPosition();
		resetCamera();
	}
	
	static private function resetCamera():void
	{
		if ( Globals.controlledModel )
		{
			Globals.controlledModel.instanceInfo.rotationSet = new Vector3D( 0,0,0 );
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// WorldToModel and ModelToWorld
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	override public function worldToModel( v:Vector3D ):Vector3D
	{
		if ( changed )
			recalculateMatrix();
		if ( _controllingModel )
			return modelMatrix.transformVector( _controllingModel.worldToModel( v ) );
		else
			return modelMatrix.transformVector( v );
	}
	
	override public function modelToWorld( v:Vector3D ):Vector3D
	{
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