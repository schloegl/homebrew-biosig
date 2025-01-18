class Libxdf < Formula
  desc "C++ library for loading XDF files"
  homepage "https://github.com/Yida-Lin/libxdf"
  url "https://github.com/xdf-modules/libxdf/archive/v0.99.9.tar.gz"
  sha256 "69669a9cbcdb1edd5befe12dc8eada3f889bcb63412fb7dbc10769563f9ac7f8"

  depends_on "cmake" => :build

  def install
    system "cmake", ".", *std_cmake_args
    system "make"

    include.mkpath
    include.install "./xdf.h"
    lib.mkpath
    lib.install "libxdf.a"
  end

  test do
    system "ls", "#{lib}/libxdf.*"
  end
end
