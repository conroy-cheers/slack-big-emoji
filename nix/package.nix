{
  lib,
  stdenvNoCC,
  makeWrapper,
  ruby,
  imagemagick,
  cacert,
}:

let
  rubyEnv = ruby.withPackages (ps: [
    ps.mini_magick
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "slack-big-emoji";
  version = "0.1.2";

  src = lib.cleanSource ./..;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/slack-big-emoji"
    cp -r bin lib "$out/share/slack-big-emoji/"

    mkdir -p "$out/bin"
    makeWrapper "${rubyEnv}/bin/ruby" "$out/bin/slack-big-emoji" \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --prefix PATH : "${lib.makeBinPath [ imagemagick ]}" \
      --add-flags "$out/share/slack-big-emoji/bin/slack-big-emoji"

    runHook postInstall
  '';

  meta = {
    description = "Command-line tool to create big emojis for Slack";
    homepage = "https://github.com/kinduff/slack-big-emoji";
    license = lib.licenses.mit;
    mainProgram = "slack-big-emoji";
    platforms = lib.platforms.all;
  };
}
