#!/bin/sh

workdir=${PWD}

if [ ! -d ${workdir}/assets ]; then
  mkdir -p ${workdir}/assets
fi

gst=${workdir}/gtk.gresource

for r in `gresource list $gst`; do
        gresource extract $gst $r >$workdir/${r#\/com\/ubuntu\/themes/\Yaru-light/\3.20/}
        #gresource extract $gst $r >$workdir/${r#\/com\/ubuntu\/themes/\Yaru/\3.20/\assets/}
done

