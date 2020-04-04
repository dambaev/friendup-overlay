{ stdenv, fetchzip, gcc, coreutils, bash
, openssl, mysql, valgrind, libssh2_1, libaio, php73, libwebsockets, libuv, libssh_0_7
, libgd, file, libpng, libxml2, libjpeg, libgcrypt, samba, cmake
}:
let
  version = "1.2.3";
in
stdenv.mkDerivation {
  name = "friendup-${version}";

  src = fetchzip {
    url = "https://github.com/FriendUPCloud/friendup/archive/3e4773a2ca2f433584a93cdd15f221c407d1f2dd.zip";
    sha256 = "0gjnxhmiknikrz9qd2l3r11nkq08mgrc2i5ri6r4psyhxsa4zscx";
    };

  buildInputs = [
    openssl mysql valgrind libssh2_1 libaio php73 libwebsockets libuv libssh_0_7
    libgd file libpng libxml2 libjpeg libgcrypt samba cmake
    ];
  NIX_CFLAGS_COMPILE = [
    "-I${libxml2.dev}/include/libxml2"
    "-I${samba.dev}/include/samba-4.0"
  ];
  buildFlags = [ "OPENSSL_INTERNAL=0" ];
  dontUseCmakeConfigure = true;
  preBuild = ''
    make setup
#   mkdir core/obj
#   mkdir core/bin
#   mkdir -p core/system/bin/emod/
#   mkdir -p core/system/bin/fsys
#   mkdir -p core/system/bin/loggers
#   mkdir -p core/system/bin/services
#   mkdir -p libs-ext/libwebsockets/build/lib/
#   mkdir -p libs-ext/libssh2/build/src/
#   ln -s ${libwebsockets}/lib/libwebsockets.a libs-ext/libwebsockets/build/lib
#   ln -s ${libssh2_1}/lib/libssh2.a libs-ext/libssh2/build/src/
    '';
}