/**
 * Created by TheBeast on 11/4/2017.
 */
package com.voxelengine.worldmodel.models {
import com.voxelengine.Log;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.server.Network;

import org.flashapi.swing.Alert;

// This class is very similar to the maker class
public class AssignModelAndChildrenToPublicOwnership {

    private static const RESULT_UNDETERMINED:String = "RESULT_UNDETERMINED";
    private static const RESULT_FAILURE:String = "RESULT_FAILURE";
    private static const RESULT_SUCCESS:String = "RESULT_SUCCESS";
    private var _guid:String;
    private var _taskResult:String = RESULT_UNDETERMINED;
    private var _mi:ModelInfo;
    // This hold a list of guids and the result for that guid
    private var _resultObject:Object = {};
    // The guid and result of all objects in the hierarchy
    private static var _s_resultAllObjects:Object = {};
    private var _topLevel:Boolean;
    public function AssignModelAndChildrenToPublicOwnership( $guid:String, $topLevel:Boolean = false ) {
        _guid = $guid;
        _topLevel = $topLevel;
        _s_resultAllObjects[_guid] = RESULT_UNDETERMINED;
        requestModelInfo();
    }

    private function requestModelInfo():void {
        //Log.out( "ModelMakerBase.retrieveBaseInfo - _ii.modelGuid: " + _ii.modelGuid );
        addMIEListeners();
        ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _guid, null );

        function retrievedModelInfo($mie:ModelInfoEvent):void  {
            if (_guid == $mie.modelGuid ) {
                removeMIEListeners();
                _mi = $mie.modelInfo;
                attemptReassignment();
            }
        }

        function failedModelInfo( $mie:ModelInfoEvent):void  {
            if ( _guid == $mie.modelGuid ) {
                removeMIEListeners();
                Log.out("AssignModelAndChildrenToPublicOwnership.failedModelInfo - guid: " + _guid + " didn't find modelInfo when trying to assign to public", Log.ERROR);
                taskStatus( RESULT_FAILURE );
            }
        }

        function addMIEListeners():void {
            ModelInfoEvent.addListener( ModelBaseEvent.ADDED, retrievedModelInfo );
            ModelInfoEvent.addListener( ModelBaseEvent.RESULT, retrievedModelInfo );
            ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );
        }

        function removeMIEListeners():void {
            ModelInfoEvent.removeListener( ModelBaseEvent.ADDED, retrievedModelInfo );
            ModelInfoEvent.removeListener( ModelBaseEvent.RESULT, retrievedModelInfo );
            ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, failedModelInfo );
        }
    }

    public function attemptReassignment():void {
        // If we have the data, check ownership
        if ( _mi ) {
            if (  _mi.owner == Network.userId || _mi.owner == Network.PUBLIC ) {
                ModelInfoEvent.addListener(ModelInfoEvent.REASSIGN_FAILED, modelReassignmentResult);
                ModelInfoEvent.addListener(ModelInfoEvent.REASSIGN_SUCCEED, modelReassignmentResult);
                var children:Object = _mi.childrenGet();
                if (children) {
                    var ol:int = objectLength( children );
                    if (0 < ol ) {
                        for (var i:int = 0; i < ol; i++) {
                            var oi:Object = children[i];
                            var childGuid:String = oi.modelGuid;
                            _resultObject[childGuid] = RESULT_UNDETERMINED;
                            new AssignModelAndChildrenToPublicOwnership(childGuid);
                        }
                    }
                }
            } else {
                // I don't have rights to assign this object to public
                _taskResult = RESULT_FAILURE;
                taskStatus( false );
            }

            taskStatus( true );
        }
    }

    private function objectLength($o:Object):int {
        var cnt:int=0;
        for (var s:String in $o) cnt++;
        return cnt;
    }

    private function taskStatus( $result:Boolean ):void {
        switch ( _taskResult ) {
            case RESULT_UNDETERMINED:
                if (false == $result) {
                    // something failed, set status to failure and wait on other to compete
                    _taskResult = RESULT_FAILURE;
                    return;
                } else {
                    _s_resultAllObjects[_guid] = ModelInfoEvent.REASSIGN_SUCCEED;
                    // it worked, send result and null members
                }
                break;
            case RESULT_FAILURE:
                _s_resultAllObjects[_guid] = ModelInfoEvent.REASSIGN_FAILED;
                // both failed, sent result
                break;
        }
        finalCheck();
    }

    private function modelReassignmentResult( $mmd:ModelInfoEvent ):void {
        // this might be our guid, or childs guid, or some other branches child guid
        var guid:String = $mmd.modelGuid;

        // is this us?
        var childCount:int = objectLength(_resultObject);
        if (_guid != guid) {
            // is this a child object?
            if (0 < childCount ) {
                // is it one of our children's guid?
                if (_resultObject[guid]) {
                    _resultObject[guid] = $mmd.type;
                } else {
                    // not us, not one of our direct descendants
                    return;
                }
            }
        }

        finalCheck();
    }

    private function finalCheck():void {

        // now check if all the children's results are in, if not, just wait
        var finalResult:Boolean = true;
        for each ( var result:String in _resultObject ){
            // if there are results yet to be determined, hold off until all have completed
            if ( result == RESULT_UNDETERMINED ){
                return;
            } else if ( result == ModelInfoEvent.REASSIGN_FAILED ) {
                finalResult = false;
            }
        }

        // all child models have been resolved
        ModelInfoEvent.removeListener(ModelInfoEvent.REASSIGN_SUCCEED, modelReassignmentResult);
        ModelInfoEvent.removeListener(ModelInfoEvent.REASSIGN_FAILED, modelReassignmentResult);

        // if we get here, then all children have been reassigned
        if ( finalResult ) {
            ModelInfoEvent.create( ModelInfoEvent.REASSIGN_SUCCEED, 0, _guid );
        } else {
            ModelInfoEvent.create( ModelInfoEvent.REASSIGN_FAILED, 0, _guid );
        }


        // if this is the top of the hierarchy
        // and everything succeeded or failed, if success we can change owningModel to public
        if ( _topLevel ) {
            if ( finalResult ){
                // This reassigns all object in hierarchy and saves them
                for ( var i:String in _s_resultAllObjects ){
                    // Do I need to be able to specify PUBLIC OR STORE HERE?
                    ModelInfoEvent.create( ModelInfoEvent.REASSIGN_PUBLIC, 0, i );
                }
            } else {
                // nothings been changed at this point, so if anything fails we are ok
                (new Alert( "One or more children belong to another user, unable to complete assignment to public" )).display();
            }
        }
    }
}
}
