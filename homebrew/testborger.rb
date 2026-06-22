# Homebrew Formula for Testborger.
#
# Bygger fra kildekode lokalt (ad-hoc-signert → ingen Gatekeeper-advarsel,
# ingen Apple Developer Program nødvendig).
#
# Installer via tap-en:
#   brew tap olefredrik/tap
#   brew install testborger            # krever publisert release (url + sha256)
#   brew install --HEAD testborger     # bygger fra siste main, ingen release nødvendig
#
# Ved første release: lag en tag v1.0.0, og fyll inn `sha256` for tarballen
# (f.eks. `brew fetch --build-from-source olefredrik/tap/testborger`, eller
# `curl -sL <url> | shasum -a 256`).
class Testborger < Formula
  desc "Menylinje-app for å håndtere BankID-testbrukere (fødselsnummer + fødselsdato)"
  homepage "https://github.com/olefredrik/testborger"
  url "https://github.com/olefredrik/testborger/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "8b5ad339fd493a889d48ae815ddca4a3942abe7bac91b76c2cd9f988db6ce316"
  license "MIT"
  head "https://github.com/olefredrik/testborger.git", branch: "main"

  # Bygges med `swift build`; Command Line Tools holder, full Xcode er ikke nødvendig.
  depends_on :macos

  def install
    system "./Scripts/build-app.sh", "release"
    prefix.install "Testborger.app"

    # CLI-snarvei som starter menylinje-appen.
    (bin/"testborger").write <<~SH
      #!/bin/bash
      open "#{opt_prefix}/Testborger.app"
    SH
    chmod 0755, bin/"testborger"
  end

  def caveats
    <<~EOS
      Testborger er en menylinje-app. Start den med:
        testborger
      eller åpne fra Finder:
        #{opt_prefix}/Testborger.app

      Tips: huk av «Start ved innlogging» i appen for å få den i menylinjen ved oppstart.
    EOS
  end

  test do
    assert_path_exists prefix/"Testborger.app/Contents/MacOS/Testborger"
  end
end
