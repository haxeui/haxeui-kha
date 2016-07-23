<p align="center">
  <img src="https://dl.dropboxusercontent.com/u/26678671/haxeui2-warning.png"/>
</p>

[![Build Status](https://travis-ci.org/haxeui/haxeui-kha.svg?branch=master)](https://travis-ci.org/haxeui/haxeui-kha)
[![Support this project on Patreon](https://dl.dropboxusercontent.com/u/26678671/patreon_button.png)](https://www.patreon.com/kha)

<h2>haxeui-kha</h2>
`haxeui-kha` is the `Kha` backend for HaxeUI.

**_Important Note: currently in the alpha release of `haxeui-kha` only the `Kha` HTML5 renderer is supported, using different renderer will most likely cause compilation errors._**

<h2>Installation</h2>
 * `haxeui-kha` has a dependency to <a href="https://github.com/haxeui/haxeui-core">`haxeui-core`</a>, and so that too must be installed.
 * `haxeui-kha` also has a dependency to <a href="https://github.com/KTXSoftware/Kha">Kha</a>, please refer to the installation instructions on their <a href="https://github.com/KTXSoftware/Kha">site</a>.

Eventually all these libs will become haxelibs, however, currently in their alpha form they do not even contain a `haxelib.json` file (for dependencies, etc) and therefore can only be used by downloading the source and using the `haxelib dev` command or by directly using the git versions using the `haxelib git` command (recommended). Eg:

```
haxelib git haxeui-core https://github.com/haxeui/haxeui-core
haxelib dev haxeui-kha path/to/expanded/source/archive
```

<h2>Usage</h2>
The simplest method to create a new `Kha` application that is HaxeUI ready is to use one of the <a href="https://github.com/haxeui/haxeui-templates">haxeui-templates</a>. These templates will allow you to start a new project rapidly with HaxeUI support baked in. 

If however you already have an existing application, then incorporating HaxeUI into that application is straightforward:

<h2>khamake.js</h2>
Simply add the following lines to your `khamake.js` and rebuild your project files (using `haxelib run kha html5` for example):

```js
project.addLibrary('haxeui-core');
project.addLibrary('haxeui-kha');
project.addLibrary('hscript');
```

<h3>Toolkit initialisation and usage</h3>
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

<h2>Kha specifics</h2>
As well as using the generic `Screen.instance.addComponent`, it is also possible to render a component to a specific surface use the components special `renderTo` function. Eg:

```haxe
main.renderTo(...);
```

<h2>Addtional resources</h2>
* <a href="http://haxeui.github.io/haxeui-api/">haxeui-api</a> - The HaxeUI api docs.
* <a href="https://github.com/haxeui/haxeui-guides">haxeui-guides</a> - Set of guides to working with HaxeUI and backends.
* <a href="https://github.com/haxeui/haxeui-demo">haxeui-demo</a> - Demo application written using HaxeUI.
* <a href="https://github.com/haxeui/haxeui-templates">haxeui-templates</a> - Set of templates for IDE's to allow quick project creation.
* <a href="https://github.com/haxeui/haxeui-bdd">haxeui-bdd</a> - A behaviour driven development engine written specifically for HaxeUI (uses <a href="https://github.com/haxeui/haxe-bdd">haxe-bdd</a> which is a gherkin/cucumber inspired project).
* <a href="https://www.youtube.com/watch?v=L8J8qrR2VSg&feature=youtu.be">WWX2016 presentation</a> - A presentation given at WWX2016 regarding HaxeUI.

