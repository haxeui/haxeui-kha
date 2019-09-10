package haxe.ui.backend.kha;

class FileSystem {

    public static var dataPath = "";
    public static var curDir:String = "";
    public static var sep ="/";
	static var lastPath:String = "";
    static function initPath(systemId: String) {
		switch (systemId){
			case "Windows":
				return "C:\\Users";
			case "Linux":
				return "$HOME";
			default:
				return "/";
		}
		// %HOMEDRIVE% + %HomePath%
		// ~
	}
	static function fixPath(path:String,systemId:String){
		if (path == "") path = initPath(systemId);
		switch (systemId){
			case "Windows":
				return path;
			case "Linux":
				if(path.charAt(0) == "~"){
					var temp = path.split('~');
					temp[0]="$HOME";
					path = temp.join("");
				}
				return path;
			default:
				return path;
		}
	}
    
    static public function getFiles(path:String, folderOnly =false){

        #if kha_krom

		var cmd = "ls -F";
		var systemId = kha.System.systemId;
		if (systemId == "Windows") {
			cmd = "dir /b ";
			if (folderOnly) cmd += "/ad ";
			sep = "\\";
			path = StringTools.replace(path, "\\\\", "\\");
			path = StringTools.replace(path, "\r", "");
		}
		path = fixPath(path,systemId);

		var save = Krom.getFilesLocation() + sep + dataPath + "dir.txt";
		if (path != lastPath) Krom.sysCommand(cmd + '"' + path + '"' + ' > ' + '"' + save + '"');
		lastPath = path;
		var str = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
		var files = str.split("\n");
		trace(files);
		#elseif kha_kore

		path = fixPath(path,systemId);
		if(StringTools.contains(path,"$HOME")){
			var home = new sys.io.Process("echo",["$HOME"]).stdout.readAll().toString();
			path = StringTools.replace(path,"$HOME",home);
		}
		var files = sys.FileSystem.isDirectory(path) ? sys.FileSystem.readDirectory(path) : [];

		#elseif kha_webgl

		var files:Array<String> = [];

		var userAgent = untyped navigator.userAgent.toLowerCase();
		if (userAgent.indexOf(' electron/') > -1) {
			var pp = untyped window.process.platform;
			var systemId = pp == "win32" ? "Windows" : (pp == "darwin" ? "OSX" : "Linux");
			try {
				path = fixPath(path,systemId);
				if(StringTools.contains(path,"$HOME")){
					var home = untyped process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE;
					path = StringTools.replace(path,"$HOME",home);
				}
				files = untyped require('fs').readdirSync(path);
			}
			catch(e:Dynamic) {
				// Non-directory item selected
			}
		}

		#else

		var files:Array<String> = [];

		#end
        curDir = path;
        return files;
    }
}