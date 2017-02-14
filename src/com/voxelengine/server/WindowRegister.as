/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.server
{
import com.voxelengine.renderer.Renderer;

import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	import flash.system.SecurityDomain;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;	
	
	import org.flashapi.collector.EventCollector;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import playerio.Client;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;
	import playerio.PlayerIORegistrationError;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.VVPopup;
	
	public class WindowRegister extends VVPopup
	{
		private const LI_WIDTH:int = 160;
		private const LABEL_WIDTH:int = 112;
		private const CAPTCHA_WIDTH:int = 160;
		private const CAPTCHA_HEIGHT:int = 64;
		
		private var _userName:String = "";
		private var _email:String = "";
		private var _password:String = "";
		private var _password2:String = "";
		private var _captcha:Image;
		private var _captchaText:String = "";
		private var _captchaKey:String = "";
		private var _errorText:TextArea;
		private var _passwordInput:TextInput
		private var _passwordInput2:TextInput
		private var _unInput:TextInput
		private var _eInput:TextInput
		
		private var _refresh:Bitmap;
		[Embed(source='../../../../embed/textures/refresh.png')]
		//[Embed(source='../../../../../Resources/bin/assets/textures/refresh.png')]
		private var _refreshImageTest:Class;
		
		private var _retrievingCaptcha:Bitmap;
		[Embed(source='../../../../embed/textures/retrievingCaptcha.jpg')]
		//[Embed(source='../../../../../Resources/bin/assets/textures/retrievingCaptcha.jpg')]
		private var _retrievingCaptchaImage:Class;
				
		
		public function WindowRegister()
		{
			super( "Register" );
			showCloseButton = false;
			padding = 5;
			width = 280;
			height = 320;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			_refresh = (new _refreshImageTest() as Bitmap);
			_retrievingCaptcha = (new _retrievingCaptchaImage() as Bitmap);

			var unc:Container = new Container( width, 30 );
			{
				var un:Label = new Label( "User Name: ", LABEL_WIDTH );
				un.textAlign = TextAlign.RIGHT;
				unc.addElement( un );
				_unInput = new TextInput( _userName );
				_unInput.tabIndex = 0;
				_unInput.width = LI_WIDTH;
				_unInput.addEventListener( TextEvent.EDITED, 
											function( $event:TextEvent ):void 
											{ _userName = $event.target.text; } );
				unc.addElement( _unInput );
			}
			addElement( unc );

			var ec:Container = new Container( width, 30 );
			{
				var em:Label = new Label( "Email: ", LABEL_WIDTH );
				em.textAlign = TextAlign.RIGHT;
				ec.addElement( em );
				_eInput = new TextInput( _email );
				_eInput.tabIndex = 1;
				_eInput.width = LI_WIDTH;
				_eInput.addEventListener( TextEvent.EDITED, 
											function( $event:TextEvent ):void 
											{ _email = $event.target.text; } );
				ec.addElement( _eInput );
			}
			addElement( ec );
			
			var pwc1:Container = new Container( width, 30 );
			{
				var pw:Label = new Label( "Password: ", LABEL_WIDTH );
				pw.textAlign = TextAlign.RIGHT;
				pwc1.addElement( pw );
				_passwordInput = new TextInput( _password );
				_passwordInput.width = LI_WIDTH;
				_passwordInput.tabIndex = 3;
				_passwordInput.password = true;
				_passwordInput.addEventListener( TextEvent.EDITED, 
												function( $event:TextEvent ):void 
												{ _password = $event.target.text; } );
				pwc1.addElement( _passwordInput );
			}
			addElement( pwc1 );
			
			var pwc2:Container = new Container( width, 30 );
			{
				var cp:Label = new Label( "Confirm Password: ", LABEL_WIDTH );
				cp.textAlign = TextAlign.RIGHT;
				pwc2.addElement( cp );
				_password2 = "";
				_passwordInput2 = new TextInput( _password2 );
				_passwordInput2.width = LI_WIDTH;
				_passwordInput2.password = true;
				_passwordInput2.tabIndex = 3;
				_passwordInput2.addEventListener( TextEvent.EDITED, 
												function( $event:TextEvent ):void 
												{ _password2 = $event.target.text; } );
				pwc2.addElement( _passwordInput2 );
			}
			addElement( pwc2 );
			
			_errorText = new TextArea( 240, 40);
			_errorText.backgroundColor = 0xC0C0C0;
			_errorText.scrollPolicy = ScrollPolicy.NONE;
			_errorText.fontColor = 0xff0000;
			_errorText.tabEnabled = false;
			_errorText.editable = false;
			//_errorText.text = "Test Message"
			
			defaultCloseOperation = ClosableProperties.DO_NOTHING_ON_CLOSE;
			//$evtColl.addEvent( this, WindowEvent.CLOSE_BUTTON_CLICKED, cancel );
			eventCollector.addEvent( this, WindowEvent.CLOSE_BUTTON_CLICKED, cancel );
			Globals.g_app.stage.addEventListener( Event.RESIZE, onResize);
			
			// have to enenable the captcha in playerio in quick connect
			//captchaLoad();
			Log.out( "WindowRegister - BYPASSING CAPTCHA until fixed by PlayerIO", Log.WARN );
			bypassCaptcha();
			
			display( Renderer.renderer.width / 2 - (((width + 10) / 2) + x ), Renderer.renderer.height / 2 - (((height + 10) / 2) + y) );
		}
		
		private function cancel( e:WindowEvent ):void {
			
			new WindowLogin( _email, _password );
			remove();
		}
		
		private function captchaLoad():void {
			addElement( new Image( _retrievingCaptcha, 270, 108, true ) ); // element 5
			PlayerIO.quickConnect.simpleGetCaptcha( Globals.GAME_ID, CAPTCHA_WIDTH, CAPTCHA_HEIGHT, captchaReceive, captchaFailure );
		}
		
		private var _ci:Container
		private function captchaReceive( $captchaKey:String, $captchaImageUrl:String):void
		{
			_captchaKey = $captchaKey
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCaptchaLoadComplete );
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onCaptchaLoadError );
			
			// This allows the jpg to be loaded from the playerIO site. Which is cross domain.
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.applicationDomain = ApplicationDomain.currentDomain;
			loaderContext.securityDomain = SecurityDomain.currentDomain; // Sets the security 
		
			loader.load(new URLRequest( $captchaImageUrl ),loaderContext);
			
			removeElementAt( 4 );
			
			function onCaptchaLoadComplete ($event:Event):void 
			{
				_ci = new Container( width, 30 );
				{
					_ci.layout.orientation = LayoutOrientation.HORIZONTAL;
					//ci.padding = 10;
					_ci.addElement( new Spacer( 30, CAPTCHA_HEIGHT ) );
					var refreshButton:Image = new Image( _refresh, CAPTCHA_HEIGHT, CAPTCHA_HEIGHT, true );
					refreshButton.addEventListener( UIMouseEvent.CLICK, captchaReload );
					_ci.addElement( refreshButton );
					
					_ci.addElement( new Spacer( 15, 10 ) );
					
					var textureBitmap:Bitmap = Bitmap(LoaderInfo($event.target).content);// .bitmapData;
					_captcha = new Image( textureBitmap, CAPTCHA_WIDTH, CAPTCHA_HEIGHT, true );
					_ci.addElement( _captcha );
				}
				addElement( _ci );
				
				addElement( new Spacer( width, 10 ) );
				
				var c:Container = new Container( width, 30 );
				{
					var cl:Label = new Label( "Captcha: ", LABEL_WIDTH );
					cl.textAlign = TextAlign.RIGHT;
					c.addElement( cl );
					var captchaText:TextInput = new TextInput( _captchaText  );
					captchaText..width = LI_WIDTH;
					captchaText.addEventListener( TextEvent.EDITED, 
												   function( $event:TextEvent ):void 
												   { _captchaText = $event.target.text; } );
					c.addElement( captchaText );
				}
				addElement( c );
				
				addElement( _errorText );
				
				var createAccountButton:Button = new Button( "Create Account", 265, 40 );
				createAccountButton.addEventListener(UIMouseEvent.CLICK, createAccountButtonHandler );
				addElement( createAccountButton );

				var backButton:Button = new Button( "Back", 265, 40 );
				backButton.addEventListener(UIMouseEvent.CLICK, backButtonHandler );
				addElement( backButton );
			}
							
			function onCaptchaLoadError( $error:IOErrorEvent):void {
				Log.out("WindowRegister.onCaptchaLoadError: " + $error.formatToString, Log.ERROR );
			}		
		}
		
		private function bypassCaptcha():void {
			addElement( _errorText );
			var createAccountButton:Button = new Button( "Create Account", 265, 40 );
				createAccountButton.addEventListener(UIMouseEvent.CLICK, createAccountButtonHandlerNoCaptcha );
				addElement( createAccountButton );

			var backButton:Button = new Button( "Back", 265, 40 );
			backButton.addEventListener(UIMouseEvent.CLICK, backButtonHandler );
			addElement( backButton );
		}
		
		private function captchaReReceive( $captchaKey:String, $captchaImageUrl:String):void
		{
			_captchaKey = $captchaKey;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCaptchaReLoadComplete );
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onCaptchaReLoadError );
			loader.load(new URLRequest( $captchaImageUrl ));
			
							
			function onCaptchaReLoadError( $error:IOErrorEvent):void {
				Log.out("WindowRegister.onCaptchaReLoadError: " + $error.formatToString, Log.ERROR );
			}		
		}		

		private function onCaptchaReLoadComplete( $event:Event ):void {
			_ci.removeElementAt( 2 );
			var textureBitmap:Bitmap = Bitmap(LoaderInfo($event.target).content);// .bitmapData;
			_ci.addElementAt( new Image( textureBitmap, CAPTCHA_WIDTH, CAPTCHA_HEIGHT, true ), 2 )
		}
		
		private function captchaFailure( $error:PlayerIOError):void {
			Log.out("WindowRegister.captchaFailure: " + $error.message, Log.ERROR, $error );
		}		
		
		private function captchaReload($event:UIMouseEvent):void {
			PlayerIO.quickConnect.simpleGetCaptcha( Globals.GAME_ID, CAPTCHA_WIDTH, CAPTCHA_HEIGHT, captchaReReceive, captchaFailure );

		}		
		
		private function createAccountButtonHandlerNoCaptcha( $event:UIMouseEvent):void {
			_passwordInput.glow = false;
			_passwordInput2.glow = false;
			_eInput.glow = false;
			_unInput.glow = false;
			_errorText.text = "";
			
			if ( 5 > _unInput.text.length ) {
				var pwe:PlayerIORegistrationError = new PlayerIORegistrationError( "Username length error: ", 1, null, "Username must be 5 characters or longer", null, null );
				registrationError( pwe );
				return;
				
			} else if ( _password != _password2 ) {
				var pwe1:PlayerIORegistrationError = new PlayerIORegistrationError( "Password error: ", 1, null, "Passwords don't match", null, null );
				registrationError( pwe1 );
				return;
			}
			
			Log.out( "userName: " + _userName + "  password: " + _password + "  email:" + _email, Log.DEBUG );
			PlayerIO.quickConnect.simpleRegister(
									Globals.g_app.stage,
									Globals.GAME_ID,
									_userName,
									_password,
									_email,
									null,  // the captcha key from the simpleGetCaptcha() method
									null, // the captcha text entered by the user
									null, 	// Extra data attached to the user on creation
									"", 	// String that identifies a possible affiliate partner.
									registrationSuccess,
									registrationError
								);
		}
		
		private function createAccountButtonHandler( $event:UIMouseEvent):void {
			_passwordInput.glow = false;
			_passwordInput2.glow = false;
			_eInput.glow = false;
			_unInput.glow = false;
			_errorText.text = "";
			
			if ( 5 > _unInput.text.length ) {
				var pwe:PlayerIORegistrationError = new PlayerIORegistrationError( "Username length error: ", 1, "Username must be 5 characters or longer", null, null, null );
				registrationError( pwe );
				return;
				
			} else if ( _password != _password2 ) {
				var pwe1:PlayerIORegistrationError = new PlayerIORegistrationError( "Password error: ", 1, null, "Passwords don't match", null, null );
				registrationError( pwe1 );
				return;
			}
			
			Log.out( "userName: " + _userName + "  password: " + _password + "  email:" + _email, Log.DEBUG );
			PlayerIO.quickConnect.simpleRegister(
									Globals.g_app.stage,
									Globals.GAME_ID,
									_userName,
									_password,
									_email,
									_captchaKey,  // the captcha key from the simpleGetCaptcha() method
									_captchaText, // the captcha text entered by the user
									null, 	// Extra data attached to the user on creation
									"", 	// String that identifies a possible affiliate partner.
									registrationSuccess,
									registrationError
								);
		}
		
		private function registrationError(e:PlayerIORegistrationError):void
		{
			if ( e.captchaError )
				_errorText.text = "Captcha Error, please retry: " + e.captchaError;
			else if ( e.emailError ) {
				_errorText.text = "Email Error: " + e.emailError;
				_eInput.glow = true;
			}
			else if ( e.passwordError ) {
				_errorText.text = "Password Error: " + e.passwordError;
				_passwordInput.glow = true;
				_passwordInput2.glow = true;
			}
			else if ( e.usernameError ) {
				_errorText.text = "User Name Error: " + e.usernameError;
				_unInput.glow = true;
			}
			else {
				_errorText.text = "Unknown Error in simpleRegister: " + e.message;
				Log.out( "WindowRegistration.registrationError Unknown Registration Error in simpleRegister: " + e.message, Log.ERROR, e);
			}
		}
			
		private function registrationSuccess(client:Client):void 
		{ 
			Log.out("WindowRegistration.registrationSuccess - simpleRegister succeed");
			new WindowLogin( _email, _password );
			remove();
		}

		private function backButtonHandler( $event:UIMouseEvent ):void {
			new WindowLogin( "", "" );
			remove();
		}

	}
}