/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.events {
import com.voxelengine.worldmodel.models.InstanceInfo;

import flash.events.Event;
import flash.events.EventDispatcher;

public class InstanceInfoEvent extends ModelBaseEvent {

    private var _ii:InstanceInfo;
    private var _modelGuid:String;
    private var _instanceGuid:String;

    public function get instanceInfo():InstanceInfo { return _ii; }
    public function get modelGuid():String { return _modelGuid; }
    public function get instanceGuid():String { return _instanceGuid; }

    public override function clone():Event { return new InstanceInfoEvent( type, _instanceGuid, _modelGuid, _ii ); }
    public override function toString():String { return formatToString("InstanceInfoEvent", "instanceGuid", "modelGuid", "instanceInfo" ); }

    public function InstanceInfoEvent( $type:String, $instanceGuid, $modelGuid, $ii ) {
        super( $type, 0 );
        _instanceGuid = $instanceGuid;
        _modelGuid = $modelGuid;
        _ii = $ii;
    }

    ///////////////// Event handler interface /////////////////////////////

    // Used to distribute all persistence messages
    static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
        _eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
    }

    static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
        _eventDispatcher.removeEventListener( $type, $listener, $useCapture );
    }

    static public function create( $type:String, $instanceGuid:String, $modelGuid:String, $modelMetadata:InstanceInfo = null ) : Boolean {
        return _eventDispatcher.dispatchEvent( new InstanceInfoEvent( $type, $instanceGuid, $modelGuid, $modelMetadata ) );
    }
    ///////////////// Event handler interface /////////////////////////////
}
}
