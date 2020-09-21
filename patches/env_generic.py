from pathlib import Path

import libtbx
import entrypoints
import pkgutil


class Environment:
    """
    A replacement libtbx.env object that doesn't need configuration.

    Designed to work via a mix of entry points and sane defaults for things
    that shouldn't matter anyway.
    """

    def under_base(self, path: str) -> str:
        # Not entirely sure what is appropriate here; we don't have the
        # concept of a base dir.
        return str(Path("/no/defined/canonical/base") / path)

    def under_build(self, path: str) -> str:
        """No concept of build, except the in-place site-packages

        For now, return a dummy but leave open to returning site packages.
        """
        # return Path(libtbx.__path__[0]).parent / path
        return str(Path("/no/defined/canonical/build") / path)

    def dist_path(self, module: str) -> str:
        entrypoint = entrypoints.get_single("libtbx.module", module)
        # Work out where this will be, without importing
        package = pkgutil.get_loader(entrypoint.module_name)
        return str(Path(package.path).parent)

    def has_module(self, module: str) -> bool:
        try:
            entrypoint = entrypoints.get_single("libtbx.module", module)
            return True
        except entrypoint.NoSuchEntryPoint:
            return False


libtbx.env = Environment()
