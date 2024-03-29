/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and prStringed documentation which are original works of
  authorship protected under uStringed States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel
{

public class Interactions 
{
	private var _interactions:Array = [];
	private var _belongsTo:String;
	private var _defaults:Array = [ "PICK", "SHOVEL", "AXE", "DFIRE", "DICE", "WATER", "AIR", "EARTH" ];
	
	public function Interactions( $belongsTo:String )
	{ 
		_belongsTo = $belongsTo; 
	}
	
	public function fromJson( $interactionJson:Object ):void
	{
		for each ( var io:Object in $interactionJson )
		{
			for ( var name:String in io )
			{
				var ip:InteractionParams = new InteractionParams( name );
				ip.fromJson( io[name] );
				_interactions[name] = ip;
			}
		}
	}
	
	public function setDefault():void
	{
		for each ( var name:String in _defaults )
		{
			var ip:InteractionParams = new InteractionParams( name );
			ip.setDefault();
			_interactions[name] = ip;
		}
	}
	
	public function IOGet( $name:String ):InteractionParams
	{
		$name = $name.toUpperCase();
		for ( var name:String in _interactions )
		{
			if ( name == $name )
				return _interactions[$name];
		}
		//Log.out( "Interactions.IOGet for " + $name + " no interaction defined" );
		var ip:InteractionParams = new InteractionParams( name );
		ip.setDefault();
		return ip;
	}
}
}
