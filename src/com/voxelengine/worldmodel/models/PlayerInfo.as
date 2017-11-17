/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models {
import playerio.DatabaseObject;

import com.voxelengine.worldmodel.models.types.Player;

public class PlayerInfo extends PersistenceObject {

    public function get modelGuid():String { return dbo.modelGuid }
    public function set modelGuid( $val:String ):void { dbo.modelGuid = $val; changed = true; }

    public function get regionGuid():String { return dbo.regionGuid }
    public function set regionGuid( $val:String ):void { dbo.regionGuid = $val; changed = true; }

    public function get instanceGuid():String { return dbo.instanceGuid }
    public function set instanceGuid( $val:String ):void { dbo.instanceGuid = $val; changed = true; }

    public function PlayerInfo( $instanceGuid:String, $dbo:DatabaseObject ):void  {
        super( $instanceGuid, PlayerInfoCache.BIGDB_TABLE_PLAYEROBJECTS );
        if ( null == $dbo)
            assignNewDatabaseObject();
        else {
            dbo = $dbo;
        }
        instanceGuid = $instanceGuid;
    }

    override protected function assignNewDatabaseObject():void {
        super.assignNewDatabaseObject();
        dbo.modelGuid = Player.DEFAULT_PLAYER;
    }


}
}