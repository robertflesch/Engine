
package com.voxelengine.GUI.panels {

import com.voxelengine.Log;
import flash.geom.Vector3D
	
import org.flashapi.swing.*
import org.flashapi.swing.event.*
import org.flashapi.swing.constants.*
import org.flashapi.swing.plaf.spas.SpasUI

import com.voxelengine.GUI.components.*
import com.voxelengine.GUI.panels.ExpandableBox

import com.voxelengine.worldmodel.animation.AnimationTransform
import com.voxelengine.worldmodel.animation.Animation
import com.voxelengine.worldmodel.models.types.VoxelModel

public class PanelAnimationTransfromInitData extends ExpandableBox
{
	private var _at:AnimationTransform
	private var _ani:Animation
	public function PanelAnimationTransfromInitData( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {		
		_at  = $ebco.item
		_ani = $ebco.rootObject
		$ebco.itemBox.showNew = false
		super( $parent, $ebco )
	}
	
	override protected function resetElement():void  { 
		_at.resetInitialPosition()
		changeMode()
	}
	
	override protected function collapasedInfo():String  {
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
	
	private function formatVec3DToSummaryBig( $title:String, $vec:Object ):String {
		return $title + "x:" + $vec.x + " y:" + $vec.y + " z:" + $vec.z + " "
	}

	private function formatVec3DToSummary( $title:String, $vec:Object ):String {
		return $title + "{" + $vec.x + ":" + $vec.y + ":" + $vec.z + "} "
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
		
		_itemBox.addElement( new ComponentSpacer( _itemBox.width, 4 ) );
		_itemBox.addElement( new ComponentVector3DSideLabel( markChangedPos
		                                                   , "location", "X: ", "Y: ", "Z: ",  _at.position, _itemBox.width ) )
		_itemBox.addElement( new ComponentVector3DSideLabel( markChangedRot
		                                                   , "rotation", "X: ", "Y: ", "Z: ",  _at.rotation, _itemBox.width ) )
		_itemBox.addElement( new ComponentVector3DSideLabel( markChangedScale
		                                                   , "scale", "X: ", "Y: ", "Z: ",  _at.scale, _itemBox.width ) )
	}
	private function markChangedPos():void { 
		Log.out( "markChangedPos: " + _at.position )
		setChanged()
		_at.hasPosition = true 
	}
	
	private function markChangedRot():void { 
		Log.out( "markChangedRot: " + _at.rotation )
		setChanged()
		_at.hasRotation = true 
	}
	
	private function markChangedScale():void { 
		Log.out( "markChangedPos: " + _at.scale )
		setChanged()
		_at.hasScale = true 
	}
	
	override protected function setChanged():void {
		_ani.changed = true
	}
	
}
}

