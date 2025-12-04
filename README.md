# FOS Computer Services Homebrew Tap

Official Homebrew tap for FOS Computer Services tools and applications.

## Installation

```bash
brew tap foscomputerservices/tap
```

## Available Formulas

| Formula | Description | Install |
|---------|-------------|---------|
| [hindsight-mcp](https://github.com/foscomputerservices/hindsight-mcp) | MCP server for development knowledge base | `brew install hindsight-mcp` |

## Available Casks

*Coming soon*

## Quick Start

### hindsight-mcp

```bash
brew install foscomputerservices/tap/hindsight-mcp
```

After installation, configure your Claude client:

**Claude Code:**
```bash
claude mcp add hindsight -- hindsight-server
```

**Claude Desktop:** Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "hindsight": {
      "command": "/opt/homebrew/bin/hindsight-server"
    }
  }
}
```

## Troubleshooting

```bash
# Update Homebrew and this tap
brew update

# Reinstall a formula
brew reinstall hindsight-mcp

# Check for issues
brew doctor
```

## For Developers

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on adding new formulas or casks.

## License

MIT License - see individual formula repositories for package-specific licenses.
