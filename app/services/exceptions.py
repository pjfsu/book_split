#!/usr/bin/env python3

class ServiceError(Exception):
    """Base class for all service-layer exceptions."""
    pass

class NotFoundError(ServiceError):
    """Raised when expected data (e.g. bookmarks) is missing."""
    pass

class ValidationError(ServiceError):
    """Raised on any invalid input or state."""
    pass
