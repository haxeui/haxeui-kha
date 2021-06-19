![build status](https://github.com/haxeui/haxeui-kha/actions/workflows/build.yml/badge.svg)

# haxeui-kha

This is the [Kha](https://github.com/Kode/Kha) backend for [HaxeUI](https://github.com/haxeui/haxeui-core)

![](https://github.com/haxeui/haxeui-kha/raw/master/.github/images/screen.png)

## Installation

- `haxeui-kha` has a dependency to <a href="https://github.com/haxeui/haxeui-core">`haxeui-core`</a>, and so that too must be installed
- `haxeui-kha` also has a dependency to [Kha](https://github.com/Kode/Kha), please refer to the installation instructions on their [site](https://kha.tech/getstarted)

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
* <a href="http://haxeui.org/explorer/">component-explorer</a> - Browse HaxeUI components
* <a href="http://haxeui.org/builder/">playground</a> - Write and test HaxeUI layouts in your browser
* <a href="https://github.com/haxeui/component-examples">component-examples</a> - Various componet examples
* <a href="http://haxeui.org/api/haxe/ui/">haxeui-api</a> - The HaxeUI api docs.
* <a href="https://github.com/haxeui/haxeui-guides">haxeui-guides</a> - Set of guides to working with HaxeUI and backends.

