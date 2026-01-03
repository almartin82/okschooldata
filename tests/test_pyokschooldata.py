"""
Tests for pyokschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyokschooldata
    assert pyokschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyokschooldata
    assert hasattr(pyokschooldata, 'fetch_enr')
    assert callable(pyokschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyokschooldata
    assert hasattr(pyokschooldata, 'get_available_years')
    assert callable(pyokschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyokschooldata
    assert hasattr(pyokschooldata, '__version__')
    assert isinstance(pyokschooldata.__version__, str)
