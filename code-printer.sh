#!/bin/bash

################################################################################
# PROFESSIONAL CODE DOCUMENTATION GENERATOR V2.0.0
################################################################################
# 
# This script generates comprehensive code documentation including directory
# structure and file contents with advanced filtering, syntax highlighting,
# and multi-profile support.
#
# Author: Luis González (ljgonzalez1)
# Version: 2.0.0
# License: MIT License
# Repository: https://github.com/ljgonzalez1/code-doc-generator
#
# USAGE:
#   ./code_doc_generator.sh [OPTIONS] [OUTPUT_DIRECTORY]
#   ./code_doc_generator.sh --profile=nodejs --profile=react
#   ./code_doc_generator.sh --exclude=node_modules --include=src --exclude="*.test.*"
#
# For complete documentation: ./code_doc_generator.sh --help
# For quick reference: ./code_doc_generator.sh --tldr
#
################################################################################

# =================== PROGRAM METADATA ===================

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="Code Documentation Generator"
readonly SCRIPT_AUTHOR="Luis González (ljgonzalez1)"
readonly SCRIPT_LICENSE="MIT License"
readonly SCRIPT_REPOSITORY="https://github.com/ljgonzalez1/code-doc-generator"

# Default configuration
DEFAULT_SOURCE_DIR=""  # Auto-detected
DEFAULT_OUTPUT_FILE="Code.txt"
DEFAULT_MAX_LINES=1500
DEFAULT_MAX_FILE_SIZE_MB=1  # 1 MiB maximum per file

# Arrays for advanced priority system
declare -a APPLIED_PROFILES=()
declare -a FILTER_RULES=()

# Required commands for advanced detection
REQUIRED_COMMANDS=("find" "wc" "head" "awk" "file" "tree")
OPTIONAL_COMMANDS=("grep" "sed" "sort" "uniq" "highlight")

# ANSI colors
readonly ANSI_RED='\033[0;31m'
readonly ANSI_GREEN='\033[0;32m'
readonly ANSI_YELLOW='\033[0;33m'
readonly ANSI_BLUE='\033[0;34m'
readonly ANSI_MAGENTA='\033[0;35m'
readonly ANSI_CYAN='\033[0;36m'
readonly ANSI_WHITE='\033[0;37m'
readonly ANSI_ORANGE='\033[0;33m'  # Using yellow as orange
readonly ANSI_BOLD='\033[1m'
readonly ANSI_RESET='\033[0m'

# Configuration variables for highlight
HIGHLIGHT_AVAILABLE=false
USE_COLOR=true
HIGHLIGHT_COMMAND=""

# Counters and statistics
declare -i TOTAL_FILES_FOUND=0
declare -i TOTAL_FILES_PROCESSED=0
declare -i TOTAL_FILES_EXCLUDED=0
declare -i TOTAL_BINARY_FILES=0
declare -i TOTAL_TEXT_FILES=0
declare -i TOTAL_LINES_PROCESSED=0
declare -i TOTAL_FILES_TOO_LARGE=0

# =================== ADVANCED PROFILES WITH INHERITANCE AND CASE-INSENSITIVE ===================

declare -A PROFILES
declare -A PROFILE_ALIASES

# ============================================
# BASE AND GENERAL PROFILES
# ============================================

# Base profile (used as foundation)
PROFILES[base]="description=Base profile with common exclusions;exclude=.git,.svn,.hg,.idea,.vscode,.vs,node_modules,dist,build,target,bin,obj,__pycache__,.pytest_cache,vendor,packages,.gradle,.mvn,cmake-build-*;exclude_files=*.log,*.tmp,*.cache,*.pid,*.lock,.DS_Store,Thumbs.db,desktop.ini,*.swp,*.swo,*~,Code.txt,show_code.sh,code_doc_generator.sh"

# General profile (for use without specifying profile)
PROFILES[general]="description=General profile for any project;extends=base;include=*.txt,*.md,*.json,*.yml,*.yaml,*.xml,*.csv,*.env*,Makefile,Dockerfile,*.conf,*.cfg,*.ini,*.toml,README*,LICENSE*,CHANGELOG*"

# ============================================
# PYTHON AND ITS FRAMEWORKS PROFILES
# ============================================

PROFILES[python]="description=General Python project;extends=base;include=*.py,*.pyx,*.pyi,*.txt,*.md,*.yml,*.yaml,*.json,*.cfg,*.ini,*.toml,requirements*.txt,setup.py,pyproject.toml,Pipfile,*.pth,*.whl;exclude=__pycache__,.pytest_cache,dist,build,.venv,venv,env,.tox,.eggs,*.egg-info,*.pyc"

# Python web frameworks
PROFILES[django]="description=Django project;auto_apply=python;extends=python;include=manage.py,settings.py,urls.py,wsgi.py,asgi.py,*.html,*.css,*.js,static/**,templates/**,migrations/**;exclude=*.sqlite3,media/**"

PROFILES[flask]="description=Flask project;auto_apply=python;extends=python;include=app.py,run.py,config.py,*.html,*.css,*.js,templates/**,static/**;exclude=instance/**"

PROFILES[fastapi]="description=FastAPI project;auto_apply=python;extends=python;include=main.py,app.py,*.py,*.json,*.yaml,openapi.json,docs/**;exclude=*.db"

PROFILES[tornado]="description=Tornado project;auto_apply=python;extends=python;include=*.py,*.html,*.css,*.js,static/**,templates/**"

PROFILES[pyramid]="description=Pyramid project;auto_apply=python;extends=python;include=*.py,*.ini,*.pt,*.html,*.css,*.js,static/**,templates/**"

# Python ML/Data Science libraries
PROFILES[tensorflow]="description=TensorFlow project;auto_apply=python;extends=python;include=*.py,*.pb,*.h5,*.hdf5,*.json,*.yaml,models/**,data/**,notebooks/**,*.ipynb;exclude=*.ckpt,logs/**"

PROFILES[pytorch]="description=PyTorch project;auto_apply=python;extends=python;include=*.py,*.pt,*.pth,*.json,*.yaml,models/**,data/**,notebooks/**,*.ipynb;exclude=checkpoints/**"

PROFILES[scikit-learn]="description=Scikit-learn project;auto_apply=python;extends=python;include=*.py,*.joblib,*.pkl,*.json,data/**,notebooks/**,*.ipynb"
PROFILE_ALIASES[scikit]="scikit-learn"
PROFILE_ALIASES[sklearn]="scikit-learn"
PROFILE_ALIASES[sk-learn]="scikit-learn"

PROFILES[numpy]="description=NumPy project;auto_apply=python;extends=python;include=*.py,*.npy,*.npz,*.json,data/**,*.ipynb"

PROFILES[pandas]="description=Pandas project;auto_apply=python;extends=python;include=*.py,*.csv,*.json,*.xlsx,*.parquet,*.feather,data/**,*.ipynb"

PROFILES[matplotlib]="description=Matplotlib project;auto_apply=python;extends=python;include=*.py,*.png,*.jpg,*.svg,*.pdf,plots/**,*.ipynb"

PROFILES[seaborn]="description=Seaborn project;auto_apply=python;extends=python;include=*.py,*.png,*.jpg,*.svg,*.pdf,plots/**,*.ipynb"

PROFILES[plotly]="description=Plotly project;auto_apply=python;extends=python;include=*.py,*.html,*.json,plots/**,*.ipynb"

# ============================================
# C++ AND ITS FRAMEWORKS PROFILES
# ============================================

PROFILES[cpp]="description=General C++ project;extends=base;include=*.cpp,*.cxx,*.cc,*.c,*.hpp,*.hxx,*.h,*.tpp,*.ipp,Makefile,*.mk,*.cmake,CMakeLists.txt,*.md;exclude=build,Debug,Release,cmake-build-*,*.o,*.a,*.so,*.dll,*.exe,*.obj"
PROFILE_ALIASES[c++]="cpp"

# C++ GUI frameworks
PROFILES[qt]="description=Qt C++ project;auto_apply=cpp;extends=cpp;include=*.pro,*.pri,*.qrc,*.ui,*.qml,*.qss,*.ts;exclude=moc_*,ui_*,qrc_*,*.moc"

PROFILES[wxwidgets]="description=wxWidgets C++ project;auto_apply=cpp;extends=cpp;include=*.xrc,*.fbp"

PROFILES[juce]="description=JUCE C++ project;auto_apply=cpp;extends=cpp;include=*.jucer,*.projucer,Source/**,JuceLibraryCode/**"

# C++ web frameworks
PROFILES[crow]="description=Crow C++ project;auto_apply=cpp;extends=cpp;include=*.cpp,*.h,static/**,templates/**"

PROFILES[pistache]="description=Pistache C++ project;auto_apply=cpp;extends=cpp;include=*.cpp,*.h,*.json"

PROFILES[cppcms]="description=CppCMS project;auto_apply=cpp;extends=cpp;include=*.cpp,*.h,*.tmpl,*.js,*.css"

PROFILES[wt]="description=Wt C++ project;auto_apply=cpp;extends=cpp;include=*.cpp,*.h,*.xml,*.css,*.js"

# C++ libraries
PROFILES[poco]="description=POCO C++ project;auto_apply=cpp;extends=cpp;include=*.cpp,*.h,*.xml,*.properties"

PROFILES[boost]="description=Boost C++ project;auto_apply=cpp;extends=cpp;include=*.cpp,*.hpp,*.h,*.jam,project-config.jam"

# Game Engines
PROFILES[unreal-engine]="description=Unreal Engine project;auto_apply=cpp;extends=cpp;include=*.uproject,*.uplugin,*.uasset,*.umap,Source/**,Content/**,Config/**,*.cs;exclude=Binaries/**,Intermediate/**"
PROFILE_ALIASES[unreal-engine3]="unreal-engine"
PROFILE_ALIASES[unreal-engine-3]="unreal-engine"
PROFILE_ALIASES[unreal-engine4]="unreal-engine"
PROFILE_ALIASES[unreal-engine-4]="unreal-engine"
PROFILE_ALIASES[unreal-engine5]="unreal-engine"
PROFILE_ALIASES[unreal-engine-5]="unreal-engine"
PROFILE_ALIASES[ue3]="unreal-engine"
PROFILE_ALIASES[ue-3]="unreal-engine"
PROFILE_ALIASES[ue4]="unreal-engine"
PROFILE_ALIASES[ue-4]="unreal-engine"
PROFILE_ALIASES[ue5]="unreal-engine"
PROFILE_ALIASES[ue-5]="unreal-engine"
PROFILE_ALIASES[ue]="unreal-engine"
PROFILE_ALIASES[unrealengine]="unreal-engine"
PROFILE_ALIASES[unrealengine3]="unreal-engine"
PROFILE_ALIASES[unrealengine-3]="unreal-engine"
PROFILE_ALIASES[unrealengine4]="unreal-engine"
PROFILE_ALIASES[unrealengine-4]="unreal-engine"
PROFILE_ALIASES[unrealengine5]="unreal-engine"
PROFILE_ALIASES[unrealengine-5]="unreal-engine"

PROFILES[tensorrt]="description=TensorRT C++ project;auto_apply=cpp;extends=cpp;include=*.cpp,*.h,*.uff,*.onnx,*.plan,*.engine"

# ============================================
# C AND ITS FRAMEWORKS PROFILES
# ============================================

PROFILES[c]="description=General C project;extends=base;include=*.c,*.h,Makefile,*.mk,*.cmake,CMakeLists.txt,*.md,*.s,*.asm;exclude=build,Debug,Release,cmake-build-*,*.o,*.a,*.so,*.dll,*.exe,*.obj"

PROFILES[gtk]="description=GTK C project;auto_apply=c;extends=c;include=*.glade,*.ui"

PROFILES[embedded]="description=Embedded C project;auto_apply=c;extends=c;include=*.ld,*.hex,*.bin,*.elf,*.map;exclude=*.o,*.elf,*.hex,*.bin,*.map"

PROFILES[kernel]="description=Kernel C project;auto_apply=c;extends=c;include=*.c,*.h,*.S,*.lds,Kconfig,Makefile*;exclude=*.o,*.ko,*.mod.c"

# ============================================
# JAVA AND ITS FRAMEWORKS PROFILES
# ============================================

PROFILES[java]="description=General Java project;extends=base;include=*.java,*.xml,*.properties,*.gradle,*.md,pom.xml,build.gradle,*.yaml,*.yml;exclude=target,.gradle,*.class,*.jar,*.war,out"

