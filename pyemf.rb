class Pyemf < Formula
  homepage "http://pyemf.sf.net"
  url "http://sourceforge.net/projects/pyemf/files/pyemf/2.0.0/pyemf-2.0.0.tar.gz"
  version "2.0.0"
  sha256 "6960341434b9683926fba01f1fd81738234848c3f25883fa44c84b9833cf2354"

  depends_on "python"  => :build

  def install
    system "python setup.py install"
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
  end
end
