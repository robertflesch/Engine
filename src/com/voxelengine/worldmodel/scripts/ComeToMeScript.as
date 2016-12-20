/**
 * Created by dev on 12/19/2016.
 */
package com.voxelengine.worldmodel.scripts {
import com.voxelengine.events.ScriptEvent;
import com.voxelengine.worldmodel.models.types.Player;

import flash.geom.Vector3D;

import com.voxelengine.Log;
import com.voxelengine.events.TransformEvent;
import com.voxelengine.worldmodel.models.ModelTransform;


public class ComeToMeScript extends Script
{
    public static const COME_TO_ME_SCRIPT:String = "ComeToMeScript";
    private var _defaultTravelTime:Number = 5;
    public function ComeToMeScript(  $params:Object ) {
        super($params);
        fromObject( $params )
    }

    override public function init():void {
//        _originalPos = vm.instanceInfo.positionGet.clone();
        addMovement();
    }

    private function addMovement():void {
        TransformEvent.addListener( TransformEvent.ENDED, transformEnded );
        // player position
        var locPlayer:Vector3D = Player.player.instanceInfo.positionGet.clone();
        vm.instanceInfo.addTransform( locPlayer.x, locPlayer.y, locPlayer.z, _defaultTravelTime, ModelTransform.POSITION_TO, COME_TO_ME_SCRIPT );
    }

    private function transformEnded( se:TransformEvent ):void {
        TransformEvent.removeListener( TransformEvent.ENDED, transformEnded );
        dispose();
        vm.dead = true;
    }

    private function reset():void {
        // have to call this before I dispose of the handle to the VM
        if ( vm ) {
            vm.instanceInfo.removeNamedTransform( ModelTransform.POSITION_TO, COME_TO_ME_SCRIPT );
        }
    }

    override public function dispose():void {
        reset();
        ScriptEvent.create( ScriptEvent.SCRIPT_EXPIRED, vm.instanceInfo.instanceGuid, COME_TO_ME_SCRIPT );
        super.dispose();
    }

    override protected function paramsObject():Object {
        return { defaultTravelTime: _defaultTravelTime };
    }

    override public function fromObject( $params:Object):void {
        if ( $params ) {
            if ($params.defaultTravelTime)
                _defaultTravelTime = $params.defaultTravelTime;

            if ( vm ) {
                reset();
                addMovement();
            }
        }
    }

    override public function paramsString():String {
        return JSON.stringify( paramsObject() );
    }

}
}