PROFILES[spring]="description=Spring Java project;auto_apply=java;extends=java;include=application*.properties,application*.yml,*.java,*.xml,src/main/resources/**"

PROFILES[spring-boot]="description=Spring Boot project;auto_apply=java;extends=java;include=application*.properties,application*.yml,*.java,*.xml,src/main/resources/**"
PROFILE_ALIASES[springboot]="spring-boot"

PROFILES[hibernate]="description=Hibernate Java project;auto_apply=java;extends=java;include=*.hbm.xml,hibernate.cfg.xml,*.java"

PROFILES[maven]="description=Maven Java project;auto_apply=java;extends=java;include=pom.xml,*.java,src/**;exclude=target/**"

PROFILES[gradle]="description=Gradle Java project;auto_apply=java;extends=java;include=build.gradle,settings.gradle,gradle.properties,*.java,src/**;exclude=build/**,.gradle/**"

PROFILES[android]="description=Android project;auto_apply=java;extends=java;include=*.java,*.kt,*.xml,*.gradle,AndroidManifest.xml,res/**,assets/**;exclude=build/**,*.apk,*.aab"

# ============================================
# C# AND ITS FRAMEWORKS PROFILES
# ============================================

PROFILES[csharp]="description=C#/.NET general project;extends=base;include=*.cs,*.csproj,*.sln,*.config,*.json,*.xml,*.md,*.yml,*.yaml,*.resx,*.settings,*.xaml;exclude=bin,obj,.vs,.idea,packages,Debug,Release,*.user,TestResults"
PROFILE_ALIASES[c#]="csharp"

PROFILES[aspnet]="description=ASP.NET project;auto_apply=csharp;extends=csharp;include=*.cs,*.cshtml,*.razor,*.css,*.js,*.json,appsettings*.json,wwwroot/**"
PROFILE_ALIASES[asp.net]="aspnet"
PROFILE_ALIASES[asp-net]="aspnet"

PROFILES[blazor]="description=Blazor project;auto_apply=csharp;extends=csharp;include=*.razor,*.cs,*.css,*.js,wwwroot/**,Pages/**,Shared/**"

PROFILES[wpf]="description=WPF project;auto_apply=csharp;extends=csharp;include=*.xaml,*.cs,*.resx,Resources/**"

PROFILES[winforms]="description=WinForms project;auto_apply=csharp;extends=csharp;include=*.cs,*.Designer.cs,*.resx,Resources/**"

PROFILES[unity]="description=Unity project;auto_apply=csharp;extends=csharp;include=*.cs,*.unity,*.prefab,*.mat,*.asset,Assets/**,ProjectSettings/**;exclude=Library/**,Logs/**,Temp/**"

PROFILES[xamarin]="description=Xamarin project;auto_apply=csharp;extends=csharp;include=*.cs,*.xaml,*.axml,*.storyboard,*.plist,*.entitlements"

# ============================================
# JAVASCRIPT AND NODE.JS PROFILES
# ============================================

PROFILES[javascript]="description=General JavaScript;extends=base;include=*.js,*.json,*.md,*.mjs,*.cjs;exclude=node_modules,dist,build,*.min.js"
PROFILE_ALIASES[js]="javascript"

PROFILES[nodejs]="description=General Node.js;extends=base;include=*.js,*.json,*.md,*.env*,package*.json,*.yml,*.yaml,.gitignore,.npmrc,*.mjs,*.ts,*.jsx,*.tsx;exclude=node_modules,dist,build,coverage,.next,.nuxt,out"
PROFILE_ALIASES[node]="nodejs"

# Frontend Frameworks
PROFILES[react]="description=React project;auto_apply=nodejs;extends=nodejs;include=*.jsx,*.tsx,*.js,*.ts,*.css,*.scss,*.sass,public/**,src/**"

PROFILES[vue]="description=Vue.js project;auto_apply=nodejs;extends=nodejs;include=*.vue,*.js,*.ts,*.css,*.scss,*.sass,public/**,src/**"
PROFILE_ALIASES[vuejs]="vue"

PROFILES[angular]="description=Angular project;auto_apply=nodejs;extends=nodejs;include=*.ts,*.js,*.html,*.css,*.scss,angular.json,*.component.*,*.service.*,*.module.*,src/**"

PROFILES[svelte]="description=Svelte project;auto_apply=nodejs;extends=nodejs;include=*.svelte,*.js,*.ts,*.css,src/**,static/**"

# Node.js Frameworks
PROFILES[express]="description=Express.js project;auto_apply=nodejs;extends=nodejs;include=*.js,*.ts,routes/**,views/**,public/**,middleware/**"

PROFILES[nestjs]="description=NestJS project;auto_apply=nodejs;extends=nodejs;include=*.ts,*.js,*.module.ts,*.controller.ts,*.service.ts,src/**"

PROFILES[nextjs]="description=Next.js project;auto_apply=nodejs;extends=nodejs;include=*.js,*.jsx,*.ts,*.tsx,pages/**,components/**,public/**,styles/**,next.config.js"
PROFILE_ALIASES[next]="nextjs"

PROFILES[nuxtjs]="description=Nuxt.js project;auto_apply=nodejs;extends=nodejs;include=*.vue,*.js,*.ts,pages/**,components/**,layouts/**,middleware/**,nuxt.config.js"
PROFILE_ALIASES[nuxt]="nuxtjs"

PROFILES[electron]="description=Electron project;auto_apply=nodejs;extends=nodejs;include=*.js,*.ts,*.html,*.css,main.js,renderer.js,preload.js"

# React Native
PROFILES[react-native]="description=React Native project;auto_apply=nodejs;extends=nodejs;include=*.jsx,*.tsx,*.js,*.ts,*.json,android/**,ios/**,*.native.*"
PROFILE_ALIASES[reactnative]="react-native"

# ============================================
# TYPESCRIPT PROFILES
# ============================================

PROFILES[typescript]="description=General TypeScript project;extends=nodejs;include=*.ts,*.tsx,*.d.ts,tsconfig*.json,*.config.ts;exclude=*.js.map,*.d.ts.map"
PROFILE_ALIASES[ts]="typescript"

# ============================================
# GO AND ITS FRAMEWORKS PROFILES
# ============================================

PROFILES[go]="description=General Go project;extends=base;include=*.go,go.mod,go.sum,*.md,Makefile;exclude=vendor,*.exe"
PROFILE_ALIASES[golang]="go"

PROFILES[gin]="description=Gin Go project;auto_apply=go;extends=go;include=*.go,templates/**,static/**"

PROFILES[echo]="description=Echo Go project;auto_apply=go;extends=go;include=*.go,templates/**,static/**"

PROFILES[fiber]="description=Fiber Go project;auto_apply=go;extends=go;include=*.go,views/**,public/**"

PROFILES[beego]="description=Beego Go project;auto_apply=go;extends=go;include=*.go,views/**,static/**,conf/**"

# ============================================
# OTHER LANGUAGES PROFILES
# ============================================

# Visual Basic
PROFILES[visual-basic]="description=Visual Basic project;extends=base;include=*.vb,*.vbs,*.vbproj,*.bas,*.cls,*.frm,*.ctl"
PROFILE_ALIASES[visualbasic]="visual-basic"
PROFILE_ALIASES[vb]="visual-basic"
PROFILE_ALIASES[vbs]="visual-basic"

# SQL
PROFILES[sql]="description=General SQL project;extends=base;include=*.sql,*.ddl,*.dml,*.plsql,*.psql"

PROFILES[mysql]="description=MySQL project;auto_apply=sql;extends=sql;include=*.sql,*.cnf,my.cnf"

PROFILES[postgresql]="description=PostgreSQL project;auto_apply=sql;extends=sql;include=*.sql,*.conf,postgresql.conf"
PROFILE_ALIASES[postgres]="postgresql"

PROFILES[sqlite]="description=SQLite project;auto_apply=sql;extends=sql;include=*.sql,*.db,*.sqlite,*.sqlite3"

PROFILES[oracle]="description=Oracle project;auto_apply=sql;extends=sql;include=*.sql,*.plsql,*.pks,*.pkb"

# R
PROFILES[r]="description=R project;extends=base;include=*.R,*.r,*.Rmd,*.Rnw,*.rda,*.rds,DESCRIPTION,NAMESPACE"

# PHP
PROFILES[php]="description=General PHP project;extends=base;include=*.php,*.phtml,*.json,*.xml,*.md,composer.json,composer.lock;exclude=vendor,*.phar"

PROFILES[laravel]="description=Laravel PHP project;auto_apply=php;extends=php;include=*.php,*.blade.php,artisan,composer.json,routes/**,app/**,resources/**,config/**"

PROFILES[symfony]="description=Symfony PHP project;auto_apply=php;extends=php;include=*.php,*.twig,composer.json,src/**,templates/**,config/**"

PROFILES[wordpress]="description=WordPress PHP project;auto_apply=php;extends=php;include=*.php,wp-config.php,functions.php,style.css,wp-content/**"

# Wolfram
PROFILES[wolfram]="description=Wolfram project;extends=base;include=*.nb,*.wl,*.m,*.mx,*.cdf"

# Matlab
PROFILES[matlab]="description=MATLAB project;extends=base;include=*.m,*.mlx,*.fig,*.mat,*.slx,*.mdl"

# Rust
PROFILES[rust]="description=General Rust project;extends=base;include=*.rs,*.toml,*.md,Cargo.lock,Cargo.toml;exclude=target,*.rlib"

PROFILES[actix]="description=Actix Rust project;auto_apply=rust;extends=rust;include=*.rs,templates/**,static/**"

PROFILES[rocket]="description=Rocket Rust project;auto_apply=rust;extends=rust;include=*.rs,templates/**,static/**"

# Ruby
PROFILES[ruby]="description=General Ruby project;extends=base;include=*.rb,*.rake,*.gemspec,Gemfile*,*.md,Rakefile;exclude=vendor,*.gem"

PROFILES[ruby-on-rails]="description=Ruby on Rails project;auto_apply=ruby;extends=ruby;include=*.rb,*.erb,*.haml,*.scss,*.css,*.js,app/**,config/**,db/**,Gemfile*"
PROFILE_ALIASES[rubyonrails]="ruby-on-rails"
PROFILE_ALIASES[ror]="ruby-on-rails"

PROFILES[sinatra]="description=Sinatra Ruby project;auto_apply=ruby;extends=ruby;include=*.rb,views/**,public/**"

# Swift
PROFILES[swift]="description=General Swift project;extends=base;include=*.swift,*.plist,*.md,Package.swift;exclude=.build,*.xcodeproj,*.xcworkspace"

PROFILES[ios]="description=iOS Swift project;auto_apply=swift;extends=swift;include=*.swift,*.storyboard,*.xib,*.plist,*.xcodeproj,*.xcworkspace"

PROFILES[macos]="description=macOS Swift project;auto_apply=swift;extends=swift;include=*.swift,*.storyboard,*.xib,*.plist,*.xcodeproj"

# Kotlin
PROFILES[kotlin]="description=General Kotlin project;extends=base;include=*.kt,*.kts,*.gradle,*.xml,*.md;exclude=build,.gradle,*.class,*.jar"

# Dart
PROFILES[dart]="description=General Dart project;extends=base;include=*.dart,pubspec.yaml,pubspec.lock,*.md;exclude=.dart_tool,build"

PROFILES[flutter]="description=Flutter project;auto_apply=dart;extends=dart;include=*.dart,pubspec.yaml,android/**,ios/**,lib/**,web/**"

# Lua
PROFILES[lua]="description=Lua project;extends=base;include=*.lua,*.rockspec"

# Bash
PROFILES[bash]="description=Bash scripts;extends=base;include=*.sh,*.bash,*.zsh,*.fish,*.csh"

# Objective-C
PROFILES[objective-c]="description=Objective-C project;extends=base;include=*.m,*.mm,*.h,*.plist,*.storyboard,*.xib"
PROFILE_ALIASES[objc]="objective-c"

# D
PROFILES[d]="description=D project;extends=base;include=*.d,dub.json,dub.sdl"

# PowerShell
PROFILES[powershell]="description=PowerShell scripts;extends=base;include=*.ps1,*.psm1,*.psd1"

# ============================================
# WEB DEVELOPMENT PROFILES
# ============================================

PROFILES[web]="description=General web development;extends=base;include=*.html,*.css,*.scss,*.sass,*.less,*.js,*.ts,*.jsx,*.tsx,*.vue,*.svelte,*.php,*.json,*.md;exclude=node_modules,dist,build,vendor,.next,*.min.css,*.min.js"

PROFILES[frontend]="description=Frontend web;extends=base;include=*.html,*.css,*.scss,*.sass,*.less,*.js,*.ts,*.jsx,*.tsx,*.vue,*.svelte,*.json;exclude=node_modules,dist,build,*.min.*"

PROFILES[backend]="description=General backend;extends=base;include=*.js,*.ts,*.py,*.php,*.rb,*.go,*.java,*.cs,*.rs,*.json,*.yaml,*.yml,*.sql"

# ============================================
# IDES AND OPERATING SYSTEMS PROFILES
# ============================================

# JetBrains IDEs
PROFILES[jetbrains]="description=JetBrains IDEs;extends=base;exclude=.idea,.idea/**,*.iml,*.iws,*.ipr,out/**,.gradle/**,cmake-build-*/**"
PROFILE_ALIASES[intellij]="jetbrains"
PROFILE_ALIASES[phpstorm]="jetbrains"
PROFILE_ALIASES[pycharm]="jetbrains"
PROFILE_ALIASES[webstorm]="jetbrains"
PROFILE_ALIASES[rustrover]="jetbrains"
PROFILE_ALIASES[clion]="jetbrains"
PROFILE_ALIASES[goland]="jetbrains"
PROFILE_ALIASES[rider]="jetbrains"
PROFILE_ALIASES[datagrip]="jetbrains"
PROFILE_ALIASES[appcode]="jetbrains"

# Visual Studio Code
PROFILES[vscode]="description=Visual Studio Code;extends=base;exclude=.vscode/**,*.code-workspace"

# Visual Studio
PROFILES[visual-studio]="description=Visual Studio;extends=base;exclude=.vs/**,*.suo,*.user,*.userosscache,*.sln.docstates,bin/**,obj/**,packages/**,TestResults/**"
PROFILE_ALIASES[visualstudio]="visual-studio"

# Other IDEs
PROFILES[kate]="description=Kate KDE;extends=base;exclude=.kateproject,.kateproject.d/**"

PROFILES[kdevelop]="description=KDevelop;extends=base;exclude=.kdev4/**,*.kdev4"

PROFILES[xcode]="description=Xcode;extends=base;exclude=*.xcodeproj/**,*.xcworkspace/**,DerivedData/**,build/**"

# Operating Systems with extensive aliases
PROFILES[windows]="description=Windows system;extends=base;exclude=Thumbs.db,Desktop.ini,*.lnk,*.tmp,System32/**,Windows/**,hiberfil.sys,pagefile.sys,*.exe,*.dll,*.msi"
PROFILE_ALIASES[windows-7]="windows"
PROFILE_ALIASES[windows-8]="windows"
PROFILE_ALIASES[windows-10]="windows"
PROFILE_ALIASES[windows-11]="windows"
PROFILE_ALIASES[win7]="windows"
PROFILE_ALIASES[win8]="windows"
PROFILE_ALIASES[win10]="windows"
PROFILE_ALIASES[win11]="windows"
PROFILE_ALIASES[win]="windows"

PROFILES[macos]="description=macOS system;extends=base;exclude=.DS_Store,.AppleDouble,.LSOverride,Icon*,.DocumentRevisions-V100,.fseventsd,.Spotlight-V100,.TemporaryItems,.Trashes,.VolumeIcon.icns,.com.apple.timemachine.donotpresent,.AppleDB,.AppleDesktop"
PROFILE_ALIASES[mac]="macos"
PROFILE_ALIASES[apple]="macos"
PROFILE_ALIASES[osx]="macos"
PROFILE_ALIASES[macos-big-sur]="macos"
PROFILE_ALIASES[macos-monterey]="macos"
PROFILE_ALIASES[macos-ventura]="macos"
PROFILE_ALIASES[macos-sonoma]="macos"
PROFILE_ALIASES[macos-sequoia]="macos"

PROFILES[linux]="description=Linux system;extends=base;exclude=*.tmp,*.log,/proc/**,/sys/**,/dev/**,/tmp/**,/var/log/**,.cache/**"
PROFILE_ALIASES[mint]="linux"
PROFILE_ALIASES[linux-mint]="linux"
PROFILE_ALIASES[debian]="linux"
PROFILE_ALIASES[debian-stable]="linux"
PROFILE_ALIASES[debian-testing]="linux"
PROFILE_ALIASES[debian-unstable]="linux"
PROFILE_ALIASES[linux-debian]="linux"
PROFILE_ALIASES[ubuntu]="linux"
PROFILE_ALIASES[ubuntu-lts]="linux"
PROFILE_ALIASES[ubuntu-20]="linux"
PROFILE_ALIASES[ubuntu-22]="linux"
PROFILE_ALIASES[ubuntu-24]="linux"
PROFILE_ALIASES[linux-ubuntu]="linux"
PROFILE_ALIASES[kali]="linux"
PROFILE_ALIASES[kali-linux]="linux"
PROFILE_ALIASES[linux-kali]="linux"
PROFILE_ALIASES[fedora]="linux"
PROFILE_ALIASES[centos]="linux"
PROFILE_ALIASES[rhel]="linux"
PROFILE_ALIASES[redhat]="linux"
PROFILE_ALIASES[arch]="linux"
PROFILE_ALIASES[arch-linux]="linux"
PROFILE_ALIASES[manjaro]="linux"
PROFILE_ALIASES[opensuse]="linux"
PROFILE_ALIASES[suse]="linux"
PROFILE_ALIASES[elementary]="linux"
PROFILE_ALIASES[zorin]="linux"
PROFILE_ALIASES[pop-os]="linux"
PROFILE_ALIASES[popos]="linux"

PROFILES[wsl]="description=Windows Subsystem for Linux;extends=base;exclude=*.tmp,*.log,*.exe,*.dll,*.msi,Thumbs.db,Desktop.ini,*.lnk,System32/**,Windows/**,hiberfil.sys,pagefile.sys"

# ============================================
# SPECIALIZED PROFILES
# ============================================

PROFILES[docs]="description=Documentation only;extends=base;include=*.md,*.txt,*.rst,*.adoc,*.tex,*.pdf,*.docx,docs/**,README*,LICENSE*,CHANGELOG*"

PROFILES[config]="description=Configuration files only;extends=base;include=*.json,*.yml,*.yaml,*.xml,*.toml,*.ini,*.cfg,*.conf,*.env*,Dockerfile,Makefile,*.config"

PROFILES[minimal]="description=Minimal essential;extends=base;include=*.txt,*.md,README*,LICENSE*"

# Default profile (mega-profile that includes everything common)
PROFILES[default]="description=Default multi-platform and multi-language profile;auto_apply=windows,wsl,macos,linux,vscode,jetbrains,python,cpp,c,csharp,rust,nodejs,javascript,typescript,vue,react,php,git;extends=base;include=README*,readme*,Makefile,makefile,CMakeLists.txt,cmakelist.txt;exclude=tmp,tmp/**,temp,temp/**,licence,licence.txt,aws,aws/**,*.key"

PROFILES[git]="description=Git version control files;extends=base;include=.gitignore,.gitattributes,.gitmodules,.gitkeep,.github/**,.gitlab-ci.yml,.gitlab/**,bitbucket-pipelines.yml,.gitea/**,*.git*;exclude=.git/objects/**,.git/refs/**,.git/logs/**"

PROFILES[tests]="description=Test files only;extends=base;include=*test*,*spec*,tests/**,spec/**,__tests__/**,*.test.*,*.spec.*"

PROFILES[docker]="description=Docker project files;extends=base;include=Dockerfile*,docker-compose*.yml,docker-compose*.yaml,.dockerignore,*.dockerfile"

# =================== ADVANCED GLOBAL VARIABLES ===================

# Current configuration
SOURCE_DIR=""
OUTPUT_FILE=""
MAX_LINES=""
MAX_FILE_SIZE_MB=""
SHOW_TREE=true
VERBOSE=false
BINARY_DETECTION=true
SHOW_BINARY_INFO=false
DRY_RUN=false

# Sensitive file flags
INCLUDE_SENSITIVE=false
EXCLUDE_SENSITIVE=false

# Output flags
NO_OUTPUT_FILE=false
NO_TTY_OUTPUT=false
CUSTOM_OUTPUT_FILE=""

# Hidden file flag
EXCLUDE_HIDDEN=false
INCLUDE_HIDDEN=false

# Program control flags
SHOW_VERSION=false
SHOW_HELP=false
SHOW_USAGE=false
SHOW_TLDR=false
SHOW_LICENSE=false

# Color flag
NO_COLOR=false

# Config file processing
CONFIG_FILE_PROVIDED=false
declare -a CONFIG_FLAGS=()

# Default sensitive files
SENSITIVE_FILES=(
    "*.env"
    "*.pem"
    "*.rsa"
    "*.key"
    "*.crt"
    "*.cert"
    "*.p12"
    "*.pfx"
    "*.keystore"
    "*.jks"
    "*.ppk"
    "id_rsa"
    "id_dsa"
    "id_ecdsa"
    "id_ed25519"
    "*.ssh"
    "*.pgp"
    "*.gpg"
    "*.asc"
    "secrets.*"
    "*.secret"
    "*.password"
    "*.passwd"
    "*.token"
    "*.tokens"
    "credentials.*"
    "*.credentials"
    "config.json"
    "settings.json"
    "*.aws"
    "*.gcp"
    "*.azure"
)

# Allowed sensitive files (templates/examples)
ALLOWED_SENSITIVE_FILES=(
    "template.env"
    "example.env"
    ".env.template"
    ".env.example"
    ".env.sample"
    "env.template"
    "env.example"
    "env.sample"
)

# =================== SIGNAL AND ERROR HANDLING FUNCTIONS ===================

# Function for cleanup when exiting
cleanup_and_exit() {
    local exit_code=${1:-1}
    echo ""
    if [[ "$NO_TTY_OUTPUT" != true ]]; then
        echo -e "${ANSI_YELLOW}${ANSI_BOLD}Script interrupted by user${ANSI_RESET}"
        echo -e "${ANSI_CYAN}Partial statistics:${ANSI_RESET}"
        echo -e "  Files found: $TOTAL_FILES_FOUND"
        echo -e "  Files processed: $TOTAL_FILES_PROCESSED"
        echo -e "  Files excluded: $TOTAL_FILES_EXCLUDED"
    fi
    exit $exit_code
}

# Function for handling unhandled errors
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo ""
    echo -e "${ANSI_RED}${ANSI_BOLD}UNHANDLED ERROR at line $line_number (code: $exit_code)${ANSI_RESET}"
    echo -e "${ANSI_RED}Please report this error with the details of the executed command.${ANSI_RESET}"
    echo ""
    show_usage
    exit $exit_code
}

