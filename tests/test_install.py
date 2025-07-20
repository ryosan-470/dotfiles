#!/usr/bin/env python
"""
Unit tests for refactored install.py
"""

from unittest.mock import Mock

import pytest

# Import the module to test
import install


class TestDotfilesConfig:
    """Test cases for DotfilesConfig"""

    def test_default_config(self, mocker):
        """Test default configuration creation"""
        mocker.patch("os.path.expanduser", return_value="/home/test")

        config = install.DotfilesConfig.default()

        assert config.home_dir == "/home/test"
        assert config.dotfiles_dir == "/home/test/.dotconfig/dotfiles"
        assert config.repo_url == "https://github.com/ryosan-470/dotfiles.git"
        assert ".git" in config.exclude_patterns
        assert "tmux" in config.required_commands

    def test_get_dotfiles(self, mocker):
        """Test getting list of dotfiles"""
        config = install.DotfilesConfig(
            home_dir="/home/test", dotfiles_dir="/home/test/.dotconfig/dotfiles"
        )

        # Mock glob to return sample dotfiles
        mocker.patch(
            "glob.glob",
            return_value=[
                "/home/test/.dotconfig/dotfiles/.zshrc",
                "/home/test/.dotconfig/dotfiles/.vimrc",
                "/home/test/.dotconfig/dotfiles/.git",
                "/home/test/.dotconfig/dotfiles/.gitignore",
            ],
        )

        dotfiles = config.get_dotfiles()

        assert ".zshrc" in dotfiles
        assert ".vimrc" in dotfiles
        assert ".git" not in dotfiles  # Should be excluded
        assert ".gitignore" not in dotfiles  # Should be excluded


class TestDotfilesInstaller:
    """Test cases for DotfilesInstaller"""

    @pytest.fixture
    def mock_dependencies(self):
        """Create mock dependencies"""
        config = install.DotfilesConfig(
            home_dir="/home/test", dotfiles_dir="/home/test/.dotconfig/dotfiles"
        )
        fs = Mock(spec=install.FileSystemInterface)
        runner = Mock(spec=install.CommandRunnerInterface)
        output = Mock(spec=install.OutputInterface)

        return config, fs, runner, output

    @pytest.fixture
    def installer(self, mock_dependencies):
        """Create installer with mocked dependencies"""
        config, fs, runner, output = mock_dependencies
        return install.DotfilesInstaller(config, fs, runner, output)

    def test_check_requirements_all_present(self, installer, mock_dependencies):
        """Test check_requirements when all commands are present"""
        config, fs, runner, output = mock_dependencies
        runner.which.return_value = True

        result = installer.check_requirements()

        assert result is True
        output.warn.assert_not_called()

    def test_check_requirements_missing_commands(self, installer, mock_dependencies):
        """Test check_requirements when commands are missing"""
        config, fs, runner, output = mock_dependencies

        def which_side_effect(cmd):
            return cmd not in ["tmux", "vim"]

        runner.which.side_effect = which_side_effect

        result = installer.check_requirements()

        assert result is False
        output.warn.assert_called_once()
        assert "tmux" in output.warn.call_args[0][0]
        assert "vim" in output.warn.call_args[0][0]

    def test_download_repository_not_exists(self, installer, mock_dependencies):
        """Test downloading when repository doesn't exist"""
        config, fs, runner, output = mock_dependencies
        fs.exists.return_value = False
        runner.run.return_value = True

        result = installer.download("master")

        assert result is True
        runner.run.assert_called_once()
        assert "git clone" in runner.run.call_args[0][0]
        output.success.assert_called()

    def test_download_repository_exists(self, installer, mock_dependencies):
        """Test downloading when repository already exists"""
        config, fs, runner, output = mock_dependencies
        fs.exists.return_value = True

        result = installer.download()

        assert result is True
        runner.run.assert_not_called()
        output.success.assert_called_with(
            "✓ Skip to clone repository since it has been existed"
        )

    def test_deploy_success(self, installer, mock_dependencies, mocker):
        """Test successful deployment"""
        config, fs, runner, output = mock_dependencies
        mocker.patch.object(config, "get_dotfiles", return_value={".zshrc", ".vimrc"})
        fs.exists.return_value = False

        result = installer.deploy()

        assert result is True
        assert fs.create_symlink.call_count == 2
        output.success.assert_called()

    def test_deploy_file_exists(self, installer, mock_dependencies, mocker):
        """Test deployment when files already exist"""
        config, fs, runner, output = mock_dependencies
        mocker.patch.object(config, "get_dotfiles", return_value={".zshrc"})
        fs.exists.return_value = True

        result = installer.deploy()

        assert result is True
        fs.create_symlink.assert_not_called()
        output.warn.assert_called()

    def test_clean_success(self, installer, mock_dependencies, mocker):
        """Test successful clean operation"""
        config, fs, runner, output = mock_dependencies
        mocker.patch.object(config, "get_dotfiles", return_value={".zshrc", ".vimrc"})
        fs.exists.return_value = True

        result = installer.clean()

        assert result is True
        assert fs.remove.call_count == 2
        output.success.assert_called_with("✓ Cleaned!")

    def test_initialize_no_init_dir(self, installer, mock_dependencies):
        """Test initialize when init directory doesn't exist"""
        config, fs, runner, output = mock_dependencies
        fs.exists.return_value = False

        result = installer.initialize()

        assert result is True
        runner.run.assert_not_called()
        output.warn.assert_called_with("No init directory found")

    def test_initialize_with_scripts(self, installer, mock_dependencies):
        """Test initialize with scripts"""
        config, fs, runner, output = mock_dependencies
        fs.exists.return_value = True
        fs.list_files.return_value = [
            "/init/init_zsh.sh",
            "/init/init_tmux.sh",
            "/init/README.md",  # Should be skipped
        ]
        runner.run.return_value = True

        result = installer.initialize()

        assert result is True
        assert runner.run.call_count == 2
        runner.run.assert_any_call("bash /init/init_zsh.sh")
        runner.run.assert_any_call("bash /init/init_tmux.sh")

    def test_verify_all_exist(self, installer, mock_dependencies, mocker):
        """Test verify when all files exist"""
        config, fs, runner, output = mock_dependencies
        mocker.patch.object(config, "get_dotfiles", return_value={".zshrc", ".vimrc"})
        fs.exists.return_value = True

        result = installer.verify()

        assert result is True
        output.success.assert_called_with("✔ All test passed")

    def test_verify_some_missing(self, installer, mock_dependencies, mocker):
        """Test verify when some files are missing"""
        config, fs, runner, output = mock_dependencies
        mocker.patch.object(config, "get_dotfiles", return_value={".zshrc", ".vimrc"})

        def exists_side_effect(path):
            return ".zshrc" in path

        fs.exists.side_effect = exists_side_effect

        result = installer.verify()

        assert result is False
        output.fail.assert_called_with("✘ Some tests are failed")

    def test_install_full_success(self, installer, mock_dependencies):
        """Test full installation success"""
        config, fs, runner, output = mock_dependencies

        # Mock all methods to return success
        installer.check_requirements = Mock(return_value=True)
        installer.download = Mock(return_value=True)
        installer.deploy = Mock(return_value=True)
        installer.initialize = Mock(return_value=True)
        installer.verify = Mock(return_value=True)

        result = installer.install()

        assert result is True
        installer.check_requirements.assert_called_once()
        installer.download.assert_called_once()
        installer.deploy.assert_called_once()
        installer.initialize.assert_called_once()
        installer.verify.assert_called_once()


