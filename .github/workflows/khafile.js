let project = new Project('Main');

//project.addAssets('./assets/**');
project.addSources('./src');

project.addLibrary('haxeui-core');
await project.addProject('Libraries/haxeui-kha');

project.addParameter("--macro haxe.macro.Compiler.include('haxe.ui', ['haxe.ui.macros'])");

resolve(project);
