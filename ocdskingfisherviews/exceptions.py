class KingfisherViewsError(Exception):
    """Base class for exceptions from within this package"""


class AmbiguousSourceError(KingfisherViewsError):
    """Raised if a SQL object has an ambiguous source"""
