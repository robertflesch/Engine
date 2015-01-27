
package com.voxelengine.server
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
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
		private const LABEL_WIDTH:int = 80;
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
		[Embed(source='../../../../../Resources/bin/assets/textures/refresh.png')]
		private var _refreshImageTest:Class;
		
		private var _retrievingCaptcha:Bitmap;
		[Embed(source='../../../../../Resources/bin/assets/textures/retrievingCaptcha.jpg')]
		private var _retrievingCaptchaImage:Class;
				
		
		public function WindowRegister()
		{
			super( "Register" );
			padding = 15;
			width = 280;
			height = 340;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			_refresh = (new _refreshImageTest() as Bitmap);
			_retrievingCaptcha = (new _retrievingCaptchaImage() as Bitmap);

			var unc:Container = new Container( width, 30 );
			{
				unc.addElement( new Label( "User Name", LABEL_WIDTH ) );
				_unInput = new TextInput( _userName );
				_unInput.width = LI_WIDTH;
				_unInput.addEventListener( TextEvent.EDITED, 
											function( $event:TextEvent ):void 
											{ _userName = $event.target.text; } );
				unc.addElement( _unInput );
			}
			addElement( unc );

			var ec:Container = new Container( width, 30 );
			{
				ec.addElement( new Label( "Email", LABEL_WIDTH ) );
				_eInput = new TextInput( _email );
				_eInput.width = LI_WIDTH;
				_eInput.addEventListener( TextEvent.EDITED, 
											function( $event:TextEvent ):void 
											{ _email = $event.target.text; } );
				ec.addElement( _eInput );
			}
			addElement( ec );
			
			var pwc1:Container = new Container( width, 30 );
			{
				pwc1.addElement( new Label( "Password", LABEL_WIDTH ) );
				_passwordInput = new TextInput( _password );
				_passwordInput.width = LI_WIDTH;
				_passwordInput.password = true;
				_passwordInput.addEventListener( TextEvent.EDITED, 
												function( $event:TextEvent ):void 
												{ _password = $event.target.text; } );
				pwc1.addElement( _passwordInput );
			}
			addElement( pwc1 );
			
			var pwc2:Container = new Container( width, 30 );
			{
				pwc2.addElement( new Label( "Password", LABEL_WIDTH ) );
				_password2 = "";
				_passwordInput2 = new TextInput( _password2 );
				_passwordInput2.width = LI_WIDTH;
				_passwordInput2.password = true;
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
			//_errorText.text = "Test Message"
			
			defaultCloseOperation = ClosableProperties.DO_NOTHING_ON_CLOSE;
			//$evtColl.addEvent( this, WindowEvent.CLOSE_BUTTON_CLICKED, cancel );
			eventCollector.addEvent( this, WindowEvent.CLOSE_BUTTON_CLICKED, cancel );
			Globals.g_app.stage.addEventListener( Event.RESIZE, onResize);
			
			captchaLoad();
			
			display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
		}
		
		private function cancel( e:WindowEvent ):void {
			
			new WindowLogin( _email, _password );
			remove();
		}
		
		private function captchaLoad():void {
			addElement( new Image( _retrievingCaptcha, 270, 108, true ) ); // element 5
			PlayerIO.quickConnect.simpleGetCaptcha( Globals.g_gamesNetworkID, CAPTCHA_WIDTH, CAPTCHA_HEIGHT, captchaReceive, captchaFailure );
		}
		
		private var _ci:Container
		private function captchaReceive( $captchaKey:String, $captchaImageUrl:String):void
		{
			_captchaKey = $captchaKey
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCaptchaLoadComplete );
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onCaptchaLoadError );
			loader.load(new URLRequest( $captchaImageUrl ));
			
			removeElementAt( 4 );
			
			function onCaptchaLoadComplete ($event:Event):void 
			{
				_ci = new Container( width, 30 );
				{
					_ci.layout.orientation = LayoutOrientation.HORIZONTAL;
					//ci.padding = 10;

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
					c.addElement( new Label( "Captcha", LABEL_WIDTH ) );
					var captchaText:TextInput = new TextInput( _captchaText  );
					captchaText..width = LI_WIDTH;
					captchaText.addEventListener( TextEvent.EDITED, 
												   function( $event:TextEvent ):void 
												   { _captchaText = $event.target.text; } );
					c.addElement( captchaText );
				}
				addElement( c );
				
				addElement( _errorText );
				
				var createAccountButton:Button = new Button( "Create Account", 240, 40 );
				createAccountButton.addEventListener(UIMouseEvent.CLICK, createAccountButtonHandler );
				addElement( createAccountButton );
			}
							
			function onCaptchaLoadError( $error:IOErrorEvent):void {
				Log.out("WindowRegister.onCaptchaLoadError: " + $error.formatToString, Log.ERROR );
			}		
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
			PlayerIO.quickConnect.simpleGetCaptcha( Globals.g_gamesNetworkID, CAPTCHA_WIDTH, CAPTCHA_HEIGHT, captchaReReceive, captchaFailure );

		}		
		
		private function createAccountButtonHandler( $event:UIMouseEvent):void {
			_passwordInput.glow = false;
			_passwordInput2.glow = false;
			_eInput.glow = false;
			_unInput.glow = false;
			_errorText.text = "";
			
			if ( _password != _password2 ) {
				var pwe:PlayerIORegistrationError = new PlayerIORegistrationError( "Password error: ", 1, null, "Passwords don't match", null, null );
				registrationError( pwe );
				return;
			}
			
			Log.out( "userName: " + _userName + "  password: " + _password + "  email:" + _email, Log.DEBUG );
			PlayerIO.quickConnect.simpleRegister(
									Globals.g_app.stage,
									Globals.g_gamesNetworkID,
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
				_errorText.text = "Unknown Error in simpleResister: " + e.message;
				Log.out( "WindowRegistration.registrationError Unknow Registrion Error in simpleResister: " + e.message, Log.ERROR, e);
			}
		}
			
		private function registrationSuccess(client:Client):void 
		{ 
			Log.out("WindowRegistration.registrationSuccess - simpleRegister succeed");
			new WindowLogin( _email, _password );
			remove();
		}
	}
}