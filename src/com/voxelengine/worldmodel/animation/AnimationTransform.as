/*==============================================================================
Copyright 2011-2013 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
import com.voxelengine.Globals;
import com.voxelengine.Log;
import flash.geom.Vector3D;
import org.flashapi.swing.text.ATM;
import com.voxelengine.worldmodel.models.ModelTransform;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class AnimationTransform
{
	static public var DEFAULT_OBJECT:Object = { 
		attachmentName:"This should be the name of the parent or child",
		//notNamed
		location: { x:0, y:0, z:0 },
		scale: { x:1, y:1, z:1 },
		rotation: { x:0, y:0, z:0 }
	}
	
	private var _attachmentName:String = "INVALID_ATTACHMENT";
	private var _position:Vector3D = new Vector3D();
	private var _rotation:Vector3D = new Vector3D();
	private var _scale:Vector3D = new Vector3D(1,1,1);
	private var _transforms:Vector.<ModelTransform> = new Vector.<ModelTransform>;
	private var _notNamed:Boolean = false;

	// for compatability with PanelVectorContainer
	public function get name():String 							{ return _attachmentName; }
	public function get attachmentName():String 				{ return _attachmentName; }
	public function set attachmentName( $val:String ):void 		{ _attachmentName = $val; }
	public function get position():Vector3D 					{ return _position; }
	public function get rotation():Vector3D 					{ return _rotation; }
	public function get scale():Vector3D 						{ return _scale; }
	public function get transforms():Vector.<ModelTransform> 	{ return _transforms; }
	public function get hasPosition():Boolean  					{ return 0 != _position.length; }
	public function set hasPosition( $val:Boolean):void			{ 
		if ( false == $val )
			_position.setTo( 0, 0, 0 );
	}
	public function get hasRotation():Boolean					{ return 0 != _rotation.length; }
	public function set hasRotation( $val:Boolean):void			{ 
		if ( false == $val )
			_rotation.setTo( 0, 0, 0 );
	}
	public function get hasScale():Boolean 						{ return 3 != _scale.lengthSquared; }
	public function set hasScale( $val:Boolean):void			{ 
		if ( false == $val )
			_scale.setTo( 1, 1, 1 );
	}
	public function get hasTransform():Boolean  				{ return 0 < _transforms.length; }
	public function get notNamed():Boolean 						{ return _notNamed; }
	
	public function resetInitialPosition():void {
		_position.setTo(0,0,0)
		_rotation.setTo(0,0,0)
		_scale.setTo(1,1,1)
	}
	
	public function AnimationTransform( $obj:Object ) 
	{ 
		if ( $obj.attachmentName )
			_attachmentName = $obj.attachmentName;
		else
			Log.out( "AnimationTransform - No attachmentName name", Log.ERROR );
			
		if ( $obj.location ) {
			_position = new Vector3D( $obj.location.x, $obj.location.y, $obj.location.z );
		}
		
		// Transforms which are not named will stick around even after animation is played
		// So they should only be used on timed animations.
		// Need more details on how this is used
		if ( $obj.notNamed ) {
			_notNamed = $obj.notNamed;
			Log.out( "AnimationTransformation - How is notNamed used?", Log.ERROR );
		}
		
		if ( $obj.scale ) {
			_scale = new Vector3D( $obj.scale.x, $obj.scale.y, $obj.scale.z );
		}
		
		if ( $obj.rotation ) {
			_rotation = new Vector3D( $obj.rotation.x, $obj.rotation.y, $obj.rotation.z );
		}
			
		if ( $obj.transforms ) {
			for each ( var modelTransform:Object in $obj.transforms )
			{
				var type:int = ModelTransform.stringToType( modelTransform.type.toLowerCase() );
				if ( "life" == modelTransform.type.toLowerCase() )
					addTransform( 0
								, 0
								, 0
								, modelTransform.time
								, type
								, attachmentName );
				else
				{
					if ( !modelTransform.time || !modelTransform.type )
					{
						Log.out( "AnimationTransform.construct - ALL transforms must contain x,y,z,time, type, and name values attachmentName: " + _attachmentName + "  mt data: " + modelTransform );
						return;
					}

					addTransform( modelTransform.delta.x
								, modelTransform.delta.y
								, modelTransform.delta.z
								, modelTransform.time
								, type
								, attachmentName );
				}
			}
		}
	}
/*
	public function buildExportObject( obj:Object ):void {			
		obj.attachmentName 	= _attachmentName;
		if ( hasPosition )
			obj.location	= _position;
		if ( hasRotation )
			obj.rotation	= _rotation;
		if ( hasScale )
			obj.scale		= _scale;
		if ( hasTransform )
			getTransformsObj( obj );
			
		function getTransformsObj( obj:Object ):void {
			var ot:Vector.<Object> = new Vector.<Object>();
			for each ( var mt:ModelTransform in _transforms ) {
				var mto:Object = new Object();
				mt.buildExportObject( mto );
				ot.push( mto );
			}
			if ( ot.length )
				obj.transforms = ot;
		}
	}
	*/
	public function toObject():Object {			
		var obj:Object = new Object()
		obj.attachmentName 	= _attachmentName;
		if ( hasPosition )
			obj.location	= vector3DIntToObject( _position );
		if ( hasRotation )
			obj.rotation	= vector3DIntToObject( _rotation );
		if ( hasScale )
			obj.scale		= vector3DToObject( _scale );
		if ( hasTransform )
			obj.transforms = getTransformsObj();
			
		return obj
		
		function getTransformsObj():Object {
			var ot:Array = new Array();
			for each ( var mt:ModelTransform in _transforms ) {
				var obj:Object = mt.toObject();
				ot.push( obj );
			}
			return ot
		}
		
		function vector3DToObject( $vec:Vector3D ):Object {
			return { x:$vec.x, y:$vec.y, z:$vec.z };
		}
		
		function vector3DIntToObject( $vec:Vector3D ):Object {
			return { x:int($vec.x), y:int($vec.y), z:int($vec.z) };
		}
	}

	public function clone( $val:Number = 1 ):AnimationTransform	{
		new Error( "AnimationTransform.clone - NOT VALIDATED" );
		var obj:Object = new Object();
		obj.attachmentName = _attachmentName;
		var at:AnimationTransform = new AnimationTransform( obj );
		at._position = position.clone();
		at._rotation = rotation.clone();
		at._scale = scale.clone();
		for each ( var mt:ModelTransform in _transforms )
			at._transforms.push( mt.clone( $val ) );
		return at;
	}

	public function addTransform( $x:Number, $y:Number, $z:Number, $time:Number, $type:int, $name:String = "Default" ):void {
		_transforms.push( new ModelTransform( $x, $y, $z, $time, $type, $name ) );
		//Log.out( "InstanceInfo.addTransform " + mt.toString() );
	}
	
	public function toString():String
	{
		return " attachmentName: " + _attachmentName + "  position: " + _position +  "  scale: " + _scale + "  rotation: " + _rotation + " transform: " + _transforms;
	}
	
}
}