# Configure signal traps
setup_signal_handlers() {
    trap 'cleanup_and_exit 130' SIGINT   # Ctrl+C
    trap 'cleanup_and_exit 143' SIGTERM  # kill
    trap 'handle_error $LINENO' ERR      # Unhandled errors
}

# =================== HIGHLIGHT AND COLORIZATION FUNCTIONS ===================

# Extension to highlight syntax mapping
declare -A HIGHLIGHT_SYNTAX_MAP
HIGHLIGHT_SYNTAX_MAP=(
    ["sh"]="bash"
    ["bash"]="bash"
    ["zsh"]="bash"
    ["fish"]="fish"
    ["py"]="python"
    ["pyw"]="python"
    ["js"]="javascript"
    ["mjs"]="javascript"
    ["cjs"]="javascript"
    ["ts"]="typescript"
    ["tsx"]="typescript"
    ["jsx"]="javascript"
    ["cpp"]="cpp"
    ["cxx"]="cpp"
    ["cc"]="cpp"
    ["c++"]="cpp"
    ["hpp"]="cpp"
    ["hxx"]="cpp"
    ["h++"]="cpp"
    ["c"]="c"
    ["h"]="c"
    ["cs"]="csharp"
    ["java"]="java"
    ["kt"]="kotlin"
    ["kts"]="kotlin"
    ["go"]="go"
    ["rs"]="rust"
    ["php"]="php"
    ["phtml"]="php"
    ["rb"]="ruby"
    ["rake"]="ruby"
    ["swift"]="swift"
    ["html"]="html"
    ["htm"]="html"
    ["xml"]="xml"
    ["css"]="css"
    ["scss"]="scss"
    ["sass"]="sass"
    ["less"]="less"
    ["json"]="json"
    ["yml"]="yaml"
    ["yaml"]="yaml"
    ["toml"]="toml"
    ["ini"]="ini"
    ["cfg"]="ini"
    ["conf"]="ini"
    ["md"]="markdown"
    ["markdown"]="markdown"
    ["sql"]="sql"
    ["r"]="r"
    ["m"]="matlab"
    ["lua"]="lua"
    ["pl"]="perl"
    ["pm"]="perl"
    ["vim"]="vim"
    ["dockerfile"]="dockerfile"
    ["makefile"]="makefile"
    ["cmake"]="cmake"
    ["tex"]="latex"
    ["dart"]="dart"
    ["vue"]="vue"
    ["svelte"]="html"
    ["ps1"]="powershell"
    ["psm1"]="powershell"
    ["vb"]="vb"
    ["vbs"]="vb"
)

