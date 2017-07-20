/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.events {
import com.voxelengine.worldmodel.models.types.VoxelModel;

public class ObjectHierarchyData {
    private var _modelGuid:String;
    private var _instanceGuid:String;
    private var _parentModelGuid:String;
    private var _parentInstanceGuid:String;
    private var _rootModelGuid:String;
    private var _rootInstanceGuid:String;

    public function get modelGuid():String { return _modelGuid; }
    public function get instanceGuid():String { return _instanceGuid; }
    public function get parentModelGuid():String { return _parentModelGuid; }
    public function get parentInstanceGuid():String { return _parentInstanceGuid; }
    public function get rootModelGuid():String { return _rootModelGuid; }
    public function get rootInstnaceGuid():String { return _rootInstanceGuid; }

    public function ObjectHierarchyData() {}

    public function fromGuids(  $modelGuid:String
                            , $instanceGuid:String
                            , $parentModelGuid:String = null
                            , $parentInstanceGuid:String = null
                            , $rootModelGuid:String = null
                            , $rootInstanceGuid:String = null ):void {
        _modelGuid          = $modelGuid;
        _instanceGuid       = $instanceGuid;
        _parentModelGuid    = $parentModelGuid;
        _parentInstanceGuid = $parentInstanceGuid;
        _rootModelGuid      = $rootModelGuid;
        _rootInstanceGuid   = $rootInstanceGuid;
    }

    public function fromModel( $vm:VoxelModel ):void {
        _modelGuid = $vm.instanceInfo.modelGuid;
        _instanceGuid = $vm.instanceInfo.instanceGuid;
        if ( $vm.instanceInfo.controllingModel ) {
            _parentModelGuid = $vm.instanceInfo.controllingModel.instanceInfo.modelGuid;
            _parentInstanceGuid = $vm.instanceInfo.controllingModel.instanceInfo.instanceGuid;

            var tmvm:VoxelModel = $vm.instanceInfo.controllingModel.topmostControllingModel();
            if ( tmvm ) {
                _rootModelGuid = tmvm.instanceInfo.modelGuid;
                _rootInstanceGuid = tmvm.instanceInfo.instanceGuid;
            }
        }
    }

    public function toString():String {
        var returnString:String = "modelGuid :" + _modelGuid + "  instanceGuid " + _instanceGuid;
        if ( _parentModelGuid )
            returnString += "  parentModelGuid: " + _parentModelGuid;
        if ( _parentInstanceGuid )
            returnString += "  parentInstanceGuid: " + _parentInstanceGuid;
        if ( _rootModelGuid )
            returnString += "  rootModelGuid: " + _rootModelGuid;
        if ( _rootInstanceGuid )
            returnString += "  _rootInstanceGuid: " + _rootInstanceGuid;

        return returnString;
    }
}
}
