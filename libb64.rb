# Documentation: https://github.com/Homebrew/brew/blob/master/docs/Formula-Cookbook.md
#                http://www.rubydoc.info/github/Homebrew/brew/master/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Libb64 < Formula
  desc "base64 encoding/decoding library"
  homepage "http://libb64.sourceforge.net/"
  url "https://sourceforge.net/projects/libb64/files/libb64/libb64/libb64-1.2.src.zip"
  version "1.2"
  sha256 "343d8d61c5cbe3d3407394f16a5390c06f8ff907bd8d614c16546310b689bfd3"

  # depends_on "cmake" => :build
  #depends_on :x11 # if your formula requires any X11/XQuartz components

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel

    # Remove unrecognized options if warned by configure
    #system "./configure", "--disable-debug",
    #                      "--disable-dependency-tracking",
    #                      "--disable-silent-rules",
    #                      "--prefix=#{prefix}"

    # system "cmake", ".", *std_cmake_args

    #system "PREFIX=$HOMEBREW_PREFIX  make"
    system "install b64/include $HOMEBREW_CELLAR/libb64/1.2/include/"
    # if this fails, try separate make/make install steps
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test libb64`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