# Function to detect and configure highlight
detect_highlight() {
    if command -v highlight >/dev/null 2>&1; then
        HIGHLIGHT_AVAILABLE=true
        HIGHLIGHT_COMMAND="highlight"
        debug "Highlight detected at: $(which highlight)"
        
        # Check if highlight supports --list-scripts to validate syntax
        if highlight --list-scripts >/dev/null 2>&1; then
            debug "Highlight supports --list-scripts"
        fi
    else
        HIGHLIGHT_AVAILABLE=false
        debug "Highlight is not available"
    fi
}

# Function to get highlight syntax for an extension
get_highlight_syntax() {
    local file="$1"
    local extension="${file##*.}"
    extension="${extension,,}"  # lowercase
    
    # Special cases
    local basename_file=$(basename "$file")
    case "${basename_file,,}" in
        "makefile"|"makefile.inc"|"gnumakefile")
            echo "makefile"
            return
            ;;
        "dockerfile"|"dockerfile."*)
            echo "dockerfile"
            return
            ;;
        "cmakelists.txt")
            echo "cmake"
            return
            ;;
    esac
    
    # Search in mapping
    if [[ -n "${HIGHLIGHT_SYNTAX_MAP[$extension]:-}" ]]; then
        echo "${HIGHLIGHT_SYNTAX_MAP[$extension]}"
    else
        # No known mapping
        echo ""
    fi
}

# Function to colorize code using highlight
colorize_code() {
    local content="$1"
    local syntax="$2"
    
    if [[ "$USE_COLOR" != true ]] || [[ "$HIGHLIGHT_AVAILABLE" != true ]] || [[ -z "$syntax" ]]; then
        echo "$content"
        return
    fi
    
    # Use highlight to colorize
    if echo "$content" | $HIGHLIGHT_COMMAND --syntax="$syntax" --out-format=ansi 2>/dev/null; then
        debug "Code colorized with syntax: $syntax"
    else
        debug "Error colorizing with syntax: $syntax, showing plain text"
        echo "$content"
    fi
}

# Function to show highlight installation suggestion
show_highlight_suggestion() {
    if [[ "$HIGHLIGHT_AVAILABLE" != true ]] && [[ "$USE_COLOR" == true ]] && [[ "$NO_TTY_OUTPUT" != true ]]; then
        echo ""
        echo -e "${ANSI_ORANGE}${ANSI_BOLD}Tip: Install 'highlight' for colored output${ANSI_RESET}"
        echo -e "${ANSI_ORANGE}   macOS:     ${ANSI_BOLD}brew install highlight${ANSI_RESET}"
        echo -e "${ANSI_ORANGE}   Ubuntu:    ${ANSI_BOLD}sudo apt install highlight${ANSI_RESET}"
        echo -e "${ANSI_ORANGE}   Fedora:    ${ANSI_BOLD}sudo dnf install highlight${ANSI_RESET}"
        echo -e "${ANSI_ORANGE}   Arch:      ${ANSI_BOLD}sudo pacman -S highlight${ANSI_RESET}"
        echo ""
    fi
}

# Function to show basic usage
show_usage() {
    local script_name=$(basename "$0")
    cat << EOF
Incorrect usage.

BASIC USAGE:
    $script_name [OPTIONS] [OUTPUT_DIRECTORY]

MAIN OPTIONS:
    -h, --help              Show detailed help
    -v, --verbose           Verbose mode with detailed debugging
    -p, --profile=PROFILE   Use profile (can be repeated to combine)
    --include=PATTERN       Include files/directories
    --exclude=PATTERN       Exclude files/directories
    --no-color, --no-colour Disable code colorization
    --dry-run               Only show what would be processed

QUICK EXAMPLES:
    $script_name --profile=python
    $script_name --profile=nodejs --profile=react
    $script_name --include="*.py" --exclude="*test*"

For complete help: $script_name --help
For profiles:      $script_name --show-profiles
EOF
}

# Function to show extended help
show_help() {
    local script_name=$(basename "$0")
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

USAGE:
    $script_name [OPTIONS] [OUTPUT_DIRECTORY]

BASIC OPTIONS:
    -h, --help              Show this help
    -v, --verbose           Verbose mode with detailed debugging
    -s, --source-dir=DIR    Source directory (auto-detects: src/ or ./ or projects)
    -o, --output-file=FILE  Output file (default: Code.txt)
    -l, --max-lines=NUM     Maximum lines per file (default: 1500)

COMBINABLE PROFILE SYSTEM:
    -p, --profile=PROFILE   Use profile (can be repeated to combine)
    
    Profiles are applied IN ORDER and each one modifies the previous:
    --profile=node --profile=typescript  # Node.js base + TypeScript specific
    --profile=csharp --profile=web       # C# base + web elements

PRIORITY FILTER SYSTEM:
    --include=PATTERN       Include files/directories
    --exclude=PATTERN       Exclude files/directories
    
    Each flag is evaluated IN ORDER with priority over previous ones:
    --include=src --exclude=src/test --include=src/test/important.js

ADVANCED OPTIONS:
    --include-sensitive     Include sensitive files (*.env, *.key, *.pem, etc.)
    --exclude-sensitive     Exclude sensitive files (override, ignores position)
    --no-output-file        Only show in terminal, don't generate file
    --output-file=PATH      Specify custom output file
    --no-tty-output         Only generate file, don't show in terminal
    --no-tree               Don't include directory structure
    --no-binary-detection   Disable binary file detection
    --show-binary-info      Show detailed binary file information
    --dry-run               Only show what would be processed (don't generate file)
    --config=FILE           Load configuration from file
    --show-profiles         Show all available profiles

SENSITIVE FILE SECURITY:
By default, the script EXCLUDES sensitive files such as:
    *.env, *.key, *.pem, *.rsa, *.crt, secrets.*, credentials.*, etc.
    
BUT INCLUDES template/example files:
    template.env, example.env, .env.template, .env.example, etc.
    
Use --include-sensitive to include all sensitive files
Use --exclude-sensitive to force exclusion (total override)

AVAILABLE PROFILES:
EOF
    
    # Show profiles organized by category
    echo ""
    echo "PROGRAMMING LANGUAGES:"
    echo "    Python: python, django, flask, fastapi, tensorflow, pytorch, numpy, pandas"
    echo "    C++:    cpp, qt, wxwidgets, unreal-engine, boost"
    echo "    C:      c, gtk, embedded, kernel"
    echo "    Java:   java, spring, android, maven, gradle"
    echo "    C#:     csharp, aspnet, blazor, wpf, unity"
    echo "    JS/Node: javascript, nodejs, react, vue, angular, nextjs"
    echo "    Go:     go, gin, echo, fiber"
    echo "    Rust:   rust, actix, rocket"
    echo "    Ruby:   ruby, ruby-on-rails, sinatra"
    echo "    PHP:    php, laravel, symfony, wordpress"
    echo "    Others: swift, kotlin, dart, python, sql, r, matlab"
    
    echo ""
    echo "WEB DEVELOPMENT:"
    echo "    Frontend:   web, frontend, react, vue, angular, svelte"
    echo "    Backend:    backend, nodejs, express, django, flask"
    echo "    Full-stack: nextjs, nuxtjs"
    
    echo ""
    echo "IDES AND SYSTEMS:"
    echo "    IDEs:       jetbrains, vscode, visual-studio, xcode"
    echo "    Systems:    windows, macos, linux"
    
    echo ""
    echo "SPECIAL:"
    for profile in general docs config minimal tests docker; do
        if [[ -n "${PROFILES[$profile]:-}" ]]; then
            local description=$(get_profile_description "$profile")
            printf "    %-12s %s\n" "$profile" "$description"
        fi
    done
    
    cat << EOF

ADVANCED EXAMPLES:

1. Combine Python + specific framework:
   $script_name --profile=python --profile=django

2. C++ with multiple frameworks:
   $script_name --profile=cpp --profile=qt --profile=boost

3. Complete web development:
   $script_name --profile=nodejs --profile=react --profile=typescript

4. Project with base profile auto-application:
   $script_name --profile=django  # Automatically applies python + django

5. Case insensitive and aliases:
   $script_name --profile=PYTHON --profile=Django  # Same as python + django
   $script_name --profile=js --profile=TS          # JavaScript + TypeScript

6. Granular control with priorities:
   $script_name --profile=csharp --exclude=bin --include="bin/important.dll"

7. Multiple frameworks of the same language:
   $script_name --profile=python --profile=django --profile=numpy --profile=matplotlib

8. IDEs and specific systems:
   $script_name --profile=csharp --profile=visual-studio --profile=windows

9. Complex multi-technology projects:
   $script_name --profile=nodejs --profile=react --profile=typescript --profile=docker

10. Complete ML/Data Science:
    $script_name --profile=python --profile=tensorflow --profile=numpy --profile=matplotlib

11. Game development:
    $script_name --profile=cpp --profile=unreal-engine

12. Only specific files with exclusions:
    $script_name --profile=web --exclude="*.min.*" --include="vendor/important.min.js"

13. Include sensitive files for audit:
    $script_name --profile=default --include-sensitive

14. Exclude sensitive files with override:
    $script_name --profile=nodejs --include-sensitive --exclude-sensitive

15. Only show in terminal without generating file:
    $script_name --profile=python --no-output-file

16. Generate file without showing in terminal (silent mode):
    $script_name --profile=csharp --no-tty-output

17. Custom output file:
    $script_name --profile=web --output-file="./docs/code_analysis.md"

18. Multi-platform project (using case-insensitive aliases):
    $script_name --profile=DEFAULT --profile=WINDOWS --profile=Linux

19. Disable code colorization:
    $script_name --profile=python --no-color

20. Large files with custom limits:
    $script_name --profile=cpp --max-size=5 --max-lines=3000

21. Silent processing for CI/CD:
    $script_name --profile=nodejs --no-tty-output --output-file="build/docs.md"

ADVANCED FEATURES:
- Auto-application of base profiles: Frameworks automatically apply their language
- Case insensitive: 'Python', 'python', 'PYTHON' are equivalent  
- Intelligent aliases: js→javascript, ts→typescript, ror→ruby-on-rails
- Automatic detection: If './src/' exists, it uses it as source directory
- Advanced binary detection: Automatically detects PDFs, images, executables
- Filtered tree: Only shows files that will be processed
- Detailed statistics: Processed files, excluded, binary vs text
- Complex filters: Support for patterns with ** and advanced wildcards

PROFILES WITH AUTO-APPLICATION:
These profiles automatically include their base language:
- django, flask, fastapi → includes python automatically
- qt, wxwidgets, unreal-engine → includes cpp automatically  
- react, vue, angular → includes nodejs automatically
- spring, android → includes java automatically
- unity, blazor → includes csharp automatically
- And many more...

EOF
}

# Function to get profile description
get_profile_description() {
    local profile="$1"
    local profile_info="${PROFILES[$profile]:-}"
    if [[ -n "$profile_info" ]]; then
        echo "$profile_info" | grep -o 'description=[^;]*' | cut -d'=' -f2-
    else
        echo "Profile not found"
    fi
}

# Function to show all organized profiles
show_profiles() {
    echo "AVAILABLE PROFILES (${#PROFILES[@]} profiles):"
    echo "=================================================="
    
    # Organize profiles by categories
    local -a base_profiles=("base" "general" "minimal" "docs" "config" "tests" "docker")
    local -a python_profiles=("python" "django" "flask" "fastapi" "tornado" "pyramid" "tensorflow" "pytorch" "scikit-learn" "numpy" "pandas" "matplotlib" "seaborn" "plotly")
    local -a cpp_profiles=("cpp" "qt" "wxwidgets" "juce" "crow" "pistache" "cppcms" "wt" "poco" "boost" "unreal-engine" "tensorrt")
    local -a c_profiles=("c" "gtk" "embedded" "kernel")
    local -a java_profiles=("java" "spring" "spring-boot" "hibernate" "maven" "gradle" "android")
    local -a csharp_profiles=("csharp" "aspnet" "blazor" "wpf" "winforms" "unity" "xamarin")
    local -a js_profiles=("javascript" "nodejs" "react" "vue" "angular" "svelte" "express" "nestjs" "nextjs" "nuxtjs" "electron" "react-native")
    local -a web_profiles=("web" "frontend" "backend" "typescript")
    local -a go_profiles=("go" "gin" "echo" "fiber" "beego")
    local -a other_lang_profiles=("visual-basic" "sql" "mysql" "postgresql" "sqlite" "oracle" "r" "php" "laravel" "symfony" "wordpress" "wolfram" "matlab" "rust" "actix" "rocket" "ruby" "ruby-on-rails" "sinatra" "swift" "ios" "macos" "kotlin" "dart" "flutter" "lua" "bash" "objective-c" "d" "powershell")
    local -a ide_profiles=("jetbrains" "vscode" "visual-studio" "kate" "kdevelop" "xcode")
    local -a os_profiles=("windows" "macos" "linux")
    
    show_profile_category "BASE PROFILES" "${base_profiles[@]}"
    show_profile_category "PYTHON AND FRAMEWORKS" "${python_profiles[@]}"
    show_profile_category "C++ AND FRAMEWORKS" "${cpp_profiles[@]}"
    show_profile_category "C AND FRAMEWORKS" "${c_profiles[@]}"
    show_profile_category "JAVA AND FRAMEWORKS" "${java_profiles[@]}"
    show_profile_category "C# AND FRAMEWORKS" "${csharp_profiles[@]}"
    show_profile_category "JAVASCRIPT/NODE.JS AND FRAMEWORKS" "${js_profiles[@]}"
    show_profile_category "WEB AND TYPESCRIPT" "${web_profiles[@]}"
    show_profile_category "GO AND FRAMEWORKS" "${go_profiles[@]}"
    show_profile_category "OTHER LANGUAGES AND FRAMEWORKS" "${other_lang_profiles[@]}"
    show_profile_category "IDES" "${ide_profiles[@]}"
    show_profile_category "OPERATING SYSTEMS" "${os_profiles[@]}"
    
    echo ""
    echo "AVAILABLE ALIASES:"
    echo "======================="
    local sorted_aliases=($(printf '%s\n' "${!PROFILE_ALIASES[@]}" | sort))
    for alias in "${sorted_aliases[@]}"; do
        printf "    %-20s → %s\n" "$alias" "${PROFILE_ALIASES[$alias]}"
    done
    
    echo ""
    echo "TIPS:"
    echo "========"
    echo "  • Profiles are case-insensitive: 'Python', 'python', 'PYTHON' are the same"
    echo "  • Specific profiles auto-apply their base profile (eg: django applies python)"
    echo "  • You can combine multiple profiles: --profile=python --profile=django --profile=docker"
    echo "  • Use aliases for convenience: --profile=js instead of --profile=javascript"
    echo ""
}

# Auxiliary function to show a profile category
show_profile_category() {
    local category_name="$1"
    shift
    local profiles=("$@")
    
    echo ""
    echo "$category_name:"
    for profile in "${profiles[@]}"; do
        if [[ -n "${PROFILES[$profile]:-}" ]]; then
            local description
            description=$(get_profile_description "$profile")
            local auto_apply=""
            local profile_info="${PROFILES[$profile]}"
            if [[ "$profile_info" == *"auto_apply="* ]]; then
                local auto_apply_profile
                auto_apply_profile=$(echo "$profile_info" | grep -o 'auto_apply=[^;]*' | cut -d'=' -f2)
                auto_apply=" (auto-applies: $auto_apply_profile)"
            fi
            printf "    %-18s %s%s\n" "$profile" "$description" "$auto_apply"
        fi
    done
}

# Advanced logging function
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[$(date '+%H:%M:%S')] [LOG] $*" >&2
    fi
}

