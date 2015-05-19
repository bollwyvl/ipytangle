import json

from setuptools import setup
from setuptools.command.test import test as TestCommand


try:
    from jupyterpip import cmdclass
except:
    import pip
    import importlib

    pip.main(["install", "jupyter-pip"])
    cmdclass = importlib.import_module("jupyterpip").cmdclass


class NosercTestCommand(TestCommand):
    def run_tests(self):
        # Run nose ensuring that argv simulates running nosetests directly
        import nose
        nose.run_exit(argv=['nosetests', '-c', './.noserc'])


with open("setup.json") as f:
    setup_data = json.load(f)


with open("README.rst") as f:
    setup_data.update(
        long_description=f.read()
    )

setup_data.update(
    cmdclass=cmdclass(
        path="{0}/static/{0}".format(
            setup_data["py_modules"][0]
        )
    )
)

setup_data["cmdclass"].update(
    test=NosercTestCommand
)

setup(**setup_data)
