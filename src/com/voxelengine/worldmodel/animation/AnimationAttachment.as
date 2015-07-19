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
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	
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
			_instanceInfo.fromObject( $json );
		}

		public function buildExportObject( obj:Object ):void {			
			obj.fileName 		= _fileName;
			obj.attachsTo 		= _attachsTo;
			obj.location		= _instanceInfo.positionGet;
			obj.rotation		= _instanceInfo.rotationGet;
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
				ModelMakerBase.load( _instanceInfo );
			}
			else
			{
				//Log.out( "AnimationAttachment.create owner: " + $owner.toString() + "   attachment: " + _voxelModel.toString() );
				$owner.modelInfo.childAdd( _voxelModel );
			}
		}
		
		public function detach():void
		{
			//Log.out( "AnimationAttachment.detach owner: " + _owner.toString() + "   attachment: " + _voxelModel.toString() );
			if ( null != _voxelModel && null != _owner )
				_owner.modelInfo.childRemove( _voxelModel.instanceInfo );
		}
		
		private function onAttachmentCreated( event:ModelEvent ):void
		{
			//Log.out( "AnimationAttachment.onAttachmentCreated owner: " + _owner.toString() );
			if ( event.instanceGuid == instanceInfo.instanceGuid )
			{
				_voxelModel = _owner.modelInfo.childModelFind( event.instanceGuid );	
				// locks like this is no longer needed, not sure why not RSF
				// must be listening for it already.
//				_voxelModel = Region.currentRegion.modelCache.instanceGet( instanceInfo.guid );
//				_owner.childAdd( _voxelModel );
				ModelEvent.removeListener( ModelEvent.CHILD_MODEL_ADDED, onAttachmentCreated );			
			}
				
		}
	}
}
