{ stdenv, fetchzip, gcc, coreutils, bash
, openssl, mysql, valgrind
, libaio, php73, libuv, libssh_0_7
, libgd, file, libpng, libxml2, libjpeg, libgcrypt, samba, cmake, sqlite, rsync
, libmysqlclient
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
    openssl mysql valgrind
    libmysqlclient
    libaio php73 libuv libssh_0_7
    libgd file libpng libxml2 libjpeg libgcrypt samba cmake sqlite rsync
    ];
  NIX_CFLAGS_COMPILE = [
    "-I${libxml2.dev}/include/libxml2"
    "-I${samba.dev}/include/samba-4.0"
  ];
  buildFlags = [
    "OPENSSL_INTERNAL=0"
  ];
  makeFlags = [
    "FRIEND_PATH=$(out)"
  ];
  dontUseCmakeConfigure = true;
  patches = [ ];
  preBuild = ''
    # it turned out, that we have to run setup before making
    make setup FRIEND_PATH=$out
    cp -r docs/ $out/
    cp -r scripts $out/doc
    cp -r db $out/
    '';
}