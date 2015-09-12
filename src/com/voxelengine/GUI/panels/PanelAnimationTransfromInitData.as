
package com.voxelengine.GUI.panels {

import flash.geom.Vector3D
	
import org.flashapi.swing.*
import org.flashapi.swing.event.*
import org.flashapi.swing.constants.*
import org.flashapi.swing.plaf.spas.SpasUI

import com.voxelengine.GUI.components.ComponentVector3DSideLabel
import com.voxelengine.GUI.panels.ExpandableBox

import com.voxelengine.worldmodel.animation.AnimationTransform
import com.voxelengine.worldmodel.animation.Animation
import com.voxelengine.worldmodel.models.types.VoxelModel

public class PanelAnimationTransfromInitData extends ExpandableBox
{
	private var _at:AnimationTransform
	private var _ani:Animation
	public function PanelAnimationTransfromInitData( $ebco:ExpandableBoxConfigObject ) {		
		_at  = $ebco.item
		_ani = $ebco.rootObject
		$ebco.itemBox.showNew = false
		$ebco.itemBox.paddingTop = 2
		super( $ebco )
	}
	
	override public function deleteElementCheck( $me:UIMouseEvent ):void {
		(new Alert( "Delete element check ", 350 )).display()
	}
	
	override public function resetElementCheck( $me:UIMouseEvent ):void  { 
		_at.hasPosition = false
		_at.hasRotation = false
		_at.hasScale = false
		collapse()
	}
	
	override public function collapasedInfo():String  {
		var outString:String = ""
		if ( _at.hasPosition )
			outString += formatVec3DToSummary( "pos:", _at.position )
		if ( _at.hasRotation )
			outString += formatVec3DToSummary( "rot:", _at.rotation )
		if ( _at.hasScale )
			outString += formatVec3DToSummary( "scl:", _at.scale )
		if ( outString == "" ) {
			outString = "No changes to initial settings"
			_ebco.itemBox.showReset = false
		}
		else
			_ebco.itemBox.showReset = true
		
			
		return outString
	}
	
	private function formatVec3DToSummary( $title:String, $vec:Object ):String {
		return $title + "x:" + $vec.x + " y:" + $vec.y + " z:" + $vec.z + " "
	}

	override public function newItemHandler( $me:UIMouseEvent ):void  {
		(new Alert( "newItemHandler", 350 )).display()
	}
	
	override protected function hasElements():Boolean {
		//if ( 0 < _ebco.item.delta.length ) 
			return true
		 
		return false
	}
	
	private function modelGet():VoxelModel {
		if ( VoxelModel.selectedModel ) {
			var parentVM:VoxelModel = VoxelModel.selectedModel.topmostControllingModel()
			if ( parentVM ) 
				return parentVM.childFindByName( _ebco.item.name )
		}
		return null	
	}
	
	override protected function expand():void {
		super.expand()
	
		var vm:VoxelModel = modelGet()
		if ( vm ) {
			if ( !_at.hasPosition )
				_at.position.copyFrom( vm.instanceInfo.positionGetOriginal() )
			if ( !_at.hasRotation )
				_at.rotation.copyFrom( vm.instanceInfo.rotationGetOriginal() )
			if ( !_at.hasScale )
				_at.scale.copyFrom( vm.instanceInfo.scaleGetOriginal() )
		}
		
		_itemBox.addElement( new ComponentVector3DSideLabel( function ():void { _ani.changed = true; _at.hasPosition = true }
		                                                   , "location", "X: ", "Y: ", "Z: ",  _at.position, _itemBox.width ) )
		_itemBox.addElement( new ComponentVector3DSideLabel( function ():void { _ani.changed = true; _at.hasRotation = true }
		                                                   , "rotation", "X: ", "Y: ", "Z: ",  _at.rotation, _itemBox.width ) )
		_itemBox.addElement( new ComponentVector3DSideLabel( function ():void { _ani.changed = true; _at.hasScale = true }
		                                                   , "scale", "X: ", "Y: ", "Z: ",  _at.scale, _itemBox.width ) )
	}
}
}

