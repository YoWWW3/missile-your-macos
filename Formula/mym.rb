# Homebrew formula for mym — Missile Your macOS
#
# Publishing steps (for maintainers):
#   1. Create a GitHub release and tag (e.g. v1.0.0):
#        git tag v1.0.0 && git push origin v1.0.0
#      Then create the release on GitHub (Releases → Draft a new release).
#
#   2. Download the release tarball and compute its SHA256:
#        curl -sL https://github.com/YoWWW3/missile-your-macos/archive/refs/tags/v1.0.0.tar.gz \
#          | shasum -a 256
#      Replace the `sha256` value below with that hash.
#
#   3. Host this formula in a Homebrew tap repository named
#      `homebrew-missile-your-macos` under your GitHub account:
#        mkdir homebrew-missile-your-macos
#        cd homebrew-missile-your-macos
#        git init && mkdir Formula
#        cp /path/to/mym.rb Formula/mym.rb
#        git add . && git commit -m "Add mym formula"
#        git remote add origin https://github.com/YoWWW3/homebrew-missile-your-macos
#        git push -u origin main
#
#   4. Users can then install with:
#        brew tap YoWWW3/missile-your-macos
#        brew install mym
#
# Updating to a new version:
#   - Update `url` to point at the new tag's tarball
#   - Update `sha256` to the new hash
#   - Update `version` if you use a separate version declaration

class Mym < Formula
  desc "Safely back up everything before erasing macOS — SSH keys, configs, and Git projects"
  homepage "https://github.com/YoWWW3/missile-your-macos"
  url "https://github.com/YoWWW3/missile-your-macos/archive/refs/tags/v1.0.0.tar.gz"
  # Run the following command after creating the v1.0.0 release on GitHub, then
  # replace the placeholder below with the real hash before publishing the formula:
  #   curl -sL https://github.com/YoWWW3/missile-your-macos/archive/refs/tags/v1.0.0.tar.gz \
  #     | shasum -a 256
  sha256 "REPLACE_WITH_ACTUAL_SHA256_OF_v1.0.0_TARBALL"
  license "MIT"
  version "1.0.0"

  # No compiled dependencies — pure Bash
  bottle :unneeded

  def install
    # Install the support scripts to libexec so they aren't exposed directly
    # on $PATH but are still reachable by the mym wrapper via relative paths.
    libexec.install "backup-config.sh"
    libexec.install "backup-projects-dry-run.sh"
    libexec.install "backup-projects-execute.sh"

    # Make the support scripts executable
    chmod 0755, libexec/"backup-config.sh"
    chmod 0755, libexec/"backup-projects-dry-run.sh"
    chmod 0755, libexec/"backup-projects-execute.sh"

    # Install the main CLI wrapper
    bin.install "bin/mym"
  end

  def caveats
    <<~EOS
      mym has been installed. Quick-start:

        mym --help                     Show all commands and options
        mym config                     Backup developer configs to ~/Desktop
        mym dry-run ~/Projects         Preview which Git projects will be archived
        mym execute ~/Projects         Archive projects and move originals to Trash

      Full guide and documentation:
        https://github.com/YoWWW3/missile-your-macos
    EOS
  end

  test do
    # Verify the CLI wrapper runs and reports the correct version
    assert_match "1.0.0", shell_output("#{bin}/mym --version")
    # Verify --help exits cleanly and mentions the main commands
    help = shell_output("#{bin}/mym --help")
    assert_match "config", help
    assert_match "dry-run", help
    assert_match "execute", help
  end
end
