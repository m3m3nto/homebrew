require 'formula'

class Xdebug <Formula
  url 'http://xdebug.org/files/xdebug-2.1.0.tgz'
  homepage 'http://xdebug.org'
  md5 '2abf000f8d94af469773b31772aa96ab'

  def install
    extensions = lib + %x[php-config --extension-dir].split('lib/')[1].strip
    ini_dir = etc + %x[php --ini].grep(/Scan/)[0].split(':')[1].split('etc/')[1].strip
    
    Dir.chdir "xdebug-#{version}" do
      # See https://github.com/mxcl/homebrew/issues/issue/69
      ENV.universal_binary unless Hardware.is_64_bit?

      system "phpize"
      system "./configure", "--disable-debug", "--disable-dependency-tracking",
                            "--prefix=#{prefix}",
                            "--enable-xdebug"
      system "make"
      extensions.install 'modules/xdebug.so'

      File.open('xdebug.ini', 'w') {|f| f.write("zend_extension=#{extensions}/xdebug.so")}
      ini_dir.install 'xdebug.ini'
    end
  end

  def caveats
      <<-EOS
To use this software:
 * Add the following line to php.ini:
    zend_extension="#{prefix}/xdebug.so"
 * Restart your webserver.
 * Write a PHP page that calls "phpinfo();"
 * Load it in a browser and look for the info on the xdebug module.
 * If you see it, you have been successful!
      EOS
  end
end
