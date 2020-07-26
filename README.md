# archwrap

A collection of POSIX shell scripts to invoke archiver programs

           (s)tar/gzip/bzip2/xz/zip/7z/lzma/lrzip/arj/zoo/brotli/zopfli/zstd

Author: Martin Väth <martin at mvath.de>

This project is under the BSD license 2.0 (“3-clause BSD license”).
SPDX-License-Identifier: BSD-3-Clause

These are some POSIX shell scripts which form an interface to
various archiver programs like
- __tar__/__star__
- __brotli__
- __zstd__
- __gzip__/__zopfli__
- __bzip2__
- __xz__/__lzma__
- __zip__
- __7z__
- __lrzip__
- __arj__
- __zoo__

For unpacking even some more formats are supported (if binaries are available).

It is in particular possible to invoke all archivers (keeping only the "best"
result), to repack archives, pack to remote hosts etc.
Note that also less popular archivers are supported.

A lot of options control the details; since the scripts are mainly written
for myself, they are not too well documented.
Use option `-h` to obtain help.

### Requirements

You need `push.sh` from https://github.com/vaeth/push (v2.0 or newer)
in your `$PATH`.

### Installation

For installation. just put the content of `bin` somewhere in your `$PATH`.
Also put the files of the subdirectory `zsh` into your zsh's `$fpath` to obtain
__zsh completion__ support. (If you do not have root access, you can add the
corresponding directory with `fpath+=("...")` before you
call `compdef` from your __zsh__ initialization files).

If you do have root access it is recommended to put the files `archwrap.sh`
not into the `$PATH` (typically `/usr/bin`) but instead into
`/usr/share/archwrap/` and to modify the line

`. archwrap.sh`

in the binaries into

`. /usr/share/archwrap/archwrap.sh`

If you do not want to put the symlinks into your path, you can
source the `archwrap_alias` file (in a shell understanding the alias command)
to obtain a similar effect in an interactive shell.

For installation under Gentoo, there is an ebuild in the `mv` repository
(available by `app-select/eselect-repository` or `app-portage/layman`).

### Examples

A standard usage is as follows

1.
   * `ppd` _directory_(s) / `pd` _directory_(s)

      Pack _directory_(s) with all subdirectories with all archiver programs
      (each directory is put into a separate archive) and keep
      only the "best" version. Lots of options control the details:
      Invoke `pd`/`ppd` without any arguments for a list of them.
      `ppd` (in contrast to `pd`) only attempts the most popular archivers.

   * `tgzd`  _directory_(s) (actually uses __zopfli__ unless `-Q` is specified)
   * `tbrd`  _directory_(s)
   * `tbzd`  _directory_(s)
   * `tlzd`  _directory_(s)
   * `t7zd`  _directory_(s)
   * `tlrd`  _directory_(s)
   * `txzd`  _directory_(s)
   * `tzsd`  _directory_(s)
   * `tard`  _directory_(s)
   * `zipd`  _directory_(s)
   * `gzipd` _directory_(s) (uses `.tar.gz`   extension)
   * `brd`   _directory_(s) (uses `.tar.br`   extension)
   * `bzipd` _directory_(s) (uses `.tar.bz2`  extension)
   * `lzmad` _directory_(s) (uses `.tar.lzma` extension)
   * `zstdd` _directory_(s) (uses `.tar.zst`  extension)
   * `xzd`   _directory_(s) (uses `.tar.xz`   extension)
   * `7zd`   _directory_(s) (uses `.tar.7z`   extension)
   * `lrzd`  _directory_(s) (uses `.tar.lrz`  extension)

     Similarly as `ppd` but invokes only the corresponding archiver program.
     Different options are available, depending on the archiver program.

2. * `ud` _ARCHIVE_(s)
      Generate the directory(s) _ARCHIVE_ and unpack _ARCHIVE_`.`???
      into it.
      This works for all archive formats (with proper name extension).
      Invoke `ud` without any arguments for a complete list of options.

   * `uv` _ARCHIVE_(s) or `uv -v` _ARCHIVE_(s)

      List content of _ARCHIVE_(s) (briefly or verbosely, respectively).
      This works for all supported archive formats whose archivers have
      corresponding options.

   *  `u -t` _ARCHIVE_(s)

      Test integrity of _ARCHIVE_(s).
      This works for all supported archive formats whose archivers have
      corresponding options.

3. `2pd` _ARCHIVE_(s) or `2ppd` _ARCHIVE_(s)
   First unpack _ARCHIVE_ and then pack it again with all/popular archivers,
   keeping only the "best" version.
   Invoke `2pd` without any arguments for a complete list of options.

4. `tbzd -C -R - / | sshcat user@host:backup.tar.bz2`

   Make a compressed backup of the whole filesystem to a file on a remote host.

