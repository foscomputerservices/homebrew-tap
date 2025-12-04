# Contributing to homebrew-tap

Guidelines for adding and maintaining formulas and casks in this tap.

## Repository Structure

```
homebrew-tap/
├── Formula/           # CLI tools and libraries
│   └── hindsight-mcp.rb
├── Casks/             # macOS GUI applications (.app bundles)
├── .github/workflows/ # CI/CD automation
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

## Adding a New Formula

### For Python Packages

1. Create `Formula/<name>.rb`:

```ruby
class MyTool < Formula
  include Language::Python::Virtualenv

  desc "Short description"
  homepage "https://github.com/foscomputerservices/<repo>"
  url "https://github.com/foscomputerservices/<repo>/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "<sha256-of-tarball>"
  license "MIT"
  head "https://github.com/foscomputerservices/<repo>.git", branch: "main"

  depends_on "python@3.12"

  # Pin direct dependencies only - let pip resolve transitive deps
  resource "some-dep" do
    url "https://files.pythonhosted.org/packages/..."
    sha256 "<sha256>"
  end

  def install
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install resources
    venv.pip_install buildpath

    # Create wrapper script
    (bin/"my-tool").write <<~BASH
      #!/bin/bash
      exec "#{libexec}/bin/python3" -m my_module "$@"
    BASH
  end

  test do
    system libexec/"bin/python3", "-c", "import my_module"
  end
end
```

2. Generate the release SHA256:
```bash
curl -sL "https://github.com/foscomputerservices/<repo>/archive/refs/tags/v1.0.0.tar.gz" | shasum -a 256
```

3. Get dependency info from PyPI:
```bash
curl -s "https://pypi.org/pypi/<package>/json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
info = d['info']
urls = d['urls']
sdist = [u for u in urls if u['packagetype'] == 'sdist'][0]
print(f'URL: {sdist[\"url\"]}')
print(f'SHA256: {sdist[\"digests\"][\"sha256\"]}')
"
```

### For Compiled Tools (Swift, Go, Rust)

```ruby
class MySwiftTool < Formula
  desc "Short description"
  homepage "https://github.com/foscomputerservices/<repo>"
  url "https://github.com/foscomputerservices/<repo>/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "<sha256>"
  license "MIT"

  depends_on xcode: ["15.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/my-tool"
  end

  test do
    assert_match "version", shell_output("#{bin}/my-tool --version")
  end
end
```

## Adding a New Cask

For macOS applications with `.app` bundles:

```ruby
cask "my-app" do
  version "1.0.0"
  sha256 "<sha256-of-dmg-or-zip>"

  url "https://github.com/foscomputerservices/<repo>/releases/download/v#{version}/MyApp.dmg"
  name "My App"
  desc "Short description"
  homepage "https://github.com/foscomputerservices/<repo>"

  app "MyApp.app"
end
```

## Publishing a Release

### Manual (via GitHub Actions UI)

1. Go to Actions > Publish Formula
2. Enter the formula name, version, and SHA256
3. A PR will be created automatically

### Automated (from source repo)

Add to your source repo's release workflow:

```yaml
- name: Update Homebrew formula
  uses: peter-evans/repository-dispatch@v2
  with:
    token: ${{ secrets.TAP_GITHUB_TOKEN }}
    repository: foscomputerservices/homebrew-tap
    event-type: formula-release
    client-payload: |
      {
        "formula": "hindsight-mcp",
        "version": "${{ github.ref_name }}",
        "sha256": "${{ steps.sha.outputs.sha256 }}"
      }
```

## Testing Locally

```bash
# Tap your local development version
brew tap foscomputerservices/tap /path/to/homebrew-tap

# Audit the formula
brew audit --strict hindsight-mcp

# Test installation
brew install --build-from-source hindsight-mcp

# Run formula tests
brew test hindsight-mcp

# Uninstall
brew uninstall hindsight-mcp
```

## Style Guidelines

- Formula class names use CamelCase: `HindsightMcp`
- Formula files use kebab-case: `hindsight-mcp.rb`
- Keep descriptions under 80 characters
- Always include a `test` block
- Pin direct dependencies, not transitive ones
- Use `opt_bin` in caveats for bottle compatibility

## References

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Python for Formula Authors](https://docs.brew.sh/Python-for-Formula-Authors)
- [Creating a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
