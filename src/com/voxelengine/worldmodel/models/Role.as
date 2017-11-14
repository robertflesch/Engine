/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models {
import com.voxelengine.server.Network;

import playerio.DatabaseObject;

public class Role  extends PersistenceObject {
    static public const BIGDB_TABLE_ROLES:String = "roles";
    static public const USER:String = "User";
    static public const ADMIN:String = "Admin";

    public function get modelPrivateDelete():Boolean { return dbo.modelPrivateDelete ? dbo.modelPrivateDelete : false; }
    public function get modelNominate():Boolean { return dbo.modelNominate ? dbo.modelNominate : false; }
    public function get modelApprove():Boolean { return dbo.modelApprove ? dbo.modelApprove : false; }
    public function get modelPublicEdit():Boolean { return dbo.modelPublicEdit ? dbo.modelPublicEdit : false; }
    public function get modelPublicDelete():Boolean { return dbo.modelPublicDelete ? dbo.modelPublicDelete : false; }
    public function get modelPutInStore():Boolean { return dbo.modelPutInStore ? dbo.modelPutInStore : false; }
    public function get modelStoreEdit():Boolean { return dbo.modelStoreEdit ? dbo.modelStoreEdit : false; }
    public function get modelStoreDelete():Boolean { return dbo.modelStoreDelete ? dbo.modelStoreDelete : false; }
    public function get modelPutInAttic():Boolean { return dbo.modelPutInAttic ? dbo.modelPutInAttic : false; }
    public function get modelGetFromAttic():Boolean { return dbo.modelGetFromAttic ? dbo.modelGetFromAttic : false; }
    public function get name():String { return dbo.name ? dbo.name : "Unknown Role"; }

    static private var _s_defaultRole:Role = null;
    static public function get defaultRole() :Role {
        if ( !_s_defaultRole )
            _s_defaultRole = new Role( Network.LOCAL, new DatabaseObject( BIGDB_TABLE_ROLES, "0", "0", 0, true, null) );
        return _s_defaultRole;
    }

    public function Role( $guid:String, $dbo:DatabaseObject = null ) {
        super( $guid, BIGDB_TABLE_ROLES );
        dbo = $dbo;
    }

    // This table is read only
    override public function save( $validateGuid:Boolean = true ):Boolean {
            return false;
    }




}
}
