# Homebrew formula for Hindsight MCP Server
#
# Copyright (c) 2025 FOS Computer Services, LLC
# Licensed under the MIT License

class HindsightMcp < Formula
  desc "MCP server for searchable knowledge base of development learnings"
  homepage "https://github.com/foscomputerservices/hindsight-mcp"
  url "https://github.com/foscomputerservices/hindsight-mcp/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "5828ca3b524905e3b8dc1c4844afcbf2c2ff66a77b00472c1fcc525c23966371"
  license "MIT"
  head "https://github.com/foscomputerservices/hindsight-mcp.git", branch: "main"

  depends_on "python@3.12"

  def install
    # Install server files to libexec
    libexec.install "server.py"
    libexec.install "schema.sql"
    libexec.install "config.json"
    libexec.install "backup.sh"
    libexec.install "setup-backup-schedule.sh"

    # Create virtualenv and install dependencies via pip (let pip resolve everything)
    venv_dir = libexec/"venv"
    system "python3.12", "-m", "venv", venv_dir
    system venv_dir/"bin/pip", "install", "--upgrade", "pip"
    system venv_dir/"bin/pip", "install", "mcp", "python-dateutil"

    # Create wrapper script
    (bin/"hindsight-server").write <<~BASH
      #!/bin/bash
      exec "#{venv_dir}/bin/python" "#{libexec}/server.py" "$@"
    BASH

    # Create init script
    (bin/"hindsight-init").write <<~BASH
      #!/bin/bash
      set -e

      HINDSIGHT_DIR="$HOME/.hindsight"

      echo "Initializing Hindsight..."

      # Create directories
      mkdir -p "$HINDSIGHT_DIR"
      mkdir -p "$HINDSIGHT_DIR/logs"
      mkdir -p "$HINDSIGHT_DIR/backups"

      # Copy config if not exists
      if [ ! -f "$HINDSIGHT_DIR/config.json" ]; then
        cp "#{libexec}/config.json" "$HINDSIGHT_DIR/"
        echo "Created config.json"
      fi

      # Initialize database if not exists
      if [ ! -f "$HINDSIGHT_DIR/knowledge.db" ]; then
        sqlite3 "$HINDSIGHT_DIR/knowledge.db" < "#{libexec}/schema.sql"
        echo "Created knowledge.db"
      fi

      echo ""
      echo "Hindsight initialized at $HINDSIGHT_DIR"
      echo ""
      echo "Configure Claude Code (globally for all projects):"
      echo "  claude mcp add --scope user hindsight -- #{opt_bin}/hindsight-server"
      echo ""
    BASH
  end

  def caveats
    <<~EOS
      Run 'hindsight-init' to set up your database.

      Then configure Claude Code (globally for all projects):
        claude mcp add --scope user hindsight -- #{opt_bin}/hindsight-server

      Or Claude Desktop (add to claude_desktop_config.json):
        {
          "mcpServers": {
            "hindsight": {
              "command": "#{opt_bin}/hindsight-server"
            }
          }
        }
    EOS
  end

  test do
    # Test that the venv and server exist
    assert_predicate libexec/"venv/bin/python", :exist?
    assert_predicate libexec/"server.py", :exist?

    # Test that mcp is installed
    system libexec/"venv/bin/python", "-c", "import mcp"
  end
end
