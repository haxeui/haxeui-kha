# haxeui-kha [![Build Status](https://travis-ci.org/haxeui/haxeui-kha.svg?branch=master)](https://travis-ci.org/haxeui/haxeui-kha)

This is the [Kha](https://github.com/Kode/Kha) backend for [HaxeUI](https://github.com/haxeui/haxeui-core)

![](https://github.com/haxeui/haxeui-kha/raw/master/screen.png)

## Support further development

[![Support this project on Patreon](https://c5.patreon.com/external/logo/become_a_patron_button.png)](https://www.patreon.com/haxeui)

## Installation

- `haxeui-kha` has a dependency to <a href="https://github.com/haxeui/haxeui-core">`haxeui-core`</a>, and so that too must be installed
- `haxeui-kha` also has a dependency to [Kha](https://github.com/Kode/Kha), please refer to the installation instructions on their [site](https://kha.tech/getstarted)

Eventually all these libs will become haxelibs, however, currently in their alpha form they do not even contain a `haxelib.json` file (for dependencies, etc) and therefore can only be used by using the git versions. Eg:

```
mkdir Libraries
cd Libraries
git clone https://github.com/haxeui/haxeui-core.git
git clone https://github.com/haxeui/haxeui-kha.git
git clone https://github.com/haxefoundation/hscript.git
```

Or even better, add them as git submodules for proper versioning!

## Usage

The simplest method to create a new `Kha` application that is HaxeUI ready is to use one of the [haxeui-templates](https://github.com/haxeui/haxeui-templates). These templates will allow you to start a new project rapidly with HaxeUI support baked in.

If however you already have an existing application, then incorporating HaxeUI into that application is straightforward.

## khamake.js

Simply add the following lines to your `khamake.js` and rebuild your project files:

```js
project.addLibrary('haxeui-core');
project.addLibrary('haxeui-kha');
project.addLibrary('hscript');
```

### Toolkit initialisation and usage

The `Kha` system itself must be initialised and a render loop started. This can be done by using code similar to:

```haxe
class Main {
    public static function main() {
        kha.System.start({}, function ( _ ) {
            kha.Assets.loadEverything(function() {
                haxe.ui.Toolkit.init();

                final screen = haxe.ui.core.Screen.instance;
                final ui = haxe.ui.macros.ComponentMacros.buildComponent("ui.xml");

                screen.addComponent(ui);

                kha.System.notifyOnFrames(function( framebuffers: Array<kha.Framebuffer> ) {
                    final fb = framebuffers[0];
                    final g2 = fb.g2;
                    g2.begin(true, kha.Color.White);
                        screen.renderTo(g2);
                    g2.end();
                });
            });
        });
    }
}
```

Once the toolkit is initialised you can add components using the methods specified [here](https://github.com/haxeui/haxeui-core#adding-components-using-haxe-code).

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
