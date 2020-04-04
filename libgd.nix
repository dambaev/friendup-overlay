{ stdenv, fetchzip, gcc, coreutils, bash, cmake
, zlib, fontconfig, libjpeg, libimagequant, libXpm, libtiff, libwebp
}:
let
  version = "2.3.0";
in
stdenv.mkDerivation {
  name = "libgd-${version}";

  src = fetchzip {
    url = "https://github.com/libgd/libgd/archive/b079fa06223c3ab862c8f0eea58a968727971988.zip";
    sha256 = "0ay4hpxb4h35vdjz1fkg1q56kij9xk0gdfln5girh5rz9196v913";
    };

  buildInputs = [
    cmake zlib fontconfig libjpeg libimagequant libXpm libtiff libwebp
    ];

}