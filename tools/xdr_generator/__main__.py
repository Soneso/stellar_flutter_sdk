"""
Entry point for running xdr_generator as a module.

Enables: python -m tools.xdr_generator
"""

import sys
from .main import main

if __name__ == '__main__':
    sys.exit(main())
