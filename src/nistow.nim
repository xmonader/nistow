# nistow
# Copyright xmonader
# Stow alternative in nim to manage dotfiles.


import os, strutils, strformat, parseopt2
type
  LinkInfo = tuple[original:string, dest:string] 

proc getLinkableFiles*(appPath: string, dest: string=expandTilde("~")): seq[LinkInfo] =

    # collects the linkable files in a certain app.

    # appPath: application's dotfiles directory
    #     we expect dir to have the hierarchy.
    #     i3
    #     `-- .config
    #         `-- i3
    #         `-- config

    # dest: destination of the link files : default is the home of user.

  var appPath = expandTilde(appPath)
  if not dirExists(appPath):
    raise newException(ValueError, fmt("App path {appPath} doesn't exist."))
  var linkables = newSeq[LinkInfo]()
  for filepath in walkDirRec(appPath, yieldFilter={pcFile}):
    let linkpath =  filepath.replace(appPath, dest)
        # remove leading /
    var linkInfo : LinkInfo = (original:filepath, dest:linkpath)
    linkables.add(linkInfo)
  return linkables

proc stow(linkables: seq[LinkInfo], simulate: bool=true, verbose: bool=true, force: bool=false) = 
    # Creates symoblic links and related directories

    # linkables is a list of tuples (filepath, linkpath) : List[Tuple[file_path, link_path]]
    # simulate does simulation with no effect on the filesystem: bool
    # verbose shows log messages: bool

  for linkinfo in linkables:
    let (filepath, linkpath) = linkinfo
    if verbose:
      echo(fmt("Will link {filepath} -> {linkpath}"))

    if not simulate:
      createDir(parentDir(linkpath))
      if not fileExists(linkpath):
        createSymlink(filepath, linkpath)
      else:
        if force:
          removeFile(linkpath)
          createSymlink(filepath, linkpath)
        else:
          if verbose:
            echo(fmt("Skipping linking {filepath} -> {linkpath}"))


proc writeHelp() = 
    echo """
Stow 0.1.0 (Manage your dotfiles easily)

Allowed arguments:
    -h | --help     : show help
    -v | --version  : show version
    --verbose       : verbose messages
    -s | --simulate : simulate stow operation
    -f | --force    : override old links
    -a | --app      : application path to stow
    -d | --dest     : destination to stow to

    """
proc writeVersion() =
    echo "Stow version 0.1.0"


proc cli*() =
  var 
    simulate, verbose, force: bool = false
    app, dest: string = ""
  
  if paramCount() == 0:
    writeHelp()
    quit(0)
  
  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
        case key
        of "help", "h": 
            writeHelp()
            quit()
        of "version", "v":
            writeVersion()
            quit()
        of "simulate", "s": simulate = true
        of "verbose": verbose = true
        of "force", "f": force = true
        of "app", "a": app = val
        of "dest", "d": dest = val 
        else:
          discard
    else:
      discard 

  if dest.isNilOrEmpty():
    dest = getHomeDir()
  if app.isNilOrEmpty():
    echo "Make sure to provide --app flags"
    quit(1)
  try:
    stow(getLinkableFiles(appPath=app, dest=dest), simulate=simulate, verbose=verbose, force=force)
  except ValueError:
    echo "Error happened: " & getCurrentExceptionMsg()

when isMainModule:
  cli()