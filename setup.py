#!/usr/bin/env python
# -*- coding: utf-8 -*-
import json

from setuptools import setup


try:
    from jupyterpip import cmdclass
except:
    import pip
    import importlib

    pip.main(["install", "jupyter-pip"])
    cmdclass = importlib.import_module("jupyterpip").cmdclass

with open("setup.json") as f:
    setup_data = json.load(f)


with open("README.rst") as f:
    setup_data.update(
        long_description=f.read()
    )

setup_data.update(
    cmdclass=cmdclass(
        path="{0}/static/{0}".format(
            setup_data["packages"][0]
        )
    )
)

setup(**setup_data)
