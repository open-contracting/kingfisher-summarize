class KingfisherSummarizeError(Exception):
    """Base class for exceptions from within this package."""


class AmbiguousSourceError(KingfisherSummarizeError):
    """Raised if a SQL object has an ambiguous source."""
