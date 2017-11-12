/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under uinted States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.panels {
import com.voxelengine.GUI.components.ComponentLabel;
import com.voxelengine.GUI.components.ComponentSpacer;
import com.voxelengine.GUI.components.ComponentVector3DToObject;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.models.AssignModelAndChildrenToPublicOwnership;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.Role;
import com.voxelengine.worldmodel.models.types.Player;

import flash.events.MouseEvent;

import flash.net.URLRequest;
import flash.net.navigateToURL;

import org.flashapi.swing.Alert;

import org.flashapi.swing.Button;
import org.flashapi.swing.Container;
import org.flashapi.swing.event.UIMouseEvent;

public class PanelAdvancedModel extends ExpandableBox
{
    private var _mmd:ModelMetadata;
    private var WIDTH:int;
    public function PanelAdvancedModel( $parent:ExpandableBox, $ebco:ExpandableBoxConfigObject ) {
        _mmd = $ebco.rootObject as ModelMetadata;
        WIDTH = $ebco.itemBox.width;
        super( $parent, $ebco )
    }

    override protected function collapasedInfo():String  {
        var outString:String = "";

        outString += "owner: " + _mmd.owner + "   ";
        return outString
    }

    override protected function hasElements():Boolean { return true; }

    override protected function expand():void {
        super.expand();

        _itemBox.addElement(new ComponentSpacer(_itemBox.width, 10));
        var panel1:Container = new Container(width, 40);
        panel1.addElement(new ComponentLabel("Animation class", (_mmd.animationClass ? _mmd.animationClass : "None"), (WIDTH / 2 - 2)));
        panel1.addElement(new ComponentLabel("Format Version", String(_mmd.version), (WIDTH / 2 - 2)));
        _itemBox.addElement(panel1);

        if (_mmd.childOf) {
            _itemBox.addElement(new ComponentLabel("Child of", String(_mmd.childOf), WIDTH));
            if (null == _mmd.modelPosition)
                _mmd.modelPosition = {x: 0, y: 0, z: 0};
            if (null == _mmd.modelScaling)
                _mmd.modelScaling = {x: 1, y: 1, z: 1};
            _itemBox.addElement(new ComponentVector3DToObject(setChanged, _mmd.modelPositionInfo, "Position Relative To Parent", "X: ", "Y: ", "Z: ", _mmd.modelPositionVec3D(), WIDTH, updateVal));
            _itemBox.addElement(new ComponentVector3DToObject(setChanged, _mmd.modelScalingInfo, "Model Scaling", "X: ", "Y: ", "Z: ", _mmd.modelScalingVec3D(), WIDTH, updateVal));
        }
        //addElement( new ComponentLabel( "Created Date",  String(_mmd.createdDate), WIDTH ) );

        var panel2:Container = new Container(width, 40);
        panel2.addElement(new ComponentLabel("Owner", String(_mmd.owner), (WIDTH / 2 - 2)));
        panel2.addElement(new ComponentLabel("Creator", String(_mmd.creator), (WIDTH / 2 - 2)));
        _itemBox.addElement(panel2);

        addButtons();
    }

    private function addButtons():void {
        var role:Role = Player.player.role;
        if ( _mmd.owner != Network.PUBLIC ) {
            if (role.modelApprove) {
                var copyButton:Button = new Button("Make copy available to public", WIDTH, 24);
                copyButton.addEventListener(MouseEvent.CLICK, copyAndGiveToPublic);
                _itemBox.addElement(copyButton);
            }
//            else if (role.modelNominate) {
//                _itemBox.addElement( new ComponentSpacer( WIDTH, 10 ) );
//                var nominateButton:Button = new Button("Nominate for public use", WIDTH, 24);
//                nominateButton.addEventListener(MouseEvent.CLICK, nominateToPublic);
//                addElement(nominateButton);
//            }
//            if (role.modelPutInStore) {
//                _itemBox.addElement( new ComponentSpacer( WIDTH, 10 ) );
//                var sellButton:Button = new Button("Sell Copy in store", WIDTH, 24);
//                sellButton.addEventListener(MouseEvent.CLICK, copyAndPutInStore);
//                _itemBox.addElement(sellButton);
//            }
        }
        _itemBox.addElement( new ComponentSpacer( WIDTH ) );
    }

    private function copyAndGiveToPublic( $me:MouseEvent ):void {
        Log.out( "PopupMetadataAndModelInfo.copyAndGiveToPublic", Log.WARN);
        if ( _mmd.owner == Network.userId  && _mmd.permissions.creator == Network.userId ) {
            new AssignModelAndChildrenToPublicOwnership( _mmd.guid, true );
        }
        remove();
    }

    private function copyAndPutInStore( $me:MouseEvent ):void {
        Log.out( "PopupMetadataAndModelInfo.copyAndPutInStore is not operational", Log.ERROR);
        (new Alert("CopyAndPutInStore is not operational yet")).display( 100, 300);
//        if ( _mmd.owner  && _mmd.permissions.creator == Network.userId ){
//            // ASK IF THEY ARE SURE
//            // EVENT
//
//            // Check to make sure they own it and all of the child models permissions
//            var cancelAssignment:Boolean = false;
//            var role:Role = Player.player.role;
//            if ( role.modelNominate && role.modelPromote ) {
//                ModelInfoEvent.addListener( ModelInfoEvent.PERMISSION_FAIL, permissionFailure )
//                _mi.assignToPublic( true );
//            }
//
//            if ( cancelAssignment )
//                return;
//            else
//                _mi.assignToPublic();
//        }
//
//        function permissionFailure( $mie:ModelInfoEvent ):void {
//            cancelAssignment = true;
//        }

    }

    private function nominateToPublic( $me:MouseEvent ):void {
        Log.out( "PopupMetadataAndModelInfo.nominateToPublic is not operational", Log.ERROR);
        (new Alert("NominateToPublic is not operational yet")).display(100, 300);
    }


    override protected function setChanged():void {
    }
}
}