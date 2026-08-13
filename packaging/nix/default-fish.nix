{ lib, stdenvNoCC, fetchFromGitHub, fish, gawk, makeWrapper }:

stdenvNoCC.mkDerivation rec {
  pname = "derakht-cli-fish";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "i-love-coffee-i-love-tea";
    repo = "derakht-cli";
    rev = "v${version}";
    sha256 = ""; # fill in after first build
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 derakht.fish $out/bin/derakht-fish
    install -Dm644 derakht.1 $out/share/man/man1/derakht.1
    install -Dm644 LICENSE $out/share/licenses/$pname/LICENSE

    wrapProgram $out/bin/derakht-fish \
      --prefix PATH : ${lib.makeBinPath [ fish gawk ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Fish shell support for derakht-cli — create CLIs with auto-completion from config";
    homepage = "https://github.com/i-love-coffee-i-love-tea/derakht-cli";
    license = licenses.bsd2;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
