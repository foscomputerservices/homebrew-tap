# Homebrew formula for Hindsight MCP Server
#
# This formula is intended for the foscomputerservices/homebrew-tap repository.
# Copy this file to: homebrew-tap/Formula/hindsight-mcp.rb
#
# Copyright (c) 2025 FOS Computer Services, LLC
# Licensed under the MIT License

class HindsightMcp < Formula
  include Language::Python::Virtualenv

  desc "MCP server for searchable knowledge base of development learnings"
  homepage "https://github.com/foscomputerservices/hindsight-mcp"
  url "https://github.com/foscomputerservices/hindsight-mcp/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_HASH"
  license "MIT"
  head "https://github.com/foscomputerservices/hindsight-mcp.git", branch: "main"

  depends_on "python@3.12"

  # Python dependencies - update with: brew update-python-resources hindsight-mcp
  # Note: Run this command after installing the formula to generate accurate resources
  #
  # Required packages: mcp, pydantic (and their transitive dependencies)
  # Use PyPI URLs from https://pypi.org/project/<package>/#files

  resource "mcp" do
    url "https://files.pythonhosted.org/packages/source/m/mcp/mcp-1.0.0.tar.gz"
    sha256 "PLACEHOLDER_MCP_SHA256"
  end

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/source/p/pydantic/pydantic-2.10.3.tar.gz"
    sha256 "PLACEHOLDER_PYDANTIC_SHA256"
  end

  resource "pydantic-core" do
    url "https://files.pythonhosted.org/packages/source/p/pydantic-core/pydantic_core-2.27.1.tar.gz"
    sha256 "PLACEHOLDER_PYDANTIC_CORE_SHA256"
  end

  resource "annotated-types" do
    url "https://files.pythonhosted.org/packages/source/a/annotated-types/annotated_types-0.7.0.tar.gz"
    sha256 "PLACEHOLDER_ANNOTATED_TYPES_SHA256"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/source/t/typing-extensions/typing_extensions-4.12.2.tar.gz"
    sha256 "PLACEHOLDER_TYPING_EXT_SHA256"
  end

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/source/a/anyio/anyio-4.7.0.tar.gz"
    sha256 "PLACEHOLDER_ANYIO_SHA256"
  end

  resource "httpx" do
    url "https://files.pythonhosted.org/packages/source/h/httpx/httpx-0.28.1.tar.gz"
    sha256 "PLACEHOLDER_HTTPX_SHA256"
  end

  resource "httpcore" do
    url "https://files.pythonhosted.org/packages/source/h/httpcore/httpcore-1.0.7.tar.gz"
    sha256 "PLACEHOLDER_HTTPCORE_SHA256"
  end

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/source/c/certifi/certifi-2024.8.30.tar.gz"
    sha256 "PLACEHOLDER_CERTIFI_SHA256"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/source/i/idna/idna-3.10.tar.gz"
    sha256 "PLACEHOLDER_IDNA_SHA256"
  end

  resource "sniffio" do
    url "https://files.pythonhosted.org/packages/source/s/sniffio/sniffio-1.3.1.tar.gz"
    sha256 "PLACEHOLDER_SNIFFIO_SHA256"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/source/h/h11/h11-0.14.0.tar.gz"
    sha256 "PLACEHOLDER_H11_SHA256"
  end

  resource "python-dateutil" do
    url "https://files.pythonhosted.org/packages/source/p/python-dateutil/python_dateutil-2.9.0.post0.tar.gz"
    sha256 "PLACEHOLDER_DATEUTIL_SHA256"
  end

  resource "six" do
    url "https://files.pythonhosted.org/packages/source/s/six/six-1.16.0.tar.gz"
    sha256 "1e61c37477a1626458e36f7b1d82aa5c9b094fa4802892072e49de9c60c4c926"
  end

  def install
    # Install Python package and dependencies into virtualenv
    virtualenv_install_with_resources

    # Install the main server script
    libexec.install "server.py"
    libexec.install "schema.sql"

    # Install configuration template
    (etc/"hindsight").mkpath
    (etc/"hindsight").install "config.json"

    # Install initialization script
    bin.install "bin/hindsight-init"

    # Install backup scripts
    bin.install "backup.sh" => "hindsight-backup"
    bin.install "setup-backup-schedule.sh" => "hindsight-backup-schedule"

    # Create wrapper script for the MCP server
    (bin/"hindsight-server").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/bin/python3" "#{libexec}/server.py" "$@"
    EOS
  end

  def post_install
    # Create runtime directory structure
    (var/"hindsight").mkpath
    (var/"hindsight/logs").mkpath
    (var/"hindsight/backups").mkpath
  end

  def caveats
    <<~EOS
      To initialize Hindsight and configure Claude Desktop/Code:

        hindsight-init

      This will:
        - Create ~/.hindsight/ directory
        - Initialize the knowledge database
        - Configure Claude Desktop and/or Claude Code (if installed)

      Manual configuration (if needed):

      For Claude Desktop, add to ~/Library/Application Support/Claude/claude_desktop_config.json:
        {
          "mcpServers": {
            "hindsight": {
              "command": "#{opt_bin}/hindsight-server"
            }
          }
        }

      For Claude Code:
        claude mcp add hindsight -- #{opt_bin}/hindsight-server

      Restart Claude Desktop after configuration.

      To verify: claude mcp list
    EOS
  end

  test do
    # Test that the server can be imported
    system libexec/"bin/python3", "-c", "import sys; sys.path.insert(0, '#{libexec}'); from server import KnowledgeBaseServer; print('Import successful')"

    # Test that schema.sql exists and is valid SQL
    assert_predicate libexec/"schema.sql", :exist?
    system "sqlite3", ":memory:", ".read #{libexec}/schema.sql"
  end
end