# Function for debug logging
debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[$(date '+%H:%M:%S')] [DEBUG] $*" >&2
    fi
}

# Function to show errors
error() {
    echo "[$(date '+%H:%M:%S')] [ERROR] $*" >&2
    exit 1
}

# Function to show warnings
warning() {
    echo "[$(date '+%H:%M:%S')] [WARNING] $*" >&2
}

# Function to show information
info() {
    echo "[$(date '+%H:%M:%S')] [INFO] $*" >&2
}

# Function to auto-detect source directory (improved)
auto_detect_source_dir() {
    local current_pwd="$(pwd)"
    
    log "Auto-detecting source directory from: $current_pwd"
    
    # 1. Look for ./src/
    if [[ -d "./src" ]]; then
        log "Found ./src/ directory"
        echo "$current_pwd/src"
        return
    fi
    
    # 2. Look for specific known projects (user patterns)
    for pattern in "./E*/Proyecto-*" "./proyecto-*" "./Project-*" "./proj-*" "./code-*" "./source-*"; do
        for dir in $pattern; do
            if [[ -d "$dir" ]]; then
                log "Found specific project: $dir"
                echo "$current_pwd/${dir#./}"
                return
            fi
        done
    done
    
    # 3. Look for common project directories
    for common_dir in "./app" "./application" "./source" "./sources" "./lib" "./library"; do
        if [[ -d "$common_dir" ]]; then
            log "Found common directory: $common_dir"
            echo "$current_pwd/${common_dir#./}"
            return
        fi
    done
    
    # 4. Use current directory
    log "Using current directory as fallback"
    echo "$current_pwd"
}

