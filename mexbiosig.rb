class Mexbiosig < Formula
  homepage "http://biosig.sf.net"
  url "https://pub.ist.ac.at/~schloegl/biosig/prereleases/mexbiosig-1.9.5.src.tar.gz"
  sha256 "74c4bb1f98b2f6d31fb4b8742e2809b9645aa81d551602f95c6052bc8c8e1a12"

  depends_on "gnu-tar" => :build
  depends_on "biosig" => :build
  depends_on "octave" => :build

  def install
    ## build mex for Octave
    system "octave --eval 'pkg install https://pub.ist.ac.at/~schloegl/biosig/prereleases/mexbiosig-1.9.5.src.tar.gz'"
  end

  test do
    system "octave", "--norc", "--eval", 'pkg load mexbiosig; which mexSLOAD; exit;'
  end
end
