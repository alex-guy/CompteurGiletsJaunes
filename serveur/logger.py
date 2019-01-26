#!/usr/bin/env python
# -*- coding: utf-8

import logging

colors = {'debug': '\033[97m',
          'info': '\033[92m',
          'warn': '\033[93m',
          'error': '\033[95m',
          'critical': '\033[91m'}

class Logger(object):
  base_format = '%(levelname)-9s\033[0m - - [%(asctime)s] %(message)s'
  debug_format = '%s%s' % (colors['debug'], base_format)
  info_format = '%s%s' % (colors['info'], base_format)
  warn_format = '%s%s' % (colors['warn'], base_format)
  error_format = '%s%s' % (colors['error'], base_format)
  critical_format = '%s%s' % (colors['critical'], base_format)
  debug_logger = logging.getLogger('debug_logger')
  debug_logger.setLevel(logging.DEBUG)
  debug_handler = logging.StreamHandler()
  debug_handler.setLevel(logging.DEBUG)
  debug_formatter = logging.Formatter(debug_format, datefmt='%d/%b/%Y %H:%M:%S')
  debug_handler.setFormatter(debug_formatter)
  debug_logger.addHandler(debug_handler)
  info_logger = logging.getLogger('info_logger')
  info_logger.setLevel(logging.INFO)
  info_handler = logging.StreamHandler()
  info_handler.setLevel(logging.INFO)
  info_formatter = logging.Formatter(info_format, datefmt='%d/%b/%Y %H:%M:%S')
  info_handler.setFormatter(info_formatter)
  info_logger.addHandler(info_handler)
  warn_logger = logging.getLogger('warn_logger')
  warn_logger.setLevel(logging.WARN)
  warn_handler = logging.StreamHandler()
  warn_handler.setLevel(logging.WARN)
  warn_formatter = logging.Formatter(warn_format, datefmt='%d/%b/%Y %H:%M:%S')
  warn_handler.setFormatter(warn_formatter)
  warn_logger.addHandler(warn_handler)
  error_logger = logging.getLogger('error_logger')
  error_logger.setLevel(logging.ERROR)
  error_handler = logging.StreamHandler()
  error_handler.setLevel(logging.ERROR)
  error_formatter = logging.Formatter(error_format, datefmt='%d/%b/%Y %H:%M:%S')
  error_handler.setFormatter(error_formatter)
  error_logger.addHandler(error_handler)
  critical_logger = logging.getLogger('critical_logger')
  critical_logger.setLevel(logging.CRITICAL)
  critical_handler = logging.StreamHandler()
  critical_handler.setLevel(logging.CRITICAL)
  critical_formatter = logging.Formatter(critical_format, datefmt='%d/%b/%Y %H:%M:%S')
  critical_handler.setFormatter(critical_formatter)
  critical_logger.addHandler(critical_handler)

  def __init__(self, level='debug'):
    levels = {'debug': self.enable_debug, 'info': self.enable_info, 'warn': self.enable_warn, 'error': self.enable_error, 'critical': self.enable_critical}
    levels[level]()

  def enable_debug(self):
    self.en_debug = True
    self.en_info = True
    self.en_warn = True
    self.en_error = True
    self.en_critical = True

  def enable_info(self):
    self.en_debug = False
    self.en_info = True
    self.en_warn = True
    self.en_error = True
    self.en_critical = True

  def enable_warn(self):
    self.en_debug = False
    self.en_info = False
    self.en_warn = True
    self.en_error = True
    self.en_critical = True

  def enable_error(self):
    self.en_debug = False
    self.en_info = False
    self.en_warn = False
    self.en_error = True
    self.en_critical = True

  def enable_critical(self):
    self.en_debug = False
    self.en_info = False
    self.en_warn = False
    self.en_error = False
    self.en_critical = True

  def debug(self, msg):
    if self.en_debug:
      self.debug_logger.debug(msg)
  def info(self, msg):
    if self.en_info:
      self.info_logger.info(msg)
  def warn(self, msg):
    if self.en_warn:
      self.warn_logger.warn(msg)
  def error(self, msg):
    if self.en_error:
      self.error_logger.error(msg)
  def critical(self, msg):
    if self.en_critical:
      self.critical_logger.critical(msg)