# Function to resolve profile inheritance
resolve_profile_inheritance() {
    local profile="$1"
    local -A resolved_rules=()
    local extends_chain=()
    
    debug "Resolving inheritance for profile: $profile"
    
    # Build inheritance chain
    local current_profile="$profile"
    while [[ -n "$current_profile" ]]; do
        if [[ " ${extends_chain[*]} " == *" $current_profile "* ]]; then
            error "Circular inheritance detected in profile: $current_profile"
        fi
        
        extends_chain+=("$current_profile")
        
        # Look for parent profile
        local profile_info="${PROFILES[$current_profile]:-}"
        if [[ -z "$profile_info" ]]; then
            break
        fi
        
        local next_profile=""
        if [[ "$profile_info" == *"extends="* ]]; then
            next_profile=$(echo "$profile_info" | grep -o 'extends=[^;]*' | cut -d'=' -f2)
        fi
        current_profile="$next_profile"
    done
    
    debug "Inheritance chain: ${extends_chain[*]}"
    
    # Apply rules in reverse order (from base to child)
    for ((i=${#extends_chain[@]}-1; i>=0; i--)); do
        local profile_name="${extends_chain[$i]}"
        local profile_info="${PROFILES[$profile_name]:-}"
        
        if [[ -n "$profile_info" ]]; then
            debug "Applying rules from profile: $profile_name"
            parse_profile_rules "$profile_info" resolved_rules
        fi
    done
    
    # Convert resolved rules to global array
    for rule_type in "${!resolved_rules[@]}"; do
        local rules="${resolved_rules[$rule_type]}"
        IFS=',' read -ra RULE_LIST <<< "$rules"
        for rule in "${RULE_LIST[@]}"; do
            if [[ -n "$rule" ]]; then
                FILTER_RULES+=("$rule_type:$rule")
                debug "Profile rule added: $rule_type:$rule"
            fi
        done
    done
}

# Function to parse profile rules
parse_profile_rules() {
    local profile_info="$1"
    local -n rules_ref=$2
    
    IFS=';' read -ra CONFIG_PARTS <<< "$profile_info"
    for part in "${CONFIG_PARTS[@]}"; do
        if [[ "$part" == include=* ]]; then
            local includes="${part#include=}"
            rules_ref["include"]="${rules_ref["include"]:-}${rules_ref["include"]:+,}$includes"
        elif [[ "$part" == exclude=* ]]; then
            local excludes="${part#exclude=}"
            rules_ref["exclude"]="${rules_ref["exclude"]:-}${rules_ref["exclude"]:+,}$excludes"
        elif [[ "$part" == exclude_files=* ]]; then
            local exclude_files="${part#exclude_files=}"
            rules_ref["exclude"]="${rules_ref["exclude"]:-}${rules_ref["exclude"]:+,}$exclude_files"
        fi
    done
}

# Function to normalize profile names (case insensitive)
normalize_profile_name() {
    local profile="$1"
    echo "${profile,,}" # Convert to lowercase
}

# Function to resolve profile aliases
resolve_profile_alias() {
    local profile="$1"
    local normalized_profile
    normalized_profile=$(normalize_profile_name "$profile")
    
    # Look for exact alias match (case insensitive)
    for alias in "${!PROFILE_ALIASES[@]}"; do
        local normalized_alias
        normalized_alias=$(normalize_profile_name "$alias")
        if [[ "$normalized_alias" == "$normalized_profile" ]]; then
            echo "${PROFILE_ALIASES[$alias]}"
            return
        fi
    done
    
    # Look for direct profile (case insensitive)
    for profile_key in "${!PROFILES[@]}"; do
        local normalized_key
        normalized_key=$(normalize_profile_name "$profile_key")
        if [[ "$normalized_key" == "$normalized_profile" ]]; then
            echo "$profile_key"
            return
        fi
    done
    
    # Not found
    echo ""
}

# Function to auto-apply multiple base profiles (for default profile)
auto_apply_multiple_base_profiles() {
    local profile="$1"
    local profile_info="${PROFILES[$profile]:-}"
    
    if [[ "$profile_info" == *"auto_apply="* ]]; then
        local auto_apply_profiles
        auto_apply_profiles=$(echo "$profile_info" | grep -o 'auto_apply=[^;]*' | cut -d'=' -f2)
        
        if [[ -n "$auto_apply_profiles" ]]; then
            # Split by commas for multiple profiles
            IFS=',' read -ra PROFILE_LIST <<< "$auto_apply_profiles"
            
            for auto_profile in "${PROFILE_LIST[@]}"; do
                auto_profile=$(echo "$auto_profile" | xargs) # trim whitespace
                
                if [[ -n "$auto_profile" ]]; then
                    debug "Auto-applying base profile: $auto_profile for $profile"
                    
                    # Check that base profile exists
                    if [[ -n "${PROFILES[$auto_profile]:-}" ]]; then
                        APPLIED_PROFILES+=("$auto_profile")
                        resolve_profile_inheritance "$auto_profile"
                    else
                        warning "Auto-applied base profile '$auto_profile' not found for '$profile'"
                    fi
                fi
            done
        fi
    fi
}

# Function to auto-apply base profiles (updated version)
auto_apply_base_profiles() {
    local profile="$1"
    local profile_info="${PROFILES[$profile]:-}"
    
    if [[ "$profile_info" == *"auto_apply="* ]]; then
        local auto_apply_content
        auto_apply_content=$(echo "$profile_info" | grep -o 'auto_apply=[^;]*' | cut -d'=' -f2)
        
        if [[ -n "$auto_apply_content" ]]; then
            # Check if it has multiple profiles (separated by comma)
            if [[ "$auto_apply_content" == *","* ]]; then
                auto_apply_multiple_base_profiles "$profile"
            else
                # Only one profile
                debug "Auto-applying base profile: $auto_apply_content for $profile"
                
                if [[ -n "${PROFILES[$auto_apply_content]:-}" ]]; then
                    APPLIED_PROFILES+=("$auto_apply_content")
                    resolve_profile_inheritance "$auto_apply_content"
                else
                    warning "Auto-applied base profile '$auto_apply_content' not found for '$profile'"
                fi
            fi
        fi
    fi
}

# Function to apply hidden file rules
apply_hidden_file_rules() {
    debug "Applying hidden file rules"
    debug "EXCLUDE_HIDDEN: $EXCLUDE_HIDDEN"
    debug "INCLUDE_HIDDEN: $INCLUDE_HIDDEN"
    
    # By default, hidden files are included (changed behavior)
    # --exclude-hidden will exclude them
    # --include-hidden provides explicit inclusion
    
    if [[ "$EXCLUDE_HIDDEN" == true ]]; then
        # Exclude hidden files and directories
        FILTER_RULES+=("exclude:.*")
        FILTER_RULES+=("exclude:*/.*")
        debug "Hidden files excluded by --exclude-hidden flag"
    elif [[ "$INCLUDE_HIDDEN" == true ]]; then
        # Explicitly include hidden files (redundant since default behavior, but for clarity)
        FILTER_RULES+=("include:.*")
        FILTER_RULES+=("include:*/.*")
        debug "Hidden files explicitly included by --include-hidden flag"
    fi
    # If neither flag is set, hidden files are included by default (no additional rules needed)
}

# Function to load multiple profiles with case insensitive and auto-apply support
load_profiles() {
    local input_profiles=("$@")
    local resolved_profiles=()
    
    # If no profiles specified and not explicitly using default, don't use default profile
    # But still apply sensitive file exclusions
    if [[ ${#input_profiles[@]} -eq 0 ]]; then
        input_profiles=("default")
        log "No profiles specified, using 'default' profile"
    fi
    
    # Resolve all profiles and their aliases
    for profile in "${input_profiles[@]}"; do
        local resolved_profile
        resolved_profile=$(resolve_profile_alias "$profile")
        
        if [[ -z "$resolved_profile" ]]; then
            error "Profile '$profile' not found. Use --show-profiles to see available profiles."
        fi
        
        resolved_profiles+=("$resolved_profile")
        debug "Profile '$profile' resolved as '$resolved_profile'"
    done
    
    log "Profiles to load: ${resolved_profiles[*]}"
    
    # Apply profiles in order
    for profile in "${resolved_profiles[@]}"; do
        # First auto-apply base profile if necessary
        auto_apply_base_profiles "$profile"
        
        # Then apply the specific profile
        APPLIED_PROFILES+=("$profile")
        log "Resolving profile: $profile"
        resolve_profile_inheritance "$profile"
    done
    
    log "Final applied profiles: ${APPLIED_PROFILES[*]}"
    log "Total filter rules: ${#FILTER_RULES[@]}"
}

# Advanced function to detect file type
detect_file_type() {
    local file="$1"
    
    if [[ "$BINARY_DETECTION" != true ]]; then
        echo "text"
        return
    fi
    
    # Check if file exists and is readable
    if [[ ! -f "$file" ]] || [[ ! -r "$file" ]]; then
        echo "unreadable"
        return
    fi
    
    # Use 'file' command for precise detection
    local file_info
    if command -v file >/dev/null 2>&1; then
        file_info=$(file -b --mime-type "$file" 2>/dev/null)
        
        # Classify based on MIME type
        case "$file_info" in
            text/*)
                echo "text"
                ;;
            application/json|application/xml|application/javascript|application/x-sh)
                echo "text"
                ;;
            application/pdf|image/*|audio/*|video/*|application/octet-stream)
                echo "binary"
                ;;
            *)
                # Fallback: check if it contains non-printable characters
                if head -c 8000 "$file" | grep -q $'\0'; then
                    echo "binary"
                else
                    echo "text"
                fi
                ;;
        esac
    else
        # Fallback without 'file' command
        if head -c 8000 "$file" | grep -q $'\0'; then
            echo "binary"
        else
            echo "text"
        fi
    fi
}

# Function to get binary file information
get_binary_info() {
    local file="$1"
    local size_bytes
    local file_type
    
    size_bytes=$(wc -c < "$file" 2>/dev/null || echo "0")
    
    if command -v file >/dev/null 2>&1; then
        file_type=$(file -b "$file" 2>/dev/null || echo "Binary file")
    else
        file_type="Binary file"
    fi
    
    echo "[$file_type - $size_bytes bytes]"
}

# Function to check if a file is sensitive
is_sensitive_file() {
    local relative_path="$1"
    local basename_file="$2"
    
    # Check if it's in the allowed files list (case insensitive)
    for allowed_file in "${ALLOWED_SENSITIVE_FILES[@]}"; do
        if [[ "${basename_file,,}" == "${allowed_file,,}" ]] || [[ "${relative_path,,}" == "${allowed_file,,}" ]]; then
            return 1 # Not sensitive (it's allowed)
        fi
    done
    
    # Check if it matches sensitive patterns (case insensitive)
    for sensitive_pattern in "${SENSITIVE_FILES[@]}"; do
        local lower_pattern="${sensitive_pattern,,}"
        if [[ "${basename_file,,}" == $lower_pattern ]] || [[ "${relative_path,,}" == $lower_pattern ]]; then
            return 0 # It's sensitive
        fi
    done
    
    return 1 # Not sensitive
}

# Function to apply sensitive file rules
apply_sensitive_file_rules() {
    debug "Applying sensitive file rules"
    debug "INCLUDE_SENSITIVE: $INCLUDE_SENSITIVE"
    debug "EXCLUDE_SENSITIVE: $EXCLUDE_SENSITIVE"
    
    # If exclude_sensitive is activated, exclude sensitive files (total override)
    if [[ "$EXCLUDE_SENSITIVE" == true ]]; then
        for sensitive_pattern in "${SENSITIVE_FILES[@]}"; do
            FILTER_RULES+=("exclude:$sensitive_pattern")
            debug "Sensitive rule (exclude override): exclude:$sensitive_pattern"
        done
        
        # Allow template/example files
        for allowed_file in "${ALLOWED_SENSITIVE_FILES[@]}"; do
            FILTER_RULES+=("include:$allowed_file")
            debug "Sensitive rule (allow template): include:$allowed_file"
        done
        
    elif [[ "$INCLUDE_SENSITIVE" == true ]]; then
        # If include_sensitive is activated, explicitly include sensitive files
        for sensitive_pattern in "${SENSITIVE_FILES[@]}"; do
            FILTER_RULES+=("include:$sensitive_pattern")
            debug "Sensitive rule (include): include:$sensitive_pattern"
        done
        
    else
        # By default, exclude sensitive files for security
        for sensitive_pattern in "${SENSITIVE_FILES[@]}"; do
            FILTER_RULES+=("exclude:$sensitive_pattern")
            debug "Sensitive rule (default exclude): exclude:$sensitive_pattern"
        done
        
        # But allow template/example files
        for allowed_file in "${ALLOWED_SENSITIVE_FILES[@]}"; do
            FILTER_RULES+=("include:$allowed_file")
            debug "Sensitive rule (allow template): include:$allowed_file"
        done
    fi
}

should_include_path() {
    local path="$1"
    local relative_path="${path#$SOURCE_DIR/}"
    [[ "$relative_path" == "$path" ]] && relative_path="$path"
    
    local basename_file=$(basename "$path")
    local decision="exclude"  # Default exclude (more restrictive)
    
    debug "Evaluating file: $relative_path"
    
    # Apply filter rules in order (priority)
    for rule in "${FILTER_RULES[@]}"; do
        local action="${rule%%:*}"
        local pattern="${rule#*:}"
        
        if matches_pattern "$relative_path" "$basename_file" "$pattern"; then
            decision="$action"
            debug "Rule applied: $action:$pattern -> $relative_path (decision: $decision)"
        fi
    done
    
    debug "Final decision for '$relative_path': $decision"
    
    if [[ "$decision" == "include" ]]; then
        return 0  # include
    else
        return 1  # exclude
    fi
}

# Function to check if a pattern matches (case insensitive)
matches_pattern() {
    local relative_path="$1"
    local basename_file="$2"
    local pattern="$3"
    
    # Normalize to lowercase for case insensitive comparison
    local lower_relative_path="${relative_path,,}"
    local lower_basename_file="${basename_file,,}"
    local lower_pattern="${pattern,,}"
    
    # Specific file pattern (contains . or *)
    if [[ "$lower_pattern" == *.* ]]; then
        if [[ "$lower_basename_file" == $lower_pattern ]] || [[ "$lower_relative_path" == $lower_pattern ]]; then
            return 0
        fi
    fi
    
    # Directory or path pattern
    if [[ "$lower_relative_path" == "$lower_pattern"* ]] || 
       [[ "$lower_relative_path" == *"$lower_pattern"* ]] || 
       [[ "$lower_basename_file" == "$lower_pattern" ]]; then
        return 0
    fi
    
    # Pattern with wildcards (bash globbing with shopt for case insensitive)
    if [[ "$lower_relative_path" == $lower_pattern ]] || [[ "$lower_basename_file" == $lower_pattern ]]; then
        return 0
    fi
    
    # Complex patterns with ** and other wildcards
    if [[ "$lower_pattern" == *"**"* ]]; then
        # Convert ** to * for bash globbing
        local glob_pattern="${lower_pattern//\*\*/\*}"
        if [[ "$lower_relative_path" == $glob_pattern ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Function to get file type for syntax highlighting
get_file_type() {
    local file="$1"
    local extension="${file##*.}"
    
    case "${extension,,}" in
        sh|bash) echo "bash" ;;
        py|pyw) echo "python" ;;
        js|mjs|cjs) echo "javascript" ;;
        ts|tsx) echo "typescript" ;;
        jsx) echo "javascript" ;;
        cpp|cxx|cc|c++) echo "cpp" ;;
        hpp|hxx|h++) echo "cpp" ;;
        cs) echo "csharp" ;;
        java) echo "java" ;;
        kt|kts) echo "kotlin" ;;
        go) echo "go" ;;
        rs) echo "rust" ;;
        php|phtml) echo "php" ;;
        rb|rake) echo "ruby" ;;
        swift) echo "swift" ;;
        html|htm) echo "html" ;;
        css) echo "css" ;;
        scss|sass) echo "scss" ;;
        less) echo "less" ;;
        json) echo "json" ;;
        xml|xsl|xsd) echo "xml" ;;
        yml|yaml) echo "yaml" ;;
        toml) echo "toml" ;;
        ini|cfg|conf) echo "ini" ;;
        md|markdown) echo "markdown" ;;
        makefile) echo "makefile" ;;
        dockerfile) echo "dockerfile" ;;
        sql) echo "sql" ;;
        r) echo "r" ;;
        matlab|m) echo "matlab" ;;
        tex) echo "latex" ;;
        *) echo "${extension,,}" ;;
    esac
}

# Function to check file size
check_file_size() {
    local file="$1"
    local max_size_bytes=$((MAX_FILE_SIZE_MB * 1024 * 1024))
    
    if [[ ! -f "$file" ]]; then
        return 1  # File doesn't exist
    fi
    
    local file_size
    file_size=$(wc -c < "$file" 2>/dev/null || echo "0")
    
    if [[ "$file_size" -gt "$max_size_bytes" ]]; then
        return 1  # File too large
    fi
    
    return 0  # Size OK
}

# Function to format file size in human readable format
format_file_size() {
    local bytes="$1"
    
    if [[ "$bytes" -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ "$bytes" -lt $((1024 * 1024)) ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1024 / 1024))MB"
    fi
}

