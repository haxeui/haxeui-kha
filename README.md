<p align="center">
  <img src="http://haxeui.org/db/haxeui2-warning.png"/>
</p>

[![Build Status](https://travis-ci.org/haxeui/haxeui-kha.svg?branch=master)](https://travis-ci.org/haxeui/haxeui-kha)
[![Support this project on Patreon](http://haxeui.org/db/patreon_button.png)](https://www.patreon.com/haxeui)

# haxeui-kha
`haxeui-kha` is the `Kha` backend for HaxeUI.

<p align="center">
	<img src="https://github.com/haxeui/haxeui-kha/raw/master/screen.png" />
</p>

## Installation
 * `haxeui-kha` has a dependency to <a href="https://github.com/haxeui/haxeui-core">`haxeui-core`</a>, and so that too must be installed.
 * `haxeui-kha` also has a dependency to <a href="https://github.com/KTXSoftware/Kha">Kha</a>, please refer to the installation instructions on their <a href="https://github.com/KTXSoftware/Kha">site</a>.

Eventually all these libs will become haxelibs, however, currently in their alpha form they do not even contain a `haxelib.json` file (for dependencies, etc) and therefore can only be used by downloading the source and using the `haxelib dev` command or by directly using the git versions using the `haxelib git` command (recommended). Eg:

```
haxelib git haxeui-core https://github.com/haxeui/haxeui-core
haxelib dev haxeui-kha path/to/expanded/source/archive
```

## Usage
The simplest method to create a new `Kha` application that is HaxeUI ready is to use one of the <a href="https://github.com/haxeui/haxeui-templates">haxeui-templates</a>. These templates will allow you to start a new project rapidly with HaxeUI support baked in. 

If however you already have an existing application, then incorporating HaxeUI into that application is straightforward:

## khamake.js
Simply add the following lines to your `khamake.js` and rebuild your project files (using `haxelib run kha html5` for example):

```js
project.addLibrary('haxeui-core');
project.addLibrary('haxeui-kha');
project.addLibrary('hscript');
```

### Toolkit initialisation and usage
The `Kha` system itself must be initialised and a render loop started. This can be done by using code similar to:

```haxe
public function new() {
    Assets.loadEverything(onAssetsLoaded);
}

function onAssetsLoaded() {
    Toolkit.init();
    System.notifyOnRender(render);
}

function render(framebuffer:Framebuffer): Void {		
    var g = framebuffer.g2;
    g.begin(true, 0xFFFFFF);
    Screen.instance.renderTo(g);
    g.end();
}
```

Once the toolkit is initialised you can add components using the methods specified <a href="https://github.com/haxeui/haxeui-core#adding-components-using-haxe-code">here</a>.

## Kha specifics
As well as using the generic `Screen.instance.addComponent`, it is also possible to render a component to a specific surface use the components special `renderTo` function. Eg:

```haxe
main.renderTo(...);
```

## Addtional resources
* <a href="http://haxeui.github.io/haxeui-api/">haxeui-api</a> - The HaxeUI api docs.
* <a href="https://github.com/haxeui/haxeui-guides">haxeui-guides</a> - Set of guides to working with HaxeUI and backends.
* <a href="https://github.com/haxeui/haxeui-demo">haxeui-demo</a> - Demo application written using HaxeUI.
* <a href="https://github.com/haxeui/haxeui-templates">haxeui-templates</a> - Set of templates for IDE's to allow quick project creation.
* <a href="https://github.com/haxeui/haxeui-bdd">haxeui-bdd</a> - A behaviour driven development engine written specifically for HaxeUI (uses <a href="https://github.com/haxeui/haxe-bdd">haxe-bdd</a> which is a gherkin/cucumber inspired project).
* <a href="https://www.youtube.com/watch?v=L8J8qrR2VSg&feature=youtu.be">WWX2016 presentation</a> - A presentation given at WWX2016 regarding HaxeUI.

