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

    private var _modelPrivateDelete:Boolean;
    public function get modelPrivateDelete():Boolean { return _modelPrivateDelete; }
    private var _modelNominate:Boolean;
    public function get modelNominate():Boolean { return _modelNominate; }
    private var _modelApprove:Boolean;
    public function get modelApprove():Boolean { return _modelApprove; }
    private var _modelPublicEdit:Boolean;
    public function get modelPublicEdit():Boolean { return _modelPublicEdit; }
    private var _modelPublicDelete:Boolean;
    public function get modelPublicDelete():Boolean { return _modelPublicDelete; }
    private var _modelPutInStore:Boolean;
    public function get modelPutInStore():Boolean { return _modelPutInStore; }
    private var _modelStoreEdit:Boolean;
    public function get modelStoreEdit():Boolean { return _modelStoreEdit; }
    private var _modelStoreDelete:Boolean;
    public function get modelStoreDelete():Boolean { return _modelStoreDelete; }

    static private var _s_defaultRole:Role = null;
    static public function get defaultRole() :Role {
        if ( !_s_defaultRole )
            _s_defaultRole = new Role( Network.LOCAL, null );
        return _s_defaultRole;
    }

    public function Role( $guid:String, $dbo:DatabaseObject = null ) {
        super( $guid, BIGDB_TABLE_ROLES );

        if ( $dbo ) {
            _modelNominate = $dbo.modelNominate;
            _modelApprove = $dbo.modelApprove;

            _modelPublicDelete = $dbo.modelPublicDelete;
            _modelPrivateDelete = $dbo.modelPrivateDelete;

            _modelPublicEdit = $dbo.modelPublicEdit;
            _modelPutInStore = $dbo.modelPutInStore;
        }
    }

    // This table is read only
    override public function save( $validateGuid:Boolean = true ):Boolean {
            return false;
    }




}
}
