from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext

# This basically does nothing, just ensures the wheels have the right tags
class FakeExtension(Extension):
    def __init__(self, name='', /):
        super().__init__(name, sources=[])


class fake_build_ext(build_ext):
    def run(self):
        super().run()


setup(
    ext_modules=[FakeExtension()],
    cmdclass={
        'build_ext': fake_build_ext,
    }
)
