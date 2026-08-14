{ lib, stdenvNoCC, fetchFromGitHub, bash, gawk, makeWrapper }:

stdenvNoCC.mkDerivation rec {
  pname = "derakht-cli";
  version = "2.0.0+1";

  src = fetchFromGitHub {
    owner = "i-love-coffee-i-love-tea";
    repo = "derakht-cli";
    rev = "v2.0.0";
    sha256 = ""; # fill in after first build
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 derakht.sh $out/bin/derakht
    install -Dm644 derakht.1 $out/share/man/man1/derakht.1
    install -Dm644 LICENSE $out/share/licenses/$pname/LICENSE

    wrapProgram $out/bin/derakht \
      --prefix PATH : ${lib.makeBinPath [ bash gawk ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Create CLIs with auto-completion, abbreviation and built-in help from config";
    homepage = "https://github.com/i-love-coffee-i-love-tea/derakht-cli";
    license = licenses.bsd2;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
