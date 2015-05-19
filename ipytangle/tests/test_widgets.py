from glob import glob
import os
import re
import sys

from IPython.testing import iptestcontroller


join = os.path.join

test_root = os.path.dirname(__file__)

tests = glob(join(test_root, 'test_*.coffee')) + \
    glob(join(test_root, 'test_*.js'))


class JSController(iptestcontroller.JSController):
    def __init__(self, section, xunit=True, engine='phantomjs', url=None):
        '''Create new test runner.'''
        iptestcontroller.TestController.__init__(self)

        self.engine = engine
        self.section = section
        self.xunit = xunit
        self.url = url
        self.slimer_failure = re.compile('^FAIL.*', flags=re.MULTILINE)

        ip_test_dir = iptestcontroller.get_js_test_dir()

        extras = [
            '--includes=' + join(ip_test_dir, 'util.js'),
            '--engine=%s' % self.engine
        ]

        self.cmd = ['casperjs', 'test'] + extras + tests


def test_notebook():
    controller = JSController('ipytangle')
    exitcode = 1
    try:
        controller.setup()
        controller.launch(buffer_output=False)
        exitcode = controller.wait()
    except Exception as err:
        print(err)
        exitcode = 1
    finally:
        controller.cleanup()
    assert exitcode == 0


if __name__ == '__main__':
    sys.exit(test_notebook())
