package haxe.ui.backend.kha.macros;

#if macro
import sys.FileSystem;
import sys.io.File;
#end

class ResourceMacros {
    macro public static function buildFileList(path:String) {
        var list:Array<String> = new Array<String>();
        listAllFiles(path, list);

        var config:Dynamic = { };
        config.files = new Array<Dynamic>();

        for (item in list) {
            var relativePath = StringTools.replace(item, path, "");
            if (StringTools.startsWith(relativePath, "/")) {
                relativePath = relativePath.substr(1, relativePath.length);
            }

            var arr:Array<String> = relativePath.split(".");
            arr.pop();
            var resourceName:String = arr.join("_");
            resourceName = StringTools.replace(resourceName, "/", "_");
            resourceName = StringTools.replace(resourceName, " ", "_");
            resourceName = StringTools.replace(resourceName, "-", "_");

            if (StringTools.endsWith(relativePath, ".png") || StringTools.endsWith(relativePath, ".jpg")) {
                config.files.push({
                    name: resourceName,
                    type: "image",
                    files: [relativePath]
                });
            } else if (StringTools.endsWith(relativePath, ".ttf")) {
                config.files.push({
                    name: resourceName,
                    type: "font",
                    files: [relativePath]
                });
            } else if (StringTools.endsWith(relativePath, ".essl")) {
                config.files.push({
                    name: resourceName,
                    type: "shader",
                    files: [relativePath]
                });
            }

        }

        var jsonString = Json.stringify(config, null, "    ");
        //trace("\n" + jsonString);

        File.saveContent("Z:\\HaxeUI-Version2\\applications\\haxeui-demo\\bin\\kha\\html5-resources\\files.json", jsonString);

        return macro null;
    }

    #if macro
    private static function listAllFiles(path:String, list:Array<String>) {
        var contents:Array<String> = FileSystem.readDirectory(path);
        if (contents != null) {
            for (file in contents) {
                if (FileSystem.isDirectory(path + "/" + file)) {
                    listAllFiles(path + "/" + file, list);
                } else {
                    list.push(path + "/" + file);
                }
            }
        }
    }
    #end
}