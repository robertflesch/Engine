/**
 * Created by dev on 12/9/2016.
 */
package com.voxelengine.events
{
import flash.events.Event;
import flash.events.EventDispatcher;
import com.voxelengine.worldmodel.models.types.VoxelModel;

/**
 * ...
 * @author Robert Flesch - RSF
 */
public class ScriptEvent extends Event
{
    static public const SCRIPT_SELECTED:String	= "SCRIPT_SELECTED";
    static public const SCRIPT_EXPIRED:String	= "SCRIPT_EXPIRED";

    private var _name:String;
    private var _guid:String;

    public function ScriptEvent($type:String, $guid:String = "", $name:String = "", $bubbles:Boolean = true, $cancellable:Boolean = false ) {
        super( $type, $bubbles, $cancellable );
        _guid = $guid;
        _name = $name;
    }

    public override function clone():Event {
        return new ScriptEvent(type, _guid, _name, bubbles, cancelable);
    }

    public override function toString():String {
        return formatToString("ScriptEvent", "scriptName", "guid", "name" );
    }

    ///////////////// Event handler interface /////////////////////////////

    static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
        _eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
    }

    static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
        _eventDispatcher.removeEventListener( $type, $listener, $useCapture );
    }

    static private function dispatch( $event:ScriptEvent ) : Boolean {
        return _eventDispatcher.dispatchEvent( $event );
    }

    static public  function create( $type:String, $guid:String = "", $name:String = "" ):Boolean {
        return ScriptEvent.dispatch( new ScriptEvent( $type, $guid, $name ) );
    }


    ///////////////// Event handler interface /////////////////////////////

    public function get guid():String {
        return _guid;
    }
    public function get name():String {
        return _name;
    }
}
}

