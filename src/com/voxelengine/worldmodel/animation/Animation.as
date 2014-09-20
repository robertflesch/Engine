/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.animation
{
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.server.Network;
	import com.voxelengine.server.Persistance;
	import com.voxelengine.server.PersistAnimation;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import playerio.DatabaseObject;
	
	import mx.utils.StringUtil;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.utils.CustomURLLoader;
	import com.voxelengine.worldmodel.models.VoxelModel;

	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 * The world model holds the active oxels
	 */
	public class Animation
	{
		// This should be a list so that it can be added to easily, this is hard coded.
		static public const MODEL_BIPEDAL_10:String = "MODEL_BIPEDAL_10";
		static public const MODEL_DRAGON_9:String =  "MODEL_DRAGON_9";
		static public const MODEL_PROPELLER:String =  "MODEL_PROPELLER";
		static public const MODEL_UNKNOWN:String =  "MODEL_UNKNOWN";
		
		static private const BLANK_ANIMATION_TEMPLATE:Object = { "animation":[] };

		static private const ANIMATION_STATE:String = "ANIMATION_STATE";
		static private const ANIMATION_ACTION:String = "ANIMATION_ACTION";
		
		private var _loaded:Boolean = false;
		private var _transforms:Vector.<AnimationTransform>;
		private var _attachments:Vector.<AnimationAttachment>;
		private var _sound:AnimationSound;
		private var _type:String;
		// For loading local files only
		public var ownerGuid:String;

		/// META DATA for DB
		public var guid:String; // File name if used locally, GUID from DB
		public var model:String = MODEL_BIPEDAL_10;  // What class of models does this apply do BIPEDAL_10, DRAGON_9, PROPELLER
		public var databaseObject:DatabaseObject;
		public var name:String;
		public var desc:String;
		public var world:String;
		//public var model:String;
		public var created:Date;
		public var modified:Date;

		public function get transforms():Vector.<AnimationTransform> { return _transforms; }
		public function get loaded():Boolean { return _loaded; }
		
		public function Animation() { ; }
		
		public function createBlank():void {
			initJSON( BLANK_ANIMATION_TEMPLATE );
		}
		
		// i.e. animData = { "name": "Glide", "guid":"Glide.ajson" }
		public function loadFromLocalFile( $animData:Object, $ownerGuid:String ):void {
			  
			ownerGuid = $ownerGuid;
			if ( $animData.name )
			{
				name = $animData.name;
			}
			else
				Log.out( "Animation.loadFromLocalFile - No animation name", Log.ERROR );	
				
			if ( $animData.guid )
			{
				guid = $animData.guid;
			}
			else
				Log.out( "Animation.loadFromLocalFile - No animation guid", Log.ERROR );	
				
			if ( $animData.type )
			{
				_type = ( "action" == $animData.type ? ANIMATION_ACTION : ANIMATION_STATE );
			}
			else
				_type = ANIMATION_STATE;

			load( name, onLoadedAction );
		}
		
		public function loadForImport( $nameAndLoc:String ):void {
			load( $nameAndLoc, onLoadForImport );
		}
		
		public function loadFromPersistance():void {
			PersistAnimation.loadAnims( Network.userId );
		}
		
		public function initJSON( $json:Object ):void 
		{
			//Log.out( "Animation.init - fileName: " + _name );
			if ( $json.sound )
			{
				_sound = new AnimationSound();
				_sound.init( $json.sound );
			}
			if ( $json.attachment )
			{
				_attachments = new Vector.<AnimationAttachment>;
				for each ( var attachmentJson:Object in $json.attachment )
				{
					_attachments.push( new AnimationAttachment( attachmentJson ) );				
				}
			}
			if ( $json.animation )
			{
				_transforms = new Vector.<AnimationTransform>;
				for each ( var transformJson:Object in $json.animation )
				{
					_transforms.push( new AnimationTransform( transformJson ) );				
				}
			}
			
			Globals.g_app.dispatchEvent( new LoadingEvent( LoadingEvent.ANIMATION_LOAD_COMPLETE, name ) );
		}
		
		/*
		public function getModelJson( outString:String ):String {
			var count:int = 0;
			//for each ( var vm:VoxelModel in _modelInstances )
			//	count++;
			var instanceData:Vector.<String> = new Vector.<String>;
				
			for each ( var instance:VoxelModel in _modelInstances )
			{
				if ( instance  )
				{
					if ( instance is Player )
						continue;
					instanceData.push( instance.getJSON() );	
				}
			}
			
			var len:int = instanceData.length;
			for ( var index:int; index < len; index++ ) {
				outString += instanceData[index];
				if ( index == len - 1 )
					continue;
				outString += ",";
			}
			return outString;
		}
		*/
	
		private function getJSON():String
		{
			var jsonString:String = "{";
			if ( _sound ) {
				jsonString += "\"sound\":";
				jsonString += _sound.getJSON();
			}
			if ( _attachments ) {
				if ( _sound )
					jsonString += ","
				jsonString += "\"attachment\":[";
				jsonString += attachmentsToJSON();
				jsonString += "]"
			}
			if ( _transforms ) {
				if ( _sound || _attachments )
					jsonString += ","
				jsonString += "\"animation\":[";
				jsonString += animationsToJSON();
				jsonString += "]"
			}

			jsonString += "}";
trace( name + " = " + jsonString );
			return jsonString;
		}

		private function animationsToJSON():String {
			var count:int = 0;
			var animations:Vector.<String> = new Vector.<String>;
			var outString:String = new String();
			
			for each ( var at:AnimationTransform in _transforms ) {
				if ( at )
					animations.push( at.getJSON() );	
			}
			
			var len:int = animations.length;
			for ( var index:int; index < len; index++ ) {
				outString += animations[index];
				if ( index == len - 1 )
					continue;
				outString += ",";
			}
			return outString;
		}

		private function attachmentsToJSON():String {
			var count:int = 0;
			var attachments:Vector.<String> = new Vector.<String>;
			var outString:String = new String();
			
			for each ( var aa:AnimationAttachment in _attachments ) {
				if ( aa  )
					attachments.push( aa.getJSON() );	
			}
			
			var len:int = attachments.length;
			for ( var index:int; index < len; index++ ) {
				outString += attachments[index];
				if ( index == len - 1 )
					continue;
				outString += ",";
			}
			return outString;
		}
	/*		
			
			
			
			var outString:String = "{\"region\":[";
			outString = _modelManager.getModelJson(outString);
			outString += "],"
			// if you dont do it this way, there is a null at begining of string
			outString += "\"skyColor\": {" + "\"r\":" + _skyColor.x  + ",\"g\":" + _skyColor.y + ",\"b\":" + _skyColor.z + "}";
			outString += ","
			outString += "\"gravity\":" + JSON.stringify(gravity);
			outString += "}"
			return outString;
		}
		*/
/*
		public function toJSON(k:*):* {
			return {
				sound: _sound.toJSON(k),
				animation: _attachments.toJSON(k)
			}
		}
*/
		public function play( $owner:VoxelModel, $val:Number ):void
		{
			//Log.out( "Animation.play - name: " + _name );
			if ( _sound )
				_sound.play( $owner, $val );
				
			if ( _attachments && 0 < _attachments.length )
			{
				for each ( var aa:AnimationAttachment in _attachments )
				{
					var cm:VoxelModel = $owner.childFindByName( aa.attachsTo );
					if ( cm )
					{
						aa.create( cm );
					}
				}
			}
		}
		
		public function stop( $owner:VoxelModel ):void
		{
			if ( _sound )
				_sound.stop();
				
			if ( _attachments && 0 < _attachments.length )
			{
				for each ( var aa:AnimationAttachment in _attachments )
				{
					var cm:VoxelModel = $owner.childFindByName( aa.attachsTo );
					if ( cm )
					{
						aa.detach();
					}
				}
			}
		}
		
		public function update( $val:Number ):void
		{
			if ( _sound )
				_sound.update( $val / 3 );
		}
		
		static private const ANIMATION_FILE_EXT:String = ".ajson"
		private function load( $fileName:String, $successAction:Function ):void
		{
			var fileName:String = $fileName + ANIMATION_FILE_EXT
			var aniNameAndLoc:String = Globals.modelPath + ownerGuid + "/" + fileName;
			//Log.out( "Animation.load - loading: " + aniNameAndLoc );
			var request:URLRequest = new URLRequest( aniNameAndLoc );
			var loader:CustomURLLoader = new CustomURLLoader(request);
			loader.addEventListener(Event.COMPLETE, $successAction );
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadErrorAction);
		}
		
		private function onLoadErrorAction(event:IOErrorEvent):void
		{
			Log.out( "Animation.onLoadErrorAction: ERROR LOADING ANIMATION: ", Log.WARN );
		}	
			
		private function onLoadForImport(event:Event):void
		{
			onLoadedAction( event );
			save();
		}

		private function onLoadFromPersistance():void
		{
			Log.out( "Animation.onLoadFromPersistance - NOT SUPPOERTED YET", Log.ERROR );
		}
		
		private function onLoadedAction(event:Event):void
		{
			_loaded = true;
			Log.out( "Animation.onLoadedAction - LOADED: " + name );
			try 
			{
				var jsonString:String = StringUtil.trim( String(event.target.data) );
				var jsonResult:Object = JSON.parse(jsonString);
			}
			catch ( error:Error )
			{
				Log.out( "Animation.onLoadedAction - ERROR PARSING: " );
			}
			
			initJSON( jsonResult );
			
			/// TEST TEST TEST ONLY
			var ba:ByteArray = new ByteArray();
			writeToByteArray( ba );
		}
		
		public function importAnimation():void {
			guid = Globals.getUID();
			save();
		}
		
		public function save():void {
			var ba:ByteArray = new ByteArray;
			writeToByteArray( ba );
			PersistAnimation.saveAnim( metadata( ba ), databaseObject, createSuccess );
			
		}
		private	function writeToByteArray( $ba:ByteArray ):void {
				var rawJSON:String = getJSON();
				var animJson:String = JSON.stringify( rawJSON );
				$ba.writeInt( animJson.length );
				$ba.writeUTFBytes( animJson );
				$ba.compress();
			}
			
		private	function metadata( $ba: ByteArray ):Object {
				Log.out( "Animation.metadata userId: " + Network.userId );
				return {
						created: created ? created : new Date(),
						data: $ba,
						description: desc ? desc : "No Description",
						model: model ? model : "No Description",
						guid: guid ? guid : Globals.getUID(),
						modified: modified ? modified : new Date(),
						name: name ? name : "No name",
						owner:  Persistance.PUBLIC,
						world: world ? world : "VoxelVerse"
						};
			}
			
		private	function createSuccess(o:DatabaseObject):void 
			{ 
				if ( o ) {
					databaseObject = o;
				}
			}
	}
}
