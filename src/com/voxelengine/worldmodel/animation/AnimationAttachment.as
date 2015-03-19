/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
	import flash.geom.Vector3D;
	
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.models.ModelLoader;
	import com.voxelengine.worldmodel.models.VoxelModel;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * 
	 */
	public class AnimationAttachment
	{
		private var _attachsTo:String = "INVALID_ATTACHMENT";
		private var _fileName:String = "INVALID_NAME";
		private var _instanceInfo:InstanceInfo = null;
		private var _voxelModel:VoxelModel = null;
		private var _owner:VoxelModel = null;
		
		public function AnimationAttachment( $json:Object ) 
		{
			if ( $json.attachsTo )
				_attachsTo = $json.attachsTo;
			else
				throw new Error( "AnimationAttachment.construct - NO attachsTo" );
				
			if ( $json.fileName )
				_fileName = $json.fileName;
			else
				throw new Error( "AnimationAttachment.construct - NO fileName" );
				
			
			Log.out( "AnimationAttachment - _attachsTo: " + _attachsTo + " fileName: " + $json.fileName );
			_instanceInfo = new InstanceInfo();
			_instanceInfo.initJSON( $json );
		}

		private function vectorToJSON( v:Vector3D ):String {  return JSON.stringify( {x:v.x, y:v.y, z:v.z} ); } 	

		
		public function getJSON():String {
			
			var outString:String = "{";
			outString += "\"fileName\": ";
			outString += "\"" + _fileName + "\"";
			outString += ",";
			outString += "\"attachsTo\": ";
			outString += "\"" + _attachsTo + "\"";
			outString += ",";
			outString += "\"location\": ";
			outString += vectorToJSON( _instanceInfo.positionGet );
			outString += ",";
			outString += "\"rotation\": ";
			outString += vectorToJSON( _instanceInfo.rotationGet );
			
			outString += "}";
			
			// TEST TEST TEST
			//JSON.parse( outString );
			
			return outString;
		}
		
		
		public function get instanceInfo():InstanceInfo 
		{
			return _instanceInfo;
		}
		
		public function get attachsTo():String 
		{
			return _attachsTo;
		}
		
		public function toJSON(k:*):* {
			return {
				attachmentName: _owner
			}
		}
		
		public function create( $owner:VoxelModel ):void
		{
			Log.out( "AnimationAttachment.create owner: " + $owner.toString() );
			_owner = $owner;
			_instanceInfo.controllingModel = $owner;
			if ( null == _voxelModel )
			{
				ModelEvent.addListener( ModelEvent.CHILD_MODEL_ADDED, onAttachmentCreated );
				ModelLoader.load( _instanceInfo );
			}
			else
			{
				//Log.out( "AnimationAttachment.create owner: " + $owner.toString() + "   attachment: " + _voxelModel.toString() );
				$owner.childAdd( _voxelModel );
			}
		}
		
		public function detach():void
		{
			//Log.out( "AnimationAttachment.detach owner: " + _owner.toString() + "   attachment: " + _voxelModel.toString() );
			if ( null != _voxelModel && null != _owner )
				_owner.childRemove( _voxelModel );
		}
		
		private function onAttachmentCreated( event:ModelEvent ):void
		{
			//Log.out( "AnimationAttachment.onAttachmentCreated owner: " + _owner.toString() );
			if ( event.instanceGuid == instanceInfo.instanceGuid )
			{
				_voxelModel = _owner.childModelFind( event.instanceGuid );	
				// locks like this is no longer needed, not sure why not RSF
				// must be listening for it already.
//				_voxelModel = Globals.modelGet( instanceInfo.guid );
//				_owner.childAdd( _voxelModel );
				ModelEvent.removeListener( ModelEvent.CHILD_MODEL_ADDED, onAttachmentCreated );			
			}
				
		}
	}
}
