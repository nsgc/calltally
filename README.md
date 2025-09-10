# Calltally

> Tally your method calls.

A simple yet powerful tool to analyze method usage in Ruby/Rails codebases. Quickly identify your most-used methods, understand code patterns, and make informed refactoring decisions.

## Installation

Add to your Gemfile:

```ruby
gem 'calltally', group: :development
```

Or install globally:

```bash
gem install calltally
```

## Quick Start

```bash
# Analyze current directory
calltally

# Analyze specific directory
calltally app/models

# Show top 20 results
calltally --top 20

# Focus on specific classes
calltally --receivers User,Post --top 10
```

## Usage Examples

### Rails Projects

Calltally automatically detects Rails projects and scans the right directories:

```bash
# Auto-detects Rails and scans app/, lib/, config/
calltally

# Include ERB templates
calltally --erb

# Focus on ActiveRecord methods
calltally --methods where,find,joins --mode pairs
```

### Output Formats

```bash
# Default table format
calltally

# JSON format for further processing
calltally --format json > analysis.json

# CSV for spreadsheet analysis
calltally --format csv -o results.csv
```

### Filtering and Analysis

```bash
# Show only method names (no receivers)
calltally --mode methods

# Show only receivers (classes being called)
calltally --mode receivers

# Show receiver-method pairs (default)
calltally --mode pairs

# Include methods called without explicit receivers
calltally --include-nil-receiver
```

## Configuration

Create `.calltally.yml` in your project root for persistent settings:

```yaml
# .calltally.yml
profile: rails          # auto|rails|default
dirs:                   # Directories to scan
  - app
  - lib
exclude:                # Patterns to exclude
  - spec
  - test
  - vendor
top: 50                 # Number of results to show
include_erb: true       # Process ERB files
mode: pairs            # pairs|methods|receivers
skip_operators: true    # Skip operators like +, -, ==
```

You can also use a custom config file:

```bash
calltally --config config/calltally-production.yml
```

## Advanced Usage

<details>
<summary>Filter by Variable Types</summary>

```bash
# Only local variables
calltally --only-locals

# Only instance variables
calltally --only-ivars

# Only class/module constants
calltally --only-constants

# Class variables
calltally --only-cvars

# Global variables
calltally --only-gvars

# Combine filters
calltally --only-locals --only-constants

# Show variable names instead of grouping
calltally --split-variables
# Shows: (var:user).name instead of (var).name
```
</details>

<details>
<summary>All CLI Options</summary>

```
calltally [PATH] [options]

Options:
  --profile PROFILE        auto|rails|default (default: auto)
  -d, --dirs x,y           Directories to include
  -x, --exclude x,y        Path parts to exclude
  -n, --top N              Show top N results (default: 100)
  -v, --verbose            Verbose output
  --erb                    Include .erb files (requires erubi gem)

  --mode MODE              Output mode:
                           - pairs: receiver-method pairs (default)
                           - methods: method names only
                           - receivers: receiver names only

  --receivers x,y          Filter by receiver constants (e.g. User,Post)
  --methods x,y            Filter by method names (e.g. where,find)

  --include-nil-receiver   Count calls without explicit receiver
  --split-variables        Show variable names (e.g. '(var:user)' vs '(var)')

  --only-locals            Show only local variable receivers
  --only-ivars             Show only instance variable receivers
  --only-cvars             Show only class variable receivers
  --only-gvars             Show only global variable receivers
  --only-constants         Show only constant receivers

  --[no-]skip-operators    Skip operator methods like +, -, ==, [] (default: true)

  --format FORMAT          Output format: table|json|csv (default: table)
  -o, --output PATH        Write result to file instead of STDOUT
  --config PATH            Use a specific config file
  -h, --help               Show help
```
</details>

## Understanding the Output

Calltally shows method calls in your codebase with their receivers:

```
10  User.where          # User class, where method, called 10 times
 5  (var).each          # Local variable, each method, called 5 times
 3  (ivar).save         # Instance variable, save method
 2  Post#.validate      # validate called within Post class (implicit receiver)
```

### Receiver Types

- `User` - Class or module constant
- `(var)` - Local variable (use `--split-variables` to see names)
- `(ivar)` - Instance variable
- `(cvar)` - Class variable
- `(gvar)` - Global variable
- `(self)` - Explicit self receiver
- `(result)` - Method calls on results (e.g., `user.posts.first` → `(var).posts` + `(result).first`)
- `#` - Implicit receiver (when using `--include-nil-receiver`)

## Use Cases

1. **Find most-used methods** - Identify candidates for optimization
2. **Understand code patterns** - See how your team uses APIs
3. **Refactoring decisions** - Know what methods are heavily depended upon
4. **API design** - Understand which methods are actually used
5. **Code reviews** - Quickly analyze unfamiliar codebases
6. **Gem development** - See how your gem's methods are used

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nsgc/calltally.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).