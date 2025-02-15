{
  lib,
  stdenv,
  buildPythonPackage,
  pytestCheckHook,
  pythonOlder,
  fetchFromGitLab,
  replaceVars,
  bubblewrap,
  exiftool,
  ffmpeg,
  wrapGAppsHook3,
  gdk-pixbuf,
  gobject-introspection,
  librsvg,
  poppler_gi,
  mutagen,
  pygobject3,
  pycairo,
  dolphinIntegration ? false,
  plasma5Packages,
}:

buildPythonPackage rec {
  pname = "mat2";
  version = "0.13.4";

  disabled = pythonOlder "3.5";

  format = "setuptools";

  src = fetchFromGitLab {
    domain = "0xacab.org";
    owner = "jvoisin";
    repo = "mat2";
    rev = version;
    hash = "sha256-SuN62JjSb5O8gInvBH+elqv/Oe7j+xjCo+dmPBU7jEY=";
  };

  patches =
    [
      # hardcode paths to some binaries
      (replaceVars ./paths.patch {
        exiftool = "${exiftool}/bin/exiftool";
        ffmpeg = "${ffmpeg}/bin/ffmpeg";
        kdialog = if dolphinIntegration then "${plasma5Packages.kdialog}/bin/kdialog" else null;
        # replaced in postPatch
        mat2 = null;
        mat2svg = null;
      })
      # the executable shouldn't be called .mat2-wrapped
      ./executable-name.patch
      # hardcode path to mat2 executable
      ./tests.patch
    ]
    ++ lib.optionals (stdenv.hostPlatform.isLinux) [
      (replaceVars ./bubblewrap-path.patch {
        bwrap = "${bubblewrap}/bin/bwrap";
      })
    ];

  postPatch = ''
    rm pyproject.toml
    substituteInPlace dolphin/mat2.desktop \
      --replace "@mat2@" "$out/bin/mat2" \
      --replace "@mat2svg@" "$out/share/icons/hicolor/scalable/apps/mat2.svg"
  '';

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook3
  ];

  buildInputs = [
    gdk-pixbuf
    librsvg
    poppler_gi
  ];

  propagatedBuildInputs = [
    mutagen
    pygobject3
    pycairo
  ];

  postInstall =
    ''
      install -Dm 444 data/mat2.svg -t "$out/share/icons/hicolor/scalable/apps"
      install -Dm 444 doc/mat2.1 -t "$out/share/man/man1"
    ''
    + lib.optionalString dolphinIntegration ''
      install -Dm 444 dolphin/mat2.desktop -t "$out/share/kservices5/ServiceMenus"
    '';

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = [
    # libmat2.pdf.cairo.MemoryError: out of memory
    "test_all"
  ];

  meta = with lib; {
    description = "Handy tool to trash your metadata";
    homepage = "https://0xacab.org/jvoisin/mat2";
    changelog = "https://0xacab.org/jvoisin/mat2/-/blob/${version}/CHANGELOG.md";
    license = licenses.lgpl3Plus;
    mainProgram = "mat2";
    maintainers = with maintainers; [ dotlambda ];
  };
}
