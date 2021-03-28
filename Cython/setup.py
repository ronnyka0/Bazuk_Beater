from setuptools import Extension, setup
from Cython.Build import cythonize
import numpy

for name in ["Board", "Maps"]:
    ext_modules = [
        Extension(
            name,
            [name + ".pyx"],
            extra_compile_args=['-fopenmp'],
            extra_link_args=['-fopenmp'],
            include_dirs=[numpy.get_include()],
        )
    ]

    setup(
        name=name,
        ext_modules=cythonize(ext_modules),
    )