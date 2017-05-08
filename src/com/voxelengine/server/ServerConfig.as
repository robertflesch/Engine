/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.server {
import com.voxelengine.Globals;

public class ServerConfig {
    static private var _configs:Vector.<ServerConfigObject> = new Vector.<ServerConfigObject>();
    static private var _currentConfig:ServerConfigObject;
    static private var _initialized:Boolean;

    public function ServerConfig() {
        throw new Error( "ServerConfig contructor called, this is pointless as it is a static object");
    }

    static private function initialize():void {
        var config1:ServerConfigObject = new ServerConfigObject();
        config1.name = "Production";
        config1.key = Globals.GAME_ID;
        config1.localServer = false;
        config1.gameType = "VoxelVerse";
        _configs.push( config1 );
        var config2:ServerConfigObject = new ServerConfigObject();
        config2.name = "Development";
        config2.key = Globals.GAME_ID_DEV;
        config2.localServer = true;
        config2.gameType = "VoxelVerseDev";
        _configs.push( config2 );

        configSetCurrent( config1 );
    }

    static public function configListGet():Vector.<ServerConfigObject> {
        initializedCheck();
        return _configs;
    }

    static public function configSetCurrent( $val:ServerConfigObject):void {
        initializedCheck();
        _currentConfig = $val;
    }

    static public function configGetCurrent():ServerConfigObject {
        initializedCheck();
        return _currentConfig;
    }

    static private function initializedCheck():void {
        if ( false == _initialized ){
            _initialized = true;
            initialize();
        }
    }

}
}
