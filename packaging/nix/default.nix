{ lib, stdenvNoCC, fetchFromGitHub, bash, gawk, makeWrapper }:

stdenvNoCC.mkDerivation rec {
  pname = "audogombleed";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "i-love-coffee-i-love-tea";
    repo = "audogombleed.sh";
    rev = "v${version}";
    sha256 = ""; # fill in after first build
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 audogombleed.sh $out/bin/audogombleed
    install -Dm644 audogombleed.1 $out/share/man/man1/audogombleed.1
    install -Dm644 LICENSE $out/share/licenses/$pname/LICENSE

    wrapProgram $out/bin/audogombleed \
      --prefix PATH : ${lib.makeBinPath [ bash gawk ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Create CLIs with auto-completion, abbreviation and built-in help from config";
    homepage = "https://github.com/i-love-coffee-i-love-tea/audogombleed.sh";
    license = licenses.bsd2;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
