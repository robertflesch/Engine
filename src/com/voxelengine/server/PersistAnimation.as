package com.voxelengine.server 
{
	import com.voxelengine.events.AnimationLoadedEvent;
	import com.voxelengine.events.AnimationMetadataEvent;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.worldmodel.animation.Animation;
	import flash.utils.ByteArray;
	
	import playerio.BigDB;
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	public class PersistAnimation extends Persistance
	{
		static public const DB_TABLE_ANIMATIONS:String = "animations";
		
		static public function addEvents():void {
			Globals.g_app.addEventListener( AnimationMetadataEvent.ANIMATION_INFO_COLLECTED, animationCreate ); 
		}

		static public function animationCreate( e:AnimationMetadataEvent):void {
			var anim:Animation = new Animation();
			anim.createBlank();
			anim.guid = e.guid;
			anim.desc = e.description;
			anim.name =  e.name;
			anim.ownerGuid =  e.owner;
			anim.world = "VoxelVerse";
			//anim.databaseObject = dbo;
			//anim.model = dbo.model;  // Parent model - OWNER?
			anim.created = new Date();
			anim.modified = new Date();
			anim.save();
		}

		
		static public function loadAnims( $userName:String ):void {
			
			loadRange( PersistAnimation.DB_TABLE_ANIMATIONS
						 , "owner"
						 , [$userName]
						 , null
						 , null
						 , 100
						, loadAnimationSuccessHandler
						, function (e:PlayerIOError):void {  Log.out( "PersistAnimation.errorHandler - e: " + e ); } );
		}
		
		static private function loadAnimationSuccessHandler( dba:Array ):void {
			
			trace( "PersistAnimation.loadAnimationSuccessHandler - Anims loaded: " + dba.length );
			for each ( var dbo:DatabaseObject in dba )
			{
				loadAnimFromDBO( dbo );
			}
		}
		
		static private function loadAnimFromDBO( dbo:DatabaseObject ):void
		{
			var anim:Animation = new Animation();
//			anim.admin = cvsToVector( dbo.admin );
//			anim.editors = cvsToVector( dbo.editors );
			anim.guid = dbo.key;
			anim.databaseObject = dbo;
			anim.desc = dbo.description;
			anim.name =  dbo.name;
			anim.ownerGuid =  dbo.owner;
			anim.world = dbo.world;
			//anim.model = dbo.model;  // Parent model
			anim.created = dbo.created;
			anim.modified = dbo.modified;
			var $ba:ByteArray = dbo.data as ByteArray;
			
//			Log.out( "PersistAnimation.loadFromDBO - AnimJson: " + anim.name + "  owner: " + newAnim.owner );
			
			$ba.uncompress();
			$ba.position = 0;
			// how many bytes is the animationInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var animJson:String = $ba.readUTFBytes( strLen );
			//AnimJson = decodeURI(AnimJson);
			anim.initJSON( animJson );
			
			// Now that we have a fully formed Anim, inform the Anim manager
			Globals.g_app.dispatchEvent( new AnimationLoadedEvent( AnimationLoadedEvent.ANIMATION_CREATED, anim ) );
		}

		static public function saveAnim( $metadata:Object, $dbo:DatabaseObject, $createSuccess:Function ):void {
		}
		
		// comma seperated variables
		static private function cvsToVector( value:String ):Vector.<String> {
			var v:Vector.<String> = new Vector.<String>;
			var start:int = 0;
			var end:int = value.indexOf( ",", 0 );
			while ( -1 < end ) {
				v.push( value.substring( start, end ) );
				start = end + 1;
				end = value.indexOf( ",", start );
			}
			// there is only one, or this is the last one
			if ( -1 == end && start < value.length ) {
				v.push( value.substring( start, value.length ) );
			}
			return v;
		}
	}	
}
