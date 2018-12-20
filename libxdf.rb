class Libxdf < Formula
  desc "C++ library for loading XDF files"
  homepage "https://github.com/Yida-Lin/libxdf"
  url "https://github.com/Yida-Lin/libxdf/archive/v0.98.tar.gz"
  sha256 "61e9b377c72f7c96b548971f265c575c71aeeb1692b4f49ddb0b7e1d03ddbdb7"

  depends_on "cmake" => :build

  def install
    system "cmake", ".", *std_cmake_args
    system "make"

    include.mkpath
    include.install "./xdf.h"
    lib.mkpath
    lib.install "libxdf.dylib"
    lib.install "libxdf.a"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test biosig4c%2B%2B`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "ls", "/usr/local/lib/libxdf.{a,dylib}"
  end
end
