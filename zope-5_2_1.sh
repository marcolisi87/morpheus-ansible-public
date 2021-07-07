#!/bin/bash
cd tmp
wget https://pypi.org/packages/source/Z/Zope/Zope-5.2.1.tar.gz
tar xfvz Zope-5.2.1.tar.gz
cd Zope-5.2.1
python3.8 -m venv .
bin/pip install -U pip wheel zc.buildout
bin/buildout
bin/mkwsgiinstance -u zope:zope -d .
bin/runwsgi -v etc/zope.ini &
