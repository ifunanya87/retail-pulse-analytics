import logging
import sys
import os
from pathlib import Path
from logging.handlers import RotatingFileHandler


def get_logger(name, log_file_name="pipeline.log", to_stdout=True):
    root_dir = Path(__file__).resolve().parent.parent.parent
    log_dir = root_dir / "log"
    os.makedirs(log_dir, exist_ok=True)
    log_path = log_dir / log_file_name

    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    if not logger.handlers:

        # Rotating File Handler
        file_handler = RotatingFileHandler(
            log_path,
            maxBytes=10_000_000,   # 10 MB per file
            backupCount=3,         # keep last 3 rotated logs
            mode="a"
        )

        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )

        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        # Conditionally add Terminal Handler
        if to_stdout:
            stdout_handler = logging.StreamHandler(sys.stdout)
            stdout_handler.setFormatter(formatter)
            logger.addHandler(stdout_handler)

    return logger
