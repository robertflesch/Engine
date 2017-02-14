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
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.worldmodel.oxel.Oxel;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.models.makers.ModelMakerBase;
	import com.voxelengine.worldmodel.models.types.VoxelModel;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.ModelInfo;
	/**
	 * ...
	 * @author Robert Flesch
	 */
	public class CollisionPoint 
	{
		private var _name:String;
		private var _point:Vector3D 		= null;
		private var _pointScaled:Vector3D	= null;
		private var _scaled:Boolean			= true;
		private var _collided:Boolean 		= false;
		private var _oxel:Oxel 				= null;
		private var _instanceGuid:String	= null;
		private var _vm:VoxelModel			= null;
		
		public function CollisionPoint( $name:String, $point:Vector3D, $scaled:Boolean = true )
		{
			_name = $name;
			_point = $point;
			_scaled = $scaled;
			_pointScaled = point.clone();
		}
		
		public function markerAdd( $owner:VoxelModel ):void {
			
			var collisionPointMarker:InstanceInfo 	= new InstanceInfo();
			collisionPointMarker.modelGuid			= "1MeterRedBlock";
			instanceGuid = collisionPointMarker.instanceGuid		= Globals.getUID();
			collisionPointMarker.scale 				= new Vector3D( 1/16, 1/16, 1/16 );
			collisionPointMarker.positionSet 		= point;
			collisionPointMarker.controllingModel 	= $owner;
			//collisionPointMarker.name				= "CollisionPoint";
			ModelMakerBase.load( collisionPointMarker );
		}
		
		public function markerRemove( $owner:VoxelModel ):void {
			
			$owner.modelInfo.childRemove( _vm.instanceInfo );
			_vm = null;
			_instanceGuid = null;
		}
		
		public function toString():String 
		{
			return "CollisionPoint name: " + _name + "  point: " + _point;
		}
		
		public function get point():Vector3D 
		{
			return _point;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function scale( $scale:Number ):void 
		{
			_pointScaled.z = _point.z - $scale;
			if ( null != _instanceGuid )
			{
				if ( null == _vm )
				{
					_vm = Region.currentRegion.modelCache.instanceGet( _instanceGuid );
					if ( !_vm )
						return; // not ready yet.
				}
				_vm.instanceInfo.positionSet = _pointScaled;
			}
		}
		
		public function get scaled():Boolean 
		{
			return _scaled;
		}
		
		public function get collided():Boolean 
		{
			return _collided;
		}
		
		public function set collided(value:Boolean):void 
		{
			_collided = value;
		}
		
		public function get oxel():Oxel 
		{
			return _oxel;
		}
		
		public function set oxel(value:Oxel):void 
		{
			_oxel = value;
		}
		
		public function get instanceGuid():String 
		{
			return _instanceGuid;
		}
		
		public function set instanceGuid(value:String):void 
		{
			_instanceGuid = value;
		}
		
		public function get pointScaled():Vector3D 
		{
			return _pointScaled;
		}
	}
}