# Function to check dependencies with installation suggestions
check_dependencies() {
    local missing_deps=()
    
    # Check required commands
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Required dependencies missing: ${missing_deps[*]}"
        echo ""
        echo "INSTALLATION SOLUTIONS:"
        echo "======================"
        
        # Detect operating system
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "macOS (using Homebrew):"
            echo "  brew install findutils coreutils tree highlight"
            if command -v brew >/dev/null 2>&1; then
                echo "  Homebrew detected"
            else
                echo "  Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
            echo "Linux/WSL:"
            
            # Detect distribution
            if command -v apt >/dev/null 2>&1; then
                echo "  Debian/Ubuntu based:"
                echo "    sudo apt update && sudo apt install -y findutils coreutils tree highlight"
            fi
            
            if command -v yum >/dev/null 2>&1; then
                echo "  RedHat/CentOS/Fedora based:"
                echo "    sudo yum install -y findutils coreutils tree highlight"
            fi
            
            if command -v dnf >/dev/null 2>&1; then
                echo "  Fedora/RHEL 8+ (DNF):"
                echo "    sudo dnf install -y findutils coreutils tree highlight"
            fi
            
            if command -v pacman >/dev/null 2>&1; then
                echo "  Arch Linux based:"
                echo "    sudo pacman -S findutils coreutils tree highlight"
            fi
            
            if command -v zypper >/dev/null 2>&1; then
                echo "  openSUSE:"
                echo "    sudo zypper install findutils coreutils tree highlight"
            fi
            
        elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
            echo "Windows:"
            echo "  Using Git Bash/MSYS2:"
            echo "    pacman -S findutils coreutils tree highlight"
            echo "  Using WSL (recommended):"
            echo "    wsl --install"
            echo "    # Then follow Linux instructions"
        fi
        
        echo ""
        echo "Alternatively, ensure these commands are in your PATH:"
        for cmd in "${missing_deps[@]}"; do
            echo "  - $cmd"
        done
        echo ""
        
        exit 1
    fi
    
    # Check optional commands
    for cmd in "${OPTIONAL_COMMANDS[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            if [[ "$cmd" != "highlight" ]]; then
                warning "Optional command not available: $cmd (reduced functionality)"
            fi
        fi
    done
    
    # Check tree if needed
    if [[ "$SHOW_TREE" == true ]] && ! command -v tree >/dev/null 2>&1; then
        warning "The 'tree' command is not available. Directory structure will be omitted."
        SHOW_TREE=false
    fi
    
    # Detect highlight and configure colorization
    detect_highlight
    
    # Configure color usage based on flags and availability
    if [[ "$NO_COLOR" == true ]]; then
        USE_COLOR=false
        debug "Colorization disabled by --no-color flag"
    elif [[ "$HIGHLIGHT_AVAILABLE" == true ]]; then
        USE_COLOR=true
        debug "Colorization enabled with highlight"
    else
        USE_COLOR=false
        debug "Colorization not available (highlight not found)"
    fi
    
    log "All dependencies verified successfully"
}

# Function to generate filtered file list for tree
generate_filtered_file_list() {
    local temp_file=$(mktemp)
    
    debug "Generating filtered file list for tree"
    
    # Find files that would be processed
    local files
    files=$(find "$SOURCE_DIR" -type f 2>/dev/null | sort)
    
    while IFS= read -r file; do
        if [[ -f "$file" ]] && [[ -r "$file" ]] && should_include_path "$file"; then
            echo "${file#$SOURCE_DIR/}" >> "$temp_file"
        fi
    done <<< "$files"
    
    echo "$temp_file"
}

# Function to generate filtered directory structure
generate_tree_structure() {
    local output_file="$1"
    
    if [[ "$SHOW_TREE" != true ]]; then
        return
    fi
    
    log "Generating filtered directory structure..."
    
    echo "\`\`\`" >> "$output_file"
    
    if command -v tree >/dev/null 2>&1; then
        # Generate list of files to be processed
        local filtered_files
        filtered_files=$(generate_filtered_file_list)
        
        if [[ -s "$filtered_files" ]]; then
            echo "Structure of files to be processed:" >> "$output_file"
            echo "" >> "$output_file"
            
            # Use tree with filtered list
            (cd "$SOURCE_DIR" && tree -a --fromfile "$filtered_files") >> "$output_file" 2>/dev/null || {
                echo "Files to process:" >> "$output_file"
                cat "$filtered_files" | sed 's/^/  /' >> "$output_file"
            }
        else
            echo "No files to process with current filters." >> "$output_file"
        fi
        
        rm -f "$filtered_files"
    else
        echo "Directory structure from: $SOURCE_DIR" >> "$output_file"
        find "$SOURCE_DIR" -type d | head -20 | sed 's/^/  /' >> "$output_file"
        echo "  ..." >> "$output_file"
    fi
    
    echo "\`\`\`" >> "$output_file"
    echo "" >> "$output_file"
}

# Main function to process files
process_files() {
    local output_file="$1"
    
    log "Starting file processing from: $SOURCE_DIR"
    
    # Reset counters
    TOTAL_FILES_FOUND=0
    TOTAL_FILES_PROCESSED=0
    TOTAL_FILES_EXCLUDED=0
    TOTAL_BINARY_FILES=0
    TOTAL_TEXT_FILES=0
    TOTAL_LINES_PROCESSED=0
    TOTAL_FILES_TOO_LARGE=0
    
    # Find all files
    local files
    files=$(find "$SOURCE_DIR" -type f 2>/dev/null | sort)
    
    if [[ -z "$files" ]]; then
        warning "No files found in directory: $SOURCE_DIR"
        return
    fi
    
    # Process each file
    while IFS= read -r file; do
        TOTAL_FILES_FOUND=$((TOTAL_FILES_FOUND + 1))
        
        # Verify file exists and is readable
        if [[ ! -f "$file" ]] || [[ ! -r "$file" ]]; then
            debug "Cannot read file: $file"
            TOTAL_FILES_EXCLUDED=$((TOTAL_FILES_EXCLUDED + 1))
            continue
        fi
        
        # Check file size
        if ! check_file_size "$file"; then
            local file_size_bytes
            file_size_bytes=$(wc -c < "$file" 2>/dev/null || echo "0")
            local file_size_formatted
            file_size_formatted=$(format_file_size "$file_size_bytes")
            
            debug "Large file excluded: $file ($file_size_formatted > ${MAX_FILE_SIZE_MB}MB)"
            TOTAL_FILES_TOO_LARGE=$((TOTAL_FILES_TOO_LARGE + 1))
            TOTAL_FILES_EXCLUDED=$((TOTAL_FILES_EXCLUDED + 1))
            continue
        fi
        
        # Apply filter system
        if ! should_include_path "$file"; then
            debug "File excluded by filters: $file"
            TOTAL_FILES_EXCLUDED=$((TOTAL_FILES_EXCLUDED + 1))
            continue
        fi
        
        # Detect file type
        local file_type_detected
        file_type_detected=$(detect_file_type "$file")
        
        # Get file information
        local lines=0
        if [[ "$file_type_detected" == "text" ]]; then
            lines=$(wc -l < "$file" 2>/dev/null || echo "0")
            TOTAL_TEXT_FILES=$((TOTAL_TEXT_FILES + 1))
            TOTAL_LINES_PROCESSED=$((TOTAL_LINES_PROCESSED + lines))
        else
            TOTAL_BINARY_FILES=$((TOTAL_BINARY_FILES + 1))
        fi
        
        # Get relative path
        local relative_path="${file#$SOURCE_DIR/}"
        [[ "$relative_path" == "$file" ]] && relative_path="$file"
        
        log "Processing: $relative_path ($file_type_detected, $lines lines)"
        
        # In dry-run mode, only show information
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY RUN] $relative_path ($file_type_detected, $lines lines)"
            TOTAL_FILES_PROCESSED=$((TOTAL_FILES_PROCESSED + 1))
            continue
        fi
        
        # Write file information
        if [[ "$file_type_detected" == "text" ]]; then
            # Text file
            local file_syntax
            file_syntax=$(get_file_type "$file")
            local highlight_syntax
            highlight_syntax=$(get_highlight_syntax "$file")
            
            echo "FILE NAME: \`$relative_path\` ($lines Lines)" >> "$output_file"
            echo "\`\`\`$file_syntax" >> "$output_file"
            
            # Read file content
            local file_content
            if [[ "$lines" -gt "$MAX_LINES" ]]; then
                file_content=$(head -n "$MAX_LINES" "$file")
                local truncation_note="... (file truncated - showing first $MAX_LINES lines of $lines)"
            else
                file_content=$(cat "$file")
                local truncation_note=""
            fi
            
            # Write to file (always plain text)
            echo "$file_content" >> "$output_file"
            if [[ -n "$truncation_note" ]]; then
                echo "" >> "$output_file"
                echo "$truncation_note" >> "$output_file"
            fi
            echo "\`\`\`" >> "$output_file"
            
            # Show in terminal (with colors if available)
            if [[ "$NO_TTY_OUTPUT" != true ]] && [[ "$DRY_RUN" != true ]]; then
                echo ""
                echo -e "${ANSI_CYAN}${ANSI_BOLD}FILE: $relative_path ($lines lines)${ANSI_RESET}"
                
                if [[ "$USE_COLOR" == true ]] && [[ -n "$highlight_syntax" ]]; then
                    # Show with colors
                    colorize_code "$file_content" "$highlight_syntax"
                else
                    # Show without colors
                    echo "$file_content"
                fi
                
                if [[ -n "$truncation_note" ]]; then
                    echo ""
                    echo -e "${ANSI_YELLOW}$truncation_note${ANSI_RESET}"
                fi
                echo ""
            fi
            
        else
            # Binary file
            local binary_info
            binary_info=$(get_binary_info "$file")
            
            echo "FILE NAME: \`$relative_path\` (Binary File)" >> "$output_file"
            echo "\`\`\`" >> "$output_file"
            echo "$binary_info" >> "$output_file"
            
            if [[ "$SHOW_BINARY_INFO" == true ]]; then
                echo "" >> "$output_file"
                echo "Additional information:" >> "$output_file"
                if command -v file >/dev/null 2>&1; then
                    file "$file" | cut -d: -f2- | sed 's/^[[:space:]]*//' >> "$output_file"
                fi
            fi
            
            echo "\`\`\`" >> "$output_file"
            
            # Show in terminal
            if [[ "$NO_TTY_OUTPUT" != true ]] && [[ "$DRY_RUN" != true ]]; then
                echo ""
                echo -e "${ANSI_MAGENTA}${ANSI_BOLD}BINARY FILE: $relative_path${ANSI_RESET}"
                echo -e "${ANSI_MAGENTA}$binary_info${ANSI_RESET}"
                echo ""
            fi
        fi
        
        echo "" >> "$output_file"
        
        TOTAL_FILES_PROCESSED=$((TOTAL_FILES_PROCESSED + 1))
        
    done <<< "$files"
    
    # Write detailed final summary
    {
        echo "=== DETAILED SUMMARY ==="
        echo "Source directory: $SOURCE_DIR"
        echo "Files found: $TOTAL_FILES_FOUND"
        echo "Files processed: $TOTAL_FILES_PROCESSED"
        echo "Files excluded: $TOTAL_FILES_EXCLUDED"
        echo "Files too large: $TOTAL_FILES_TOO_LARGE (limit: ${MAX_FILE_SIZE_MB}MB)"
        echo "Text files: $TOTAL_TEXT_FILES"
        echo "Binary files: $TOTAL_BINARY_FILES"
        echo "Total text lines: $TOTAL_LINES_PROCESSED"
        echo "Line limit per file: $MAX_LINES"
        echo ""
        echo "Applied profiles: ${APPLIED_PROFILES[*]:-none}"
        echo "Filter rules applied: ${#FILTER_RULES[@]}"
        echo "Maximum lines per file: $MAX_LINES"
        echo "Maximum size per file: ${MAX_FILE_SIZE_MB}MB"
        echo "Binary file detection: $BINARY_DETECTION"
        echo "Colorization enabled: $USE_COLOR"
        echo ""
        echo "Generated on: $(date)"
        echo "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
        echo "Author: $SCRIPT_AUTHOR"
    } >> "$output_file"
    
    echo ""
    info "Processing completed:"
    info "  Files found: $TOTAL_FILES_FOUND"
    info "  Files processed: $TOTAL_FILES_PROCESSED ($TOTAL_TEXT_FILES text, $TOTAL_BINARY_FILES binary)"
    info "  Files excluded: $TOTAL_FILES_EXCLUDED"
    if [[ "$TOTAL_FILES_TOO_LARGE" -gt 0 ]]; then
        info "  Files too large: $TOTAL_FILES_TOO_LARGE (limit: ${MAX_FILE_SIZE_MB}MB)"
    fi
    info "  Total lines: $TOTAL_LINES_PROCESSED"
    
    # Show highlight suggestion if appropriate
    show_highlight_suggestion
}

