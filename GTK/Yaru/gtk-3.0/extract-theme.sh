#!/bin/sh

workdir=${PWD}

if [ ! -d ${workdir}/theme ]; then
  mkdir -p ${workdir}/theme
fi

gst=${workdir}/gtk.gresource

for r in `gresource list $gst`; do
        gresource extract $gst $r >$workdir/${r#\/com\/ubuntu\/themes/\Yaru/\3.0/}
        gresource extract $gst $r >$workdir/${r#\/com\/ubuntu\/themes/\Yaru/\3.0/\assets/}
done

