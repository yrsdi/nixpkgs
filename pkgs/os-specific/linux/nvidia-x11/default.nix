{ stdenv, fetchurl, kernel ? null, xlibs, zlib, perl
, gtk, atk, pango, glib, gdk_pixbuf, cairo
, # Whether to build the libraries only (i.e. not the kernel module or
  # nvidia-settings).  Used to support 32-bit binaries on 64-bit
  # Linux.
  libsOnly ? false
}:

with stdenv.lib;

assert (!libsOnly) -> kernel != null;

let

  # TODO: Remove the use of the beta driver for kernel 4.0 in
  # nixos/modules/hardware/video/nvidia.nix when this driver supports
  # kernel 4.0
  versionNumber = "346.47";

  # Policy: use the highest stable version as the default (on our master).
  inherit (stdenv.lib) makeLibraryPath;

in

stdenv.mkDerivation {
  name = "nvidia-x11-${versionNumber}${optionalString (!libsOnly) "-${kernel.version}"}";

  builder = ./builder.sh;

  src =
    if stdenv.system == "i686-linux" then
      fetchurl {
        url = "http://us.download.nvidia.com/XFree86/Linux-x86/${versionNumber}/NVIDIA-Linux-x86-${versionNumber}.run";
        sha256 = "0vkayz6nhw00kn2nvxvr9hsh4sa555nbbr9swlx5x1frziym48dv";
      }
    else if stdenv.system == "x86_64-linux" then
      fetchurl {
        url = "http://us.download.nvidia.com/XFree86/Linux-x86_64/${versionNumber}/NVIDIA-Linux-x86_64-${versionNumber}-no-compat32.run";
        sha256 = "0xqnjs54i281pnkky7dnz4n7jcn2vqjba0kra8da1wnyklm6gdni";
      }
    else throw "nvidia-x11 does not support platform ${stdenv.system}";

  inherit versionNumber libsOnly;

  kernel = if libsOnly then null else kernel.dev;

  dontStrip = true;

  glPath      = makeLibraryPath [xlibs.libXext xlibs.libX11 xlibs.libXrandr];
  cudaPath    = makeLibraryPath [zlib stdenv.cc.cc];
  openclPath  = makeLibraryPath [zlib];
  allLibPath  = makeLibraryPath [xlibs.libXext xlibs.libX11 xlibs.libXrandr zlib stdenv.cc.cc];

  gtkPath = optionalString (!libsOnly) (makeLibraryPath
    [ gtk atk pango glib gdk_pixbuf cairo ] );
  programPath = makeLibraryPath [ xlibs.libXv ];

  buildInputs = [ perl ];

  meta = with stdenv.lib.meta; {
    homepage = http://www.nvidia.com/object/unix.html;
    description = "X.org driver and kernel module for NVIDIA graphics cards";
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux;
    maintainers = [ maintainers.vcunat ];
  };
}
