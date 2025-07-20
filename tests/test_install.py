#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Unit tests for install.py
"""
# Import the module to test
import install

class TestWhichFunction:
    """Test cases for the which() function"""
    def test_which_existing_command(self, mocker):
        """Test which() returns True for existing commands"""
        # Mock os.path.exists to return True
        mocker.patch('os.path.exists', return_value=True)
        # Mock os.access to return True (executable)
        mocker.patch('os.access', return_value=True)
        # Mock os.getenv to return a sample PATH
        mocker.patch('os.getenv', return_value='/usr/bin:/usr/local/bin')
        assert install.which('python') is True

    def test_which_nonexistent_command(self, mocker):
        """Test which() returns False for non-existent commands"""
        # Mock os.path.exists to return False
        mocker.patch('os.path.exists', return_value=False)
        mocker.patch('os.getenv', return_value='/usr/bin:/usr/local/bin')
        assert install.which('nonexistent_command') is False

    def test_which_non_executable_file(self, mocker):
        """Test which() returns False for non-executable files"""
        # Mock os.path.exists to return True
        mocker.patch('os.path.exists', return_value=True)
        # Mock os.access to return False (not executable)
        mocker.patch('os.access', return_value=False)
        mocker.patch('os.getenv', return_value='/usr/bin:/usr/local/bin')
        assert install.which('non_executable_file') is False


class TestHasRequiredFunction:
    """Test cases for the has_required() function"""
    def test_has_required_all_commands_exist(self, mocker):
        """Test has_required() returns True when all required commands exist"""
        # Mock which to always return True
        mocker.patch('install.which', return_value=True)
        assert install.has_required() is True

    def test_has_required_missing_command(self, mocker):
        """Test has_required() returns False when a command is missing"""
        # Mock which to return False for 'tmux'
        def which_side_effect(cmd):
            return cmd != 'tmux'

        mocker.patch('install.which', side_effect=which_side_effect)
        # Mock print to capture output
        mock_print = mocker.patch('builtins.print')
        assert install.has_required() is False
        # Check that warning was printed
        mock_print.assert_called()

    def test_has_required_multiple_missing_commands(self, mocker):
        """Test has_required() handles multiple missing commands"""
        # Mock which to return False for tmux and vim
        def which_side_effect(cmd):
            return cmd not in ['tmux', 'vim']
        mocker.patch('install.which', side_effect=which_side_effect)
        mocker.patch('builtins.print')
        assert install.has_required() is False


class TestFormattedColor:
    """Test cases for the FormattedColor class"""

    def test_success_message(self, req):
        """Test success message formatting"""
        fc = install.FormattedColor()
        fc.success("Test success")
        captured = req.readouterr()
        assert "Test success" in captured.out
        assert install.FormattedColor.SUCCESS in captured.out

    def test_fail_message(self, req):
        """Test fail message formatting"""
        fc = install.FormattedColor()
        fc.fail("Test failure")
        captured = req.readouterr()
        assert "Test failure" in captured.out
        assert install.FormattedColor.DANGER in captured.out

    def test_warn_message(self, req):
        """Test warning message formatting"""
        fc = install.FormattedColor()
        fc.warn("Test warning")
        captured = req.readouterr()
        assert "Test warning" in captured.out
        assert install.FormattedColor.WARNING in captured.out

    def test_info_message(self, req):
        """Test info message formatting"""
        fc = install.FormattedColor()
        fc.info("Test info")
        captured = req.readouterr()
        assert "Test info" in captured.out
        assert install.FormattedColor.BOLD in captured.out


class TestRunFunction:
    """Test cases for the run() function"""

    def test_run_successful_command(self, mocker):
        """Test run() returns True for successful commands"""
        mock_check_call = mocker.patch('subprocess.check_call')
        result = install.run("echo 'test'")
        assert result is True
        mock_check_call.assert_called_once()

    def test_run_failed_command(self, mocker):
        """Test run() returns False for failed commands"""
        # Mock subprocess.check_call to raise CalledProcessError
        mocker.patch('subprocess.check_call',
                    side_effect=install.subprocess.CalledProcessError(1, 'cmd'))
        mock_print = mocker.patch('builtins.print')
        result = install.run("false")
        assert result is False
        # Check that error message was printed
        mock_print.assert_called()


class TestDownloadingDotfiles:
    """Test cases for the downloading_dotfiles() function"""

    def test_downloading_dotfiles_default_branch(self, mocker):
        """Test downloading dotfiles with default branch"""
        mock_run = mocker.patch('install.run', return_value=True)
        mocker.patch('builtins.print')
        result = install.downloading_dotfiles()
        assert result is True
        # Check that git clone was called with master branch
        mock_run.assert_called_once()
        call_args = mock_run.call_args[0][0]
        assert 'git clone' in call_args
        assert '-b master' in call_args

    def test_downloading_dotfiles_custom_branch(self, mocker):
        """Test downloading dotfiles with custom branch"""
        mock_run = mocker.patch('install.run', return_value=True)
        result = install.downloading_dotfiles("develop")
        assert result is True
        call_args = mock_run.call_args[0][0]
        assert '-b develop' in call_args

    def test_downloading_dotfiles_failed(self, mocker):
        """Test downloading dotfiles when git clone fails"""
        mocker.patch('install.run', return_value=False)
        result = install.downloading_dotfiles()
        assert result is False
