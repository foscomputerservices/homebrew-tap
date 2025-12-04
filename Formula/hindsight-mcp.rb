# Homebrew formula for Hindsight MCP Server
#
# Copyright (c) 2025 FOS Computer Services, LLC
# Licensed under the MIT License

class HindsightMcp < Formula
  include Language::Python::Virtualenv

  desc "MCP server for searchable knowledge base of development learnings"
  homepage "https://github.com/foscomputerservices/hindsight-mcp"
  url "https://github.com/foscomputerservices/hindsight-mcp/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_RELEASE_SHA256"
  license "MIT"
  head "https://github.com/foscomputerservices/hindsight-mcp.git", branch: "main"

  depends_on "python@3.12"

  # Core dependencies - transitive deps resolved by pip at install time
  # To regenerate: pip install homebrew-pypi-poet && poet hindsight-mcp

  resource "mcp" do
    url "https://files.pythonhosted.org/packages/12/42/10c0c09ca27aceacd8c428956cfabdd67e3d328fe55c4abc16589285d294/mcp-1.23.1.tar.gz"
    sha256 "7403e053e8e2283b1e6ae631423cb54736933fea70b32422152e6064556cd298"
  end

  resource "python-dateutil" do
    url "https://files.pythonhosted.org/packages/66/c0/0c8b6ad9f17a802ee498c46e004a0eb49bc148f2fd230864601a86dcf6db/python-dateutil-2.9.0.post0.tar.gz"
    sha256 "37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3"
  end

  resource "six" do
    url "https://files.pythonhosted.org/packages/94/e7/b2c673351809dca68a0e064b6af791aa332cf192da575fd474ed7d6f16a2/six-1.17.0.tar.gz"
    sha256 "ff70335d468e7eb6ec65b95b99d3a2836546063f63acc5171de367e834932a81"
  end

  def install
    # Create virtualenv and install dependencies
    venv = virtualenv_create(libexec, "python3.12")

    # Install pinned direct dependencies
    venv.pip_install resources

    # Install the package itself (this resolves any remaining transitive deps)
    venv.pip_install buildpath

    # Create wrapper script for the MCP server
    (bin/"hindsight-server").write <<~BASH
      #!/bin/bash
      exec "#{libexec}/bin/python3" -m server "$@"
    BASH

    # Install schema for reference
    pkgshare.install "schema.sql"
  end

  def post_install
    # Create data directory
    (var/"hindsight").mkpath
  end

  def caveats
    <<~EOS
      To configure Claude Code:
        claude mcp add hindsight -- #{opt_bin}/hindsight-server

      To configure Claude Desktop, add to:
        ~/Library/Application Support/Claude/claude_desktop_config.json

        {
          "mcpServers": {
            "hindsight": {
              "command": "#{opt_bin}/hindsight-server"
            }
          }
        }

      Data is stored in: #{var}/hindsight

      Restart Claude after configuration.
    EOS
  end

  test do
    # Test that the server module can be imported
    system libexec/"bin/python3", "-c", "from server import KnowledgeBaseServer"

    # Test schema is valid SQL
    assert_predicate pkgshare/"schema.sql", :exist?
    system "sqlite3", ":memory:", ".read #{pkgshare}/schema.sql"
  end
end