class TestFileSystem:
    """Test cases for FileSystem implementation"""

    def test_exists(self, mocker):
        """Test exists method"""
        mocker.patch("os.path.exists", return_value=True)
        fs = install.FileSystem()

        assert fs.exists("/some/path") is True

    def test_create_symlink(self, mocker):
        """Test create_symlink method"""
        mock_symlink = mocker.patch("os.symlink")
        fs = install.FileSystem()

        fs.create_symlink("/src", "/dst")
        mock_symlink.assert_called_once_with("/src", "/dst")


class TestCommandRunner:
    """Test cases for CommandRunner implementation"""

    def test_run_success(self, mocker):
        """Test successful command execution"""
        mocker.patch("subprocess.check_call")
        runner = install.CommandRunner()

        result = runner.run("echo test")
        assert result is True

    def test_run_failure(self, mocker):
        """Test failed command execution"""
        mocker.patch(
            "subprocess.check_call",
            side_effect=install.subprocess.CalledProcessError(1, "cmd"),
        )
        runner = install.CommandRunner()

        result = runner.run("false")
        assert result is False

    def test_which_command_exists(self, mocker):
        """Test which when command exists"""
        mocker.patch("os.getenv", return_value="/usr/bin:/usr/local/bin")
        mocker.patch("os.path.exists", return_value=True)
        mocker.patch("os.access", return_value=True)
        runner = install.CommandRunner()

        assert runner.which("python") is True


class TestColoredOutput:
    """Test cases for ColoredOutput implementation"""

    def test_output_methods(self, capsys):
        """Test all output methods"""
        output = install.ColoredOutput()

        output.info("Info message")
        output.success("Success message")
        output.warn("Warning message")
        output.fail("Fail message")

        captured = capsys.readouterr()
        assert "Info message" in captured.out
        assert "Success message" in captured.out
        assert "Warning message" in captured.out
        assert "Fail message" in captured.out
