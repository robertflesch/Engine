/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;
import playerio.DatabaseObject;

/**
 * ...
 * @author Robert Flesch - RSF
 * IPersistance
 */
public interface IPersistance
{
	////////////////////////////////////////////////////////////////
	// TO Persistance
	////////////////////////////////////////////////////////////////
	function toPersistance():void;
	function toObject():void;
	function toByteArray( $ba:ByteArray ):ByteArray;
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	function fromPersistance( $dbo:DatabaseObject ):void;
	function fromObject( $object:Object, $ba:ByteArray ):void;
	function fromByteArray( $ba:ByteArray ):void;
}
}

