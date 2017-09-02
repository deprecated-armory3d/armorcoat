# armorcoat

![](./img/man.jpg)

Node-based material editor for PBR texture authoring. Material nodes are based on [Cycles](https://www.blender.org/features/cycles/). Used in Armory for baking complex materials down into single PBR texture set. Written in Haxe and Kha.

## Download

Get the pre-packaged [binaries](https://github.com/armory3d/armorcoat/releases). Alternatively, you can compile and run from sources.

## Run

```
git clone https://github.com/armory3d/armorcoat
cd armorcoat/build/krom
```

Windows
```
./run_windows.bat
```

Linux
```
./run_linux.sh
```

MacOS
```
./run_macos.sh
```

## Build

[Node](https://nodejs.org) and [Git](https://git-scm.com) required.

1. Recursive clone

```
git clone --recursive https://github.com/armory3d/armorcoat
cd armorcoat
git submodule foreach --recursive git pull origin master
git pull origin master
```

2. a) Compile Krom
```
node Kha/make krom
```

2. b) Compile C++
```
node Kha/make --compile
```

*Note: To edit data files(contained in .blend file), [Armory SDK](http://armory3d.org/download.html) is required. This will be resolved soon.*

## Tech

- [Armory](https://github.com/armory3d/armory)
- [Iron](https://github.com/armory3d/iron)
- [Kha](https://github.com/Kode/Kha)
- [Krom](https://github.com/Kode/Krom)
- [Haxe](https://github.com/HaxeFoundation/haxe)
