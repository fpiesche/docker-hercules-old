#!/usr/bin/env python3

import argparse
from configparser import ConfigParser
import dataset
import dateparser
import logging


class HerculesLauncher(object):
    def __init__(self):
        self._parse_args()

        self.logger = logging.getLogger('hercules')

        self.git_version = 'unknown'
        self.packet_version = 'unknown'
        self.server_mode = 'unknown'
        self.build_date = 'unknown'

        self.map_server_pid = None
        self.char_server_pid = None
        self.login_server_pid = None

        self.version_info_file = os.path.join(self.hercules_path, 'version_info.ini')

        self._parse_version_info()
        self._read_pids()

    def _parse_args(self):
        parser = argparse.ArgumentParser(
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        parser.add_argument('operation',
                            choices=['info', 'start', 'stop', 'restart',
                                     'setup_all', 'setup_database', 'setup_interserver'],
                            help=('The action to perform on the servers.\n',
                                    '\tinfo: Output version information and exit.\n',
                                    '\tstart: Start the game servers.\n',
                                    '\tstop: Stop the game servers.\n',
                                    '\trestart: Stop and restart the servers as needed.\n',
                                    '\tsetup_all: Set up the server configuration.\n',
                                    '\tsetup_database: Set up the database server configuration.\n',
                                    '\tsetup_interserver: Set up the inter-server configuration.\n',
                            ))

        parser.add_argument('-p', '--hercules_path',
                            default=os.path.abspath(os.path.dirname(__file__)),
                            help='The path containing the Hercules installation to control.')
        parser.add_argument('-f', '--foreground', action='store_true',
                            help='Run the servers in the foreground.')
        parser.add_argument('-r', '--autorestart', action='store_true',
                            help='Automatically restart servers when making configuration changes.')

        args = parser.parse_args()
        self.operation = args.operation
        self.hercules_path = args.hercules_path
        self.foreground = args.foreground
        self.autorestart = args.autorestart

    def _parse_version_info(self):
        if not os.path.exists(self.version_info_file):
            self.logger.warning('Failed to find version info file %s! Version info will be empty.'
                                % self.version_info_file)
            return

        config = configparser.ConfigParser()
        config.read(self.version_info_file)

        if 'version_info' not in config.sections():
            self.logger.warning('version_info section not found in %s! Version info will be empty.'
                                % self.version_info_file)
            return

        for info in ['git_version', 'packet_version', 'build_date', 'server_mode']:
            try:
                setattr(self, info, config['version_info'][info])
            except KeyError:
                self.logger.warning('Failed to find entry %s in %s! Data will be empty.'
                                    % (info, self.version_info_file))
                continue

    def _read_pids(self):
        """Read the pid files in the Hercules directory."""
        raise NotImplementedError

    def _run_executable(self, server):
        """Run the specified server executable.
        
        Will clean up stray pid files."""
        raise NotImplementedError

    def info(self):
        self.logger.info('Hercules %s git version %s' %
                         (self.config['version_info']['arch'],
                          self.config['version_info']['git_version']))
        self.logger.info('Packet version %s' %
                         self.config['version_info']['packet_version'])
        self.logger.info('%s mode' %
                         self.config['version_info']['server_mode'])
        self.logger.info('Build date %s' %
                         self.config['version_info']['build_date'])

    def execute(self):
        """Perform the operation specified by the command line."""
        getattr(self, self.operation)()

    def setup_all(self):
        """Read configuration information and set up the server configuration files to match."""
        raise NotImplementedError

    def setup_database(self, hostname=None, username=None, password=None, database=None):
        """Set up the database configuration file."""
        raise NotImplementedError

    def setup_interserver(self, username=None, password=None):
        """Set up the inter-server configuration file and user."""
        raise NotImplementedError

    def start(self):
        """Start the servers."""
        self.info()
        raise NotImplementedError

    def stop(self):
        """Stop the servers."""
        raise NotImplementedError

    def restart(self):
        """Restart the servers."""
        self.stop()
        self.start()


if __name__ == '__main__':
    launcher = HerculesLauncher()
    launcher.execute()
