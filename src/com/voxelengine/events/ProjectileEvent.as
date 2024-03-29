/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
import com.voxelengine.worldmodel.weapons.Ammo;
import flash.events.Event;
import flash.geom.Vector3D;
import flash.events.EventDispatcher;

/**
 * ...
 * @author Robert Flesch - RSF 
 * 
 */
public class ProjectileEvent extends Event
{
	static public const PROJECTILE_SHOT:String			= "PROJECTILE_SHOT";
	static public const PROJECTILE_CREATED:String		= "PROJECTILE_CREATED";
	static public const PROJECTILE_DESTROYED:String		= "PROJECTILE_DESTROYED";
	
	private var _position:Vector3D;
	private var _direction:Vector3D;
	private var _ammo:Ammo;
	private var _ownerGuid:String = "NOT SET";
	
	public function get position():Vector3D { return _position; }
	public function get direction():Vector3D { return _direction; }
	public function get ammo():Ammo { return _ammo;}
	public function get owner():String { return _ownerGuid; }
	
	public function set position(val:Vector3D):void { _position = val; }
	public function set direction(val:Vector3D):void { _direction = val; }
	public function set ammo(value:Ammo):void  { _ammo = value; }
	public function set owner(val:String):void { _ownerGuid = val; }
	
	public function ProjectileEvent( $type:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
	{
		super( $type, $bubbles, $cancellable );
	}
	
	public override function clone():Event
	{
		// Use the change type method, but use the same type
		return changeType( type );
	}
   
	public function changeType( $newType:String ):ProjectileEvent
	{
		throw new Error( "ProjectileEvent.changeType - what to do here" );
		var pe:ProjectileEvent = new ProjectileEvent( $newType, bubbles, cancelable);
		//pe.position = position.clone();
		//pe.ammo = _ammo.clone();
		//pe.direction = direction.clone();
		//pe.owningModel = owningModel;
		return pe;
	}
   
	public override function toString():String
	{
		return formatToString("ProjectileEvent" + "  position: " + position + "  direction: " + direction + " ammo: " + ammo  + " ownerId: " + owner);
	}
		
	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all persistance messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function dispatch( $event:ProjectileEvent ) : Boolean {
		return _eventDispatcher.dispatchEvent( $event );
	}
	
	///////////////// Event handler interface /////////////////////////////
}
}
