"""Logging configuration for AnalystAI backend."""

import logging
import sys
from typing import Any
import json
from datetime import datetime
from pathlib import Path
from functools import lru_cache

from .config import get_settings


class JSONFormatter(logging.Formatter):
    """JSON log formatter for structured logging."""
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON."""
        log_obj = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # Add exception info if present
        if record.exc_info:
            log_obj['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields
        for key, value in record.__dict__.items():
            if key not in ['name', 'msg', 'args', 'created', 'filename', 
                          'funcName', 'levelname', 'levelno', 'lineno', 
                          'module', 'msecs', 'message', 'pathname', 'process',
                          'processName', 'relativeCreated', 'thread', 'threadName',
                          'exc_info', 'exc_text', 'stack_info']:
                log_obj[key] = value
        
        return json.dumps(log_obj)


class ColoredFormatter(logging.Formatter):
    """Colored console formatter for development."""
    
    COLORS = {
        'DEBUG': '\033[36m',    # Cyan
        'INFO': '\033[32m',     # Green
        'WARNING': '\033[33m',  # Yellow
        'ERROR': '\033[31m',    # Red
        'CRITICAL': '\033[35m', # Magenta
    }
    RESET = '\033[0m'
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record with colors."""
        levelname = record.levelname
        if levelname in self.COLORS:
            record.levelname = f"{self.COLORS[levelname]}{levelname}{self.RESET}"
        return super().format(record)


def setup_logging() -> None:
    """Configure application logging."""
    settings = get_settings()
    
    # Create logger
    logger = logging.getLogger('analystai')
    logger.setLevel(getattr(logging, settings.LOG_LEVEL.upper()))
    
    # Remove existing handlers
    logger.handlers.clear()
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    
    # Use JSON formatter in production, colored in development
    if settings.is_production:
        formatter = JSONFormatter()
    else:
        formatter = ColoredFormatter(
            '%(asctime)s - %(levelname)s - %(name)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # Optionally add file handler
    if not settings.is_production:
        log_dir = Path('logs')
        log_dir.mkdir(exist_ok=True)
        
        file_handler = logging.FileHandler(
            log_dir / f"analystai_{datetime.now().strftime('%Y%m%d')}.log"
        )
        file_handler.setFormatter(JSONFormatter())
        logger.addHandler(file_handler)
    
    # Set third-party loggers to WARNING
    logging.getLogger('urllib3').setLevel(logging.WARNING)
    logging.getLogger('google').setLevel(logging.WARNING)
    logging.getLogger('faiss').setLevel(logging.WARNING)


@lru_cache()
def get_logger(name: str = 'analystai') -> logging.Logger:
    """Get a logger instance.
    
    Args:
        name: Logger name
        
    Returns:
        Logger instance
    """
    return logging.getLogger(name)


def log_api_call(endpoint: str, method: str, **kwargs) -> None:
    """Log API call details.
    
    Args:
        endpoint: API endpoint
        method: HTTP method
        **kwargs: Additional context
    """
    logger = get_logger()
    logger.info(
        f"API call: {method} {endpoint}",
        extra={
            'api_endpoint': endpoint,
            'api_method': method,
            **kwargs
        }
    )


def log_error(error: Exception, context: dict = None) -> None:
    """Log error with context.
    
    Args:
        error: Exception to log
        context: Additional context
    """
    logger = get_logger()
    logger.error(
        f"Error occurred: {str(error)}",
        exc_info=True,
        extra={'error_context': context or {}}
    )
