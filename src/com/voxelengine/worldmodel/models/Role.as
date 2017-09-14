/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models {
import playerio.DatabaseObject;

public class Role  extends PersistenceObject {
    static public const BIGDB_TABLE_ROLES:String = "roles";

    private var _modelPublicDelete:Boolean;
    private var _modelNominate:Boolean;
    private var _modelPromote:Boolean;
    private var _modelPrivateDelete:Boolean;
    private var _modelPublicEdit:Boolean;

    public function Role( $guid:String, $dbo:DatabaseObject = null ) {
        super( $guid, BIGDB_TABLE_ROLES );

        _modelNominate = $dbo.modelNominate;
        _modelPromote = $dbo.modelPromote;

        _modelPublicDelete = $dbo.modelPublicDelete;
        _modelPrivateDelete = $dbo.modelPrivateDelete;

        _modelPublicEdit = $dbo.modelPublicEdit;

    }

    public function get modelPublicDelete():Boolean {
        return _modelPublicDelete;
    }

    public function get modelNominate():Boolean {
        return _modelNominate;
    }

    public function get modelPromote():Boolean {
        return _modelPromote;
    }

    public function get modelPrivateDelete():Boolean {
        return _modelPrivateDelete;
    }

    public function get modelPublicEdit():Boolean {
        return _modelPublicEdit;
    }
}
}
