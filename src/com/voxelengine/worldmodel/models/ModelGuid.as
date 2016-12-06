/**
 * Created by dev on 12/6/2016.
 */
package com.voxelengine.worldmodel.models {
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;

// This class is to make the process of keeping model guids in sync with possibly changing values
// Changes are seen most often in importing models, but also in cloning.
public class ModelGuid {
    private var _guid:String = "INVALID";

    public function get val():String { return _guid; }
    public function set valSet( $newVal:String ):void { _guid = $newVal; }

    public function ModelGuid() {
        ModelInfoEvent.addListener( ModelBaseEvent.UPDATE_GUID, updateGuid )
    }

    private function updateGuid( $ode:ModelInfoEvent ):void {
        var guidArray:Array = $ode.modelGuid.split( ":" );
        var oldGuid:String = guidArray[0];
        if ( oldGuid != _guid )
                return;
        var newGuid:String = guidArray[1];
        _guid = newGuid;
    }

    public function release():void {
        ModelInfoEvent.removeListener( ModelBaseEvent.UPDATE_GUID, updateGuid );
    }
}
}
