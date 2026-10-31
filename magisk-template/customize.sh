ui_print "RTL88x2BU Android driver autoload"

if [ "$ARCH" != "arm64" ]; then
  abort "Unsupported architecture: $ARCH"
fi

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/88x2bu.ko" 0 0 0644
