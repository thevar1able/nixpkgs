{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libsodium,
  asciidoc,
  xmlto,
  enableDrafts ? false,
  # for passthru.tests
  azmq,
  cppzmq,
  czmq,
  zmqpp,
  ffmpeg,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zeromq";
  version = "4.3.5";

  src = fetchFromGitHub {
    owner = "zeromq";
    repo = "libzmq";
    rev = "59c91227b46b60b7f965816544b25fe0a3cc8bbe";
    hash = "sha256-XboVI5CzXDOqnCv0pnEJaUB3q8cNKqJLudkPynkSBi8=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    asciidoc
    xmlto
  ];

  buildInputs = [ libsodium ];

  doCheck = false; # fails all the tests (ctest)

  cmakeFlags = [
    (lib.cmakeBool "WITH_LIBSODIUM" true)
    (lib.cmakeBool "ENABLE_CURVE" true)
    (lib.cmakeBool "ENABLE_DRAFTS" enableDrafts)
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace '$'{prefix}/'$'{CMAKE_INSTALL_LIBDIR} '$'{CMAKE_INSTALL_FULL_LIBDIR} \
      --replace '$'{prefix}/'$'{CMAKE_INSTALL_INCLUDEDIR} '$'{CMAKE_INSTALL_FULL_INCLUDEDIR}
  '';

  postBuild = ''
    # From https://gitlab.archlinux.org/archlinux/packaging/packages/zeromq/-/blob/main/PKGBUILD
    # man pages aren't created when using cmake
    # https://github.com/zeromq/libzmq/issues/4160
    pushd ../doc
    for FILE in *.txt; do
        asciidoc \
            -d manpage \
            -b docbook \
            -f asciidoc.conf \
            -a zmq_version="${finalAttrs.version}" \
            "''${FILE}"
        xmlto --skip-validation man "''${FILE%.txt}.xml"
    done
    popd
  '';

  postInstall = ''
    # Install manually created man pages
    install -vDm644 -t "$out/share/man/man3" ../doc/*.3
    install -vDm644 -t "$out/share/man/man7" ../doc/*.7
  '';

  passthru.tests = {
    inherit
      azmq
      cppzmq
      czmq
      zmqpp
      ;
    pyzmq = python3.pkgs.pyzmq;
    ffmpeg = ffmpeg.override { withZmq = true; };
  };

  meta = {
    branch = "4";
    homepage = "http://www.zeromq.org";
    description = "Intelligent Transport Layer";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ fpletz ];
  };
})
