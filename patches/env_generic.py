from pathlib import Path

import entrypoints
import pkgutil

class Environment:
    """
    A replacement libtbx.env object that doesn't need configuration.

    Designed to work via a mix of entry points and sane defaults for things
    that shouldn't matter anyway.
    """

    def under_base(self, path):
        # Not entirely sure what is appropriate here; we don't have the
        # concept of a base dir.
        return str(Path("/no/defined/canonical/base") / path)

    def dist_path(self, module):
        entrypoint = entrypoints.get_single("libtbx.module", module)
        # Work out where this will be, without importing
        package = pkgutil.get_loader(entrypoint.module_name)
        return str(Path(package.path).parent)
