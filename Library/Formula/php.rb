require 'formula'

def mysql_installed?
    `which mysql_config`.length > 0
end

class Php <Formula
  @url='http://www.php.net/get/php-5.3.2.tar.gz/from/this/mirror'
  @homepage='http://php.net/'
  @md5='4480d7c6d6b4a86de7b8ec8f0c2d1871'
  @version='5.3.2'

  depends_on 'jpeg'
  depends_on 'libpng'
  depends_on 'mcrypt'
  depends_on 'gettext'
  if ARGV.include? '--with-mysql'
    depends_on 'mysql' => :recommended unless mysql_installed?
  end
  
  def options
   [
     ['--with-mysql', 'Build with MySQL support.']
   ]
  end

  def patches
   DATA
  end
  
  def configure_args
    args = [
      "--prefix=#{prefix}",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--with-iconv-dir=/usr",
      "--enable-exif",
      "--enable-soap",
      "--enable-sqlite-utf8",
      "--enable-wddx",
      "--enable-ftp",
      "--enable-sockets",
      "--enable-zip",
      "--enable-pcntl",
      "--enable-shmop",
      "--enable-sysvsem",
      "--enable-sysvshm",
      "--enable-sysvmsg",
      "--enable-memory-limit",
      "--enable-mbstring",
      "--enable-bcmath",
      "--enable-calendar",
      "--enable-memcache",
      "--with-openssl=/usr",
      "--with-zlib=/usr",
      "--with-bz2=/usr",
      "--with-ldap",
      "--with-ldap-sasl=/usr",
      "--with-xmlrpc",
      "--with-iodbc",
      "--with-kerberos=/usr",
      "--with-libxml-dir=/usr",
      "--with-xsl=/usr",
      "--with-curl=/usr",
      "--with-apxs2=/usr/sbin/apxs",
      "--libexecdir=#{prefix}/libexec",
      "--with-gd",
      "--enable-gd-native-ttf",
      "--with-mcrypt=#{Formula.factory('mcrypt').prefix}",
      "--with-jpeg-dir=#{Formula.factory('jpeg').prefix}",
      "--with-png-dir=#{Formula.factory('libpng').prefix}",
      "--with-gettext=#{Formula.factory('gettext').prefix}"
    ]
    
    # For some reason freetype.h can't be found when building on 10.5
    if (MACOS_VERSION >= 10.6) && (File.exist? "/usr/X11/lib")
      args.push "--with-freetype-dir=/usr/X11/lib"
    end
    
    if ARGV.include? '--with-mysql'
      if mysql_installed?
        args.push "--with-mysql-sock=/tmp/mysql.sock"
        args.push "--with-mysqli=mysqlnd"
        args.push "--with-mysql=mysqlnd"
        args.push "--with-pdo-mysql=mysqlnd"
      else
        args.push "--with-mysqli=#{Formula.factory('mysql').bin}/mysql_config}"
        args.push "--with-mysql=#{Formula.factory('mysql').prefix}"
        args.push "--with-pdo-mysql=#{Formula.factory('mysql').prefix}"
      end
    end
    return args
  end
  
  def install
    ENV.O3 # Speed things up
    system "./configure", *configure_args

    inreplace "Makefile",
      "INSTALL_IT = $(mkinstalldirs) '$(INSTALL_ROOT)/usr/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='$(INSTALL_ROOT)/usr/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so",
      "INSTALL_IT = $(mkinstalldirs) '#{prefix}/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='#{prefix}/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so"
    
    system "make"
    system "make install"

    system "cp ./php.ini-production #{prefix}/lib/php.ini"
  end

 def caveats; <<-EOS
   For 10.5 and Apache:
    Apache needs to run in 32-bit mode. You can either force Apache to start 
    in 32-bit mode or you can thin the Apache executable. The following page 
    has instructions for both methods:
    http://code.google.com/p/modwsgi/wiki/InstallationOnMacOSX
   
   To enable PHP in Apache add the following to httpd.conf and restart Apache:
    LoadModule php5_module    #{prefix}/libexec/apache2/libphp5.so

   Edits you will most likely want to make to php.ini
    Date:
      You will want to set date.timezone setting to your timezone.
      http://www.php.net/manual/en/timezones.php

    MySQL:
      pdo_mysql.default_socket = /tmp/mysql.sock
      mysql.default_port = 3306
      mysql.default_socket = /tmp/mysql.sock
      mysqli.default_socket = /tmp/mysql.sock

      The php.ini file can be found in: 
      #{prefix}/lib/php.ini
   EOS
 end
end

__END__
diff -Naur php-5.3.0/ext/iconv/iconv.c php/ext/iconv/iconv.c
--- php-5.3.0/ext/iconv/iconv.c	2009-03-16 22:31:04.000000000 -0700
+++ php/ext/iconv/iconv.c	2009-07-15 14:40:09.000000000 -0700
@@ -51,9 +51,6 @@
 #include <gnu/libc-version.h>
 #endif
 
-#ifdef HAVE_LIBICONV
-#undef iconv
-#endif
 
 #include "ext/standard/php_smart_str.h"
 #include "ext/standard/base64.h"
@@ -182,9 +179,6 @@
 }
 /* }}} */
 
-#ifdef HAVE_LIBICONV
-#define iconv libiconv
-#endif
 
 /* {{{ typedef enum php_iconv_enc_scheme_t */
 typedef enum _php_iconv_enc_scheme_t {
