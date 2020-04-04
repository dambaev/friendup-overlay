self: super:
{
  friendup = super.callPackage ./friendup.nix {};
  libgd = super.callPackage ./libgd.nix {};
  # nixos uses libssh-0.8.7, which does not uses libssh_threading.so anymore, so
  # we need to port older version
  libssh2_1 = super.libssh2.overrideAttrs (old: old // {
    # friendup wants to link to libssh statically
    dontDisableStatic = true;
  });
  libssh_0_7 =
    let
      libssh_version = "0.7.7"; # latest libssh 0.7 with libssh_threading
    in
      super.libssh.overrideAttrs (old: old // {
        name = "libssh-${libssh_version}";
        src = super.fetchurl {
          url = "https://git.libssh.org/projects/libssh.git/snapshot/libssh-${libssh_version}.tar.xz";
          sha256 = "0gsp0m0dnzd1q56j5iy1m878v0qp1aqmv0ndk6r0kihf08j4fgzs";
        };
      });
}
