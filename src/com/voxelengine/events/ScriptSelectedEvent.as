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
public class ScriptSelectedEvent extends Event
{
    static public const SCRIPT_SELECTED:String	= "SCRIPT_SELECTED";

    private var _scriptName:String          = "";

    public function ScriptSelectedEvent( $type:String, $scriptName:String, $bubbles:Boolean = true, $cancellable:Boolean = false )
    {
        super( $type, $bubbles, $cancellable );
        _scriptName = $scriptName;
    }

    public override function clone():Event
    {
        return new ScriptSelectedEvent(type, _scriptName, bubbles, cancelable);
    }

    public override function toString():String
    {
        return formatToString("ScriptSelectedEvent", "scriptName" );
    }

    ///////////////// Event handler interface /////////////////////////////

    static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

    static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
        _eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
    }

    static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
        _eventDispatcher.removeEventListener( $type, $listener, $useCapture );
    }

    static private function dispatch( $event:ScriptSelectedEvent ) : Boolean {
        return _eventDispatcher.dispatchEvent( $event );
    }

    static public  function create( $type:String, $scriptName:String ):Boolean {
        return ScriptSelectedEvent.dispatch( new ScriptSelectedEvent( $type, $scriptName ) );
    }


    ///////////////// Event handler interface /////////////////////////////

    public function get scriptName():String {
        return _scriptName;
    }
}
}

