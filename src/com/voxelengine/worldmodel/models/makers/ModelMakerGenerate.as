/*==============================================================================
   Copyright 2011-2017 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models.makers
{

import com.voxelengine.Log;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelInfo;

/**
	 * ...
	 * @author Robert Flesch - RSF
	 * This class is used to generate the modelInfo and the modelMetadata
	 * The class is different then all the other makers which depend on local or persistent object
	 * it then removes its listeners, which should cause it be to be garbage collected.
	 * Might I need to add a timeout on this object in case if never completes.
	 */
public class ModelMakerGenerate extends ModelMakerBase {
	private var _creationInfo:Object;
	private var _name:String;
	private var _type:int;
	private var _doNotPersist:Boolean;

	public function ModelMakerGenerate( $ii:InstanceInfo, $miJson:Object, $doNotPersist:Boolean = false, $addToRegionWhenComplete:Boolean = true ) {
		super($ii);
		_name = $miJson.name;
		_type = $miJson.biomes.layers[0].type;
		_creationInfo = $miJson;
		_doNotPersist = $doNotPersist;
        //Log.out("ModelMakerGenerate construct - instanceGuid: " + ii.instanceGuid + "  model guid: " + ii.modelGuid + "  using generation script: " + $miJson.biomes.layers[0].functionName, Log.WARN);
		addToRegionWhenComplete = $addToRegionWhenComplete;
		retrieveOrGenerateModelInfo();
	}

	private function retrieveOrGenerateModelInfo():void {
		// So there is a chance that this model already exists, as in the case for the DefaultPlayer
		// Check to see if this modelInfo already exists.
		ModelInfoEvent.addListener( ModelBaseEvent.EXISTS, modelInfoExists );
		ModelInfoEvent.addListener( ModelBaseEvent.EXISTS_FAILED, modelInfoDoesNotExists );
		ModelInfoEvent.create( ModelBaseEvent.EXISTS_REQUEST, 0, ii.modelGuid, null );

	}

    private function modelInfoExists( $e:ModelInfoEvent ):void {
        if ( $e.modelGuid != ii.modelGuid )
            return;
        removeModelInfoEventHandler();
        _modelInfo = $e.modelInfo;
        _modelInfo.doNotPersist = _doNotPersist;
    }

    private function modelInfoDoesNotExists( $e:ModelInfoEvent ):void {
        if ( $e.modelGuid != ii.modelGuid )
            return;
        removeModelInfoEventHandler();
        _modelInfo = new ModelInfo( ii.modelGuid, null, _creationInfo );
        _modelInfo.init();
        _modelInfo.doNotPersist = _doNotPersist;
        var name:String;
        if ( _type && 0 == _name.length )
            name = _name + TypeInfo.name( _type ) + "-" + _name;
        else
            name = TypeInfo.name( _type ) + _name;
        // Bypass the setter so that we don't set it to changed
        modelInfo.setGeneratedData( name, Network.userId );
        attemptMake();
    }

    private function removeModelInfoEventHandler():void {
        ModelInfoEvent.removeListener( ModelBaseEvent.EXISTS, modelInfoExists );
        ModelInfoEvent.removeListener( ModelBaseEvent.EXISTS_FAILED, modelInfoDoesNotExists );
    }

	// once they both have been retrieved, we can make the object
	override protected function attemptMake():void {
		//Log.out( "ModelMakerGenerate.attemptMake " + ii.modelGuid );
		if ( null != _modelInfo ) {
			_vm = make();
			if ( _vm ) {
				addODEListeners();
				OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, modelInfo.guid, null, true, true, _creationInfo );
			}
			else {
				Log.out( "ModelMakerGenerate.attemptMake FAILED to generate from " + _name, Log.WARN );
				markComplete( false );
			}
		}
	}
	
	override protected function markComplete( $success:Boolean ):void {
		// do this last as it nulls everything.
		//Log.out( "ModelMakerGenerate.markComplete " + ii.modelGuid );
		if ( $success ){
			// Everything worked, add these to the caches and save them

//			if ( modelInfo.guid != Player.DEFAULT_PLAYER ) {
				modelInfo.oxelPersistence.doNotPersist = _doNotPersist;
				if ( !_doNotPersist ) {
					modelInfo.changed = true;
					_vm.save();
					modelInfo.oxelPersistence.changed = true;
					modelInfo.oxelPersistence.save();
				}
//			}
			ModelInfoEvent.create( ModelBaseEvent.GENERATION, 0, _modelInfo.guid, _modelInfo );
		} else {
			Log.out( "ModelMakerGenerate.markComplete FAILURE - guid: " + modelInfo.guid, Log.WARN );
			ModelInfoEvent.create( ModelBaseEvent.DELETE, 0, ii.modelGuid, null );
		}

		super.markComplete( $success );
		_name = null;
		_creationInfo = null;
	}

}
}