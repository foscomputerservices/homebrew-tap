# Homebrew Tap Setup for Hindsight MCP Server

This document describes how to set up and maintain the Homebrew tap for distributing Hindsight MCP Server.

## Tap Repository Structure

Create a repository named `homebrew-tap` under the FOS Computer Services organization:

```
foscomputerservices/homebrew-tap/
├── Formula/
│   └── hindsight-mcp.rb
└── README.md
```

## Initial Setup

### 1. Create the Tap Repository

```bash
# Create new repository on GitHub: foscomputerservices/homebrew-tap
# Clone it locally
git clone https://github.com/foscomputerservices/homebrew-tap.git
cd homebrew-tap

# Create Formula directory
mkdir -p Formula

# Copy the formula from hindsight-mcp repo
cp /path/to/hindsight-mcp/Formula/hindsight-mcp.rb Formula/
```

### 2. Generate Release and SHA256

Before publishing, you need to:

1. Create a release tag in the main hindsight-mcp repository:
   ```bash
   cd /path/to/hindsight-mcp
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. Get the SHA256 of the release tarball:
   ```bash
   curl -sL https://github.com/foscomputerservices/hindsight-mcp/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
   ```

3. Update the formula with the correct SHA256

### 3. Update Python Resource Hashes

Use Homebrew's built-in tool to generate correct resource stanzas:

```bash
# First, install the formula to get it registered
brew install --build-from-source ./Formula/hindsight-mcp.rb

# Then update resources
brew update-python-resources hindsight-mcp
```

Alternatively, manually get SHA256 for each Python package:

```bash
# Example for mcp package
curl -sL https://files.pythonhosted.org/packages/source/m/mcp/mcp-1.0.0.tar.gz | shasum -a 256
```

### 4. Test the Formula Locally

```bash
# Install from local formula
brew install --build-from-source ./Formula/hindsight-mcp.rb

# Test it works
hindsight-init --skip-claude-config
hindsight-server &
# Check it starts without errors, then kill it

# Run formula tests
brew test hindsight-mcp

# Audit the formula
brew audit --strict hindsight-mcp
```

### 5. Commit and Push

```bash
git add Formula/hindsight-mcp.rb
git commit -m "Add hindsight-mcp formula v1.0.0"
git push origin main
```

## User Installation

Once the tap is published, users install with:

```bash
# Add the tap (one-time)
brew tap foscomputerservices/tap

# Install hindsight-mcp
brew install hindsight-mcp

# Initialize and configure Claude
hindsight-init
```

## Updating the Formula

When releasing a new version:

### 1. Tag New Release

```bash
cd /path/to/hindsight-mcp
git tag v1.x.x
git push origin v1.x.x
```

### 2. Update Formula

```bash
cd /path/to/homebrew-tap

# Update URL version
# Update SHA256 hash
# Update any changed dependencies

# Get new SHA256
curl -sL https://github.com/foscomputerservices/hindsight-mcp/archive/refs/tags/v1.x.x.tar.gz | shasum -a 256
```

### 3. Test and Push

```bash
brew upgrade hindsight-mcp --build-from-source
brew test hindsight-mcp
brew audit --strict hindsight-mcp

git add Formula/hindsight-mcp.rb
git commit -m "Update hindsight-mcp to v1.x.x"
git push origin main
```

## Formula Notes

### Python Dependencies

The formula uses `virtualenv_install_with_resources` which:
- Creates an isolated Python environment in `libexec`
- Installs all declared resource packages
- Avoids conflicts with system Python packages

Key dependencies:
- `mcp` - Model Context Protocol SDK
- `pydantic` - Data validation (required by mcp)
- `python-dateutil` - Date parsing utilities

### File Locations

After Homebrew installation:

| File | Location |
|------|----------|
| Server script | `$(brew --prefix)/opt/hindsight-mcp/libexec/server.py` |
| Schema | `$(brew --prefix)/opt/hindsight-mcp/libexec/schema.sql` |
| Default config | `$(brew --prefix)/etc/hindsight/config.json` |
| Python venv | `$(brew --prefix)/opt/hindsight-mcp/libexec/` |
| User database | `~/.hindsight/knowledge.db` |
| User config | `~/.hindsight/config.json` |
| Logs | `~/.hindsight/logs/` |

### Wrapper Scripts

The formula installs these wrapper scripts to `bin`:

- `hindsight-server` - Runs the MCP server
- `hindsight-init` - Initializes runtime and configures Claude
- `hindsight-backup` - Manual database backup
- `hindsight-backup-schedule` - Set up automated backups

## Troubleshooting

### Formula Won't Install

```bash
# Check for issues
brew audit --strict hindsight-mcp

# Verbose install
brew install -v hindsight-mcp
```

### Python Resource Errors

If Python packages fail to install:

```bash
# Update resource hashes
brew update-python-resources hindsight-mcp

# Or manually verify URLs are correct on PyPI
```

### Server Won't Start

```bash
# Check Python path
$(brew --prefix)/opt/hindsight-mcp/libexec/bin/python3 --version

# Try importing directly
$(brew --prefix)/opt/hindsight-mcp/libexec/bin/python3 -c "from server import KnowledgeBaseServer"
```

## CI/CD Integration

Consider adding GitHub Actions to the tap repository:

```yaml
# .github/workflows/test.yml
name: Test Formula

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install formula
        run: brew install --build-from-source ./Formula/hindsight-mcp.rb
      - name: Test formula
        run: brew test hindsight-mcp
      - name: Audit formula
        run: brew audit --strict hindsight-mcp
```

## References

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Python for Formula Authors](https://docs.brew.sh/Python-for-Formula-Authors)
- [Creating a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
