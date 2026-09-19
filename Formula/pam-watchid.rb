class PamWatchid < Formula
  desc "PAM module for sudo approval with Apple Watch or Touch ID (hardened fork)"
  homepage "https://github.com/seanb4t/pam-watchid"
  url "https://github.com/seanb4t/pam-watchid/archive/refs/tags/v2.0.0-fzymgc.1.tar.gz"
  version "2.0.0-fzymgc.1"
  sha256 "b3b1082e0c4919998cbdcfc2bd4c585f8fdcb1abf23463cbeb08a391adfc493f"
  license "Unlicense"
  head "https://github.com/seanb4t/pam-watchid.git", branch: "main"

  depends_on :macos

  def install
    system "swiftc", "-O", "-emit-library",
           "-target", "#{Hardware::CPU.arch}-apple-macos11.0",
           "-module-cache-path", buildpath/"module-cache",
           "Sources/pam-watchid/pam_watchid.swift", "-o", "pam_watchid.so"

    # The guard cases must all skip before any prompt; refuse to install a module that fails them.
    system ENV.cc, "-Wall", "-Werror", "-o", "guard_check", "Tests/guard_check.c", "-lpam"
    system "./guard_check", "./pam_watchid.so"

    (lib/"pam").install "pam_watchid.so" => "pam_watchid.so.2"
  end

  def caveats
    <<~EOS
      sudo loads PAM modules as root, and your user can write to this Homebrew copy,
      so point PAM at a root-owned copy instead. Every directory above it must be
      root-owned and not group- or world-writable (check /usr/local/lib):
        sudo install -d -o root -g wheel -m 0755 /usr/local/lib/pam
        sudo install -o root -g wheel -m 0444 #{opt_lib}/pam/pam_watchid.so.2 /usr/local/lib/pam/
      Then add it to /etc/pam.d/sudo_local, after pam_tid.so:
        auth       sufficient     /usr/local/lib/pam/pam_watchid.so.2
      Repeat the copy after every upgrade.
    EOS
  end

  test do
    assert_match "_pam_sm_authenticate", shell_output("nm -gU #{lib}/pam/pam_watchid.so.2")
  end
end
