from setuptools import Extension, setup
from Cython.Build import cythonize
import numpy

for name in ["Board", "Move_Gen", "Maps", "misc"]:
    ext_modules = [
        Extension(
            name,
            [name + ".pyx"],
            extra_compile_args=[''],
            extra_link_args=[''],
            include_dirs=[numpy.get_include()],
        )
    ]

    setup(
        name=name,
        ext_modules=cythonize(ext_modules),
    )