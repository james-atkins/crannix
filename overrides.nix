{ lib, pkgs }:

let
  recursiveMerge = with lib; attrList:
    let
      f = attrPath:
        zipAttrsWith (n: values:
          if tail values == [ ] then head values
          else if all isList values then unique (concatLists values)
          else if all isAttrs values then f (attrPath ++ [ n ]) values
          else abort "Cannot merge conflicting values"
        );
    in
    f [ ] attrList;

  requiresHome = {
    preInstall = "export HOME=$(mktemp -d)";
  };

  buildInputs = inputs:
    { buildInputs = inputs; };

  nativeBuildInputs = inputs:
    { nativeBuildInputs = inputs; };

  propagatedBuildInputs = inputs:
    { propagatedBuildInputs = inputs; };

  patchConfigure = {
    patchPhase = "patchShebangs configure";
  };

  overrides = with pkgs;
    {
      AlphaHull3D = nativeBuildInputs [ pkg-config ];
      Cairo = buildInputs [ libtiff libjpeg cairo.dev xorg.libXt.dev fontconfig.lib ] // nativeBuildInputs [ pkg-config ];
      curl = buildInputs [ curl.dev ];
      data_table = patchConfigure // buildInputs [ zlib.dev ];
      gert = buildInputs [ libgit2 ];
      haven = buildInputs [ libiconv zlib.dev ];
      httpuv = buildInputs [ zlib.dev ];
      jpeg = buildInputs [ libjpeg.dev ];
      nloptr = buildInputs [ nlopt ] // nativeBuildInputs [ pkg-config ];
      stringi = buildInputs [ icu.dev ];
      ps = patchConfigure;
      purrr = patchConfigure;
      png = buildInputs [ libpng.dev ];
      ragg = buildInputs [ freetype.dev libtiff.dev ];
      R_cache = requiresHome;
      RCurl = buildInputs [ curl.dev ];
      rgl = buildInputs [ libGLU libGLU.dev libGL xorg.libX11.dev freetype.dev libpng.dev ];
      styler = requiresHome;
      systemfonts = nativeBuildInputs [ fontconfig ];
      textshaping = buildInputs [ harfbuzz.dev freetype.dev fribidi ] // nativeBuildInputs [ pkg-config ];
      tiledb = buildInputs [ tiledb ] // requiresHome;
      units = buildInputs [ udunits ];
      XML = buildInputs [ libtool libxml2.dev xmlsec libxslt ] // nativeBuildInputs [ pkg-config ];
      xml2 = buildInputs [ libxml2.dev ];
    };

  otherOverrides = final: prev:
    {
      arrow = prev.arrow.overrideAttrs (attrs:
        let
          arrow-cpp = pkgs.arrow-cpp.overrideAttrs (attrs: rec {
            version = "12.0.1";
            src = pkgs.fetchurl {
              url = "mirror://apache/arrow/arrow-${version}/apache-arrow-${version}.tar.gz";
              sha256 = "sha256-NIHEETk6oVx16I2Tz4MV+vf0PhgP4HkBKNOEDUF96Fg=";
            };
            sourceRoot = "apache-arrow-${version}/cpp";
          });
        in
        {
          patchPhase = "patchShebangs configure";
          buildInputs = attrs.buildInputs ++ [ arrow-cpp ];
          nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.pkg-config ];
        });

      rJava = prev.rJava.overrideAttrs (attrs: {
        buildInputs = with pkgs; attrs.buildInputs ++ [ bzip2.dev icu jdk libzip pcre.dev xz.dev zlib ];
        JAVA_CPPFLAGS = "-I${pkgs.jdk}/include/";
        JAVA_HOME = "${pkgs.jdk}";
      });

      openssl = prev.openssl.overrideAttrs (attrs: {
        PKGCONFIG_CFLAGS = "-I${pkgs.openssl.dev}/include";
        PKGCONFIG_LIBS = "-Wl,-rpath,${lib.getLib pkgs.openssl}/lib -L${lib.getLib pkgs.openssl}/lib -lssl -lcrypto";
      });

      RcppParallel = prev.RcppParallel.overrideAttrs (attrs: {
        patchPhase = "patchShebangs configure";
        TBB_INC = "${pkgs.tbb.dev}/include";
        TBB_LIB = "${pkgs.tbb.out}/lib";
      });
    };
in
final: prev:
(lib.mapAttrs (name: value: prev.${name}.overrideAttrs (attrs: recursiveMerge [ attrs value ])) overrides)
  //
otherOverrides final prev