# Function to validate that a file is plain text
is_plain_text_file() {
    local file="$1"
    
    # Check if file exists and is readable
    if [[ ! -f "$file" ]] || [[ ! -r "$file" ]]; then
        return 1
    fi
    
    # Check file size (prevent reading huge files)
    local file_size
    file_size=$(wc -c < "$file" 2>/dev/null || echo "0")
    if [[ "$file_size" -gt 1048576 ]]; then  # 1MB limit for config files
        debug "Config file too large: $file ($file_size bytes)"
        return 1
    fi
    
    # Use file command to check MIME type if available
    if command -v file >/dev/null 2>&1; then
        local mime_type
        mime_type=$(file -b --mime-type "$file" 2>/dev/null)
        case "$mime_type" in
            text/*|application/json|application/xml|application/x-empty)
                return 0
                ;;
            *)
                debug "Config file not plain text: $file (MIME: $mime_type)"
                return 1
                ;;
        esac
    fi
    
    # Fallback: check for null bytes (binary indicator)
    if head -c 8000 "$file" | grep -q '\0'; then
        debug "Config file contains null bytes: $file"
        return 1
    fi
    
    return 0
}

# Function to validate supported flags
is_supported_flag() {
    local flag="$1"
    
    # List of all supported flags (without values)
    local supported_flags=(
        "--profile" "-p"
        "--include" "--exclude"
        "--include-sensitive" "--exclude-sensitive"
        "--include-hidden" "--exclude-hidden"
        "--source-dir" "-s"
        "--output-file" "-o"
        "--max-lines" "-l" "--max-size"
        "--no-color" "--no-colour"
        "--no-output-file" "--no-tty-output"
        "--no-tree" "--no-binary-detection" "--show-binary-info"
        "--dry-run" "--verbose"
        "--help" "-h" "--usage" "--tldr" "--tl-dr"
        "--version" "--licence" "--license"
        "--show-profiles" "--config"
    )
    
    # Check if flag starts with any supported flag
    for supported_flag in "${supported_flags[@]}"; do
        if [[ "$flag" == "$supported_flag" ]] || [[ "$flag" == "$supported_flag="* ]]; then
            return 0
        fi
    done
    
    return 1
}

# Function to load configuration from file with validation
load_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        error "Configuration file not found: $config_file"
    fi
    
    # Validate that file is plain text
    if ! is_plain_text_file "$config_file"; then
        error "Configuration file is not plain text or is corrupted: $config_file"
    fi
    
    log "Loading configuration from: $config_file"
    
    local line_number=0
    local config_flags=()
    
    # Read file line by line
    while IFS= read -r line; do
        line_number=$((line_number + 1))
        
        # Skip empty lines and comments
        line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue
        
        # Validate that line looks like a flag
        if [[ ! "$line" =~ ^-- ]]; then
            error "Invalid configuration at line $line_number: '$line' (must start with --)"
        fi
        
        # Extract flag name (before = if present)
        local flag_name="${line%%=*}"
        
        # Validate flag is supported
        if ! is_supported_flag "$flag_name"; then
            error "Unsupported flag in configuration at line $line_number: '$flag_name'"
        fi
        
        config_flags+=("$line")
        debug "Config flag loaded: $line"
    done < "$config_file"
    
    # Apply config flags by adding them to the argument list
    CONFIG_FLAGS=("${config_flags[@]}")
    CONFIG_FILE_PROVIDED=true
    
    log "Successfully loaded ${#config_flags[@]} configuration flags from $config_file"
}

# Function to check if any priority flag is present
check_priority_flags() {
    local args=("$@")
    
    # Check for help flags (highest priority)
    for arg in "${args[@]}"; do
        case "$arg" in
            -h|--help|--usage)
                SHOW_HELP=true
                return 0
                ;;
        esac
    done
    
    # Check for TLDR flags (second priority)
    for arg in "${args[@]}"; do
        case "$arg" in
            --tldr|--tl-dr)
                SHOW_TLDR=true
                return 0
                ;;
        esac
    done
    
    # Check for version flags (third priority)
    for arg in "${args[@]}"; do
        case "$arg" in
            --version)
                SHOW_VERSION=true
                return 0
                ;;
        esac
    done
    
    # Check for license flags
    for arg in "${args[@]}"; do
        case "$arg" in
            --licence|--license)
                SHOW_LICENSE=true
                return 0
                ;;
        esac
    done
    
    return 1
}

# =================== MAIN FUNCTION ===================

main() {
    local profiles=()
    
    # Configure signal handling
    setup_signal_handlers
    
    # Initialize default values
    SOURCE_DIR=$(auto_detect_source_dir)
    OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
    MAX_LINES="$DEFAULT_MAX_LINES"
    MAX_FILE_SIZE_MB="$DEFAULT_MAX_FILE_SIZE_MB"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --show-profiles)
                show_profiles
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -p|--profile)
                profiles+=("$2")
                shift 2
                ;;
            --profile=*)
                profiles+=("${1#*=}")
                shift
                ;;
            -s|--source-dir)
                SOURCE_DIR="$2"
                shift 2
                ;;
            --source-dir=*)
                SOURCE_DIR="${1#*=}"
                shift
                ;;
            -o|--output-file)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --output-file=*)
                OUTPUT_FILE="${1#*=}"
                shift
                ;;
            -l|--max-lines)
                MAX_LINES="$2"
                shift 2
                ;;
            --max-lines=*)
                MAX_LINES="${1#*=}"
                shift
                ;;
            --max-size)
                MAX_FILE_SIZE_MB="$2"
                shift 2
                ;;
            --max-size=*)
                MAX_FILE_SIZE_MB="${1#*=}"
                shift
                ;;
            --include)
                FILTER_RULES+=("include:$2")
                debug "Manual rule added: include:$2"
                shift 2
                ;;
            --include=*)
                local pattern="${1#*=}"
                FILTER_RULES+=("include:$pattern")
                debug "Manual rule added: include:$pattern"
                shift
                ;;
            --exclude)
                FILTER_RULES+=("exclude:$2")
                debug "Manual rule added: exclude:$2"
                shift 2
                ;;
            --exclude=*)
                local pattern="${1#*=}"
                FILTER_RULES+=("exclude:$pattern")
                debug "Manual rule added: exclude:$pattern"
                shift
                ;;
            --include-sensitive)
                INCLUDE_SENSITIVE=true
                shift
                ;;
            --exclude-sensitive)
                EXCLUDE_SENSITIVE=true
                shift
                ;;
            --include-hidden)
                INCLUDE_HIDDEN=true
                shift
                ;;
            --exclude-hidden)
                EXCLUDE_HIDDEN=true
                shift
                ;;
            --no-output-file)
                NO_OUTPUT_FILE=true
                shift
                ;;
            --no-tty-output)
                NO_TTY_OUTPUT=true
                shift
                ;;
            --no-tree)
                SHOW_TREE=false
                shift
                ;;
            --no-binary-detection)
                BINARY_DETECTION=false
                shift
                ;;
            --show-binary-info)
                SHOW_BINARY_INFO=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-color|--no-colour)
                NO_COLOR=true
                shift
                ;;
            --config=*)
                load_config_file "${1#*=}"
                shift
                ;;
            --version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                echo "Author: $SCRIPT_AUTHOR"
                echo "License: $SCRIPT_LICENSE"
                echo "Repository: $SCRIPT_REPOSITORY"
                exit 0
                ;;
            --license|--licence)
                cat << EOF
MIT License

Copyright (c) 2024 Luis González

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
                exit 0
                ;;
            -*)
                error "Unknown option: $1. Use -h for help."
                ;;
            *)
                # Positional argument - output directory
                local output_dir="$1"
                [[ "$output_dir" != */ ]] && output_dir="${output_dir}/"
                OUTPUT_FILE="${output_dir}$(basename "$OUTPUT_FILE")"
                shift
                ;;
        esac
    done
    
    # Handle custom output files
    if [[ -n "$CUSTOM_OUTPUT_FILE" ]]; then
        OUTPUT_FILE="$CUSTOM_OUTPUT_FILE"
    fi
    
    # Load profiles (this must go after argument parsing)
    if [[ ${#profiles[@]} -eq 0 ]]; then
        # Use default profile if nothing specified
        profiles=("default")
    fi
    load_profiles "${profiles[@]}"
    
    # Apply sensitive file rules (must go at the end to have priority)
    apply_sensitive_file_rules
    
    # Apply hidden file rules
    apply_hidden_file_rules
    
    # Validate numeric values
    if ! [[ "$MAX_LINES" =~ ^[0-9]+$ ]] || [[ "$MAX_LINES" -le 0 ]]; then
        error "Invalid value for --max-lines: $MAX_LINES (must be a positive number)"
    fi
    
    if ! [[ "$MAX_FILE_SIZE_MB" =~ ^[0-9]+$ ]] || [[ "$MAX_FILE_SIZE_MB" -le 0 ]]; then
        error "Invalid value for --max-size: $MAX_FILE_SIZE_MB (must be a positive number in MB)"
    fi
    
    # Validate configuration
    if [[ ! -d "$SOURCE_DIR" ]]; then
        error "Source directory does not exist: $SOURCE_DIR"
    fi
    
    # Check dependencies
    check_dependencies
    
    # If it's dry run, don't create files
    if [[ "$DRY_RUN" != true ]] && [[ "$NO_OUTPUT_FILE" != true ]]; then
        # Create output directory if it doesn't exist
        local output_dir
        output_dir=$(dirname "$OUTPUT_FILE")
        if [[ ! -d "$output_dir" ]]; then
            log "Creating output directory: $output_dir"
            mkdir -p "$output_dir" || error "Could not create directory: $output_dir"
        fi
    fi
    
    # Show configuration if in verbose mode
    if [[ "$VERBOSE" == true ]]; then
        echo ""
        echo "=== DETAILED CONFIGURATION ==="
        echo "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
        echo "Source directory: $SOURCE_DIR"
        echo "Output file: $OUTPUT_FILE"
        echo "Maximum lines: $MAX_LINES"
        echo "Maximum file size: ${MAX_FILE_SIZE_MB}MB"
        echo "Show tree: $SHOW_TREE"
        echo "Binary detection: $BINARY_DETECTION"
        echo "Show binary info: $SHOW_BINARY_INFO"
        echo "Dry run mode: $DRY_RUN"
        echo "No output file: $NO_OUTPUT_FILE"
        echo "No TTY output: $NO_TTY_OUTPUT"
        echo "Include sensitive: $INCLUDE_SENSITIVE"
        echo "Exclude sensitive: $EXCLUDE_SENSITIVE"
        echo "Include hidden: $INCLUDE_HIDDEN"
        echo "Exclude hidden: $EXCLUDE_HIDDEN"
        echo "Use color: $USE_COLOR"
        echo ""
        echo "Applied profiles (${#profiles[@]}): ${profiles[*]:-none}"
        echo "Resolved profiles: ${APPLIED_PROFILES[*]:-none}"
        echo ""
        echo "=== FILTER RULES (${#FILTER_RULES[@]}) ==="
        for i in "${!FILTER_RULES[@]}"; do
            echo "  $((i+1)). ${FILTER_RULES[$i]}"
        done
        echo "==============================="
        echo ""
    fi
    
    # Clear screen and start processing
    clear
    
    echo "Code Documentation Generator v$SCRIPT_VERSION"
    echo "Source directory: $SOURCE_DIR"
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY RUN MODE - Only showing what would be processed:"
    elif [[ "$NO_OUTPUT_FILE" == true ]]; then
        echo "OUTPUT: Terminal only (no file will be generated)"
    else
        echo "Output file: $OUTPUT_FILE"
    fi
    echo "Profiles: ${APPLIED_PROFILES[*]:-general}"
    echo "Filter rules: ${#FILTER_RULES[@]}"
    echo "Binary detection: $BINARY_DETECTION"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "Files that would be processed:"
        process_files "/dev/null"
    elif [[ "$NO_OUTPUT_FILE" == true ]]; then
        echo "Processing files (terminal output only):"
        process_files "/dev/null"
    else
        # Create output file
        : > "$OUTPUT_FILE" # Create empty file
        
        # Generate header
        {
            echo "# CODE DOCUMENTATION"
            echo ""
            echo "Generated automatically on $(date)"
            echo "Source directory: $SOURCE_DIR"
            echo "Applied profiles: ${APPLIED_PROFILES[*]:-general}"
            echo "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
            echo ""
        } >> "$OUTPUT_FILE"
        
        # Generate directory structure
        generate_tree_structure "$OUTPUT_FILE"
        
        # Process files
        process_files "$OUTPUT_FILE"
        
        echo ""
        echo "File generated successfully: $OUTPUT_FILE"
        echo "Open the file to view the complete documentation"
    fi
}

# =================== ENTRY POINT ===================

# Verify that it's not being executed with source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
else
    error "This script must be executed directly, not with 'source'"
fi
